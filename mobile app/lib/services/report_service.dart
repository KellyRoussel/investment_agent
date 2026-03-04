import '../core/network/api_client.dart';
import '../core/constants/api_constants.dart';
import '../models/report.dart';

class ReportService {
  final ApiClient _api;

  ReportService(this._api);

  Future<List<InvestmentReport>> fetchHistory() async {
    final response = await _api.get(ApiConstants.reportHistory);
    final list = response.data as List;
    return list
        .map((e) => InvestmentReport.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
