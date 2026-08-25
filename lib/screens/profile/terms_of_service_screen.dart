import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  static const _pageBg = Color(0xFFFEFAE4);
  static const _textDark = Color(0xFF1D1C0F);
  static const _textTertiary = Color(0xFF536256);
  static const _primaryDark = Color(0xFF176E00);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: _pageBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Terms of Service',
          style: TextStyle(color: _textDark, fontSize: 20, fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Terms of Service',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Last updated: April 2026',
                style: TextStyle(
                  fontSize: 13,
                  color: _textTertiary,
                ),
              ),
              const SizedBox(height: 24),
              _buildSection(
                '1. Acceptance of Terms',
                'By accessing and using the GrainHero Technician application ("the App"), you agree to be bound by these Terms of Service. If you do not agree to these terms, you must not use the App.',
              ),
              _buildSection(
                '2. Description of Service',
                'GrainHero Technician is a grain storage monitoring and management application designed for authorized technicians. The App provides real-time monitoring of silo conditions including temperature, humidity, and air quality, as well as tools for managing grain batches, sensors, and actuators.',
              ),
              _buildSection(
                '3. User Accounts',
                'You must be an authorized technician with valid credentials to access the App. You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account. You must immediately notify administration of any unauthorized use of your account.',
              ),
              _buildSection(
                '4. Authorized Use',
                'The App is intended solely for authorized personnel performing grain storage monitoring and maintenance duties. You agree to use the App only for its intended purpose and in compliance with all applicable laws and regulations. Unauthorized access, modification, or distribution of the App or its data is strictly prohibited.',
              ),
              _buildSection(
                '5. Data Accuracy',
                'While we strive to provide accurate sensor readings and data, GrainHero does not guarantee the absolute accuracy of any data displayed in the App. Critical decisions regarding grain storage should always be verified with physical inspections and additional measurements.',
              ),
              _buildSection(
                '6. Intellectual Property',
                'All content, features, and functionality of the App, including but not limited to text, graphics, logos, and software, are the exclusive property of GrainHero Inc. and are protected by international copyright, trademark, and other intellectual property laws.',
              ),
              _buildSection(
                '7. Limitation of Liability',
                'GrainHero Inc. shall not be liable for any indirect, incidental, special, consequential, or punitive damages resulting from your use of or inability to use the App, including but not limited to damages for loss of profits, data, or other intangible losses.',
              ),
              _buildSection(
                '8. Service Availability',
                'We do not guarantee uninterrupted access to the App. The service may be temporarily unavailable due to maintenance, updates, or circumstances beyond our control. We reserve the right to modify, suspend, or discontinue the App at any time without prior notice.',
              ),
              _buildSection(
                '9. Modifications to Terms',
                'GrainHero Inc. reserves the right to modify these Terms of Service at any time. Changes will be effective immediately upon posting within the App. Your continued use of the App after any changes constitutes your acceptance of the new terms.',
              ),
              _buildSection(
                '10. Contact Information',
                'For questions or concerns regarding these Terms of Service, please contact us at support@grainhero.com.',
              ),
              const SizedBox(height: 32),
              const Center(
                child: Text(
                  '© 2026 GrainHero Inc. All rights reserved.',
                  style: TextStyle(
                    fontSize: 12,
                    color: _textTertiary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
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
              color: _primaryDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: _textDark,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
