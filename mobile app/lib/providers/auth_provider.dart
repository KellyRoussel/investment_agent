import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/auth.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  User? _user;
  bool _isAuthenticated = false;
  bool _isLoading = true;
  String? _error;

  AuthProvider(this._authService);

  User? get user => _user;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> initAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      final hasToken = await _authService.isAuthenticated();
      if (hasToken) {
        _user = await _authService.getCurrentUser();
        _isAuthenticated = true;
      }
    } catch (_) {
      _isAuthenticated = false;
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    _error = null;
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.login(LoginRequest(email: email, password: password));
      _user = await _authService.getCurrentUser();
      _isAuthenticated = true;
      _error = null;
    } catch (e) {
      _error = e.toString();
      _isAuthenticated = false;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    String? currencyPreference,
    String? riskTolerance,
  }) async {
    _error = null;
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.register(RegisterRequest(
        email: email,
        password: password,
        fullName: fullName,
        currencyPreference: currencyPreference,
        riskTolerance: riskTolerance,
      ));
      _user = await _authService.getCurrentUser();
      _isAuthenticated = true;
      _error = null;
    } catch (e) {
      _error = e.toString();
      _isAuthenticated = false;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _isAuthenticated = false;
    _error = null;
    notifyListeners();
  }

  Future<void> refreshUser() async {
    try {
      _user = await _authService.getCurrentUser();
      notifyListeners();
    } catch (_) {
      // Silently fail
    }
  }

  void setUser(User user) {
    _user = user;
    notifyListeners();
  }

  void handleAuthFailure() {
    _user = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}
