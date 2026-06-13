import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureCredentialStorage {
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const String _passwordKey = 'remember_me_password';

  static Future<void> writePassword(String password) async {
    await _storage.write(key: _passwordKey, value: password);
  }

  static Future<String> readPassword() async {
    return await _storage.read(key: _passwordKey) ?? '';
  }

  static Future<void> deletePassword() async {
    await _storage.delete(key: _passwordKey);
  }
}
