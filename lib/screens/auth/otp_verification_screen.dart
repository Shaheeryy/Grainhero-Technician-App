import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../utils/validators.dart';
import '../../widgets/common/custom_button.dart';
import '../../config/app_theme.dart';
import '../main/main_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final Future<bool> Function(String otp) onVerify;
  final Future<bool> Function() onResend;

  const OtpVerificationScreen({
    super.key,
    required this.email,
    required this.onVerify,
    required this.onResend,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  int _resendTimer = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _resendTimer = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        setState(() => _resendTimer--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final success = await widget.onVerify(_otpController.text);

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authService.error ?? 'Invalid or expired code'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _resend() async {
    if (_resendTimer > 0) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final success = await widget.onResend();

    if (!mounted) return;

    if (success) {
      _startTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Code sent successfully'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } else {
      // Supabase rate-limits still count as "sent recently" — restart the
      // cooldown so the button doesn't re-enable prematurely.
      _startTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authService.error ?? 'Could not resend code'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),

                const Text(
                  'Enter Code',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 8),

                Text(
                  'Enter the code sent to ${widget.email}',
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                ),

                const SizedBox(height: 48),

                // OTP Input
                TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  validator: Validators.validateOtp,
                  maxLength: 6,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    hintText: '_ _ _ _ _ _',
                    counterText: '',
                  ),
                ),

                const SizedBox(height: 32),

                // Verify Button
                Consumer<AuthService>(
                  builder: (context, authService, _) {
                    return CustomButton(
                      text: 'Verify',
                      onPressed: _verify,
                      isLoading: authService.isLoading,
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Resend Code
                Center(
                  child: _resendTimer > 0
                      ? Text(
                          'Resend code in $_resendTimer seconds',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        )
                      : TextButton(
                          onPressed: _resend,
                          child: const Text(
                            'Resend Code',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
