import 'package:flutter/foundation.dart';
import '../models/investment.dart';
import '../services/investments_service.dart';

class InvestmentsProvider extends ChangeNotifier {
  final InvestmentsService _investmentsService;

  List<Investment> _investments = [];
  bool _isLoading = false;
  String? _error;

  InvestmentsProvider(this._investmentsService);

  List<Investment> get investments => _investments;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchInvestments() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _investments = await _investmentsService.getUserInvestments();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Investment> addInvestment(InvestmentCreate data) async {
    try {
      final investment = await _investmentsService.createInvestment(data);
      _investments = [..._investments, investment];
      notifyListeners();
      return investment;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteInvestment(String investmentId) async {
    try {
      await _investmentsService.deleteInvestment(investmentId);
      _investments = _investments.where((i) => i.id != investmentId).toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
