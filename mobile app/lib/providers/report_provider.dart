import 'package:flutter/foundation.dart';
import '../models/report.dart';
import '../services/report_service.dart';

class ReportProvider extends ChangeNotifier {
  final ReportService _service;

  List<InvestmentReport> _reports = [];
  bool _isLoading = false;
  String? _error;

  ReportProvider(this._service);

  List<InvestmentReport> get reports => _reports;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchHistory() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _reports = await _service.fetchHistory();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
