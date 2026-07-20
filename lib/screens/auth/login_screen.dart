import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:grainhero_technician_app/config/api_config.dart';
import 'package:grainhero_technician_app/config/app_theme.dart';
import 'package:grainhero_technician_app/config/auth_theme.dart';
import 'package:grainhero_technician_app/screens/main/main_screen.dart';
import 'package:grainhero_technician_app/screens/auth/forgot_password_screen.dart';
import 'package:grainhero_technician_app/screens/auth/sign_up_screen.dart';
import 'package:grainhero_technician_app/utils/secure_storage.dart';
import 'package:grainhero_technician_app/services/notification_service.dart';
import 'package:grainhero_technician_app/widgets/auth_button.dart';

class LoginScreen extends StatefulWidget {
  final String? email;
  final String? password;
  const LoginScreen({super.key, this.email, this.password});

  static Route route({String? email, String? password}) {
    return MaterialPageRoute(
      builder: (_) => LoginScreen(email: email, password: password),
    );
  }

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
    final size = MediaQuery.of(context).size;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
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
          body: Stack(
            children: [
              // Background Image with green overlay
              Container(
                width: size.width,
                height: size.height,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/wheat_background.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Container(
                width: size.width,
                height: size.height,
                color: AuthTheme.greenOverlay.withOpacity(0.85),
              ),

              // Content
              SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    ),
                  ),
                ),
                    const SizedBox(height: 40),
                    // Logo and Title
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.all(Radius.circular(23)),
                                child: Image.asset(
                                  'assets/images/logo_grain.png',
                                  width: 85,
                                  height: 85,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'GrainHero',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Bottom Sheet Card
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: AuthTheme.beigeBackground,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(40),
                            topRight: Radius.circular(40),
                          ),
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 32,
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'Login Here!',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: AuthTheme.textPrimary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),

                                // Email Field
                                _buildOutlinedTextField(
                                  controller: emailController,
                                  icon: Icons.email_outlined,
                                  hintText: 'Email',
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Email required';
                                    }
                                    if (!value.contains('@')) {
                                      return 'Invalid email';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Password Field
                                _buildOutlinedTextField(
                                  controller: passwordController,
                                  icon: Icons.lock_outline,
                                  hintText: 'Password',
                                  obscureText: _obscurePassword,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: AuthTheme.textSecondary,
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
                                      return 'Enter password';
                                    }
                                    if (value.length < 6) {
                                      return 'Minimum 6 characters';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),

                                // Forgot Password Link
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: GestureDetector(
                                    onTap: _forgotPassword,
                                    child: const Text(
                                      'Forgot Password?',
                                      style: TextStyle(
                                        color: AuthTheme.primaryGreen,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                AuthButton(
                                  text: 'Login',
                                  isLoading: _isLoading,
                                  onPressed: _login,
                                ),
                                const SizedBox(height: 24),

                                // OR Divider
                                Row(
                                  children: [
                                    const Expanded(
                                      child: Divider(
                                        color: AuthTheme.dividerColor,
                                        thickness: 1,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      child: const Text(
                                        'OR',
                                        style: TextStyle(
                                          color: AuthTheme.textHint,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const Expanded(
                                      child: Divider(
                                        color: AuthTheme.dividerColor,
                                        thickness: 1,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // Google Continue Button
                                SizedBox(
                                  height: 52,
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Google Login not implemented yet.')),
                                      );
                                    },
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      side: BorderSide.none,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(26),
                                      ),
                                    ),
                                    icon: Image.asset(
                                      'assets/images/google-logo.png',
                                      width: 28,
                                      height: 24,
                                    ),
                                    label: const Text(
                                      'Continue with Google',
                                      style: TextStyle(
                                        color: Color(0xFF424242),
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 32),

                                // Sign Up Link
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      "New to GrainHero? ",
                                      style: TextStyle(
                                        color: AuthTheme.textSecondary,
                                        fontSize: 14,
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
                                      child: const Text(
                                        'Sign Up',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AuthTheme.primaryGreen,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOutlinedTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hintText,
    TextInputType? keyboardType,
    bool obscureText = false,
    bool readOnly = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      readOnly: readOnly,
      style: const TextStyle(
        fontSize: 15,
        color: AuthTheme.textPrimary,
      ),
      decoration: AuthTheme.getInputDecoration(
        hintText: hintText,
        prefixIcon: icon,
        suffixIcon: suffixIcon,
      ),
      validator: validator,
    );
  }
}