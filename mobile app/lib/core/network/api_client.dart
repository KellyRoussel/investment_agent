import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../storage/secure_storage.dart';
import 'api_interceptors.dart';
import 'api_exceptions.dart';

class ApiClient {
  late final Dio dio;
  final SecureStorage storage;
  void Function()? onAuthFailure;

  ApiClient(this.storage) {
    dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      headers: {'Content-Type': 'application/json'},
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));

    dio.interceptors.addAll([
      AuthInterceptor(storage),
      TokenRefreshInterceptor(dio, storage, () {
        onAuthFailure?.call();
      }),
    ]);
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await dio.get<T>(path, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Options? options,
  }) async {
    try {
      return await dio.post<T>(path, data: data, options: options);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Options? options,
  }) async {
    try {
      return await dio.patch<T>(path, data: data, options: options);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response<T>> delete<T>(
    String path, {
    Options? options,
  }) async {
    try {
      return await dio.delete<T>(path, options: options);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  ApiException _handleError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return NetworkException('Connection timed out. Please try again.');
    }

    if (e.type == DioExceptionType.connectionError) {
      return NetworkException();
    }

    final statusCode = e.response?.statusCode;
    final data = e.response?.data;
    String message = 'An unexpected error occurred';

    if (data is Map<String, dynamic> && data.containsKey('detail')) {
      message = data['detail'].toString();
    }

    switch (statusCode) {
      case 401:
        return UnauthorizedException(message);
      case 409:
        return ConflictException(message);
      case 400:
        return ApiException(message, statusCode: 400);
      case 403:
        return ApiException(message, statusCode: 403);
      case 404:
        return ApiException('Resource not found', statusCode: 404);
      case 500:
      case 502:
      case 503:
        return ServerException(message);
      default:
        return ApiException(message, statusCode: statusCode);
    }
  }
}
