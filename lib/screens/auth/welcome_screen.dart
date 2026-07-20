import 'package:flutter/material.dart';
import 'package:grainhero_technician_app/config/auth_theme.dart';
import 'package:grainhero_technician_app/screens/auth/login_screen.dart';
import 'package:grainhero_technician_app/screens/auth/sign_up_screen.dart';
import 'package:grainhero_technician_app/widgets/auth_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthTheme.beigeBackground,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Top Section: Logo
                        const SizedBox(height: 40),
                        Column(
                          children: [
                            Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 30,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  
                                  borderRadius: BorderRadius.circular(18),
                                  child: Image.asset(
                                    'assets/images/logo_grain.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        // Middle Section: Text and Buttons
                        Column(
                          children: [
                            const Text(
                              'Welcome\nto GrainHero',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AuthTheme.textPrimary,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 48),

                            AuthButton(
                              text: 'Sign Up',
                              icon: Icons.person_add_alt_1_rounded,
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const SignUpScreen()),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            AuthButton(
                              text: 'Log In',
                              icon: Icons.login_rounded,
                              isOutlined: true,
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                                );
                              },
                            ),
                            const SizedBox(height: 32),

                            // Divider
                            Row(
                              children: [
                                const Expanded(child: Divider(color: AuthTheme.dividerColor)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                  child: Text(
                                    'OR CONTINUE WITH',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AuthTheme.textHint,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const Expanded(child: Divider(color: AuthTheme.dividerColor)),
                              ],
                            ),
                            const SizedBox(height: 32),

                            // Social Buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _SocialButton(
                                  child: Image.asset(
                                    'assets/images/google-logo.png',
                                    width: 24,
                                    height: 24,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.g_mobiledata, size: 36),
                                  ),
                                  onPressed: () {},
                                ),
                                const SizedBox(width: 20),
                                _SocialButton(
                                  child: Image.asset(
                                    'assets/images/x logo.png',
                                    width: 24,
                                    height: 24,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.g_mobiledata, size: 36),
                                  ),
                                  onPressed: () {},
                                ),
                                const SizedBox(width: 20),
                                _SocialButton(
                                  child: Image.asset(
                                    'assets/images/insta_logo.jpg',
                                    width: 24,
                                    height: 24,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.g_mobiledata, size: 36),
                                  ),
                                  onPressed: () {},
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Bottom Section: Terms
                        const SizedBox(height: 40),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Text.rich(
                            TextSpan(
                              text: 'By continuing, you agree to our ',
                              style: const TextStyle(
                                color: AuthTheme.textSecondary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Terms of Service',
                                  style: const TextStyle(
                                    color: AuthTheme.primaryGreen,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const TextSpan(text: '.'),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onPressed;

  const _SocialButton({
    required this.child,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AuthTheme.borderLight, width: 1),
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}
