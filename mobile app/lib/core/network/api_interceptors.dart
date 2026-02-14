import 'dart:async';
import 'package:dio/dio.dart';
import '../storage/secure_storage.dart';
import '../constants/api_constants.dart';
import 'api_exceptions.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorage _storage;

  AuthInterceptor(this._storage);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

class TokenRefreshInterceptor extends Interceptor {
  final Dio _dio;
  final SecureStorage _storage;
  final void Function() _onAuthFailure;

  bool _isRefreshing = false;
  Completer<String>? _refreshCompleter;

  TokenRefreshInterceptor(this._dio, this._storage, this._onAuthFailure);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    // Don't retry refresh or login requests
    final path = err.requestOptions.path;
    if (path.contains('/auth/refresh') || path.contains('/auth/login')) {
      return handler.next(err);
    }

    // Don't retry if already retried
    if (err.requestOptions.extra.containsKey('_retry')) {
      return handler.next(err);
    }

    try {
      final newToken = await _refreshAccessToken();
      err.requestOptions.extra['_retry'] = true;
      err.requestOptions.headers['Authorization'] = 'Bearer $newToken';

      final response = await _dio.fetch(err.requestOptions);
      handler.resolve(response);
      return;
    } catch (_) {
      await _storage.clearAll();
      _onAuthFailure();
      handler.reject(err);
      return;
    }
  }

  Future<String> _refreshAccessToken() async {
    if (_isRefreshing && _refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _isRefreshing = true;
    _refreshCompleter = Completer<String>();

    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null) {
        throw UnauthorizedException('No refresh token available');
      }

      final response = await Dio(BaseOptions(baseUrl: ApiConstants.baseUrl)).post(
        ApiConstants.refresh,
        data: {'refresh_token': refreshToken},
      );

      final accessToken = response.data['access_token'] as String;
      final newRefreshToken = response.data['refresh_token'] as String;
      await _storage.setTokens(accessToken, newRefreshToken);

      _refreshCompleter!.complete(accessToken);
      return accessToken;
    } catch (e) {
      _refreshCompleter!.completeError(e);
      rethrow;
    } finally {
      _isRefreshing = false;
      _refreshCompleter = null;
    }
  }
}
