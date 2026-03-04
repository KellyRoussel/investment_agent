import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../core/storage/secure_storage.dart';
import '../models/recommendation.dart';

class RecommendationsService {
  final Dio _dio;
  final SecureStorage _storage;

  RecommendationsService(this._dio, this._storage);

  Future<Map<String, dynamic>> fetchAvailableModels() async {
    final token = await _storage.getAccessToken();
    final response = await _dio.get<Map<String, dynamic>>(
      ApiConstants.investmentModels,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data!;
  }

  Stream<AgentStreamEvent> streamRecommendation(
    CancelToken cancelToken, {
    required double budgetEur,
    String? model,
  }) async* {
    final token = await _storage.getAccessToken();

    final queryParameters = <String, dynamic>{'budget_eur': budgetEur};
    if (model != null) queryParameters['model'] = model;

    final response = await _dio.get<ResponseBody>(
      ApiConstants.recommendations,
      queryParameters: queryParameters,
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'text/event-stream',
        },
        responseType: ResponseType.stream,
        receiveTimeout: const Duration(minutes: 10),
      ),
      cancelToken: cancelToken,
    );

    String buffer = '';

    await for (final chunk in response.data!.stream) {
      buffer += utf8.decode(chunk);
      final lines = buffer.split('\n');
      buffer = lines.removeLast();

      for (final line in lines) {
        if (line.startsWith('data: ')) {
          final jsonStr = line.substring(6).trim();
          if (jsonStr.isEmpty || jsonStr == '[DONE]') continue;
          try {
            final data = jsonDecode(jsonStr) as Map<String, dynamic>;
            yield AgentStreamEvent.fromJson(data);
          } catch (_) {
            // Skip malformed events
          }
        }
      }
    }
  }
}
