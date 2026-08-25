import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../utils/validators.dart';
import '../../config/auth_theme.dart';
import '../../widgets/common/app_toast.dart';
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
  bool _isVerifying = false;

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

    setState(() => _isVerifying = true);

    final authService = Provider.of<AuthService>(context, listen: false);
    final success = await widget.onVerify(_otpController.text);

    if (!mounted) return;

    setState(() => _isVerifying = false);

    if (success) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (route) => false,
      );
    } else {
      AppToast.show(context, authService.error ?? 'Invalid or expired code', isError: true);
    }
  }

  Future<void> _resend() async {
    if (_resendTimer > 0) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final success = await widget.onResend();

    if (!mounted) return;

    if (success) {
      _startTimer();
      AppToast.show(context, 'Code sent successfully');
    } else {
      // Supabase rate-limits still count as "sent recently" — restart the
      // cooldown so the button doesn't re-enable prematurely.
      _startTimer();
      AppToast.show(context, authService.error ?? 'Could not resend code', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return GestureDetector(
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
                  const SizedBox(height: 24),

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
                                'Enter Code',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AuthTheme.textPrimary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Enter the code sent to ${widget.email}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AuthTheme.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 32),

                              // OTP Input
                              TextFormField(
                                controller: _otpController,
                                keyboardType: TextInputType.number,
                                validator: Validators.validateOtp,
                                maxLength: 6,
                                autofocus: true,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AuthTheme.textPrimary,
                                  letterSpacing: 8,
                                ),
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                decoration: InputDecoration(
                                  hintText: '· · · · · ·',
                                  hintStyle: const TextStyle(
                                    color: AuthTheme.textHint,
                                    fontSize: 20,
                                  ),
                                  counterText: '',
                                  filled: true,
                                  fillColor: Colors.transparent,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 18),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: const BorderSide(color: AuthTheme.borderLight, width: 1),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: const BorderSide(color: AuthTheme.borderLight, width: 1),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: const BorderSide(color: AuthTheme.primaryGreen, width: 1.8),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: const BorderSide(color: Colors.red, width: 1.2),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Verify Button
                              SizedBox(
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _isVerifying ? null : _verify,
                                  style: AuthTheme.primaryButtonStyle,
                                  child: _isVerifying
                                      ? const SizedBox(
                                          height: 22,
                                          width: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : const Text(
                                          'Verify',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Resend Code
                              Center(
                                child: _resendTimer > 0
                                    ? Text(
                                        'Resend code in $_resendTimer seconds',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: AuthTheme.textSecondary,
                                        ),
                                      )
                                    : TextButton(
                                        onPressed: _resend,
                                        child: const Text(
                                          'Resend Code',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: AuthTheme.primaryGreen,
                                          ),
                                        ),
                                      ),
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
    );
  }
}
