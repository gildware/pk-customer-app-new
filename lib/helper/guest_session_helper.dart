import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:demandium/util/core_export.dart';

class GuestSessionHelper {
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const String _secretKey = 'guest_session_secret';

  static Future<String> getOrCreateSecret() async {
    final existing = await _storage.read(key: _secretKey);
    if (existing != null && existing.length >= 32) {
      return existing;
    }

    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    final secret = base64Url.encode(bytes);
    await _storage.write(key: _secretKey, value: secret);
    return secret;
  }

  static Future<void> clearSecret() async {
    await _storage.delete(key: _secretKey);
  }

  static Future<void> ensureRegistered(String guestId) async {
    if (guestId.isEmpty) {
      return;
    }

    final secret = await getOrCreateSecret();
    await Get.find<ApiClient>().postData('/api/v1/customer/guest/session', {
      'guest_id': guestId,
      'guest_secret': secret,
    });
  }

  static Future<void> regenerateForGuest(String guestId) async {
    await clearSecret();
    await ensureRegistered(guestId);
  }
}
