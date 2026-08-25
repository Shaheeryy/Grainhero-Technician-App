import 'package:flutter/material.dart';
import 'legal_page_components.dart';

// =====================================================
// Terms of Service Screen
// Visual UI redesign matching screenshot specifications while
// preserving 100% of existing terms content, sections, and navigation.
// =====================================================
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  static const _pageBg = Color(0xFFFEFAE4);
  static const _textDark = Color(0xFF1D1C0F);
  static const _textTertiary = Color(0xFF536256);
  static const _primaryDark = Color(0xFF176E00);

  @override
  Widget build(BuildContext context) {
    return LegalDocumentPage(
      title: 'Terms of Service',
      icon: Icons.article_outlined,
      introduction:
          'Welcome to GrainHero Technician, operated by GrainHero Systems Inc. '
          'These Terms of Service govern your access to and use of the '
          'GrainHero Technician mobile application.\n\n'
          'By signing in to or using the application, you confirm that you '
          'have read and accepted these terms.',
      effectiveDate: '',
      lastUpdated: '7 August 2026',
      showSectionNavigator: true,
      sections: const [
        // =====================================================
        // Section 1: Purpose of the Application / Acceptance
        // =====================================================
        LegalSectionData(
          title: '1. Purpose of the Application',
          blocks: [
            LegalBlock.paragraph(
              'GrainHero Technician is designed for authorized technicians to:',
            ),
            LegalBlock.bullets([
              'Install and configure GrainHero monitoring devices.',
              'Connect devices with assigned grains, silos, farms or storage locations.',
              'Record inspections, maintenance and troubleshooting activities.',
              'View equipment status and diagnostic information.',
              'Submit installation reports, notes and supporting images.',
            ]),
            LegalBlock.paragraph(
              'By accessing and using the GrainHero Technician application ("the App"), '
              'you agree to be bound by these Terms of Service. If you do not agree to '
              'these terms, you must not use the App.',
            ),
          ],
        ),

        // =====================================================
        // Section 2: Authorized Access & Description of Service
        // =====================================================
        LegalSectionData(
          title: '2. Authorized Access',
          blocks: [
            LegalBlock.paragraph(
              'GrainHero Technician is a grain storage monitoring and management '
              'application designed for authorized technicians. The App provides '
              'real-time monitoring of silo conditions including temperature, humidity, '
              'and air quality, as well as tools for managing grain batches, sensors, '
              'and actuators.',
            ),
          ],
        ),

        // =====================================================
        // Section 3: Technician Responsibilities / User Accounts
        // =====================================================
        LegalSectionData(
          title: '3. Technician Responsibilities',
          blocks: [
            LegalBlock.paragraph(
              'You must be an authorized technician with valid credentials to access '
              'the App. You are responsible for maintaining the confidentiality of your '
              'account credentials and for all activities that occur under your account. '
              'You must immediately notify administration of any unauthorized use of your account.',
            ),
          ],
        ),

        // =====================================================
        // Section 4: Prohibited Use
        // =====================================================
        LegalSectionData(
          title: '4. Prohibited Use',
          blocks: [
            LegalBlock.paragraph('You may not:'),
            LegalBlock.bullets([
              'Attempt to access another user\'s account.',
              'Copy, reverse-engineer or interfere with the application.',
              'Upload false, harmful, unlawful or misleading information.',
              'Bypass security or authentication controls.',
              'Use GrainHero data for an unauthorized commercial purpose.',
              'Introduce malware or disrupt GrainHero services.',
              'Access customer, farm or silo data outside your assigned work.',
            ]),
          ],
        ),

        // =====================================================
        // Section 5: Application Availability & Data Accuracy
        // =====================================================
        LegalSectionData(
          title: '5. Application Availability',
          blocks: [
            LegalBlock.paragraph(
              'We aim to keep GrainHero Technician operational, but uninterrupted '
              'availability is not guaranteed. Features may occasionally be unavailable '
              'because of maintenance, network conditions, device compatibility or '
              'circumstances outside our control.',
            ),
            LegalBlock.paragraph(
              'Some information may be stored temporarily and synchronized when an '
              'internet connection becomes available.',
            ),
            LegalBlock.paragraph(
              'While we strive to provide accurate sensor readings and data, GrainHero '
              'does not guarantee the absolute accuracy of any data displayed in the App. '
              'Critical decisions regarding grain storage should always be verified with '
              'physical inspections and additional measurements.',
            ),
          ],
        ),

        // =====================================================
        // Section 6: Intellectual Property
        // =====================================================
        LegalSectionData(
          title: '6. Intellectual Property',
          blocks: [
            LegalBlock.paragraph(
              'All content, features, and functionality of the App, including but not '
              'limited to text, graphics, logos, and software, are the exclusive property '
              'of GrainHero Systems Inc. and are protected by international copyright, '
              'trademark, and other intellectual property laws.',
            ),
          ],
        ),

        // =====================================================
        // Section 7: Third-Party Services
        // =====================================================
        LegalSectionData(
          title: '7. Third-Party Services',
          blocks: [
            LegalBlock.paragraph(
              'The application may integrate with third-party mapping, cloud storage, '
              'or telemetry services. Your use of these integrated features may also '
              'be subject to third-party service terms and privacy statements.',
            ),
          ],
        ),

        // =====================================================
        // Section 8: Suspension or Termination
        // =====================================================
        LegalSectionData(
          title: '8. Suspension or Termination',
          blocks: [
            LegalBlock.paragraph(
              'GrainHero Systems Inc. reserves the right to suspend or terminate '
              'technician access to the App at any time for violation of these terms '
              'or security concerns, without prior notice.',
            ),
          ],
        ),

        // =====================================================
        // Section 9: Disclaimer and Liability
        // =====================================================
        LegalSectionData(
          title: '9. Disclaimer and Liability',
          blocks: [
            LegalBlock.paragraph(
              'GrainHero Systems Inc. shall not be liable for any indirect, incidental, '
              'special, consequential, or punitive damages resulting from your use of '
              'or inability to use the App, including but not limited to damages for '
              'loss of profits, data, or other intangible losses.',
            ),
          ],
        ),

        // =====================================================
        // Section 10: Changes to These Terms
        // =====================================================
        LegalSectionData(
          title: '10. Changes to These Terms',
          blocks: [
            LegalBlock.paragraph(
              'GrainHero Systems Inc. reserves the right to modify these Terms of '
              'Service at any time. Changes will be effective immediately upon posting '
              'within the App. Your continued use of the App after any changes constitutes '
              'your acceptance of the new terms.',
            ),
          ],
        ),

        // =====================================================
        // Section 11: Contact Us
        // =====================================================
        LegalSectionData(
          title: '11. Contact Us',
          blocks: [
            LegalBlock.paragraph(
              'For questions or concerns regarding these Terms of Service, please contact us at:',
            ),
            LegalBlock.email('support@grainhero.com'),
          ],
        ),
      ],
    );
  }
}
