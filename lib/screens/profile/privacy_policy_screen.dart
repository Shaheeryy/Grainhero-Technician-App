import 'package:flutter/material.dart';
import '../../config/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Privacy Policy', style: TextStyle(color: AppTheme.textPrimary)),
        backgroundColor: AppTheme.surfaceColor,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Privacy Policy',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last updated: April 2026',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              '1. Information We Collect',
              'We collect information you provide directly to us, including your name, email address, phone number, and professional credentials when you create an account. We also collect data from sensors and devices connected through the App, including environmental readings (temperature, humidity, air quality) and equipment status information.',
            ),
            _buildSection(
              '2. How We Use Your Information',
              'We use the information we collect to:\n'
              '• Provide and maintain the GrainHero Technician service\n'
              '• Monitor and optimize grain storage conditions\n'
              '• Send alerts and notifications about storage conditions\n'
              '• Authenticate your identity and manage your account\n'
              '• Improve our services and develop new features\n'
              '• Comply with legal obligations',
            ),
            _buildSection(
              '3. Data Storage & Security',
              'Your data is stored securely on cloud servers with industry-standard encryption. We implement appropriate technical and organizational measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction. Authentication tokens are stored securely on your device using encrypted storage.',
            ),
            _buildSection(
              '4. Data Sharing',
              'We do not sell, trade, or rent your personal information to third parties. We may share data with:\n'
              '• Your organization\'s administrators for management purposes\n'
              '• Service providers who assist in operating our platform\n'
              '• Law enforcement when required by law\n\n'
              'Sensor and environmental data may be shared within your organization for monitoring and compliance purposes.',
            ),
            _buildSection(
              '5. Sensor & Device Data',
              'The App collects real-time data from connected IoT sensors and devices, including temperature, humidity, TVOC/CO2 levels, and equipment operational status. This data is used solely for grain storage monitoring and is associated with your organization\'s account.',
            ),
            _buildSection(
              '6. Data Retention',
              'We retain your personal information for as long as your account is active or as needed to provide services. Sensor data and environmental readings are retained according to your organization\'s data retention policies. You may request deletion of your personal data by contacting your administrator.',
            ),
            _buildSection(
              '7. Your Rights',
              'You have the right to:\n'
              '• Access your personal information\n'
              '• Correct inaccurate data\n'
              '• Request deletion of your account\n'
              '• Export your data in a portable format\n'
              '• Withdraw consent for data processing\n\n'
              'To exercise these rights, contact your organization administrator or reach out to us directly.',
            ),
            _buildSection(
              '8. Cookies & Local Storage',
              'The App uses secure local storage to maintain your authentication session and user preferences. No tracking cookies or third-party analytics are used within the mobile application.',
            ),
            _buildSection(
              '9. Children\'s Privacy',
              'The App is not intended for use by individuals under 18 years of age. We do not knowingly collect personal information from children.',
            ),
            _buildSection(
              '10. Changes to This Policy',
              'We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new policy within the App and updating the "Last updated" date. Your continued use of the App after any changes constitutes acceptance of the updated policy.',
            ),
            _buildSection(
              '11. Contact Us',
              'If you have any questions about this Privacy Policy or our data practices, please contact us at:\n\n'
              'Email: privacy@grainhero.com\n'
              'GrainHero Inc.',
            ),
            const SizedBox(height: 32),
            Center(
              child: Text(
                '© 2026 GrainHero Inc. All rights reserved.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textHint,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
