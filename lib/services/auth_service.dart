import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/user_model.dart';
import '../utils/secure_storage.dart';

class AuthService extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  // Send OTP
  Future<bool> sendOtp(String phone) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.sendOtp),
        headers: ApiConfig.getHeaders(),
        body: jsonEncode({'phone': phone}),
      );

      _isLoading = false;

      if (response.statusCode == 200) {
        notifyListeners();
        return true;
      } else {
        final data = jsonDecode(response.body);
        _error = data['message'] ?? 'Failed to send OTP';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _error = 'Network error. Please check your connection.';
      notifyListeners();
      return false;
    }
  }

  // Verify OTP
  Future<bool> verifyOtp(String phone, String otp) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.verifyOtp),
        headers: ApiConfig.getHeaders(),
        body: jsonEncode({'phone': phone, 'otp': otp}),
      );

      _isLoading = false;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Save token
        final token = data['token'] ?? data['accessToken'];
        await SecureStorage.saveToken(token);

        // Save user data
        final userData = data['user'] ?? data['technician'];
        _user = UserModel.fromJson(userData);

        await SecureStorage.saveUserData(
          userId: _user!.id,
          userName: _user!.name,
          userPhone: _user!.phone,
        );

        notifyListeners();
        return true;
      } else {
        final data = jsonDecode(response.body);
        _error = data['message'] ?? 'Invalid OTP';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _error = 'Network error. Please check your connection.';
      notifyListeners();
      return false;
    }
  }

  // Check authentication status
  Future<bool> checkAuth() async {
    final token = await SecureStorage.getToken();

    if (token == null) {
      return false;
    }

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.technicianProfile),
        headers: ApiConfig.getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _user = UserModel.fromJson(data['user'] ?? data['technician']);
        notifyListeners();
        return true;
      } else {
        await logout();
        return false;
      }
    } catch (e) {
      await logout();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await SecureStorage.getToken();
      if (token != null) {
        // Call logout API
        await http.post(
          Uri.parse(ApiConfig.logout),
          headers: ApiConfig.getHeaders(token: token),
        );
      }
    } catch (e) {
      // Continue with logout even if API call fails
      debugPrint('Logout API error: $e');
    } finally {
      // Clear local storage regardless of API call result
      await SecureStorage.clearAll();
      _user = null;
      _error = null;
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Request Password Reset
  Future<bool> forgetPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.forgetPassword),
        headers: ApiConfig.getHeaders(),
        body: jsonEncode({'email': email}),
      );

      _isLoading = false;

      if (response.statusCode == 200 || response.statusCode == 201) {
        notifyListeners();
        return true;
      } else {
        final data = jsonDecode(response.body);
        _error = data['message'] ?? 'Failed to send reset link';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _error = 'Network error: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Reset Password
  Future<bool> resetPassword(String token, String newPassword, String confirmPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.resetPassword),
        headers: ApiConfig.getHeaders(),
        body: jsonEncode({
          'token': token,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        }),
      );

      _isLoading = false;

      if (response.statusCode == 200 || response.statusCode == 201) {
        notifyListeners();
        return true;
      } else {
        final data = jsonDecode(response.body);
        _error = data['message'] ?? 'Failed to reset password';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _error = 'Network error: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
}
