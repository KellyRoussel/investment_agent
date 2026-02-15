import 'package:flutter/foundation.dart';
import '../models/user.dart';
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
        _user = await _authService.getStoredUser();
        _isAuthenticated = _user != null;
      }
    } catch (_) {
      _isAuthenticated = false;
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loginWithGoogle() async {
    _error = null;
    _isLoading = true;
    notifyListeners();

    try {
      _user = await _authService.initiateGoogleAuth();
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
