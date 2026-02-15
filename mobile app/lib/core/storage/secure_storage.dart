import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userKey = 'user';
  static const _profileKey = 'investment_profile';

  Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);

  Future<void> setAccessToken(String token) =>
      _storage.write(key: _accessTokenKey, value: token);

  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> setRefreshToken(String token) =>
      _storage.write(key: _refreshTokenKey, value: token);

  Future<void> setTokens(String accessToken, String refreshToken) async {
    await Future.wait([
      setAccessToken(accessToken),
      setRefreshToken(refreshToken),
    ]);
  }

  Future<Map<String, dynamic>?> getUser() async {
    final userStr = await _storage.read(key: _userKey);
    if (userStr == null) return null;
    return jsonDecode(userStr) as Map<String, dynamic>;
  }

  Future<void> setUser(Map<String, dynamic> user) =>
      _storage.write(key: _userKey, value: jsonEncode(user));

  Future<Map<String, dynamic>?> getInvestmentProfile() async {
    final profileStr = await _storage.read(key: _profileKey);
    if (profileStr == null) return null;
    return jsonDecode(profileStr) as Map<String, dynamic>;
  }

  Future<void> setInvestmentProfile(Map<String, dynamic> profile) =>
      _storage.write(key: _profileKey, value: jsonEncode(profile));

  Future<void> clearAuthData() => Future.wait([
    _storage.delete(key: _accessTokenKey),
    _storage.delete(key: _refreshTokenKey),
    _storage.delete(key: _userKey),
  ]);

  Future<void> clearAll() => _storage.deleteAll();
}
