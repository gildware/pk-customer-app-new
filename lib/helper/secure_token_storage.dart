import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureTokenStorage {
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const String _tokenKey = 'auth_access_token';
  static const String _legacyPrefsKey = 'demand_token';
  static const String _walletPaymentTokenKey = 'wallet_payment_access_token';
  static const String _legacyWalletPrefsKey = 'wallet_access_token';

  static String _memoryCache = '';
  static String _walletPaymentTokenCache = '';

  static String cachedToken() => _memoryCache;

  static Future<void> preload(SharedPreferences sharedPreferences) async {
    await _migrateLegacy(sharedPreferences);
    _memoryCache = await _storage.read(key: _tokenKey) ?? '';
    await _migrateLegacyWalletToken(sharedPreferences);
    _walletPaymentTokenCache = await _storage.read(key: _walletPaymentTokenKey) ?? '';
  }

  static Future<void> _migrateLegacyWalletToken(SharedPreferences sharedPreferences) async {
    final legacy = sharedPreferences.getString(_legacyWalletPrefsKey);
    if (legacy != null && legacy.isNotEmpty) {
      await _storage.write(key: _walletPaymentTokenKey, value: legacy);
      await sharedPreferences.remove(_legacyWalletPrefsKey);
    }
  }

  static Future<void> _migrateLegacy(SharedPreferences sharedPreferences) async {
    final legacy = sharedPreferences.getString(_legacyPrefsKey);
    if (legacy != null && legacy.isNotEmpty) {
      await _storage.write(key: _tokenKey, value: legacy);
      await sharedPreferences.remove(_legacyPrefsKey);
    }
  }

  static Future<void> writeToken(String token) async {
    _memoryCache = token;
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<void> deleteToken() async {
    _memoryCache = '';
    await _storage.delete(key: _tokenKey);
  }

  static void evictToken() {
    _memoryCache = '';
    unawaited(_storage.delete(key: _tokenKey));
  }

  static String cachedWalletPaymentToken() => _walletPaymentTokenCache;

  static Future<void> writeWalletPaymentToken(String token) async {
    _walletPaymentTokenCache = token;
    await _storage.write(key: _walletPaymentTokenKey, value: token);
  }

  static Future<String> readWalletPaymentToken() async {
    if (_walletPaymentTokenCache.isNotEmpty) {
      return _walletPaymentTokenCache;
    }
    _walletPaymentTokenCache = await _storage.read(key: _walletPaymentTokenKey) ?? '';
    return _walletPaymentTokenCache;
  }

  static Future<void> deleteWalletPaymentToken() async {
    _walletPaymentTokenCache = '';
    await _storage.delete(key: _walletPaymentTokenKey);
  }
}
