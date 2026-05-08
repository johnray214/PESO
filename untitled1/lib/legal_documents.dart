import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Keep aligned with `kAppDisplayName` in main.dart.
const String kLegalAppDisplayName = 'Kabsat Empoy';

/// Local PESO office operating this program (matches branding in legal copy).
const String kLegalPesoOfficeName = 'PESO Santiago City';

/// Update when you publish policy changes (shown at top of each document).
const String kLegalEffectiveDateLabel = '7 May 2026';

/// Official public contact — PESO Santiago City.
const String kLegalContactEmail = 'pesosantiago@yahoo.com.ph';

const String kLegalContactMessengerUrl =
    'https://www.facebook.com/messages/t/pesosantiagocity';

const String kLegalContactParagraph =
    'You may contact $kLegalPesoOfficeName by email at $kLegalContactEmail or through Facebook Messenger at $kLegalContactMessengerUrl (Messenger is a service of Meta Platforms, Inc., with its own terms and privacy policy).';

/// Full Terms & Conditions (jobseeker mobile app).
class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF8FAFC),
        foregroundColor: const Color(0xFF0F172A),
        title: const Text(
          'Terms & Conditions',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _docHeader(
            'These Terms & Conditions govern use of $kLegalAppDisplayName in connection with $kLegalPesoOfficeName.',
          ),
          const SizedBox(height: 16),
          _section(
            title: '1. Agreement',
            body:
                'By creating an account or using $kLegalAppDisplayName ("the App"), operated in connection with $kLegalPesoOfficeName, you agree to these Terms & Conditions. If you do not agree, do not register or use the App.',
          ),
          _section(
            title: '2. Eligibility',
            body:
                'You must be of legal working age and capacity under applicable laws of the Philippines. You confirm that registration details you provide are truthful. If you are assisting someone else, you confirm you are authorized to do so.',
          ),
          _section(
            title: '3. Service description',
            body:
                'The App helps jobseekers discover employers, job listings, events, and related employment services under $kLegalPesoOfficeName (Public Employment Service Office – Santiago City). Features may change as we improve the service.',
          ),
          _section(
            title: '4. Account security',
            body:
                'You must provide accurate registration information (including contact details) and keep your password confidential. You are responsible for activity under your account. If you suspect unauthorized use, notify $kLegalPesoOfficeName (see Contact below), or use Help & Support in the App.',
          ),
          _section(
            title: '5. Acceptable use',
            body:
                'You agree not to misuse the App: no unlawful activity, harassment, false applications, scraping or attempts to disrupt systems, or impersonation. Employers and $kLegalPesoOfficeName may report misuse subject to local rules.',
          ),
          _section(
            title: '6. Applications & third parties',
            body:
                'Job applications and hiring decisions are made by employers or partner organizations working with $kLegalPesoOfficeName, not by the App alone. We do not guarantee employment, interview outcomes, or accuracy of every listing. Always verify important details with the employer.',
          ),
          _section(
            title: '7. Intellectual property',
            body:
                'The App, branding, and content supplied by the platform are protected by applicable laws. You retain rights to content you upload (e.g. resume) but grant the operational rights needed to provide the service.',
          ),
          _section(
            title: '8. Disclaimer & limitation',
            body:
                'The App is provided "as is" to the extent permitted by law. To the fullest extent permitted, we are not liable for indirect or consequential losses arising from use of the App, employer actions, or third-party services.',
          ),
          _section(
            title: '9. Changes',
            body:
                'We may update these terms. Continued use after changes constitutes acceptance of the revised terms unless prohibited by law. Material changes will be communicated in-app where practicable and the "Last updated" date at the top will change.',
          ),
          _section(
            title: '10. Governing law',
            body:
                'These Terms are governed by the laws of the Republic of the Philippines. You agree that courts in the Philippines have jurisdiction over disputes arising from these Terms or the App, subject to mandatory local protections if you qualify as a consumer or employee under law.',
          ),
          _section(
            title: '11. Contact',
            body:
                'For questions about these Terms, you may use Help & Support in the App or reach $kLegalPesoOfficeName through the following:',
            belowBody: const _LegalContactActions(),
          ),
        ],
      ),
    );
  }
}

