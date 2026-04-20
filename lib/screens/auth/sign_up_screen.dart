import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:grainhero_technician_app/config/api_config.dart';
import 'package:grainhero_technician_app/config/app_theme.dart';
import 'package:grainhero_technician_app/screens/auth/login_screen.dart';
import 'package:grainhero_technician_app/utils/secure_storage.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

class SignUpScreen extends StatefulWidget {
  final String? prefilledEmail;
  const SignUpScreen({super.key, this.prefilledEmail});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final nameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final invitationTokenController = TextEditingController();
  String phoneNumber = '';
  String countryCode = '+92';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    if (widget.prefilledEmail != null) {
      emailController.text = widget.prefilledEmail!;
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    nameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    invitationTokenController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final body = <String, dynamic>{
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'phone': '$countryCode$phoneNumber',
        'password': passwordController.text,
        'confirm_password': confirmPasswordController.text,
      };

      // Add invitation token if provided
      final token = invitationTokenController.text.trim();
      if (token.isNotEmpty) {
        body['invitation_token'] = token;
      }

      final response = await http
          .post(
            Uri.parse(ApiConfig.signup),
            headers: ApiConfig.getHeaders(),
            body: jsonEncode(body),
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw Exception(
                'Connection timeout. Please check your internet connection.',
              );
            },
          );

      if (!mounted) return;

      final contentType = response.headers['content-type'] ?? '';
      if (contentType.contains('text/html') ||
          response.body.trim().startsWith('<!DOCTYPE')) {
        _showError('Backend error: Received HTML instead of JSON.');
        return;
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final data = jsonDecode(response.body);

          if (data['token'] != null || data['accessToken'] != null) {
            final token = data['token'] ?? data['accessToken'];
            await SecureStorage.saveToken(token);
          }

          if (data['user'] != null || data['technician'] != null) {
            final userData = data['user'] ?? data['technician'];
            await SecureStorage.saveUserData(
              userId: userData['id'] ?? userData['_id'] ?? '',
              userName: userData['name'] ?? userData['fullName'] ?? '',
              userPhone: userData['phone'] ?? userData['phoneNumber'] ?? '',
            );
          }

          if (!mounted) return;
          
          setState(() {
            _isLoading = false;
          });

          _showSuccess('Account created successfully!');
          
          Navigator.pushReplacement(
            context,
            LoginScreen.route(
              email: emailController.text.trim(),
              password: passwordController.text,
            ),
          );
          return;
        } catch (e) {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
          });
          Navigator.pushReplacement(
            context,
            LoginScreen.route(
              email: emailController.text.trim(),
              password: passwordController.text,
            ),
          );
          return;
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        try {
          final errorData = jsonDecode(response.body);
          if (!mounted) return;
          _showError(errorData['message'] ?? 'Signup failed');
        } catch (e) {
          if (!mounted) return;
          _showError('Signup failed (Status: ${response.statusCode})');
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      
      String errorMessage = 'Connection error';
      if (e.toString().contains('timeout')) {
        errorMessage = 'Request timed out. Please check your connection.';
      } else if (e.toString().contains('SocketException')) {
        errorMessage = 'Cannot connect to server.';
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
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          color: AppTheme.backgroundColor,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Back button
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingL),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios),
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.surfaceColor,
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ),
              ),

              // Main content - fully scrollable
              Expanded(
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
                          // Header
                          const Text(
                            'CREATE ACCOUNT',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                              letterSpacing: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          const SizedBox(height: 8),
                          
                          const Text(
                            'Fill in your details to get started',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          const SizedBox(height: 32),

                          // Invitation Token field
                          _buildUnderlineTextField(
                            controller: invitationTokenController,
                            icon: Icons.vpn_key_outlined,
                            hintText: 'Invitation Token (if provided)',
                          ),

                          const SizedBox(height: 20),

                          // Email field
                          _buildUnderlineTextField(
                            controller: emailController,
                            icon: Icons.email_outlined,
                            hintText: 'Email',
                            keyboardType: TextInputType.emailAddress,
                            readOnly: widget.prefilledEmail != null,
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Email required';
                              if (!val.contains('@')) return 'Invalid email';
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Full name field
                          _buildUnderlineTextField(
                            controller: nameController,
                            icon: Icons.person_outline,
                            hintText: 'Full Name',
                            validator: (val) =>
                                val == null || val.isEmpty ? 'Name required' : null,
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Phone field with international format
                          Container(
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: AppTheme.dividerColor),
                              ),
                            ),
                            child: IntlPhoneField(
                              initialCountryCode: 'PK',
                              decoration: InputDecoration(
                                hintText: 'Phone Number',
                                hintStyle: TextStyle(
                                  color: AppTheme.textHint,
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              style: const TextStyle(
                                fontSize: 15,
                                color: AppTheme.textPrimary,
                              ),
                              dropdownTextStyle: const TextStyle(
                                fontSize: 15,
                                color: AppTheme.textPrimary,
                              ),
                              onChanged: (phone) {
                                phoneNumber = phone.number;
                                countryCode = '+${phone.countryCode}';
                              },
                              validator: (val) =>
                                  val == null || val.number.isEmpty ? 'Phone required' : null,
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Password field
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
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Enter password';
                              if (val.length < 6) return 'Minimum 6 characters';
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Confirm password field
                          _buildUnderlineTextField(
                            controller: confirmPasswordController,
                            icon: Icons.lock_outline,
                            hintText: 'Confirm Password',
                            obscureText: _obscureConfirmPassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: AppTheme.textSecondary,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword = !_obscureConfirmPassword;
                                });
                              },
                            ),
                            validator: (val) => val != passwordController.text
                                ? "Passwords don't match"
                                : null,
                          ),
                          
                          const SizedBox(height: 40),
                          
                          // Sign up button with gradient
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
                              onPressed: _isLoading ? null : _signup,
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
                                      'SIGN UP',
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
                          
                          // Login link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Already Have An Account? ",
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                                  );
                                },
                                child: const Text(
                                  'Login',
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
            ],
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
        color: AppTheme.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
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
        border: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppTheme.dividerColor),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppTheme.dividerColor),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppTheme.errorColor),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
      validator: validator,
    );
  }
}
