import 'package:flutter/material.dart';
import 'package:grainhero_technician_app/widgets/auth_text_field.dart';
import 'package:provider/provider.dart';
import 'package:grainhero_technician_app/config/app_theme.dart';
import 'package:grainhero_technician_app/config/auth_theme.dart';
import 'package:grainhero_technician_app/services/auth_service.dart';
import 'package:grainhero_technician_app/screens/auth/reset_password_screen.dart';
import 'package:grainhero_technician_app/widgets/auth_button.dart';

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
            
                const Text(
                  "Forgot Password",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: AuthTheme.textSecondary,
                  ),
                ),
            
                const SizedBox(height: 8),
            
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    "Remember and input your email or phone number below.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: AuthTheme.textHint,
                      height: 1.5,
                    ),
                  ),
                ),
            
                const SizedBox(height: 40),
            
                // Illustration styled with circular border
                Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AuthTheme.beigeBackground,
                    border: Border.all(
                      color: const Color.fromARGB(130, 255, 255, 255),
                      width: 10,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 25,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(1.0),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/forgot_password.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 50),
                
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
            
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Wait, I remember it! ",
                      style: TextStyle(
                        color: AuthTheme.textHint,
                        fontSize: 15,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        "Log In",
                        style: TextStyle(
                          color: AuthTheme.primaryGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
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