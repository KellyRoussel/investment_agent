import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import '../core/constants/api_constants.dart';
import '../core/storage/secure_storage.dart';
import '../models/auth.dart';
import '../models/user.dart';

class AuthService {
  final SecureStorage _storage;

  // Uses its own Dio instance (no auth interceptors) for the OAuth flow
  AuthService(this._storage);

  Future<User> initiateGoogleAuth() async {
    // OAuth uses production backend: Google requires a valid HTTPS domain as redirect URI.
    // Investment API calls (investments, portfolio, etc.) use local baseUrl instead.
    final oauthDio = Dio(BaseOptions(baseUrl: ApiConstants.oauthBaseUrl));

    // 1. Get Google OAuth URL from backend
    final urlResponse = await oauthDio.get(ApiConstants.googleAuthUrl);
    final authUrl = urlResponse.data['authorization_url'] as String;

    // 2. Open browser and intercept deep link callback (investtrack://auth?code=...&state=...)
    final result = await FlutterWebAuth2.authenticate(
      url: authUrl,
      callbackUrlScheme: 'investtrack',
    );

    // 3. Extract code and state from callback URL
    final uri = Uri.parse(result);
    final code = uri.queryParameters['code'];
    if (code == null) {
      throw Exception('Authorization code not found in callback');
    }
    final state = uri.queryParameters['state'] ?? '';

    // 4. Exchange code for tokens + user (also via production backend)
    final Response exchangeResponse;
    try {
      exchangeResponse = await oauthDio.get(ApiConstants.exchangeCode(code, state));
    } on DioException catch (e) {
      debugPrint('=== AUTH EXCHANGE ERROR ===');
      debugPrint('Status: ${e.response?.statusCode}');
      debugPrint('Body: ${e.response?.data}');
      debugPrint('URL: ${e.requestOptions.uri}');
      rethrow;
    }
    final data = OAuthExchangeResponse.fromJson(
      exchangeResponse.data as Map<String, dynamic>,
    );

    // 5. Store tokens and user
    await _storage.setTokens(data.accessToken, data.refreshToken);
    await _storage.setUser(data.user.toJson());

    return data.user;
  }

  Future<void> logout() async {
    await _storage.clearAuthData();
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
