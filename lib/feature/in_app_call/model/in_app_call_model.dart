class InAppCallPeer {
  final String? id;
  final String? name;
  final String? image;
  final String? phone;
  final String? userType;

  const InAppCallPeer({
    this.id,
    this.name,
    this.image,
    this.phone,
    this.userType,
  });

  factory InAppCallPeer.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const InAppCallPeer();
    return InAppCallPeer(
      id: json['id']?.toString(),
      name: json['name']?.toString(),
      image: json['image']?.toString(),
      phone: json['phone']?.toString(),
      userType: json['user_type']?.toString(),
    );
  }
}

class InAppCallModel {
  final String callId;
  final String channelId;
  final String status;
  final bool isCaller;
  final List<Map<String, dynamic>> iceServers;
  final InAppCallPeer peer;
  final int? durationSeconds;
  final String? startedAt;
  final String? answeredAt;
  final String? endedAt;
  final String? endReason;

  const InAppCallModel({
    required this.callId,
    required this.channelId,
    required this.status,
    required this.isCaller,
    required this.iceServers,
    required this.peer,
    this.durationSeconds,
    this.startedAt,
    this.answeredAt,
    this.endedAt,
    this.endReason,
  });

  factory InAppCallModel.fromJson(Map<String, dynamic> json) {
    final servers = <Map<String, dynamic>>[];
    final rawServers = json['ice_servers'];
    if (rawServers is List) {
      for (final item in rawServers) {
        if (item is Map) {
          servers.add(Map<String, dynamic>.from(item));
        }
      }
    }

    final direction = json['direction']?.toString().toLowerCase();
    final isCaller = json['is_caller'] == true || direction == 'outbound';

    return InAppCallModel(
      callId: json['call_id']?.toString() ?? '',
      channelId: json['channel_id']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      isCaller: isCaller,
      iceServers: servers,
      peer: InAppCallPeer.fromJson(
        json['peer'] is Map<String, dynamic> ? json['peer'] as Map<String, dynamic> : null,
      ),
      durationSeconds: int.tryParse(json['duration_seconds']?.toString() ?? ''),
      startedAt: json['started_at']?.toString(),
      answeredAt: json['answered_at']?.toString(),
      endedAt: json['ended_at']?.toString(),
      endReason: json['end_reason']?.toString(),
    );
  }

  factory InAppCallModel.fromHistoryJson(Map<String, dynamic> json) {
    final direction = json['direction']?.toString().toLowerCase();
    final isCaller = json['is_caller'] == true || direction == 'outbound';

    return InAppCallModel(
      callId: json['call_id']?.toString() ?? '',
      channelId: json['channel_id']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      isCaller: isCaller,
      iceServers: const [],
      peer: InAppCallPeer.fromJson(
        json['peer'] is Map<String, dynamic> ? json['peer'] as Map<String, dynamic> : null,
      ),
      durationSeconds: int.tryParse(json['duration_seconds']?.toString() ?? ''),
      startedAt: json['started_at']?.toString(),
      answeredAt: json['answered_at']?.toString(),
      endedAt: json['ended_at']?.toString(),
      endReason: json['end_reason']?.toString(),
    );
  }

  bool get isRinging => status == 'ringing';
  bool get isAccepted => status == 'accepted';
  bool get isOutbound => isCaller;
  bool get isInbound => !isCaller;
  bool get isTerminal => const {
    'declined',
    'missed',
    'ended',
    'cancelled',
  }.contains(status);

  String get directionLabelKey => isCaller ? 'outbound' : 'inbound';

  String get statusLabelKey {
    switch (status) {
      case 'ringing':
        return 'call_status_ringing';
      case 'accepted':
        return 'call_status_in_progress';
      case 'ended':
        return 'call_status_ended';
      case 'missed':
        return 'call_status_missed';
      case 'declined':
        return 'call_status_declined';
      case 'cancelled':
        return 'call_status_cancelled';
      default:
        return status;
    }
  }

  String get formattedDuration {
    final seconds = durationSeconds ?? 0;
    if (seconds <= 0) return '';
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }
}

class InAppCallConfig {
  final bool enabled;
  final List<Map<String, dynamic>> iceServers;
  final int ringTimeoutSeconds;

  const InAppCallConfig({
    required this.enabled,
    required this.iceServers,
    required this.ringTimeoutSeconds,
  });

  factory InAppCallConfig.fromJson(Map<String, dynamic> json) {
    final servers = <Map<String, dynamic>>[];
    final rawServers = json['ice_servers'];
    if (rawServers is List) {
      for (final item in rawServers) {
        if (item is Map) {
          servers.add(Map<String, dynamic>.from(item));
        }
      }
    }

    return InAppCallConfig(
      enabled: json['ice_servers'] != null ? json['enabled'] != false : true,
      iceServers: servers.isNotEmpty
          ? servers
          : [
              {'urls': 'stun:stun.l.google.com:19302'},
            ],
      ringTimeoutSeconds: int.tryParse(json['ring_timeout_seconds']?.toString() ?? '') ?? 60,
    );
  }
}
