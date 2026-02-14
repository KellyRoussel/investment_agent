import 'package:flutter/foundation.dart';
import '../models/portfolio.dart';
import '../services/portfolio_service.dart';

class PortfolioProvider extends ChangeNotifier {
  final PortfolioService _portfolioService;

  PortfolioMetrics? _metrics;
  PortfolioHistoryResponse? _history;
  bool _isLoading = false;
  bool _isLoadingHistory = false;
  String? _error;

  PortfolioProvider(this._portfolioService);

  PortfolioMetrics? get metrics => _metrics;
  PortfolioHistoryResponse? get history => _history;
  bool get isLoading => _isLoading;
  bool get isLoadingHistory => _isLoadingHistory;
  String? get error => _error;

  Future<void> fetchMetrics() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _metrics = await _portfolioService.getPortfolioMetrics();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchHistory({String? startDate, String? endDate}) async {
    _isLoadingHistory = true;
    notifyListeners();

    try {
      _history = await _portfolioService.getPortfolioHistory(
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  Future<void> fetchAll({String? startDate, String? endDate}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.wait([
        fetchMetrics(),
        fetchHistory(startDate: startDate, endDate: endDate),
      ]);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
