import 'dart:convert';
import 'dart:io' show SocketException;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/public_api_config.dart';
import '../models/user_model.dart';
import 'notification_service.dart';

class AuthService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _supabase.auth.currentSession != null;

  AuthService() {
    _initAuthListener();
  }

  void _initAuthListener() {
    _supabase.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      if (session != null) {
        await _fetchUserProfile(session.user.id);
      } else {
        _user = null;
      }
      notifyListeners();
    });
  }

  Future<void> _fetchUserProfile(String userId) async {
    try {
      // No FK relationship exists between profiles/user_roles (confirmed
      // against the live schema), so these can't be a single embedded
      // select — run them in parallel instead of sequentially.
      final results = await Future.wait([
        _supabase.from('profiles').select().eq('id', userId).maybeSingle(),
        _supabase.from('user_roles').select('role').eq('user_id', userId).maybeSingle(),
      ]);
      final profileData = results[0];
      final roleData = results[1];

      if (profileData != null) {
        profileData['role'] = roleData?['role'] ?? 'technician';
        profileData['id'] = userId;
        _user = UserModel.fromJson(profileData);
      }
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
    }
  }

  /// Re-fetches the current user's profile and notifies listeners — call
  /// after updating profile fields (name, avatar) elsewhere so every screen
  /// reading `AuthService.user` (e.g. the dashboard header) picks up the
  /// change immediately instead of only the screen that made the edit.
  Future<void> refreshUser() async {
    final id = _supabase.auth.currentUser?.id;
    if (id == null) return;
    await _fetchUserProfile(id);
    notifyListeners();
  }

  Future<bool> sendLoginOtp(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _supabase.auth.signInWithOtp(
        email: email,
        shouldCreateUser: false,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthRetryableFetchException {
      // Thrown when the underlying HTTP request itself fails (timeout, no
      // connectivity, DNS) — its .message is the raw SocketException text,
      // not something to show a user.
      _isLoading = false;
      _error = 'Network error. Please check your connection.';
      notifyListeners();
      return false;
    } on AuthException catch (e) {
      _isLoading = false;
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _error = 'Network error. Please check your connection.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyLoginOtp(String email, String otp) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _supabase.auth.verifyOTP(
        email: email,
        token: otp,
        type: OtpType.email,
      );

      if (response.user != null) {
        await _fetchUserProfile(response.user!.id);

        NotificationService().registerToken().catchError((e) {
          debugPrint('FCM token registration after login: $e');
        });

        _isLoading = false;
        notifyListeners();
        return true;
      }
      _isLoading = false;
      _error = 'Verification failed';
      notifyListeners();
      return false;
    } on AuthRetryableFetchException {
      _isLoading = false;
      _error = 'Network error. Please check your connection.';
      notifyListeners();
      return false;
    } on AuthException catch (e) {
      _isLoading = false;
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _error = 'Network error. Please check your connection.';
      notifyListeners();
      return false;
    }
  }

  /// POSTs JSON and safely decodes the response body — a non-JSON body
  /// (e.g. an HTML 404 page from a missing route) must NOT be reported as a
  /// connectivity failure, so decoding failures are captured here rather
  /// than left to throw into the caller's catch block.
  Future<({int status, dynamic body})> _postJson(
    String url,
    Map<String, dynamic> payload,
  ) async {
    final res = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    dynamic body;
    try {
      body = res.body.isNotEmpty ? jsonDecode(res.body) : null;
    } catch (_) {
      body = null;
    }
    return (status: res.statusCode, body: body);
  }

  /// Extracts a human-readable message from the backend's response envelope:
  /// `{ error: "invalid_invitation", message: "Invalid or expired..." }`.
  /// `message` is the human-readable text; `error` is a machine code, so it's
  /// only used as a last-resort fallback if `message` is missing.
  String? _extractErrorMessage(dynamic body) {
    if (body is! Map) return null;
    if (body['message'] is String) return body['message'] as String;
    final error = body['error'];
    if (error is Map && error['message'] is String) {
      return error['message'] as String;
    }
    if (error is String) return error;
    return null;
  }

  /// Fallback message when the response has no usable `{error/message}`
  /// body (e.g. a non-JSON 404/500 page) — surfaces the status code instead
  /// of a generic message so a missing/misconfigured route is diagnosable.
  String _httpErrorFallback(int status) {
    if (status == 404) {
      return 'This feature isn\'t available yet (404). Please contact support.';
    }
    if (status >= 500) {
      return 'Server error ($status). Please try again later.';
    }
    return 'Request failed ($status). Please try again.';
  }

  /// Activates a technician's invite-created account: no password anywhere
  /// in this backend, no `supabase.auth.signUp()` call. The account already
  /// exists (created, unconfirmed, when the admin sent the invite) — this
  /// just confirms the email, records name/phone, and consumes the code.
  /// Caller should route to the normal OTP login screen afterward.
  Future<bool> acceptInvite({
    required String email,
    required String code,
    required String name,
    String? phone,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _postJson(PublicApiConfig.acceptInvite, {
        'email': email,
        'code': code,
        'name': name,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      });

      final data = res.body is Map ? res.body['data'] : null;
      if (res.status >= 200 && res.status < 300 && data is Map && data['accepted'] == true) {
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _isLoading = false;
      _error = _extractErrorMessage(res.body) ??
          (res.status >= 200 && res.status < 300
              ? 'Could not activate your account.'
              : _httpErrorFallback(res.status));
      notifyListeners();
      return false;
    } on SocketException {
      _isLoading = false;
      _error = 'Network error. Please check your connection.';
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _error = 'Something went wrong. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> checkAuth() async {
    final session = _supabase.auth.currentSession;
    if (session != null) {
      await _fetchUserProfile(session.user.id);
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await NotificationService().unregisterToken().catchError((e) {
        debugPrint('FCM unregister error: $e');
      });
      await _supabase.auth.signOut();
    } catch (e) {
      debugPrint('Logout error: $e');
    } finally {
      _user = null;
      _error = null;
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
