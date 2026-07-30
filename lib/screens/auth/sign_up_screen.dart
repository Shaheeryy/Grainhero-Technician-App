import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:grainhero_technician_app/config/api_config.dart';
import 'package:grainhero_technician_app/config/app_theme.dart';
import 'package:grainhero_technician_app/config/auth_theme.dart';
import 'package:grainhero_technician_app/screens/auth/login_screen.dart';
import 'package:grainhero_technician_app/utils/secure_storage.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:grainhero_technician_app/widgets/common/auth_button.dart';
import 'package:grainhero_technician_app/widgets/common/auth_text_field.dart';
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
    final size = MediaQuery.of(context).size;
    return Scaffold(
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
                // Back button
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
                                borderRadius: BorderRadiusGeometry.circular(23),
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
                              'CREATE ACCOUNT',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AuthTheme.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            
                            const SizedBox(height: 8),
                            
                            const Text(
                              'Fill in your details to get started',
                              style: TextStyle(
                                fontSize: 14,
                                color: AuthTheme.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            
                            const SizedBox(height: 32),

                            // Invitation Token field
                            AuthTextField(
                              controller: invitationTokenController,
                              icon: Icons.vpn_key_outlined,
                              hintText: 'Invitation Token (if provided)',
                            ),

                            const SizedBox(height: 16),

                            // Email field
                            AuthTextField(
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
                            
                            const SizedBox(height: 16),
                            
                            // Full name field
                            AuthTextField(
                              controller: nameController,
                              icon: Icons.person_outline,
                              hintText: 'Full Name',
                              validator: (val) =>
                                  val == null || val.isEmpty ? 'Name required' : null,
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Phone field with international format
                            Container(
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  border: Border.all(
                                    color: AuthTheme.borderLight,
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                child: IntlPhoneField(
                                  initialCountryCode: 'PK',

                                  dropdownIcon: const Icon(
                                    Icons.keyboard_arrow_down,
                                    color: AuthTheme.textSecondary,
                                    size: 20,
                                  ),

                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: AuthTheme.textPrimary,
                                  ),

                                  dropdownTextStyle: const TextStyle(
                                    fontSize: 15,
                                    color: AuthTheme.textPrimary,
                                  ),

                                  flagsButtonPadding: const EdgeInsets.only(left: 12),

                                  disableLengthCheck: true,

                                  decoration: const InputDecoration(
                                    hintText: 'Phone Number',
                                    hintStyle: TextStyle(
                                      color: AuthTheme.textHint,
                                      fontSize: 15,
                                    ),

                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    errorBorder: InputBorder.none,
                                    focusedErrorBorder: InputBorder.none,

                                    counterText: '',

                                    filled: false,
                                    isDense: true,

                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 18,
                                    ),
                                  ),

                                  onChanged: (phone) {
                                    phoneNumber = phone.number;
                                    countryCode = '+${phone.countryCode}';
                                  },

                                  validator: (val) {
                                    if (val == null || val.number.trim().isEmpty) {
                                      return 'Phone required';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            
                            const SizedBox(height: 16),
                            
                            // Password field
                            AuthTextField(
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
                              validator: (val) {
                                if (val == null || val.isEmpty) return 'Enter password';
                                if (val.length < 6) return 'Minimum 6 characters';
                                return null;
                              },
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Confirm password field
                            AuthTextField(
                              controller: confirmPasswordController,
                              icon: Icons.lock_outline,
                              hintText: 'Confirm Password',
                              obscureText: _obscureConfirmPassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: AuthTheme.textSecondary,
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
                            
                            const SizedBox(height: 32),
                            
                            AuthButton(
                              text: 'SIGN UP',
                              isLoading: _isLoading,
                              onPressed: _signup,
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Login link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Already Have An Account? ",
                                  style: TextStyle(
                                    color: AuthTheme.textSecondary,
                                    fontSize: 14,
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
                                      color: AuthTheme.primaryGreen,
                                      fontSize: 14,
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
        ],
      ),
    );
  }

}
