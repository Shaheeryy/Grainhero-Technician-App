import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:grainhero_technician_app/config/auth_theme.dart';
import 'package:grainhero_technician_app/screens/auth/login_screen.dart';
import 'package:grainhero_technician_app/services/auth_service.dart';
import 'package:grainhero_technician_app/widgets/common/app_toast.dart';

class AcceptInviteScreen extends StatefulWidget {
  final String? prefilledEmail;
  const AcceptInviteScreen({super.key, this.prefilledEmail});

  @override
  State<AcceptInviteScreen> createState() => _AcceptInviteScreenState();
}

class _AcceptInviteScreenState extends State<AcceptInviteScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final codeController = TextEditingController();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  bool _isLoading = false;

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
    codeController.dispose();
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _activate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authService = Provider.of<AuthService>(context, listen: false);
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    final success = await authService.acceptInvite(
      email: email,
      code: codeController.text.trim(),
      name: nameController.text.trim(),
      phone: phone.isEmpty ? null : phone,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      AppToast.show(context, 'Account activated — please log in');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => LoginScreen(email: email)),
        (route) => false,
      );
    } else {
      _showError(authService.error ?? 'Could not activate your account');
    }
  }

  void _showError(String message) {
    AppToast.show(context, message, isError: true);
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
                              'ACTIVATE YOUR ACCOUNT',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AuthTheme.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 8),

                            const Text(
                              'Enter the invite code your admin sent you to finish setting up',
                              style: TextStyle(
                                fontSize: 14,
                                color: AuthTheme.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 32),

                            // Email field
                            _buildOutlinedTextField(
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

                            // Invite code field
                            _buildOutlinedTextField(
                              controller: codeController,
                              icon: Icons.vpn_key_outlined,
                              hintText: 'Invite Code',
                              validator: (val) => val == null || val.isEmpty
                                  ? 'Invite code required'
                                  : null,
                            ),

                            const SizedBox(height: 16),

                            // Full name field
                            _buildOutlinedTextField(
                              controller: nameController,
                              icon: Icons.person_outline,
                              hintText: 'Full Name',
                              validator: (val) =>
                                  val == null || val.isEmpty ? 'Full name required' : null,
                            ),

                            const SizedBox(height: 16),

                            // Phone field (optional)
                            _buildOutlinedTextField(
                              controller: phoneController,
                              icon: Icons.phone_outlined,
                              hintText: 'Phone (optional)',
                              keyboardType: TextInputType.phone,
                            ),

                            const SizedBox(height: 32),

                            // Activate button
                            SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _activate,
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
                                        'ACTIVATE ACCOUNT',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.5,
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
                                  "Already activated? ",
                                  style: TextStyle(
                                    color: AuthTheme.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).pushAndRemoveUntil(
                                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                                      (route) => false,
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

  Widget _buildOutlinedTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hintText,
    TextInputType? keyboardType,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      style: const TextStyle(
        fontSize: 15,
        color: AuthTheme.textPrimary,
      ),
      decoration: AuthTheme.getInputDecoration(
        hintText: hintText,
        prefixIcon: icon,
      ),
      validator: validator,
    );
  }
}
