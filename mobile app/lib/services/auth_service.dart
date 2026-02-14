import '../core/network/api_client.dart';
import '../core/constants/api_constants.dart';
import '../core/storage/secure_storage.dart';
import '../models/auth.dart';
import '../models/user.dart';

class AuthService {
  final ApiClient _api;
  final SecureStorage _storage;

  AuthService(this._api, this._storage);

  Future<TokenResponse> register(RegisterRequest data) async {
    final response = await _api.post(ApiConstants.register, data: data.toJson());
    final tokenResponse = TokenResponse.fromJson(response.data as Map<String, dynamic>);
    await _storage.setTokens(tokenResponse.accessToken, tokenResponse.refreshToken);
    return tokenResponse;
  }

  Future<TokenResponse> login(LoginRequest data) async {
    final response = await _api.post(ApiConstants.login, data: data.toJson());
    final tokenResponse = TokenResponse.fromJson(response.data as Map<String, dynamic>);
    await _storage.setTokens(tokenResponse.accessToken, tokenResponse.refreshToken);
    return tokenResponse;
  }

  Future<void> logout() async {
    await _storage.clearAll();
  }

  Future<User> getCurrentUser() async {
    final response = await _api.get(ApiConstants.me);
    final user = User.fromJson(response.data as Map<String, dynamic>);
    await _storage.setUser(user.toJson());
    return user;
  }

  Future<TokenResponse> refreshToken() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null) throw Exception('No refresh token');

    final response = await _api.post(
      ApiConstants.refresh,
      data: {'refresh_token': refreshToken},
    );
    final tokenResponse = TokenResponse.fromJson(response.data as Map<String, dynamic>);
    await _storage.setTokens(tokenResponse.accessToken, tokenResponse.refreshToken);
    return tokenResponse;
  }

  Future<bool> isAuthenticated() async {
    final token = await _storage.getAccessToken();
    return token != null;
  }

  Future<User?> getStoredUser() async {
    final userData = await _storage.getUser();
    if (userData == null) return null;
    return User.fromJson(userData);
  }
}
