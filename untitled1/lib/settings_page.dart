import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'change_email_page.dart';
import 'change_password_page.dart';
import 'locale_service.dart';
import 'l10n/app_localizations.dart';
import 'app_haptics.dart';

/// Profile → Settings: account actions (e.g. change password).
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late bool _hapticsEnabled;

  @override
  void initState() {
    super.initState();
    _hapticsEnabled = AppHaptics.enabled;
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
                            const HugeIcon(
                              icon: HugeIcons.strokeRoundedCheckmarkCircle01,
                              color: Color(0xFF2563EB),
                              size: 22,
                              strokeWidth: 2.0,
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
    final currentLocale = LocaleService.instance.locale;
    final l10n = S.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF1F5F9),
        foregroundColor: const Color(0xFF0F172A),
        leading: IconButton(
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            size: 20,
            color: Color(0xFF0F172A),
            strokeWidth: 2.0,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l10n?.settings ?? 'Settings',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          // Section 1: Preferences
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              (l10n?.preferences ?? 'Preferences').toUpperCase(),
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: Color(0xFF94A3B8),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const HugeIcon(
                      icon: HugeIcons.strokeRoundedGlobal,
                      color: Color(0xFF2563EB),
                      size: 20,
                      strokeWidth: 2.0,
                    ),
                  ),
                  title: Text(
                    l10n?.language ?? 'Language',
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  subtitle: Text(
                    AppLocales.displayName(currentLocale),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  trailing: const HugeIcon(
                    icon: HugeIcons.strokeRoundedArrowRight01,
                    color: Color(0xFF94A3B8),
                    size: 18,
                    strokeWidth: 2.0,
                  ),
                  onTap: _showLanguageSelector,
                ),
                const Divider(
                    height: 1,
                    thickness: 1,
                    indent: 64,
                    endIndent: 16,
                    color: Color(0xFFF1F5F9)),
                SwitchListTile.adaptive(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  secondary: Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.vibration_rounded,
                      color: Color(0xFF2563EB),
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Haptics & Vibration',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  subtitle: const Text(
                    'Vibrate on bottom nav, buttons, and actions',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  activeTrackColor: const Color(0xFF2563EB),
                  value: _hapticsEnabled,
                  onChanged: (val) async {
                    setState(() => _hapticsEnabled = val);
                    await AppHaptics.setEnabled(val);
                    if (val) AppHaptics.lightImpact();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section 2: Account
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              (l10n?.account ?? 'Account').toUpperCase(),
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: Color(0xFF94A3B8),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const HugeIcon(
                      icon: HugeIcons.strokeRoundedMail01,
                      color: Color(0xFF2563EB),
                      size: 20,
                      strokeWidth: 2.0,
                    ),
                  ),
                  title: Text(
                    l10n?.changeEmail ?? 'Change email address',
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  subtitle: Text(
                    l10n?.changeEmailSubtitle ??
                        'Secure this change using OTP verification',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  trailing: const HugeIcon(
                    icon: HugeIcons.strokeRoundedArrowRight01,
                    color: Color(0xFF94A3B8),
                    size: 18,
                    strokeWidth: 2.0,
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ChangeEmailPage(),
                      ),
                    );
                  },
                ),
                const Divider(
                    height: 1,
                    thickness: 1,
                    indent: 64,
                    endIndent: 16,
                    color: Color(0xFFF1F5F9)),
                ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const HugeIcon(
                      icon: HugeIcons.strokeRoundedLock,
                      color: Color(0xFF2563EB),
                      size: 20,
                      strokeWidth: 2.0,
                    ),
                  ),
                  title: Text(
                    l10n?.changePassword ?? 'Change password',
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  trailing: const HugeIcon(
                    icon: HugeIcons.strokeRoundedArrowRight01,
                    color: Color(0xFF94A3B8),
                    size: 18,
                    strokeWidth: 2.0,
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ChangePasswordPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
