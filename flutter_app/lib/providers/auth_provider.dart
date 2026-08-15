import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isTeacher => _currentUser?.isTeacher ?? false;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _loadUserFromPrefs();
  }

  Future<void> _loadUserFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('user_data');
    final token = prefs.getString('auth_token');
    if (userStr != null && token != null) {
      try {
        final json = jsonDecode(userStr);
        _currentUser = UserModel.fromJson(json, token);
        notifyListeners();
      } catch (e) {
        logout();
      }
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final deviceId = await ApiService.getDeviceInstallId();
    final response = await ApiService.login(email, password, deviceInstallId: deviceId);
    _isLoading = false;

    if (response.isSuccess && response.data != null) {
      _currentUser = response.data;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _currentUser!.token);
      await prefs.setString('user_data', jsonEncode({
        'id': _currentUser!.id,
        'email': _currentUser!.email,
        'role': _currentUser!.role,
        'registrationNo': _currentUser!.registrationNo,
      }));
      notifyListeners();
      return true;
    } else {
      _errorMessage = response.message ?? 'Login failed';
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String role,
    String? registrationNo,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final deviceId = await ApiService.getDeviceInstallId();
    final response = await ApiService.register(
      email: email,
      password: password,
      role: role,
      registrationNo: registrationNo,
      deviceInstallId: deviceId,
    );
    _isLoading = false;

    if (response.isSuccess && response.data != null) {
      _currentUser = response.data;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _currentUser!.token);
      await prefs.setString('user_data', jsonEncode({
        'id': _currentUser!.id,
        'email': _currentUser!.email,
        'role': _currentUser!.role,
        'registrationNo': _currentUser!.registrationNo,
      }));
      notifyListeners();
      return true;
    } else {
      _errorMessage = response.message ?? 'Registration failed';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
    notifyListeners();
  }
}
