import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:demandium/feature/in_app_call/helper/call_sound_util.dart';
import 'package:demandium/feature/in_app_call/model/in_app_call_model.dart';
import 'package:demandium/feature/in_app_call/repo/in_app_call_repo.dart';
import 'package:demandium/feature/in_app_call/service/web_rtc_call_session.dart';
import 'package:demandium/feature/in_app_call/view/in_app_call_screen.dart';
import 'package:demandium/util/core_export.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

enum InAppCallPhase { idle, calling, ringing, incoming, connecting, inCall, ended }

class InAppCallController extends GetxController with WidgetsBindingObserver implements GetxService {
  InAppCallController({required this.inAppCallRepo});

  final InAppCallRepo inAppCallRepo;

  InAppCallConfig _config = const InAppCallConfig(
    enabled: true,
    iceServers: [{'urls': 'stun:stun.l.google.com:19302'}],
    ringTimeoutSeconds: 60,
  );
  InAppCallConfig get config => _config;

  InAppCallModel? _activeCall;
  InAppCallModel? get activeCall => _activeCall;

  InAppCallPhase _phase = InAppCallPhase.idle;
  InAppCallPhase get phase => _phase;

  bool _busy = false;
  bool get busy => _busy;

  WebRtcCallSession? _webRtc;
  final AudioPlayer _ringPlayer = AudioPlayer();
  Timer? _pollTimer;
  Timer? _signalPollTimer;
  Timer? _ringTimeoutTimer;
  String _callDurationLabel = '00:00';
  String get callDurationLabel => _callDurationLabel;
  Timer? _durationTimer;
  DateTime? _connectedAt;
  bool _callScreenOpen = false;
  Timer? _incomingPollTimer;
  String? _lastEndedCallId;
  DateTime? _suppressPendingUntil;

  bool get isMuted => _webRtc?.isMuted ?? false;
  bool get isOnHold => _webRtc?.isOnHold ?? false;
  bool get isSpeakerOn => _webRtc?.isSpeakerOn ?? true;

  List<InAppCallModel>? _callHistoryList;
  List<InAppCallModel>? get callHistoryList => _callHistoryList;
  List<InAppCallModel>? get callHistory => _callHistoryList;

  int? _callHistoryPageSize;
  int? get callHistoryPageSize => _callHistoryPageSize;
  int? _callHistoryLastPage;
  int? get callHistoryLastPage => _callHistoryLastPage;

  int _callHistoryOffset = 1;
  int get callHistoryOffset => _callHistoryOffset;
  bool _callHistoryLoading = false;
  bool get callHistoryLoading => _callHistoryLoading;

  bool get isEnabled => _config.enabled;