/// Privacy Policy (jobseeker mobile app).
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF8FAFC),
        foregroundColor: const Color(0xFF0F172A),
        title: const Text(
          'Privacy Policy',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _docHeader(
            'This Privacy Policy describes how personal data is handled when you use $kLegalAppDisplayName with $kLegalPesoOfficeName. It is designed to align with the transparency goals of the Data Privacy Act of 2012 (Republic Act No. 10173); it does not replace official legal advice.',
          ),
          const SizedBox(height: 16),
          _section(
            title: '1. Who we are',
            body:
                '$kLegalAppDisplayName is a jobseeker application operated in support of $kLegalPesoOfficeName (Public Employment Service Office – Santiago City). This policy explains how we handle personal information when you use the App.',
          ),
          _section(
            title: '2. Personal information controller',
            body:
                '$kLegalPesoOfficeName acts as the primary contact for this employment program. Technical hosting, the mobile App, and the employer/admin web systems may be operated for the program under arrangements approved by $kLegalPesoOfficeName. For privacy-related questions or requests, see the Contact section at the end of this Policy. You may also visit $kLegalPesoOfficeName during office hours.',
          ),
          _section(
            title: '3. Information we collect',
            body:
                'Account and sign-up: name (first, middle initial, last), email, password (stored in secured form), mobile number, sex, date of birth; optional mailing address fields; email OTP for verification. Profile: contact number, structured Philippine address (province, city/municipality, barangay, street), optional coordinates if you save them for distance or map features, bio, education level, prior work experience notes, profile photo. Skills: skills you select from the program catalog (and related identifiers stored with your account). Documents: resume/CV, training certificate, barangay clearance — stored on program-controlled servers or associated file storage. Employment activity: job applications and status history, responses to offers, jobs you save, event registrations. Notifications: records of in-app notifications; a Firebase Cloud Messaging (FCM) device token so we can deliver push alerts. Optional feedback: satisfaction ratings you submit in-app. On your device: settings such as saved map “location profiles” and exact map picks may be kept locally until you sync or clear them; live GPS is used when you allow it.',
          ),
          _section(
            title: '4. How we use information',
            body:
                'We use this data to operate your account; verify email and password changes; show jobs, employers, and events; process and track applications and offers; notify you about program activity; compute job–skill matching where the program supports it; display maps and nearby employers when you use those features; comply with program and legal requirements of $kLegalPesoOfficeName; and maintain security and audit records appropriate to a public employment program.',
          ),
          _section(
            title: '5. Sharing',
            body:
                'Employers you apply to (or who are authorized under the program) may receive application details, resume, and contact information needed for recruitment. Authorized PESO admin and staff may access jobseeker records through the administrative web system for registration, verification, reporting, case management, and program integrity. Service providers may process data on our behalf (for example: hosting the Laravel API and file storage, sending transactional email, Firebase/Google for push notifications). We do not sell your personal data. We may disclose information if required by law or to protect rights and safety.',
          ),
          _section(
            title: '6. Third-party services (processors)',
            body:
                'Depending on how you use the App, limited data may be processed by: your program API (Laravel backend you connect to over HTTPS) — account, profile, applications, documents, and notifications; Google Firebase and Firebase Cloud Messaging — push notification delivery and device tokens; OpenStreetMap tile servers — when the map loads, your device requests map tiles (operators may see approximate geographic areas served); Google Fonts — some screens load fonts via Google’s font service; Facebook / Meta — if you contact us via Messenger, Meta’s policies apply to that conversation. Each provider has its own privacy terms.',
          ),
          _section(
            title: '7. Cross-border transfers',
            body:
                'Some processors may store or process data outside the Philippines. Where that occurs, we rely on appropriate safeguards where required by law (such as contracts or program-approved arrangements). Contact $kLegalPesoOfficeName if you need more detail about specific transfers relevant to the program.',
          ),
          _section(
            title: '8. Retention',
            body:
                'We keep information while your account is active and as needed for legal, audit, or obligations of $kLegalPesoOfficeName, then delete or anonymize it according to internal policies unless a longer period is required by law.',
          ),
          _section(
            title: '9. Security',
            body:
                'We use reasonable technical and organizational measures to protect data (including encryption in transit where HTTPS is used). No method of transmission over the internet is perfectly secure; please use a strong password and protect your device.',
          ),
          _section(
            title: '10. Your rights',
            body:
                'Under the Data Privacy Act and related rules, you may have rights to reasonable access, correction, or objection to certain processing, among others, subject to exceptions. To exercise rights, use the channels in the Contact section at the end of this Policy. We will respond as soon as practicable and within any period required by applicable law after verifying your identity.',
          ),
          _section(
            title: '11. Children',
            body:
                'The App is intended for users who are of legal working age under Philippine law. If you believe we have collected data from someone who should not use the service, contact us immediately through the Contact section at the end of this Policy.',
          ),
          _section(
            title: '12. Changes',
            body:
                'We may update this Privacy Policy. We will post the updated version in the App and adjust the "Last updated" date. Significant changes may be highlighted in-app.',
          ),
          _section(
            title: '13. Contact',
            body:
                '$kLegalContactParagraph For privacy-specific questions, prefer email so we can document your request. You can also use Help & Support in the App.',
            belowBody: const _LegalContactActions(),
          ),
        ],
      ),
    );
  }
}

Widget _docHeader(String summary) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Last updated: $kLegalEffectiveDateLabel',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[800],
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        summary,
        style: TextStyle(
          fontSize: 13,
          height: 1.45,
          color: Colors.grey[800],
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}

Widget _section({
  required String title,
  required String body,
  Widget? belowBody,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          body,
          style: const TextStyle(
            fontSize: 13.5,
            height: 1.45,
            color: Color(0xFF475569),
          ),
        ),
        if (belowBody != null) belowBody,
      ],
    ),
  );
}

/// Highlighted, tappable email + Messenger (Contact sections only).
class _LegalContactActions extends StatelessWidget {
  const _LegalContactActions();

  static Future<void> _openEmail(BuildContext context) async {
    final uri = Uri.parse(
      'mailto:$kLegalContactEmail?subject=${Uri.encodeComponent('$kLegalAppDisplayName — inquiry')}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open an email app.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  static Future<void> _openMessenger(BuildContext context) async {
    final uri = Uri.parse(kLegalContactMessengerUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open the link.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Material(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF93C5FD)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.alternate_email_rounded,
                      size: 20,
                      color: Color(0xFF1D4ED8),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Tap to open',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E3A8A),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _LegalContactTile(
                  icon: Icons.email_outlined,
                  title: 'Email',
                  value: kLegalContactEmail,
                  onTap: () => _openEmail(context),
                ),
                const SizedBox(height: 10),
                _LegalContactTile(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'Facebook Messenger',
                  value: kLegalContactMessengerUrl,
                  onTap: () => _openMessenger(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LegalContactTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  const _LegalContactTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 22, color: const Color(0xFF2563EB)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      value,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2563EB),
                        height: 1.35,
                        decoration: TextDecoration.underline,
                        decorationColor: Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.open_in_new_rounded,
                size: 18,
                color: Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
