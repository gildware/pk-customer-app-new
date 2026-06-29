import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationSoundUtil {
  static const String defaultRawSound = 'notification';
  static const String withoutSoundChannelId = 'demandium_silent_v3';

  static const List<String> legacyAndroidChannelIds = [
    'demandium',
    'demandium_v2',
    'demandium_booking_v2',
    'demandium_chat_v2',
    'demandium_wallet_v2',
    'demandium_bidding_v2',
    'demandiumWithoutsound',
  ];

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
      case 'incoming_call':
        return 'call_incoming';
      case 'call_accepted':
      case 'call_declined':
      case 'call_ended':
      case 'call_cancelled':
      case 'call_missed':
        return 'notification';
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
        return 'demandium_booking_v3';
      case 'chatting':
        return 'demandium_chat_v3';
      case 'wallet':
      case 'loyalty_point':
      case 'admin_pay':
      case 'withdraw':
      case 'refund':
        return 'demandium_wallet_v3';
      case 'bidding':
      case 'bid-withdraw':
        return 'demandium_bidding_v3';
      default:
        return 'demandium_v3';
    }
  }

  static String androidChannelNameForId(String channelId) {
    switch (channelId) {
      case 'demandium_booking_v3':
      case 'demandium_booking_v2':
        return 'Booking notifications';
      case 'demandium_chat_v3':
      case 'demandium_chat_v2':
        return 'Chat notifications';
      case 'demandium_wallet_v3':
      case 'demandium_wallet_v2':
        return 'Wallet notifications';
      case 'demandium_bidding_v3':
      case 'demandium_bidding_v2':
        return 'Bidding notifications';
      case 'demandium_v3':
      case 'demandium_v2':
        return 'General notifications';
      case 'demandium':
        return 'General notifications';
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

  static String? channelIdFromData(Map<String, dynamic> data) {
    final channelId = data['android_channel_id']?.toString();
    if (channelId != null && channelId.isNotEmpty) {
      return normalizeAndroidChannelId(channelId);
    }
    return null;
  }

  static String normalizeAndroidChannelId(String channelId) {
    switch (channelId) {
      case 'demandium_v2':
        return 'demandium_v3';
      case 'demandium_booking_v2':
        return 'demandium_booking_v3';
      case 'demandium_chat_v2':
        return 'demandium_chat_v3';
      case 'demandium_wallet_v2':
        return 'demandium_wallet_v3';
      case 'demandium_bidding_v2':
        return 'demandium_bidding_v3';
      case 'demandiumWithoutsound':
        return withoutSoundChannelId;
      default:
        return channelId;
    }
  }

  static String rawSoundFromData(Map<String, dynamic> data, {String? type}) {
    final sound = data['notification_sound']?.toString();
    if (sound != null && sound.isNotEmpty) {
      return sound.replaceAll(RegExp(r'\.(wav|mp3|ogg)$', caseSensitive: false), '');
    }
    return rawSoundForType(type);
  }

  static Future<void> deleteLegacyAndroidChannels(
    AndroidFlutterLocalNotificationsPlugin? androidPlugin,
  ) async {
    if (androidPlugin == null) return;
    for (final channelId in legacyAndroidChannelIds) {
      await androidPlugin.deleteNotificationChannel(channelId: channelId);
    }
  }

  static List<AndroidNotificationChannel> buildAndroidChannels() {
    const channelDefinitions = <(String, String, String)>[
      ('demandium_v3', 'notification', 'General notifications'),
      ('demandium_booking_v3', 'booking', 'Booking notifications'),
      ('demandium_chat_v3', 'chat', 'Chat notifications'),
      ('demandium_wallet_v3', 'wallet', 'Wallet notifications'),
      ('demandium_bidding_v3', 'bidding', 'Bidding notifications'),
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
    String? channelIdOverride,
    String? rawSoundOverride,
  }) {
    final channelId = channelIdOverride ??
        androidChannelIdForType(type, withSound: withSound);
    final channelName = androidChannelNameForId(channelId);

    if (!withSound) {
      return AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelName,
        icon: 'notification_icon',
        playSound: false,
        importance: Importance.max,
        priority: Priority.max,
        styleInformation: styleInformation,
        largeIcon: largeIcon,
      );
    }

    final rawSound = rawSoundOverride ?? rawSoundForType(type);

    return AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelName,
      icon: 'notification_icon',
      playSound: true,
      sound: RawResourceAndroidNotificationSound(rawSound),
      importance: Importance.max,
      priority: Priority.max,
      styleInformation: styleInformation,
      largeIcon: largeIcon,
    );
  }

  static AndroidNotificationDetails androidDetailsFromData(
    Map<String, dynamic> data, {
    bool withSound = true,
    StyleInformation? styleInformation,
    AndroidBitmap<Object>? largeIcon,
  }) {
    final type = data['type']?.toString();
    return androidDetailsForType(
      type,
      withSound: withSound,
      styleInformation: styleInformation,
      largeIcon: largeIcon,
      channelIdOverride: withSound ? channelIdFromData(data) : null,
      rawSoundOverride: withSound ? rawSoundFromData(data, type: type) : null,
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
