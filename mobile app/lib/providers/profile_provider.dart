import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/users_service.dart';

class ProfileProvider extends ChangeNotifier {
  final UsersService _usersService;

  bool _isEditingInfo = false;
  bool _isEditingPrefs = false;
  bool _isLoading = false;
  String? _error;
  String? _success;

  ProfileProvider(this._usersService);

  bool get isEditingInfo => _isEditingInfo;
  bool get isEditingPrefs => _isEditingPrefs;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get success => _success;

  void startEditingInfo() {
    _isEditingInfo = true;
    _error = null;
    _success = null;
    notifyListeners();
  }

  void cancelEditingInfo() {
    _isEditingInfo = false;
    _error = null;
    notifyListeners();
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

  Future<User?> updateProfile(String userId, UserUpdate data) async {
    _isLoading = true;
    _error = null;
    _success = null;
    notifyListeners();

    try {
      final user = await _usersService.updateUser(userId, data);
      _isEditingInfo = false;
      _isEditingPrefs = false;
      _success = 'Profile updated successfully';
      _isLoading = false;
      notifyListeners();
      return user;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  void clearMessages() {
    _error = null;
    _success = null;
    notifyListeners();
  }
}
