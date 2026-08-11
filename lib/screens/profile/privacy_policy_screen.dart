import 'package:flutter/material.dart';

import 'legal_page_components.dart';

class AboutAppPrivacyPolicyPage extends StatelessWidget {
  const AboutAppPrivacyPolicyPage({super.key});

  static const List<LegalSectionData> _sections = [
    LegalSectionData(
      title: '1. Information We Collect',
      blocks: [
        LegalBlock.paragraph(
          'Depending on the features you use, we may collect:',
        ),
        LegalBlock.disclosure(
          'Account information',
          items: [
            'Name',
            'Email address',
            'Phone number',
            'Technician ID, organization or role',
            'Login and authentication information',
          ],
        ),
        LegalBlock.disclosure(
          'Operational information',
          items: [
            'Assigned farms, facilities and silos',
            'Device serial numbers and equipment identifiers',
            'Installation, inspection and maintenance records',
            'Technician notes and completion status',
            'Grain or silo condition readings',
            'Fault reports and diagnostic information',
          ],
        ),
        LegalBlock.disclosure(
          'Photos and files',
          supportingText:
              'With your permission, the app may access the camera or selected files to upload:',
          items: [
            'Installation evidence',
            'Device-condition photographs',
            'Equipment labels',
            'Maintenance documentation',
          ],
        ),
        LegalBlock.disclosure(
          'Location information',
          supportingText:
              'The current version of GrainHero Technician does not request device-location permission or collect precise, approximate or background location.',
          footerText:
              'Assigned farm, facility and silo names may appear as operational records, but they are not obtained from your device’s location services.',
        ),
        LegalBlock.disclosure(
          'Device and usage information',
          supportingText: 'We may collect:',
          items: [
            'Device model and operating-system version',
            'Application version',
            'IP address',
            'Login history',
            'Crash reports',
            'Performance and diagnostic logs',
          ],
        ),
      ],
    ),
    LegalSectionData(
      title: '2. How We Use Information',
      blocks: [
        LegalBlock.paragraph('We use information to:'),
        LegalBlock.bullets([
          'Authenticate and manage technician accounts.',
          'Assign installation and maintenance work.',
          'Configure and monitor GrainHero equipment.',
          'Maintain service and inspection records.',
          'Diagnose faults and provide technical support.',
          'Improve application reliability and security.',
          'Send operational alerts and notifications.',
          'Prevent fraud, misuse and unauthorized access.',
          'Meet contractual, safety and legal obligations.',
        ]),
      ],
    ),
    LegalSectionData(
      title: '3. How Information Is Shared',
      blocks: [
        LegalBlock.paragraph('Information may be shared with:'),
        LegalBlock.bullets([
          'Authorized GrainHero employees and administrators.',
          'Customers whose sites or equipment you service.',
          'Approved cloud, authentication, mapping, notification and technical-support providers.',
          'Authorities when disclosure is legally required.',
          'A successor organization in connection with a merger, acquisition or business transfer.',
        ]),
        LegalBlock.paragraph('We do not sell technician personal information.'),
        LegalBlock.paragraph(
          'Service providers should only receive the information necessary to perform services on GrainHero’s behalf.',
        ),
      ],
    ),
    LegalSectionData(
      title: '4. Application Permissions',
      blocks: [
        LegalBlock.paragraph('The app may request access to:'),
        LegalBlock.bullets([
          'Camera: To capture installation and maintenance photographs.',
          'Photos and files: To upload supporting documentation.',
          'Bluetooth or nearby devices: To connect with supported GrainHero equipment.',
          'Notifications: To deliver assignments, alerts and service updates.',
        ]),
        LegalBlock.paragraph(
          'Permissions can be managed through your device settings. Disabling a required permission may prevent certain features from working.',
        ),
      ],
    ),
    LegalSectionData(
      title: '5. Data Retention',
      blocks: [
        LegalBlock.paragraph(
          'We retain information for as long as necessary to:',
        ),
        LegalBlock.bullets([
          'Maintain technician and service records.',
          'Support GrainHero customers and equipment.',
          'Meet contractual, security and legal obligations.',
          'Resolve disputes and investigate incidents.',
        ]),
        LegalBlock.paragraph(
          'Information that is no longer required will be deleted, anonymized or securely archived according to GrainHero’s retention procedures.',
        ),
      ],
    ),
    LegalSectionData(
      title: '6. Data Security',
      blocks: [
        LegalBlock.paragraph(
          'We use reasonable administrative, technical and organizational safeguards, including access controls, authentication, secure communications and system monitoring.',
        ),
        LegalBlock.paragraph(
          'No electronic system is completely secure. Immediately report suspected account compromise or unauthorized access.',
        ),
      ],
    ),
    LegalSectionData(
      title: '7. Your Choices and Rights',
      blocks: [
        LegalBlock.paragraph(
          'Subject to applicable law and organizational requirements, you may request to:',
        ),
        LegalBlock.bullets([
          'Access personal information held about you.',
          'Correct inaccurate or incomplete information.',
          'Delete information that is no longer required.',
          'Restrict or object to certain processing.',
          'Withdraw optional permissions.',
          'Receive information about how your data is handled.',
        ]),
        LegalBlock.paragraph(
          'Some operational records may need to be retained for security, contractual or legal purposes.',
        ),
      ],
    ),
    LegalSectionData(
      title: '8. Children’s Privacy',
      blocks: [
        LegalBlock.paragraph(
          'GrainHero Technician is intended for authorized professional users and is not directed to children.',
        ),
      ],
    ),
    LegalSectionData(
      title: '9. International Processing',
      blocks: [
        LegalBlock.paragraph(
          'Information may be processed using service providers or infrastructure located outside your country. Where applicable, GrainHero will use appropriate safeguards for such transfers.',
        ),
      ],
    ),
    LegalSectionData(
      title: '10. Changes to This Policy',
      blocks: [
        LegalBlock.paragraph(
          'We may update this policy when our application, technology or data practices change. The latest version will be available inside the app.',
        ),
      ],
    ),
    LegalSectionData(
      title: '11. Contact Us',
      blocks: [
        LegalBlock.paragraph(
          'For privacy questions or data requests, contact:',
        ),
        LegalBlock.paragraph(
          'GrainHero Systems Inc.\nNASTP, Rawalpindi, Pakistan',
        ),
        LegalBlock.email(
          'privacy@grainhero.com',
          label: 'Privacy requests',
          isPrimary: true,
        ),
        LegalBlock.email('support@grainhero.com', label: 'General support'),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return const LegalDocumentPage(
      title: 'Privacy Policy',
      icon: Icons.shield_outlined,
      effectiveDate: '11 August 2026',
      lastUpdated: '11 August 2026',
      bodyFontWeight: FontWeight.w400,
      showSectionNavigator: true,
      introduction:
          'GrainHero Systems Inc. respects your privacy. This Privacy Policy explains how information is collected, used, stored and shared when you use the GrainHero Technician application.',
      sections: _sections,
    );
  }
}
