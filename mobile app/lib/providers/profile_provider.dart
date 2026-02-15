import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/users_service.dart';

class ProfileProvider extends ChangeNotifier {
  final UsersService _usersService;

  InvestmentProfile? _profile;
  bool _isEditingPrefs = false;
  bool _isLoading = false;
  String? _error;
  String? _success;

  ProfileProvider(this._usersService);

  InvestmentProfile? get profile => _profile;
  bool get isEditingPrefs => _isEditingPrefs;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get success => _success;

  Future<void> loadStoredProfile() async {
    _profile = await _usersService.getStoredProfile();
    notifyListeners();
    try {
      _profile = await _usersService.fetchProfile();
      notifyListeners();
    } catch (e) {
      debugPrint('=== FETCH PROFILE ERROR: $e ===');
      // Network unavailable — keep the cached value
    }
  }

  void startEditingPrefs() {
    _isEditingPrefs = true;
    _error = null;
    _success = null;
    notifyListeners();
  }

  void cancelEditingPrefs() {
    _isEditingPrefs = false;
    _error = null;
    notifyListeners();
  }

  Future<void> updatePreferences(InvestmentProfileUpdate data) async {
    _isLoading = true;
    _error = null;
    _success = null;
    notifyListeners();

    try {
      _profile = await _usersService.updateInvestmentProfile(data);
      _isEditingPrefs = false;
      _success = 'Preferences updated successfully';
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearMessages() {
    _error = null;
    _success = null;
    notifyListeners();
  }
}
