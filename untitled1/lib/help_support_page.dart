import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'home_pages.dart' show replayHomeTourNotifier;
import 'l10n/app_localizations.dart';
import 'legal_documents.dart';
import 'locale_service.dart';
import 'my_documents_page.dart';
import 'onboarding_prefs.dart';
import 'settings_page.dart';
import 'user_session.dart';

typedef _FaqItem = ({String question, String answer});

class _FaqCategory {
  const _FaqCategory({
    required this.title,
    required this.icon,
    required this.items,
  });

  final String title;
  final IconData icon;
  final List<_FaqItem> items;
}

List<_FaqCategory> _faqCategories(BuildContext context) {
  final isTl = Localizations.localeOf(context).languageCode == 'tl';
  if (isTl) {
    return const [
      _FaqCategory(
        title: 'Trabaho at aplikasyon',
        icon: Icons.work_outline_rounded,
        items: [
          (
            question: 'Bakit hindi ako makapag-apply sa trabaho?',
            answer:
                'Kailangan ang Resume/CV bago makapag-apply. Pumunta sa Mga Dokumento Ko, mag-upload ng Resume/CV, pagkatapos ay subukan muli.'
          ),
          (
            question: 'Ano ang ibig sabihin ng Processing sa Aking Mga Aplikasyon?',
            answer:
                'Ibig sabihin ng Processing ay sinusuri pa ng employer ang iyong aplikasyon. Maaaring may sub-stage gaya ng Shortlisted, Interview, o For Job Offer.'
          ),
        ],
      ),
      _FaqCategory(
        title: 'Kasanayan at job matching',
        icon: Icons.psychology_outlined,
        items: [
          (
            question: 'Paano gamitin ang Skills Profile / Skills Editor?',
            answer:
                'Buksan ang Skills Profile mula sa iyong Profile page, idagdag ang iyong pangunahing kasanayan, pagkatapos ay i-tap ang Save Skills. Gamitin ang search at category filters para mas mabilis makahanap ng skills. Ang saved skills ay nagpapaganda ng job match suggestions.'
          ),
          (
            question: 'Ano ang green check icon filter sa mapa?',
            answer:
                'Ang green check icon ay para i-toggle ang Best Match Only. Kapag naka-enable, inuuna ng mapa at company list ang mga employer na tugma sa iyong skills o matched-job results.'
          ),
        ],
      ),
      _FaqCategory(
        title: 'Mapa at lokasyon',
        icon: Icons.map_outlined,
        items: [
          (
            question: 'Paano naaapektuhan ng exact location ang resulta ng trabaho sa mapa?',
            answer:
                'Kapag naka-set ang Exact Location, ang nearby jobs ay kakalkulahin batay sa napili mong punto, hindi sa live GPS location mo.'
          ),
          (
            question: 'Paano gamitin ang Location Profiles sa mapa?',
            answer:
                'I-tap ang Location Profiles sa mapa para pumili ng eksaktong pin, bumalik sa live GPS, o mag-save ng paulit-ulit gamitin na lugar gaya ng Home/Boarding House. Puwedeng palitan ang pangalan o burahin ang saved profiles anumang oras.'
          ),
          (
            question: 'Ano ang ginagawa ng "Search this area" sa mapa?',
            answer:
                'Pagkatapos i-pan ang mapa, i-tap ang Search this area para muling kalkulahin ang pinakamalalapit na kumpanya batay sa kasalukuyang sentro ng mapa.'
          ),
          (
            question: 'Pwede ba akong magkumpara ng mga kumpanya sa mapa?',
            answer:
                'Oo. Sa company cards section, long-press ang cards para pumili ng hanggang 3 kumpanya, pagkatapos ay i-tap ang Compare para makita sila nang magkatabi.'
          ),
        ],
      ),
      _FaqCategory(
        title: 'Account at settings',
        icon: Icons.person_outline_rounded,
        items: [
          (
            question: 'Paano ko papalitan ang email ko?',
            answer:
                'Buksan ang Settings > Change email address. Magpapadala ang app ng OTP sa bagong email mo para sa verification.'
          ),
          (
            question: 'Paano ko papalitan ang password ko?',
            answer:
                'Buksan ang Profile > Settings, pagkatapos ay i-tap ang Change password. Ilagay ang kasalukuyang password, bagong password (ayon sa strength rules), at kumpirmahin ang bagong password, pagkatapos ay i-submit.'
          ),
        ],
      ),
      _FaqCategory(
        title: 'Mga notipikasyon',
        icon: Icons.notifications_outlined,
        items: [
          (
            question: 'Mukhang luma o mali ang notifications. Ano ang dapat gawin?',
            answer:
                'I-pull down para i-refresh ang Notifications at buksan muli ang item. Ang read state at offer status ay ina-update mula sa pinakabagong server data.'
          ),
        ],
      ),
    ];
  }

  return const [
    _FaqCategory(
      title: 'Jobs & applications',
      icon: Icons.work_outline_rounded,
      items: [
        (
          question: 'Why can\'t I apply to a job?',
          answer:
              'Your Resume/CV is required before applying. Go to My Documents, upload Resume/CV, then try applying again.'
        ),
        (
          question: 'What does Processing mean in My Applications?',
          answer:
              'Processing means the employer is reviewing your application. You may see a sub-stage like Shortlisted, Interview, or For Job Offer.'
        ),
      ],
    ),
    _FaqCategory(
      title: 'Skills & job matching',
      icon: Icons.psychology_outlined,
      items: [
        (
          question: 'How do I use the Skills Profile / Skills Editor?',
          answer:
              'Open Skills Profile from your Profile page, add your key skills, then tap Save Skills. Use search and category filters to find skills faster. Saved skills improve your job match suggestions.'
        ),
        (
          question: 'What is the green check icon filter on the map?',
          answer:
              'The green check icon toggles Best Match Only. When enabled, the map and company list prioritize employers that match your skills or matched-job results.'
        ),
      ],
    ),
    _FaqCategory(
      title: 'Map & location',
      icon: Icons.map_outlined,
      items: [
        (
          question: 'How does exact location affect job results on map?',
          answer:
              'When you set Exact Location, nearby jobs are computed from that chosen point instead of your live GPS location.'
        ),
        (
          question: 'How do I use Location Profiles on the map?',
          answer:
              'Tap Location Profiles on the map to pick an exact pin, switch back to live GPS, or save reusable places like Home/Boarding House. Saved profiles can be renamed or deleted anytime.'
        ),
        (
          question: 'What does "Search this area" do on the map?',
          answer:
              'After panning the map, tap Search this area to recalculate the closest companies based on the current map center instead of your previous reference point.'
        ),
        (
          question: 'Can I compare companies on the map?',
          answer:
              'Yes. In the company cards section, long-press cards to select up to 3 companies, then tap Compare to view them side by side.'
        ),
      ],
    ),
    _FaqCategory(
      title: 'Account & settings',
      icon: Icons.person_outline_rounded,
      items: [
        (
          question: 'How do I change my email?',
          answer:
              'Open Settings > Change email address. The app will send an OTP to your new email for verification.'
        ),
        (
          question: 'How do I change my password?',
          answer:
              'Open Profile > Settings, then tap Change password. Enter your current password, your new password (following the strength rules shown), and confirm the new password, then submit.'
        ),
      ],
    ),
    _FaqCategory(
      title: 'Notifications',
      icon: Icons.notifications_outlined,
      items: [
        (
          question: 'Notifications look outdated or wrong. What should I do?',
          answer:
              'Pull down to refresh Notifications and reopen the item. Read state and offer status are updated from your latest server data.'
        ),
      ],
    ),
  ];
}

