import 'dart:convert';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists in-flight Razorpay verify params so payment can complete after app restart.
class PendingPaymentHelper {
  static const _keyPayload = 'pending_razorpay_verify_payload';

  static Future<void> saveVerifyPayload(Map<String, String> payload) async {
    if (!Get.isRegistered<SharedPreferences>()) {
      return;
    }
    await Get.find<SharedPreferences>().setString(_keyPayload, jsonEncode(payload));
  }

  static Future<Map<String, String>?> readVerifyPayload() async {
    if (!Get.isRegistered<SharedPreferences>()) {
      return null;
    }
    final raw = Get.find<SharedPreferences>().getString(_keyPayload);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return null;
      }
      return decoded.map((key, value) => MapEntry(key.toString(), value.toString()));
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear() async {
    if (!Get.isRegistered<SharedPreferences>()) {
      return;
    }
    await Get.find<SharedPreferences>().remove(_keyPayload);
  }
}
