import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:grainhero_technician_app/config/api_config.dart';
import 'package:grainhero_technician_app/config/app_theme.dart';
import 'package:grainhero_technician_app/screens/main/main_screen.dart';
import 'package:grainhero_technician_app/screens/auth/forgot_password_screen.dart';
import 'package:grainhero_technician_app/screens/auth/sign_up_screen.dart';
import 'package:grainhero_technician_app/utils/secure_storage.dart';
import 'package:grainhero_technician_app/services/notification_service.dart';

class LoginScreen extends StatefulWidget {
  final String? email;
  final String? password;
  const LoginScreen({super.key, this.email, this.password});

  static Route route({String? email, String? password}) => MaterialPageRoute(
    builder: (_) => LoginScreen(email: email, password: password),
  );

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final emailController = TextEditingController(text: widget.email ?? "");
  late final passwordController = TextEditingController(
    text: widget.password ?? "",
  );
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final body = jsonEncode({
        'email': emailController.text.trim(),
        'password': passwordController.text,
      });

      final loginUrl = ApiConfig.login;
      debugPrint('🔐 Attempting login to: $loginUrl');
      
      final response = await http
          .post(
            Uri.parse(loginUrl),
            headers: ApiConfig.getHeaders(),
            body: body,
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              debugPrint('⏱️ Login request timed out after 15 seconds');
              throw Exception(
                'Connection timeout. Please check your internet connection and try again.',
              );
            },
          );
      
      debugPrint('✅ Login response received: Status ${response.statusCode}');

      if (!mounted) return;

      final contentType = response.headers['content-type'] ?? '';
      if (contentType.contains('text/html') ||
          response.body.trim().startsWith('<!DOCTYPE')) {
        _showError('Backend error: Received HTML instead of JSON. Check if backend is running.');
        return;
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final data = jsonDecode(response.body);

          String? token;
          if (data['token'] != null) {
            token = data['token'];
          } else if (data['accessToken'] != null) {
            token = data['accessToken'];
          } else if (data['user'] != null && data['user']['token'] != null) {
            token = data['user']['token'];
          }

          if (token != null && token.isNotEmpty) {
            await SecureStorage.saveToken(token);
          } else {
            debugPrint('Warning: No token found in login response');
          }

          Map<String, dynamic>? userData;
          if (data['user'] != null) {
            userData = data['user'] is Map
                ? Map<String, dynamic>.from(data['user'])
                : null;
          } else if (data['technician'] != null) {
            userData = data['technician'] is Map
                ? Map<String, dynamic>.from(data['technician'])
                : null;
          } else {
            userData = data;
          }

          if (userData != null) {
            await SecureStorage.saveUserData(
              userId:
                  userData['id']?.toString() ??
                  userData['_id']?.toString() ??
                  '',
              userName:
                  userData['name']?.toString() ??
                  userData['fullName']?.toString() ??
                  '',
              userPhone:
                  userData['phone']?.toString() ??
                  userData['phoneNumber']?.toString() ??
                  '',
            );
          }

          if (!mounted) return;
          
          debugPrint('✅ Login successful, navigating to dashboard...');

          // Register FCM token now that we have a valid auth token
          NotificationService().registerToken().catchError((e) {
            debugPrint('FCM token registration after login: $e');
          });
          
          setState(() {
            _isLoading = false;
          });

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainScreen()),
          );
          return;
        } catch (e) {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
          });
          _showError('Error parsing response: $e');
          return;
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        try {
          final errorData = jsonDecode(response.body);
          if (!mounted) return;
          _showError(errorData['message'] ?? 'Login failed');
        } catch (e) {
          if (!mounted) return;
          _showError('Login failed (Status: ${response.statusCode})');
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      
      String errorMessage = 'Connection error';
      if (e.toString().contains('timeout') || e.toString().contains('TimeoutException')) {
        errorMessage = 'Request timed out. Please check your connection.';
      } else if (e.toString().contains('Failed host lookup') ||
          e.toString().contains('SocketException')) {
        errorMessage = 'Cannot connect to server. Check your connection.';
      } else if (e.toString().contains('FormatException')) {
        errorMessage = 'Backend returned invalid data.';
      } else {
        errorMessage = 'Error: ${e.toString()}';
      }
      
      _showError(errorMessage);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _forgotPassword() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Dismiss keyboard on back press instead of closing app
        final currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
          currentFocus.unfocus();
        } else {
          SystemNavigator.pop();
        }
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          body: Container(
            decoration: const BoxDecoration(
              color: AppTheme.backgroundColor,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingXXL,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 60),
                    
                    // Welcome header
                    Text(
                      'WELCOME !',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                        letterSpacing: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      'Please Log In To Continue',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // LOGIN section header
                    Text(
                      'LOGIN',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Email field with underline style
                    _buildUnderlineTextField(
                      controller: emailController,
                      icon: Icons.person_outline,
                      hintText: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@') || !value.contains('.')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Password field with underline style
                    _buildUnderlineTextField(
                      controller: passwordController,
                      icon: Icons.lock_outline,
                      hintText: 'Password',
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppTheme.textSecondary,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _login(),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Submit button with gradient
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'SUBMIT',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Forgot password link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Forgot Your Password? ",
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        GestureDetector(
                          onTap: _forgotPassword,
                          child: Text(
                            'Reset Here',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Sign up link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't Have An Account? ",
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const SignUpScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'Register',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildUnderlineTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hintText,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    void Function(String)? onFieldSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textInputAction: onFieldSubmitted != null 
          ? TextInputAction.done 
          : TextInputAction.next,
      onFieldSubmitted: onFieldSubmitted,
      style: const TextStyle(
        fontSize: 15,
        color: AppTheme.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: AppTheme.textHint,
          fontSize: 14,
        ),
        prefixIcon: Container(
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 20,
          ),
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 50,
          minHeight: 40,
        ),
        suffixIcon: suffixIcon,
        filled: false,
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: AppTheme.dividerColor),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppTheme.dividerColor),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        errorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppTheme.errorColor),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
      validator: validator,
    );
  }
}
