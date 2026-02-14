import '../core/network/api_client.dart';
import '../core/constants/api_constants.dart';
import '../models/investment.dart';
import '../models/price_history.dart';

class InvestmentsService {
  final ApiClient _api;

  InvestmentsService(this._api);

  Future<Investment> createInvestment(InvestmentCreate data) async {
    final response = await _api.post(ApiConstants.investments, data: data.toJson());
    return Investment.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<Investment>> getUserInvestments({
    int skip = 0,
    int limit = 100,
    bool activeOnly = true,
  }) async {
    final response = await _api.get(
      ApiConstants.userInvestments,
      queryParameters: {
        'skip': skip,
        'limit': limit,
        'active_only': activeOnly,
      },
    );
    final list = response.data as List;
    return list.map((e) => Investment.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<PriceHistoryResponse> getPriceHistory(
    String investmentId, {
    String? startDate,
    String? endDate,
  }) async {
    final queryParams = <String, dynamic>{};
    if (startDate != null) queryParams['start_date'] = startDate;
    if (endDate != null) queryParams['end_date'] = endDate;

    final response = await _api.get(
      ApiConstants.priceHistory(investmentId),
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    return PriceHistoryResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteInvestment(String investmentId) async {
    await _api.delete(ApiConstants.deleteInvestment(investmentId));
  }
}