Future<void> _showPesoContactDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Contact support'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              kLegalPesoOfficeName,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Email',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            SelectableText(
              kLegalContactEmail,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF2563EB),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final uri = Uri.parse(
                  'mailto:$kLegalContactEmail?subject=${Uri.encodeComponent('$kLegalAppDisplayName — support inquiry')}',
                );
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                } else if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Could not open an email app on this device.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.email_outlined),
              label: const Text('Open email app'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                final uri = Uri.parse(kLegalContactMessengerUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Could not open the link.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              label: const Text('Facebook Messenger'),
            ),
            const SizedBox(height: 12),
            Text(
              'For account, verification, or application concerns, include your registered name and email in your message.',
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {
  @override
  void initState() {
    super.initState();
    LocaleService.instance.addListener(_onLocaleChanged);
  }

  @override
  void dispose() {
    LocaleService.instance.removeListener(_onLocaleChanged);
    super.dispose();
  }

  void _onLocaleChanged() {
    if (mounted) setState(() {});
  }

  void _showLanguageSelector() {
    final currentLocale = LocaleService.instance.locale;
    final l10n = S.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n?.languageSelectTitle ?? 'Select Language',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n?.languageSelectSubtitle ?? 'Choose your preferred language',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 20),
            ...AppLocales.supported.map((locale) {
              final isSelected = locale == currentLocale;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      LocaleService.instance.setLocale(locale);
                      Navigator.of(ctx).pop();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF2563EB)
                              : const Color(0xFFE2E8F0),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            locale.languageCode == 'tl' ? '🇵🇭' : '🇺🇸',
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocales.displayName(locale),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? const Color(0xFF2563EB)
                                        : const Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  AppLocales.nativeName(locale),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF2563EB),
                              size: 22,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = _faqCategories(context);
    final currentLocale = LocaleService.instance.locale;
    final l10n = S.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF1F5F9),
        foregroundColor: const Color(0xFF0F172A),
        title: Text(
          l10n?.helpSupport ?? 'Help & Support',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          _SectionCard(
            title: l10n?.quickHelp ?? 'Quick Help',
            child: Column(
              children: [
                _QuickActionTile(
                  icon: Icons.language_rounded,
                  title: l10n?.language ?? 'Language',
                  subtitle: AppLocales.displayName(currentLocale),
                  onTap: _showLanguageSelector,
                ),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                _QuickActionTile(
                  icon: Icons.description_outlined,
                  title: l10n?.goToMyDocuments ?? 'Go to My Documents',
                  subtitle: l10n?.goToMyDocumentsSubtitle ?? 'Upload required files before applying',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const MyDocumentsPage(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                _QuickActionTile(
                  icon: Icons.settings_outlined,
                  title: l10n?.openSettings ?? 'Open Settings',
                  subtitle: l10n?.openSettingsSubtitle ?? 'Manage account details and email',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const SettingsPage(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                _QuickActionTile(
                  icon: Icons.support_agent_rounded,
                  title: l10n?.contactSupport ?? 'Contact Support',
                  subtitle: kLegalContactEmail,
                  onTap: () => _showPesoContactDialog(context),
                ),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                _QuickActionTile(
                  icon: Icons.play_circle_outline_rounded,
                  title: l10n?.replayTour ?? 'Replay App Tour',
                  subtitle: l10n?.replayTourSubtitle ?? 'See the guided walkthrough again',
                  onTap: () async {
                    final token = UserSession().token;
                    await OnboardingPrefs.clearHomeTourDone(token: token);
                    await OnboardingPrefs.clearMapTourDone(token: token);
                    if (!context.mounted) return;
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    replayHomeTourNotifier.value = true;
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: l10n?.legal ?? 'Legal',
            child: Column(
              children: [
                _QuickActionTile(
                  icon: Icons.gavel_rounded,
                  title: l10n?.termsOfService ?? 'Terms & Conditions',
                  subtitle: l10n?.termsOfServiceSubtitle ?? 'Rules for using the app',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const TermsOfServicePage(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                _QuickActionTile(
                  icon: Icons.privacy_tip_outlined,
                  title: l10n?.privacyPolicy ?? 'Privacy Policy',
                  subtitle: l10n?.privacyPolicySubtitle ?? 'How we handle personal data',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const PrivacyPolicyPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: l10n?.applicationStatusGuide ?? 'Application Status Guide',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatusHint(
                  title: l10n?.statusRegistration ?? 'Registration',
                  description: l10n?.statusRegistrationDesc ?? 'Application submitted and recorded by the system.',
                ),
                const SizedBox(height: 10),
                _StatusHint(
                  title: l10n?.statusProcessing ?? 'Processing',
                  description: l10n?.statusProcessingDesc ?? 'Employer review stage. Sub-stages can appear as: • Shortlisted • Interview • For Job Offer',
                ),
                const SizedBox(height: 10),
                _StatusHint(
                  title: l10n?.statusPlacementHired ?? 'Placement/Hired',
                  description: l10n?.statusPlacementHiredDesc ?? 'Final stage after hiring decision.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: l10n?.faq ?? 'Frequently Asked Questions',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var c = 0; c < categories.length; c++) ...[
                  if (c > 0) const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        categories[c].icon,
                        size: 20,
                        color: const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          categories[c].title,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF64748B),
                            letterSpacing: 0.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  for (var i = 0; i < categories[c].items.length; i++) ...[
                    Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.transparent,
                      ),
                      child: ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        childrenPadding: const EdgeInsets.only(bottom: 10),
                        iconColor: const Color(0xFF64748B),
                        collapsedIconColor: const Color(0xFF94A3B8),
                        title: Text(
                          categories[c].items[i].question,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              categories[c].items[i].answer,
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.45,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (i != categories[c].items.length - 1)
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF64748B),
              letterSpacing: 0.35,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: const Color(0xFF64748B), size: 22),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFF0F172A),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Color(0xFF94A3B8),
      ),
      onTap: onTap,
    );
  }
}

class _StatusHint extends StatelessWidget {
  final String title;
  final String description;

  const _StatusHint({
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(
            Icons.circle,
            size: 8,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 13,
                height: 1.45,
                color: Color(0xFF475569),
              ),
              children: [
                TextSpan(
                  text: '$title: ',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                TextSpan(text: description),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
