import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:grainhero_technician_app/config/auth_theme.dart';
import 'package:grainhero_technician_app/screens/auth/otp_verification_screen.dart';
import 'package:grainhero_technician_app/screens/auth/accept_invite_screen.dart';
import 'package:grainhero_technician_app/services/auth_service.dart';
import 'package:grainhero_technician_app/widgets/common/app_toast.dart';

class LoginScreen extends StatefulWidget {
  final String? email;
  const LoginScreen({super.key, this.email});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final emailController = TextEditingController(text: widget.email ?? "");
  bool _isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    final email = emailController.text.trim();
    final success = await authService.sendLoginOtp(email);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(
            email: email,
            onVerify: (otp) => authService.verifyLoginOtp(email, otp),
            onResend: () => authService.sendLoginOtp(email),
          ),
        ),
      );
    } else {
      _showError(authService.error ?? 'Could not send code');
    }
  }

  void _showError(String message) {
    AppToast.show(context, message, isError: true);
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
                color: AuthTheme.greenOverlay.withValues(alpha: 0.85),
              ),

              // Content
              SafeArea(
                bottom: false,
                child: Column(
                  children: [
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
                                const SizedBox(height: 8),
                                const Text(
                                  "Enter your email and we'll send you a login code.",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AuthTheme.textSecondary,
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
                                const SizedBox(height: 24),

                                // Submit Button
                                SizedBox(
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _sendCode,
                                    style: AuthTheme.primaryButtonStyle,
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
                                            'Send Code',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                  ),
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
                                      AppToast.show(context, 'Google Login not implemented yet.');
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
                                            builder: (_) => const AcceptInviteScreen(),
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
