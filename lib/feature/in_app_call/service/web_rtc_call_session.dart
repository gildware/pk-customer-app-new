import 'package:demandium/feature/in_app_call/repo/in_app_call_repo.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class WebRtcCallSession {
  WebRtcCallSession({required this.repo, required this.callId});

  final InAppCallRepo repo;
  final String callId;

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  final Set<String> _seenSignalIds = {};
  bool _hasRemoteDescription = false;
  bool _muted = false;
  bool _onHold = false;
  bool _speakerOn = true;

  bool get isMuted => _muted;
  bool get isOnHold => _onHold;
  bool get isSpeakerOn => _speakerOn;

  Future<void> dispose() async {
    try {
      await _localStream?.dispose();
    } catch (_) {}
    try {
      await _remoteStream?.dispose();
    } catch (_) {}
    try {
      await _peerConnection?.close();
    } catch (_) {}
    _peerConnection = null;
    _localStream = null;
    _remoteStream = null;
  }

  Future<void> startAsCaller(List<Map<String, dynamic>> iceServers) async {
    await _initPeerConnection(iceServers);
    final offer = await _peerConnection!.createOffer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': false,
    });
    await _peerConnection!.setLocalDescription(offer);
    await repo.postSignal(callId, 'offer', Map<String, dynamic>.from(offer.toMap()));
    await setSpeakerOn(true);
  }

  Future<void> startAsCallee(List<Map<String, dynamic>> iceServers) async {
    await _initPeerConnection(iceServers);
    await _waitForOffer();
    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);
    await repo.postSignal(callId, 'answer', Map<String, dynamic>.from(answer.toMap()));
    await setSpeakerOn(true);
  }

  Future<void> setMuted(bool muted) async {
    _muted = muted;
    for (final track in _localStream?.getAudioTracks() ?? <MediaStreamTrack>[]) {
      track.enabled = !muted;
    }
  }

  Future<void> toggleMute() => setMuted(!_muted);

  Future<void> setOnHold(bool onHold) async {
    _onHold = onHold;
    await setMuted(onHold);
    for (final track in _remoteStream?.getAudioTracks() ?? <MediaStreamTrack>[]) {
      track.enabled = !onHold;
    }
  }

  Future<void> toggleHold() => setOnHold(!_onHold);

  Future<void> setSpeakerOn(bool speakerOn) async {
    _speakerOn = speakerOn;
    await Helper.setSpeakerphoneOn(speakerOn);
  }

  Future<void> toggleSpeaker() => setSpeakerOn(!_speakerOn);

  Future<void> pollPeerSignals() async {
    final response = await repo.listSignals(callId);
    if (response.statusCode != 200 || response.body['content'] == null) return;

    final signals = response.body['content'];
    if (signals is! List) return;

    for (final raw in signals) {
      if (raw is! Map) continue;
      final signal = Map<String, dynamic>.from(raw);
      final id = signal['id']?.toString() ?? '';
      if (id.isEmpty || _seenSignalIds.contains(id)) continue;
      _seenSignalIds.add(id);

      final type = signal['signal_type']?.toString() ?? '';
      final payload = signal['payload'];
      if (payload is! Map) continue;
      final payloadMap = Map<String, dynamic>.from(payload);

      try {
        if (type == 'offer' && !_hasRemoteDescription) {
          await _peerConnection?.setRemoteDescription(
            RTCSessionDescription(payloadMap['sdp'], payloadMap['type']),
          );
          _hasRemoteDescription = true;
        } else if (type == 'answer' && !_hasRemoteDescription) {
          await _peerConnection?.setRemoteDescription(
            RTCSessionDescription(payloadMap['sdp'], payloadMap['type']),
          );
          _hasRemoteDescription = true;
        } else if (type == 'ice' && payloadMap['candidate'] != null) {
          await _peerConnection?.addCandidate(
            RTCIceCandidate(
              payloadMap['candidate'],
              payloadMap['sdpMid'],
              payloadMap['sdpMLineIndex'],
            ),
          );
        }
      } catch (e) {
        if (kDebugMode) {
          print('WebRTC signal error: $e');
        }
      }
    }
  }

  Future<void> _waitForOffer() async {
    for (var i = 0; i < 30; i++) {
      await pollPeerSignals();
      if (_hasRemoteDescription) return;
      await Future.delayed(const Duration(milliseconds: 500));
    }
    throw StateError('Timed out waiting for call offer');
  }

  Future<void> _initPeerConnection(List<Map<String, dynamic>> iceServers) async {
    final configuration = <String, dynamic>{
      'iceServers': iceServers,
      'sdpSemantics': 'unified-plan',
    };
    _peerConnection = await createPeerConnection(configuration);
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': false,
    });

    for (final track in _localStream!.getTracks()) {
      await _peerConnection!.addTrack(track, _localStream!);
    }

    _peerConnection!.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams.first;
      }
      if (event.track.kind == 'audio') {
        event.track.enabled = !_onHold;
      }
    };

    _peerConnection!.onIceCandidate = (RTCIceCandidate? candidate) {
      if (candidate == null || candidate.candidate == null || candidate.candidate!.isEmpty) {
        return;
      }
      repo.postSignal(callId, 'ice', {
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      });
    };
  }
}
