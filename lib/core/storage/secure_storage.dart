import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Thin wrapper around the platform keystore/keychain for the JWT + a tiny
/// cached user blob, so the app can restore a session before the first
/// `/api/users/me` round trip completes (mirrors the web app's `localStorage`
/// use for `muni_token` / `muni_user`, but backed by secure storage on device).
class SecureStorage {
  SecureStorage._();
  static final SecureStorage instance = SecureStorage._();

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _tokenKey = 'muni_token';
  static const _userKey = 'muni_user_json';

  Future<void> saveToken(String token) => _storage.write(key: _tokenKey, value: token);
  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> saveUserJson(String json) => _storage.write(key: _userKey, value: json);
  Future<String?> readUserJson() => _storage.read(key: _userKey);

  Future<void> clear() => _storage.deleteAll();
}
