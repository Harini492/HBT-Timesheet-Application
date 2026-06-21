import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_constants.dart';

/// Wraps secure storage for the JWT and the last-known user JSON blob,
/// so the app can restore a session on cold start without re-hitting the API.
class TokenStorage {
  final FlutterSecureStorage _storage;

  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveToken(String token) =>
      _storage.write(key: AppConstants.tokenStorageKey, value: token);

  Future<String?> readToken() => _storage.read(key: AppConstants.tokenStorageKey);

  Future<void> deleteToken() => _storage.delete(key: AppConstants.tokenStorageKey);

  Future<void> saveUser(Map<String, dynamic> user) =>
      _storage.write(key: AppConstants.userStorageKey, value: jsonEncode(user));

  Future<Map<String, dynamic>?> readUser() async {
    final raw = await _storage.read(key: AppConstants.userStorageKey);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> clearAll() async {
    await _storage.delete(key: AppConstants.tokenStorageKey);
    await _storage.delete(key: AppConstants.userStorageKey);
  }
}
