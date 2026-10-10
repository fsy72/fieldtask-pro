import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  const TokenStorage(this._storage);

  static const tokenKey = 'auth_token';
  static const userKey = 'auth_user';
  final FlutterSecureStorage _storage;

  Future<String?> read() => _storage.read(key: tokenKey);

  Future<Map<String, dynamic>?> readUser() async {
    final value = await _storage.read(key: userKey);
    if (value == null) return null;
    final decoded = jsonDecode(value);
    return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
  }

  Future<void> saveSession({
    required String token,
    required Map<String, dynamic> user,
  }) async {
    await _storage.write(key: userKey, value: jsonEncode(user));
    await _storage.write(key: tokenKey, value: token);
  }

  Future<void> saveUser(Map<String, dynamic> user) =>
      _storage.write(key: userKey, value: jsonEncode(user));

  Future<void> delete() async {
    await _storage.delete(key: tokenKey);
    await _storage.delete(key: userKey);
  }
}
