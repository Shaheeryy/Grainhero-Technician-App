import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../config/app_theme.dart';
import 'terms_of_service_screen.dart';
import 'privacy_policy_screen.dart';

class AboutAppScreen extends StatefulWidget {
  const AboutAppScreen({super.key});

  @override
  State<AboutAppScreen> createState() => _AboutAppScreenState();
}

class _AboutAppScreenState extends State<AboutAppScreen> {
  String _version = '1.0.0';
  String _buildNumber = '1';

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _version = info.version;
          _buildNumber = info.buildNumber;
        });
      }
    } catch (e) {
      debugPrint('Error loading package info: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('About GrainHero', style: TextStyle(color: AppTheme.textPrimary)),
        backgroundColor: AppTheme.surfaceColor,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingXL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            // App Logo
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/grainhero logo.png',
                  height: 80,
                  width: 80,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // App Name & Version
            const Text(
              'GrainHero Technician',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryLight.withOpacity(0.3)),
              ),
              child: Text(
                'v$_version ($_buildNumber)',
                style: const TextStyle(
                  color: AppTheme.primaryLight,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            
            const SizedBox(height: 48),

            // Info Cards
            _buildInfoTile(
              title: 'Technician Edition',
              subtitle: 'Authorized for maintenance & monitoring',
              icon: Icons.verified_user_outlined,
            ),
            const SizedBox(height: 16),
            _buildInfoTile(
              title: 'Terms of Service',
              subtitle: 'Read our terms and conditions',
              icon: Icons.description_outlined,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TermsOfServiceScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildInfoTile(
              title: 'Privacy Policy',
              subtitle: 'How we handle your data',
              icon: Icons.privacy_tip_outlined,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                );
              },
            ),

            const SizedBox(height: 48),
            
            // Footer
            const Text(
              '© 2026 GrainHero Inc.',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Designed for Efficiency',
              style: TextStyle(
                color: AppTheme.textHint,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required String title,
    required String subtitle,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: AppTheme.cardDecoration,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
          ),
        ),
        trailing: onTap != null 
            ? const Icon(Icons.chevron_right, color: AppTheme.textHint)
            : null,
      ),
    );
  }
}