  List<Map<String, dynamic>> get _iceServers {
    if (_activeCall != null && _activeCall!.iceServers.isNotEmpty) {
      return _activeCall!.iceServers;
    }
    return _config.iceServers;
  }

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _incomingPollTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      unawaited(checkPendingIncomingCall());
    });
    unawaited(loadConfig());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(checkPendingIncomingCall());
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _incomingPollTimer?.cancel();
    _stopRingtone();
    _pollTimer?.cancel();
    _signalPollTimer?.cancel();
    _ringTimeoutTimer?.cancel();
    _durationTimer?.cancel();
    _disposeWebRtc();
    _ringPlayer.dispose();
    super.onClose();
  }

  Future<void> loadConfig() async {
    final response = await inAppCallRepo.getConfig();
    if (response.statusCode == 200 && response.body['content'] != null) {
      _config = InAppCallConfig.fromJson(
        Map<String, dynamic>.from(response.body['content'] as Map),
      );
      update();
    }
    await checkPendingIncomingCall();
  }

  Future<void> checkPendingIncomingCall() async {
    if (_phase != InAppCallPhase.idle) return;
    if (_suppressPendingUntil != null && DateTime.now().isBefore(_suppressPendingUntil!)) {
      return;
    }

    Response? response;
    for (var attempt = 0; attempt < 3; attempt++) {
      response = await inAppCallRepo.getPendingIncoming();
      if (response.statusCode == 200) break;
      if (response.statusCode != 500 || attempt == 2) return;
      await Future.delayed(Duration(milliseconds: 250 * (attempt + 1)));
    }

    if (response == null || response.statusCode != 200) return;

    final rawContent = response.body['content'];
    if (rawContent is! Map) return;

    final content = Map<String, dynamic>.from(rawContent);
    final callId = content['call_id']?.toString() ?? '';
    if (callId.isEmpty || callId == _lastEndedCallId) return;

    await handlePushData({
      'type': 'incoming_call',
      'call_id': callId,
      'channel_id': content['channel_id']?.toString() ?? '',
      'user_name': content['peer'] is Map ? content['peer']['name']?.toString() : null,
      'user_image': content['peer'] is Map ? content['peer']['image']?.toString() : null,
      'user_phone': content['peer'] is Map ? content['peer']['phone']?.toString() : null,
      'user_type': content['peer'] is Map ? content['peer']['user_type']?.toString() : null,
    });
  }

  bool _isAdminSupportChat(String? userType) {
    if (userType == null || userType.isEmpty) return false;
    final type = userType.toLowerCase().trim();
    return type == 'super-admin' || type == 'admin';
  }

  bool canCallPeer(String? userType) {
    if (userType == null || userType.isEmpty) return false;
    if (_isAdminSupportChat(userType)) return false;
    final type = userType.toLowerCase();
    return type.contains('provider') || type.contains('serviceman');
  }

  Future<void> getCallHistory(int offset, {bool reload = false}) async {
    if (_callHistoryLoading) return;
    _callHistoryLoading = true;
    if (reload) {
      _callHistoryOffset = 1;
      _callHistoryList = null;
    } else {
      _callHistoryOffset = offset;
    }
    update();

    final response = await inAppCallRepo.getHistory(_callHistoryOffset);
    _callHistoryLoading = false;

    if (response.statusCode == 200 && response.body['content'] != null) {
      final content = response.body['content'];
      final rawList = content['data'];
      final parsed = <InAppCallModel>[];
      if (rawList is List) {
        for (final item in rawList) {
          if (item is Map) {
            parsed.add(InAppCallModel.fromHistoryJson(Map<String, dynamic>.from(item)));
          }
        }
      }

      if (reload || _callHistoryList == null || _callHistoryOffset == 1) {
        _callHistoryList = parsed;
      } else {
        _callHistoryList = [...?_callHistoryList, ...parsed];
      }
      _callHistoryPageSize = int.tryParse(content['total_size']?.toString() ?? '');
      final limit = int.tryParse(content['limit']?.toString() ?? '20') ?? 20;
      final totalSize = _callHistoryPageSize ?? 0;
      _callHistoryLastPage = limit > 0 ? (totalSize / limit).ceil() : 1;
      if ((_callHistoryLastPage ?? 1) < 1) _callHistoryLastPage = 1;
    } else if (reload || _callHistoryOffset == 1) {
      _callHistoryList = [];
    }
    update();
  }

  void _refreshCallHistory() {
    unawaited(getCallHistory(1, reload: true));
  }

  String get phaseStatusLabel {
    switch (_phase) {
      case InAppCallPhase.calling:
        return 'calling'.tr;
      case InAppCallPhase.ringing:
      case InAppCallPhase.incoming:
        return 'ringing'.tr;
      case InAppCallPhase.connecting:
        return 'connecting'.tr;
      case InAppCallPhase.inCall:
        if (isOnHold) return 'on_hold'.tr;
        return _callDurationLabel;
      case InAppCallPhase.ended:
        return 'call_ended'.tr;
      case InAppCallPhase.idle:
        return '';
    }
  }

  bool get isCallerRingingPhase =>
      _phase == InAppCallPhase.calling || _phase == InAppCallPhase.ringing;

  bool shouldShowCallButton(String? channelId, String? userType) {
    if (channelId == null || channelId.isEmpty) return false;
    if (_busy || _phase != InAppCallPhase.idle) return false;
    if (userType == null || userType.isEmpty) return true;
    return canCallPeer(userType);
  }

  Future<void> startCall(
    String channelId, {
    String? peerName,
    String? peerImage,
    String? peerPhone,
    String? peerUserType,
  }) async {
    if (_busy) return;
    _busy = true;
    _activeCall = InAppCallModel(
      callId: '',
      channelId: channelId,
      status: 'calling',
      isCaller: true,
      iceServers: _config.iceServers,
      peer: InAppCallPeer(
        name: peerName,
        image: peerImage,
        phone: peerPhone,
        userType: peerUserType,
      ),
    );
    _phase = InAppCallPhase.calling;
    update();
    _openCallScreen();
    await _startDialTone();

    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      customSnackBar('microphone_permission_denied'.tr);
      _busy = false;
      await _closeCallFlow(showEnded: false);
      return;
    }

    final response = await inAppCallRepo.initiate(channelId);
    _busy = false;

    if (response.statusCode == 200 && response.body['content'] != null) {
      _activeCall = InAppCallModel.fromJson(
        Map<String, dynamic>.from(response.body['content'] as Map),
      );
      _phase = InAppCallPhase.ringing;
      update();
      unawaited(_startRingbackTone());
      _startRingTimeout();
      _startCallStatusPoll();
      try {
        await _connectWebRtc(asCaller: true);
      } catch (_) {
        await inAppCallRepo.cancel(_activeCall!.callId);
        await _closeCallFlow(showEnded: false);
        customSnackBar('try_again'.tr);
        return;
      }
    } else {
      ApiChecker.checkApi(response);
      await _closeCallFlow(showEnded: false);
    }
  }

  Future<void> handlePushData(Map<String, dynamic> data) async {
    final type = data['type']?.toString() ?? '';
    final callId = data['call_id']?.toString() ?? '';
    if (callId.isEmpty) return;

    if (type == 'incoming_call') {
      if (_phase != InAppCallPhase.idle) return;
      if (callId == _lastEndedCallId) return;

      _activeCall = InAppCallModel(
        callId: callId,
        channelId: data['channel_id']?.toString() ?? '',
        status: 'ringing',
        isCaller: false,
        iceServers: _config.iceServers,
        peer: InAppCallPeer(
          name: data['user_name']?.toString(),
          image: data['user_image']?.toString(),
          phone: data['user_phone']?.toString(),
          userType: data['user_type']?.toString(),
        ),
      );
      _phase = InAppCallPhase.incoming;
      update();
      _openCallScreen();
      unawaited(_startIncomingRingtone());
      _startRingTimeout();
      _startCallStatusPoll();
      unawaited(_hydrateIncomingCall(callId));
      return;
    }

    if (callId == _lastEndedCallId) return;
    if (!_matchesActiveCall(callId)) return;

    switch (type) {
      case 'call_accepted':
        await _onRemoteAccepted();
        break;
      case 'call_declined':
      case 'call_cancelled':
      case 'call_missed':
      case 'call_ended':
        await _finishCallLocally(endReason: type);
        break;
    }
  }

  Future<void> acceptIncoming() async {
    if (_activeCall == null) return;

    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      await declineIncoming();
      return;
    }

    _stopRingtone();
    _ringTimeoutTimer?.cancel();
    _phase = InAppCallPhase.connecting;
    update();

    final response = await inAppCallRepo.accept(_activeCall!.callId);
    if (response.statusCode == 200 && response.body['content'] != null) {
      _activeCall = InAppCallModel.fromJson(
        Map<String, dynamic>.from(response.body['content'] as Map),
      );
      await _connectWebRtc(asCaller: false);
      _phase = InAppCallPhase.inCall;
      _connectedAt = DateTime.now();
      _startCallStatusPoll();
      await _playConnectedFeedback();
      _startDurationTimer();
      update();
    } else {
      ApiChecker.checkApi(response);
      await _closeCallFlow(showEnded: false);
    }
  }

  Future<void> declineIncoming() async {
    if (_activeCall == null) return;
    _stopRingtone();
    _ringTimeoutTimer?.cancel();
    await inAppCallRepo.decline(_activeCall!.callId);
    await _closeCallFlow(showEnded: false);
  }

  Future<void> cancelOutgoing() async {
    if (_activeCall == null) return;
    _stopRingtone();
    _pollTimer?.cancel();
    _ringTimeoutTimer?.cancel();
    await inAppCallRepo.cancel(_activeCall!.callId);
    await _closeCallFlow(showEnded: false);
  }

  Future<void> hangUp() async {
    if (_activeCall == null) return;
    _pollTimer?.cancel();
    _ringTimeoutTimer?.cancel();
    _stopRingtone();
    if (isCallerRingingPhase) {
      await inAppCallRepo.cancel(_activeCall!.callId);
      await _closeCallFlow(showEnded: false);
    } else {
      await inAppCallRepo.end(_activeCall!.callId);
      await _finishCallLocally(endReason: 'ended');
    }
  }

  Future<void> toggleMute() async {
    if (_webRtc == null || _phase != InAppCallPhase.inCall) return;
    await _webRtc!.toggleMute();
    update();
  }

  Future<void> toggleHold() async {
    if (_webRtc == null || _phase != InAppCallPhase.inCall) return;
    await _webRtc!.toggleHold();
    update();
  }

  Future<void> toggleSpeaker() async {
    if (_webRtc == null) return;
    await _webRtc!.toggleSpeaker();
    update();
  }

  Future<void> _onRemoteAccepted() async {
    if (_activeCall == null || !_activeCall!.isCaller) return;
    _stopRingtone();
    _pollTimer?.cancel();
    _ringTimeoutTimer?.cancel();

    final response = await inAppCallRepo.show(_activeCall!.callId);
    if (response.statusCode == 200 && response.body['content'] != null) {
      _activeCall = InAppCallModel.fromJson(
        Map<String, dynamic>.from(response.body['content'] as Map),
      );
      if (_activeCall!.isAccepted) {
        _phase = InAppCallPhase.connecting;
        update();
        if (_webRtc == null) {
          await _connectWebRtc(asCaller: true);
        } else {
          _startSignalPolling();
        }
        _phase = InAppCallPhase.inCall;
        _connectedAt = DateTime.now();
        _startCallStatusPoll();
        await _playConnectedFeedback();
        _startDurationTimer();
        update();
      }
    }
  }

  Future<void> _connectWebRtc({required bool asCaller}) async {
    await _disposeWebRtc();
    _webRtc = WebRtcCallSession(repo: inAppCallRepo, callId: _activeCall!.callId);
    if (asCaller) {
      await _webRtc!.startAsCaller(_iceServers);
    } else {
      await _webRtc!.startAsCallee(_iceServers);
    }
    _startSignalPolling();
  }

  Future<void> _hydrateIncomingCall(String callId) async {
    final response = await inAppCallRepo.show(callId);
    if (_phase != InAppCallPhase.incoming || _activeCall?.callId != callId) return;
    if (response.statusCode != 200 || response.body['content'] == null) return;

    final call = InAppCallModel.fromJson(
      Map<String, dynamic>.from(response.body['content'] as Map),
    );
    if (call.isTerminal) {
      await _finishCallLocally(endReason: call.status);
      return;
    }

    _activeCall = call;
    update();
  }

  void _startCallStatusPoll() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      unawaited(_pollCallStatus());
    });
  }

  Future<void> _pollCallStatus() async {
    if (_activeCall == null) return;
    final callId = _activeCall!.callId;
    if (callId.isEmpty) return;
    if (_phase == InAppCallPhase.idle || _phase == InAppCallPhase.ended) return;

    final response = await inAppCallRepo.show(callId);
    if (response.statusCode != 200 || response.body['content'] == null) return;
    if (_activeCall?.callId != callId) return;

    final call = InAppCallModel.fromJson(
      Map<String, dynamic>.from(response.body['content'] as Map),
    );

    if (call.isTerminal) {
      if (_phase != InAppCallPhase.ended) {
        await _finishCallLocally(endReason: call.status);
      }
      return;
    }

    if (isCallerRingingPhase) {
      if (call.isRinging && _phase == InAppCallPhase.calling) {
        _activeCall = call;
        _phase = InAppCallPhase.ringing;
        update();
        unawaited(_startRingbackTone());
      } else if (call.isAccepted) {
        _activeCall = call;
        await _onRemoteAccepted();
      }
    }
  }

  void _startOutgoingPoll() => _startCallStatusPoll();

  void _startSignalPolling() {
    _signalPollTimer?.cancel();
    _signalPollTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      await _webRtc?.pollPeerSignals();
    });
  }

  void _startRingTimeout() {
    _ringTimeoutTimer?.cancel();
    final seconds = _config.ringTimeoutSeconds > 0 ? _config.ringTimeoutSeconds : 60;
    _ringTimeoutTimer = Timer(Duration(seconds: seconds), () async {
      if (_activeCall == null) return;
      if (_phase == InAppCallPhase.incoming) {
        await inAppCallRepo.missed(_activeCall!.callId);
        await _finishCallLocally(endReason: 'missed');
      } else if (isCallerRingingPhase) {
        await inAppCallRepo.cancel(_activeCall!.callId);
        await _finishCallLocally(endReason: 'missed');
      }
    });
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_connectedAt == null) return;
      final elapsed = DateTime.now().difference(_connectedAt!);
      final minutes = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
      final seconds = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
      _callDurationLabel = '$minutes:$seconds';
      update();
    });
  }

  Future<void> _disposeWebRtc() async {
    _signalPollTimer?.cancel();
    await _webRtc?.dispose();
    _webRtc = null;
  }

  Future<void> _startDialTone() async {
    await _ringPlayer.setReleaseMode(ReleaseMode.loop);
    await _ringPlayer.play(AssetSource(CallSoundUtil.dialTone));
  }

  Future<void> _startRingbackTone() async {
    await _ringPlayer.setReleaseMode(ReleaseMode.loop);
    await _ringPlayer.play(AssetSource(CallSoundUtil.ringbackTone));
  }

  Future<void> _startIncomingRingtone() async {
    await _ringPlayer.setReleaseMode(ReleaseMode.loop);
    await _ringPlayer.play(AssetSource(CallSoundUtil.incomingRingtone));
  }

  Future<void> _playConnectedFeedback() async {
    await _stopRingtone();
    await HapticFeedback.heavyImpact();
    await _ringPlayer.setReleaseMode(ReleaseMode.release);
    await _ringPlayer.play(AssetSource(CallSoundUtil.connectedTone));
  }

  Future<void> _playDisconnectedFeedback() async {
    await HapticFeedback.mediumImpact();
    await _ringPlayer.setReleaseMode(ReleaseMode.release);
    await _ringPlayer.play(AssetSource(CallSoundUtil.disconnectedTone));
  }

  Future<void> _stopRingtone() async {
    await _ringPlayer.stop();
  }

  void _openCallScreen() {
    if (_callScreenOpen) return;
    _callScreenOpen = true;
    Get.to(() => const InAppCallScreen(), preventDuplicates: true)?.whenComplete(() {
      _callScreenOpen = false;
    });
  }

  void _dismissCallScreen() {
    if (_callScreenOpen) {
      final context = Get.context;
      if (context != null && Navigator.of(context).canPop()) {
        Get.back();
      }
    }
    _callScreenOpen = false;
  }

  Future<void> _closeCallFlow({bool showEnded = true}) async {
    final endedCallId = _activeCall?.callId;
    _pollTimer?.cancel();
    _ringTimeoutTimer?.cancel();
    _durationTimer?.cancel();
    if (!showEnded) {
      await _stopRingtone();
    }
    await _disposeWebRtc();
    if (showEnded && _phase != InAppCallPhase.ended) {
      await _playDisconnectedFeedback();
      _phase = InAppCallPhase.ended;
      update();
      await Future.delayed(const Duration(milliseconds: 400));
    } else if (showEnded) {
      await _playDisconnectedFeedback();
      await Future.delayed(const Duration(milliseconds: 400));
    }
    _dismissCallScreen();
    if (endedCallId != null && endedCallId.isNotEmpty) {
      _lastEndedCallId = endedCallId;
    }
    _suppressPendingUntil = DateTime.now().add(const Duration(seconds: 4));
    _activeCall = null;
    _phase = InAppCallPhase.idle;
    _connectedAt = null;
    _callDurationLabel = '00:00';
    _busy = false;
    _refreshCallHistory();
    update();
  }

  Future<void> _finishCallLocally({required String endReason}) async {
    if (_phase == InAppCallPhase.idle) return;
    _pollTimer?.cancel();
    _ringTimeoutTimer?.cancel();
    _durationTimer?.cancel();
    await _stopRingtone();
    _phase = InAppCallPhase.ended;
    update();
    await _closeCallFlow(showEnded: true);
  }

  bool _matchesActiveCall(String callId) => _activeCall?.callId == callId;
}
