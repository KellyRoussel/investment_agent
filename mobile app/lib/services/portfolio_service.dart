import '../core/network/api_client.dart';
import '../core/constants/api_constants.dart';
import '../models/portfolio.dart';

class PortfolioService {
  final ApiClient _api;

  PortfolioService(this._api);

  Future<PortfolioMetrics> getPortfolioMetrics() async {
    final response = await _api.get(ApiConstants.portfolioMetrics);
    return PortfolioMetrics.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PortfolioHistoryResponse> getPortfolioHistory({
    String? startDate,
    String? endDate,
  }) async {
    final queryParams = <String, dynamic>{};
    if (startDate != null) queryParams['start_date'] = startDate;
    if (endDate != null) queryParams['end_date'] = endDate;

    final response = await _api.get(
      ApiConstants.portfolioHistory,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    return PortfolioHistoryResponse.fromJson(response.data as Map<String, dynamic>);
  }
}
