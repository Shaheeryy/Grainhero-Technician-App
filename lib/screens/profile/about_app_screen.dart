import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'terms_of_service_screen.dart';
import 'privacy_policy_screen.dart';
import 'open_source_licenses_screen.dart';
import '../../config/grainhero_colors.dart';
import '../../config/typography.dart';

class AboutAppScreen extends StatefulWidget {
  const AboutAppScreen({super.key});

  @override
  State<AboutAppScreen> createState() => _AboutAppScreenState();
}

class _AboutAppScreenState extends State<AboutAppScreen> {
  String _version = '2.4.12';
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
      backgroundColor: GrainHeroColors.pageBackground,
      appBar: AppBar(
        backgroundColor: GrainHeroColors.pageBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: GrainHeroColors.dark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'About GrainHero',
          style: AppTypography.headingStyle(
            color: GrainHeroColors.dark,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 32,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        const SizedBox(height: 12),
                        // Circular Logo Container with Soft Stroke & Subtle Shadow
                        Container(
                          width: 112,
                          height: 112,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 12,
                                // offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/logo_grain.png',
                              height: 100,
                              width: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.eco_rounded,
                                  size: 48,
                                  color: GrainHeroColors.primaryDark,
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // App Name
                        Text(
                          'GrainHero Technician',
                          textAlign: TextAlign.center,
                          style: AppTypography.headingStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: GrainHeroColors.dark,
                          ).copyWith(letterSpacing: -0.2),
                        ),
                        const SizedBox(height: 10),

                        // Version Badge
                        Tooltip(
                          message: 'Build $_buildNumber',
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: GrainHeroColors.primaryDark.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: GrainHeroColors.primaryDark.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'v$_version',
                              style: AppTypography.bodyStyle(
                                color: GrainHeroColors.primaryDark,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ).copyWith(letterSpacing: 0.3),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Action Cards List
                        _buildActionCard(
                          context: context,
                          title: 'Terms of Service',
                          subtitle: 'Read our terms and conditions',
                          icon: Icons.description_outlined,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TermsOfServiceScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 14),
                        _buildActionCard(
                          context: context,
                          title: 'Privacy Policy',
                          subtitle: 'How we handle your data',
                          icon: Icons.shield_outlined,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AboutAppPrivacyPolicyPage(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 14),
                        _buildActionCard(
                          context: context,
                          title: 'Open Source Licenses',
                          subtitle: 'Third party software notice',
                          icon: Icons.verified_outlined,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const OpenSourceLicensesScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),

                    // Footer Area
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12, top: 16),
                      child: Column(
                        children: [
                          Text(
                            '© 2024 GrainHero Systems Inc.',
                            style: AppTypography.bodyStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: GrainHeroColors.dark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Main Office, Portland OR',
                            style: AppTypography.bodyStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: GrainHeroColors.mutedText,
                            ).copyWith(fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: GrainHeroColors.outline.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: GrainHeroColors.primaryDark.withValues(alpha: 0.08),
          highlightColor: GrainHeroColors.primaryDark.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Icon circular container
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: GrainHeroColors.primaryDark.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: GrainHeroColors.primaryDark,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                // Title and Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.headingStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: GrainHeroColors.dark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTypography.bodyStyle(
                          fontSize: 12,
                          color: GrainHeroColors.mutedText,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                // Chevron icon
                const Icon(
                  Icons.chevron_right_rounded,
                  color: GrainHeroColors.mutedText,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


