import 'package:flutter/material.dart';
import 'package:grainhero_technician_app/widgets/common/auth_text_field.dart';
import 'package:provider/provider.dart';
import 'package:grainhero_technician_app/config/app_theme.dart';
import 'package:grainhero_technician_app/config/auth_theme.dart';
import 'package:grainhero_technician_app/services/auth_service.dart';
import 'package:grainhero_technician_app/screens/auth/reset_password_screen.dart';
import 'package:grainhero_technician_app/widgets/common/auth_button.dart';
import 'widgets/auth_header.dart';
import 'widgets/auth_logo.dart';
import 'widgets/auth_footer.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = Provider.of<AuthService>(context, listen: false);

    final success =
        await authService.forgetPassword(_emailController.text.trim());

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reset link sent! Please check your email.'),
          backgroundColor: AppTheme.successColor,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const ResetPasswordScreen(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(authService.error ?? 'Failed to send reset link'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      backgroundColor: AuthTheme.beigeBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 10),
            
                // Back Button
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AuthTheme.textPrimary,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
            
                const SizedBox(height: 15),
            
                // =====================================================
                // HEADER
                // =====================================================
                const AuthHeader(
                  title: "Forgot Password",
                  subtitle: "Remember and input your email or phone number below.",
                ),
            
                const SizedBox(height: 40),
            
                // =====================================================
                // ILLUSTRATION LOGO
                // =====================================================
                const AuthLogo(imagePath: 'assets/images/forgot_password.png'),
                
                const SizedBox(height: 50),
                
                // =====================================================
                // FORM
                // =====================================================
                
                const Align(
                  alignment: Alignment.center,
                  child: Text(
                    "Email or Phone Number",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AuthTheme.textPrimary,
                    ),
                  ),
                ),
            
                const SizedBox(height: 12),
            
                AuthTextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  hintText: "example@gmail.com",
                  icon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
            
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
            
                    return null;
                  },
                ),
            
                const SizedBox(height: 30),
            
                AuthButton(
                  text: 'Reset Password',
                  isLoading: authService.isLoading,
                  onPressed: _submit,
                ),
            
                const SizedBox(height: 40),
            
                // =====================================================
                // FOOTER
                // =====================================================
                AuthFooter(
                  text: "Wait, I remember it! ",
                  actionText: "Log In",
                  onActionTap: () => Navigator.pop(context),
                ),
            
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}