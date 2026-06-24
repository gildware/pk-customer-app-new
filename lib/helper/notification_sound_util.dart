import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationSoundUtil {
  static const String defaultRawSound = 'notification';
  static const String withoutSoundChannelId = 'demandiumWithoutsound';

  static String rawSoundForType(String? type) {
    switch (type) {
      case 'booking':
      case 'booking_ignored':
      case 'offline-payment':
        return 'booking';
      case 'chatting':
        return 'chat';
      case 'wallet':
      case 'loyalty_point':
      case 'admin_pay':
      case 'withdraw':
      case 'refund':
        return 'wallet';
      case 'bidding':
      case 'bid-withdraw':
        return 'bidding';
      default:
        return defaultRawSound;
    }
  }

  static String androidChannelIdForType(String? type, {required bool withSound}) {
    if (!withSound) return withoutSoundChannelId;

    switch (type) {
      case 'booking':
      case 'booking_ignored':
      case 'offline-payment':
        return 'demandium_booking';
      case 'chatting':
        return 'demandium_chat';
      case 'wallet':
      case 'loyalty_point':
      case 'admin_pay':
      case 'withdraw':
      case 'refund':
        return 'demandium_wallet';
      case 'bidding':
      case 'bid-withdraw':
        return 'demandium_bidding';
      default:
        return 'demandium';
    }
  }

  static String androidChannelNameForId(String channelId) {
    switch (channelId) {
      case 'demandium_booking':
        return 'Booking notifications';
      case 'demandium_chat':
        return 'Chat notifications';
      case 'demandium_wallet':
        return 'Wallet notifications';
      case 'demandium_bidding':
        return 'Bidding notifications';
      case withoutSoundChannelId:
        return 'Notifications without sound';
      default:
        return 'General notifications';
    }
  }

  static String assetSoundForType(String? type) => '${rawSoundForType(type)}.wav';

  static String iosSoundForType(String? type) => '${rawSoundForType(type)}.wav';

  static String? typeFromPayload(String payload) {
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map && decoded['type'] != null) {
        return decoded['type'].toString();
      }
    } catch (_) {}
    return null;
  }

  static List<AndroidNotificationChannel> buildAndroidChannels() {
    const channelDefinitions = <(String, String, String)>[
      ('demandium', 'notification', 'General notifications'),
      ('demandium_booking', 'booking', 'Booking notifications'),
      ('demandium_chat', 'chat', 'Chat notifications'),
      ('demandium_wallet', 'wallet', 'Wallet notifications'),
      ('demandium_bidding', 'bidding', 'Bidding notifications'),
    ];

    return [
      ...channelDefinitions.map(
        (channel) => AndroidNotificationChannel(
          channel.$1,
          channel.$3,
          description: channel.$3,
          importance: Importance.max,
          playSound: true,
          sound: RawResourceAndroidNotificationSound(channel.$2),
        ),
      ),
      const AndroidNotificationChannel(
        withoutSoundChannelId,
        'Notifications without sound',
        description: 'Notifications without sound',
        importance: Importance.max,
        playSound: false,
      ),
    ];
  }

  static AndroidNotificationDetails androidDetailsForType(
    String? type, {
    bool withSound = true,
    StyleInformation? styleInformation,
    AndroidBitmap<Object>? largeIcon,
  }) {
    final channelId = androidChannelIdForType(type, withSound: withSound);
    final channelName = androidChannelNameForId(channelId);

    if (!withSound) {
      return AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelName,
        playSound: false,
        importance: Importance.max,
        priority: Priority.max,
        styleInformation: styleInformation,
        largeIcon: largeIcon,
      );
    }

    return AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelName,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(rawSoundForType(type)),
      importance: Importance.max,
      priority: Priority.max,
      styleInformation: styleInformation,
      largeIcon: largeIcon,
    );
  }

  static DarwinNotificationDetails darwinDetailsForType(
    String? type, {
    bool withSound = true,
  }) {
    return DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: withSound,
      sound: withSound ? iosSoundForType(type) : null,
    );
  }
}
