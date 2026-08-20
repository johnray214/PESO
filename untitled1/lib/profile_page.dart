import 'dart:typed_data';
import 'dart:convert';
import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb, listEquals;
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'job_models.dart';
import 'user_session.dart';
import 'api_service.dart';
import 'auth_gate.dart';
import '_error_state_widget.dart';
import 'job_action_service.dart';
import 'micro_interactions.dart';
import 'skills_profile_page.dart';
import 'my_documents_page.dart';
import 'session_prefs.dart';
import 'settings_page.dart';
import 'app_haptics.dart';
import 'help_support_page.dart';
import 'app_nav.dart';
import 'notification_service.dart';
import 'main.dart';
import 'home_pages.dart'; // Added to access global map notifiers
import 'skill_match_utils.dart';
import 'l10n/app_localizations.dart';
import 'job_offer_modal.dart';

const String _kProfileHeaderMascotAsset = 'assets/empoy_profile.png';
const double _kProfileHeaderMascotImageSize = 170;
const double _kProfileHeaderMascotOffsetX = 2.80;
const double _kProfileHeaderMascotOffsetY = -56.5;

/// Matches app blues ([AppColors]); menu rows stay one hue — no rainbow accents.
class _ProfileTheme {
  static const Color scaffoldBg = AppColors.pageBackground;
  static const Color primary = AppColors.blueAccent;

  /// Icon tiles on white cards — blue glyph on soft blue surface.
  static const Color iconInk = AppColors.blueAccent;
  static const Color iconSurface = Color(0xFFEFF6FF);
  static const Color destructive = Color(0xFFDC2626);
  static const Color destructiveSurface = Color(0xFFFEE2E2);

  /// Same diagonal blues as the original profile header (Tailwind-style blues).
  static const LinearGradient coverGradient = LinearGradient(
    colors: [
      Color(0xFF1E3A8A),
      AppColors.blueAccent,
      AppColors.blueLight,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

// ─── Profile Tab ──────────────────────────────────────────────────────────────
class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  int _appliedCount = 0;
  int _interviewCount = 0;
  int _savedCount = 0;
  int _unreadApplicationsCount = 0;
  List<int>? _avatarBytes;
  Timer? _statsRefreshTimer;
  bool _isStatsRefreshing = false;
  int _missingDocsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _loadAvatar();

    // Auto-update stats when a push notification (like application update) arrives
    NotificationService.addListener(_loadStats);
  }

  @override
  void dispose() {
    NotificationService.removeListener(_loadStats);
    _statsRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAvatar() async {
    final token = UserSession().token;
    if (token == null || UserSession().avatarPath == null) return;
    final bytes = await ApiService.getAvatarBytes(token);
    if (mounted) setState(() => _avatarBytes = bytes);
  }

  Future<void> _loadStats() async {
    if (_isStatsRefreshing) return;
    _isStatsRefreshing = true;
    final token = UserSession().token;
    if (token == null || token.isEmpty) {
      if (mounted) {
        setState(() {
          _appliedCount = 0;
          _interviewCount = 0;
          _savedCount = 0;
        });
      }
      _isStatsRefreshing = false;
      return;
    }

    try {
      final appsResult = await ApiService.getApplications(token);
      final savedResult = await ApiService.getSavedJobs(token);

      int applied = 0;
      int interview = 0;
      int saved = 0;
      int unreadApps = 0;
      final prefs = await SharedPreferences.getInstance();

      if (appsResult['success'] == true) {
        final list = appsResult['data'] as List<dynamic>? ?? [];
        applied = list.length;
        for (final item in list) {
          final map = item as Map<String, dynamic>;
          final appId = map['id']?.toString() ?? '';
          final currentStatus = map['status']?.toString() ?? 'pending';
          if (appId.isNotEmpty) {
            final key = 'app_status_$appId';
            final lastSeenStatus = prefs.getString(key);
            if (lastSeenStatus == null) {
              await prefs.setString(key, currentStatus);
            } else if (lastSeenStatus != currentStatus) {
              unreadApps++;
            }
          }
        }
        interview = list.where((item) {
          final map = item as Map<String, dynamic>;
          final rawStatus = (map['status'] as String? ?? '')
              .trim()
              .toLowerCase()
              .replaceAll('_', ' ')
              .replaceAll('-', ' ')
              .replaceAll(RegExp(r'\s+'), ' ');
          // Processing bucket includes shortlist, interview, and job-offer review stage.
          return rawStatus == 'shortlisted' ||
              rawStatus == 'interview' ||
              rawStatus == 'for job offer' ||
              rawStatus == 'for_job_offer';
        }).length;
      }

      if (savedResult['success'] == true) {
        final list = savedResult['data'] as List<dynamic>? ?? [];
        saved = list.length;
      }

      final userResult = await ApiService.getUser(token);
      int missing = 0;
      if (userResult['success'] == true && userResult['data'] != null) {
        final user = userResult['data'] as Map<String, dynamic>;
        if (user['resume_path'] == null ||
            user['resume_path'].toString().isEmpty) missing++;
        if (user['certificate_path'] == null ||
            user['certificate_path'].toString().isEmpty) missing++;
        if (user['barangay_clearance_path'] == null ||
            user['barangay_clearance_path'].toString().isEmpty) missing++;
      }

      if (!mounted) return;
      final hasChanges = _appliedCount != applied ||
          _interviewCount != interview ||
          _savedCount != saved ||
          _missingDocsCount != missing ||
          _unreadApplicationsCount != unreadApps;
      if (hasChanges) {
        setState(() {
          _appliedCount = applied;
          _interviewCount = interview;
          _savedCount = saved;
          _missingDocsCount = missing;
          _unreadApplicationsCount = unreadApps;
        });
      }
    } catch (_) {
      // Keep existing counts on error; profile still loads.
    } finally {
      _isStatsRefreshing = false;
    }
  }

  void _showEditProfileSheet(BuildContext context) {
    final token = UserSession().token;
    if (token == null) return;

    // Open Edit Profile sheet IMMEDIATELY on click for snappy zero-delay feedback
    Navigator.of(context)
        .push<void>(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) =>
            EditProfileSheet(
          onUpdate: () {
            _loadStats();
            _loadAvatar();
          },
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;
          final tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 240),
        reverseTransitionDuration: const Duration(milliseconds: 200),
      ),
    )
        .then((_) {
      if (mounted) setState(() {});
    });

    // Refresh user details in background without delaying page presentation
    ApiService.getUser(token).then((userResult) {
      if (userResult['success'] == true && userResult['data'] != null) {
        UserSession()
            .updateFromUser(userResult['data'] as Map<String, dynamic>);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (UserSession().isGuest) {
      return _buildGuestProfile(context);
    }

    final l10n = S.of(context);
    const coverHeight = 180.0;
    const avatarSize = 100.0;
    const avatarTop = coverHeight - avatarSize / 2;

    return Scaffold(
      backgroundColor: _ProfileTheme.scaffoldBg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: CustomScrollView(
              physics: const ClampingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: coverHeight + avatarSize / 2 + 20,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Top safety extension for overscroll (matches top gradient color)
                        Positioned(
                          top: -400,
                          left: 0,
                          right: 0,
                          height: 400,
                          child: Container(
                            color: const Color(0xFF1E3A8A),
                          ),
                        ),

                        // Cover — app blue gradient (same family as rest of PESO UI)
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: coverHeight,
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: _ProfileTheme.coverGradient,
                            ),
                            child: SafeArea(
                              bottom: false,
                              child: Align(
                                alignment: Alignment.topRight,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: IconButton(
                                    onPressed: () =>
                                        _showEditProfileSheet(context),
                                    icon: const HugeIcon(
                                      icon: HugeIcons.strokeRoundedPencilEdit01,
                                      color: Colors.white,
                                      size: 18,
                                      strokeWidth: 2.0,
                                    ),
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.white24,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Avatar
                        Positioned(
                          top: avatarTop,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              width: avatarSize,
                              height: avatarSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 4),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        AppColors.blueAccent.withOpacity(0.22),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: _avatarBytes != null &&
                                        _avatarBytes!.isNotEmpty
                                    ? Image.memory(
                                        Uint8List.fromList(_avatarBytes!),
                                        width: avatarSize,
                                        height: avatarSize,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        color: AppColors.blueAccent,
                                        alignment: Alignment.center,
                                        child: Text(
                                          UserSession().initials,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 36,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: avatarTop,
                          left: 0,
                          right: 0,
                          child: IgnorePointer(
                            child: Center(
                              child: Transform.translate(
                                offset: const Offset(
                                  _kProfileHeaderMascotOffsetX,
                                  _kProfileHeaderMascotOffsetY,
                                ),
                                child: Image.asset(
                                  _kProfileHeaderMascotAsset,
                                  width: _kProfileHeaderMascotImageSize,
                                  height: _kProfileHeaderMascotImageSize,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      Text(
                        UserSession().displayName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        UserSession().email ?? '',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 6, horizontal: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    const Color(0xFF0F172A).withOpacity(0.04),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              _buildCompactStat('$_appliedCount',
                                  l10n?.statApplied ?? 'Applied',
                                  onTap: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const MyApplicationsPage()),
                                );
                                _loadStats();
                              }),
                              Container(
                                  width: 1,
                                  height: 32,
                                  color: const Color(0xFFF1F5F9)),
                              _buildCompactStat('$_interviewCount',
                                  l10n?.statProcessing ?? 'Processing',
                                  onTap: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const MyApplicationsPage()),
                                );
                                _loadStats();
                              }),
                              Container(
                                  width: 1,
                                  height: 32,
                                  color: const Color(0xFFF1F5F9)),
                              _buildCompactStat(
                                  '$_savedCount', l10n?.statSaved ?? 'Saved',
                                  onTap: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) => const SavedJobsPage()),
                                );
                                _loadStats();
                              }),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Section 1: Career & Jobs
                      _buildSectionHeader('CAREER & JOBS'),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F172A).withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildGroupedMenuItem(
                              icon: HugeIcons.strokeRoundedFolder01,
                              title: l10n?.myApplications ?? 'My Applications',
                              isFirst: true,
                              trailing: _unreadApplicationsCount > 0
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEF4444),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFEF4444)
                                                .withOpacity(0.30),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        '$_unreadApplicationsCount new',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                    )
                                  : null,
                              onTap: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const MyApplicationsPage()),
                                );
                                _loadStats();
                              },
                            ),
                            _buildHairlineDivider(),
                            _buildGroupedMenuItem(
                              icon: HugeIcons.strokeRoundedBookmark01,
                              title: l10n?.savedJobs ?? 'Saved Jobs',
                              onTap: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) => const SavedJobsPage()),
                                );
                                _loadStats();
                              },
                            ),
                            _buildHairlineDivider(),
                            _buildGroupedMenuItem(
                              icon: HugeIcons.strokeRoundedFileBadge,
                              title: l10n?.skillsProfile ?? 'Skills Profile',
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => const SkillsProfilePage()),
                              ),
                            ),
                            _buildHairlineDivider(),
                            _buildGroupedMenuItem(
                              icon: HugeIcons.strokeRoundedFile01,
                              title: l10n?.myDocuments ?? 'My Documents',
                              isLast: true,
                              trailing: _missingDocsCount > 0
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFFBEB),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                            color: const Color(0xFFFDE68A),
                                            width: 1),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const HugeIcon(
                                              icon: HugeIcons
                                                  .strokeRoundedAlertCircle,
                                              size: 14,
                                              color: Color(0xFFD97706),
                                              strokeWidth: 2.0),
                                          const SizedBox(width: 4),
                                          Text(
                                            '$_missingDocsCount more',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFFD97706),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF0FDF4),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                            color: const Color(0xFFDCFCE7),
                                            width: 1),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const HugeIcon(
                                              icon: HugeIcons
                                                  .strokeRoundedCheckmarkCircle01,
                                              size: 14,
                                              color: Color(0xFF16A34A),
                                              strokeWidth: 2.0),
                                          const SizedBox(width: 4),
                                          Text(
                                            l10n?.docsComplete ?? 'Complete',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF16A34A),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                              onTap: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) => const MyDocumentsPage()),
                                );
                                _loadStats();
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Section 2: Preferences & Support
                      _buildSectionHeader('PREFERENCES & SUPPORT'),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F172A).withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildGroupedMenuItem(
                              icon: HugeIcons.strokeRoundedAccountSetting01,
                              title: l10n?.settings ?? 'Settings',
                              isFirst: true,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => const SettingsPage()),
                              ),
                            ),
                            _buildHairlineDivider(),
                            _buildGroupedMenuItem(
                              icon: HugeIcons.strokeRoundedHelpCircle,
                              title: l10n?.helpSupport ?? 'Help & Support',
                              isLast: true,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => const HelpSupportPage()),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Section 3: Account
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: _buildGroupedMenuItem(
                          icon: HugeIcons.strokeRoundedLogout01,
                          title: l10n?.signOut ?? 'Sign Out',
                          isSignOut: true,
                          isFirst: true,
                          isLast: true,
                          onTap: () => _confirmSignOut(context),
                        ),
                      ),
                      const SizedBox(height: 36),
                    ]),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 100,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _ProfileTheme.scaffoldBg.withOpacity(0.0),
                      _ProfileTheme.scaffoldBg.withOpacity(0.85),
                      _ProfileTheme.scaffoldBg,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestProfile(BuildContext context) {
    return Scaffold(
      backgroundColor: _ProfileTheme.scaffoldBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.divider),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Transform.translate(
                          offset: const Offset(0, 52),
                          child: Container(
                            width: 100,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.08),
                              borderRadius: const BorderRadius.all(
                                Radius.elliptical(100, 12),
                              ),
                            ),
                          ),
                        ),
                        Transform.scale(
                          scale: 1.25,
                          child: Image.asset(
                            'assets/empoysignin.png',
                            width: 175,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Sign in to manage your profile',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Create or access your account to apply for jobs, save listings, upload documents, and receive PESO updates.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => unawaited(openAuthForGuest(context)),
                        icon: const HugeIcon(
                          icon: HugeIcons.strokeRoundedLogin01,
                          size: 18,
                          color: Colors.white,
                          strokeWidth: 2.0,
                        ),
                        label: const Text('Sign in or create account'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.blueAccent,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildMenuItem(
                icon: HugeIcons.strokeRoundedHelpCircle,
                title: S.of(context)?.helpSupport ?? 'Help & Support',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HelpSupportPage()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: Color(0xFF94A3B8),
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildHairlineDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: Color(0xFFF1F5F9),
      indent: 64,
      endIndent: 16,
    );
  }

  Widget _buildGroupedMenuItem({
    required dynamic icon,
    required String title,
    required VoidCallback onTap,
    Widget? trailing,
    bool isSignOut = false,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final iconBg =
        isSignOut ? const Color(0xFFFEF2F2) : const Color(0xFFEFF6FF);
    final iconFg =
        isSignOut ? const Color(0xFFEF4444) : const Color(0xFF2563EB);

    final borderRadius = BorderRadius.vertical(
      top: isFirst ? const Radius.circular(20) : Radius.zero,
      bottom: isLast ? const Radius.circular(20) : Radius.zero,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: icon is IconData
                    ? Icon(icon, size: 20, color: iconFg)
                    : HugeIcon(
                        icon: icon as List<List<dynamic>>,
                        size: 20,
                        color: iconFg,
                        strokeWidth: 2.0,
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: isSignOut
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF0F172A),
                  ),
                ),
              ),
              if (trailing != null) ...[
                trailing,
                const SizedBox(width: 8),
              ],
              HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                size: 18,
                color: isSignOut
                    ? const Color(0xFFFCA5A5)
                    : const Color(0xFF94A3B8),
                strokeWidth: 2.0,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactStat(String value, String label, {VoidCallback? onTap}) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Removed redundant _showEditProfileSheet

  Future<void> _confirmSignOut(BuildContext context) async {
    final l10n = S.of(context);
    final confirmed = await showAppDialog<bool>(
      context: context,
      type: AppDialogType.destructive,
      icon: HugeIcons.strokeRoundedLogout01,
      title: l10n?.signOut ?? 'Sign Out',
      message: l10n?.signOutConfirm ?? 'Are you sure you want to sign out?',
      confirmLabel: l10n?.signOut ?? 'Sign Out',
      onConfirm: () => Navigator.pop(context, true),
      onCancel: () => Navigator.pop(context, false),
    );

    if (confirmed != true || !mounted) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF2563EB)),
      ),
    );

    // Call logout API (best-effort — clear session either way)
    final token = UserSession().token;
    if (token != null && token.isNotEmpty) {
      await ApiService.logout(token);
    }

    UserSession().clear();
    SkillMatchUtils.invalidateUserSkillsCache();
    mapUserSkillsRevisionNotifier.value++;
    await SessionPrefs.clear();

    if (!mounted) return;
    Navigator.pop(context); // close loading
    // Home is already the root route — popUntil does nothing. Replace stack with auth.
    navigateToAuthEntryReplacingStack();
  }

  Widget _buildMenuItem({
    required dynamic icon,
    required String title,
    required VoidCallback onTap,
    Widget? trailing,
    bool isSignOut = false,
  }) {
    final iconBg = isSignOut
        ? _ProfileTheme.destructiveSurface
        : _ProfileTheme.iconSurface;
    final iconFg =
        isSignOut ? _ProfileTheme.destructive : _ProfileTheme.iconInk;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: icon is IconData
                      ? Icon(icon, size: 22, color: iconFg)
                      : HugeIcon(
                          icon: icon as List<List<dynamic>>,
                          size: 22,
                          color: iconFg,
                          strokeWidth: 2.2,
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                if (trailing != null) ...[
                  trailing,
                  const SizedBox(width: 12),
                ],
                const HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowRight01,
                  size: 20,
                  color: Color(0xFFCBD5E1),
                  strokeWidth: 2.0,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Edit Profile (full-screen route) ─────────────────────────────────────────
class EditProfileSheet extends StatefulWidget {
  final VoidCallback onUpdate;
  const EditProfileSheet({super.key, required this.onUpdate});

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  int _activeTab = 0;
  late final PageController _pageController;
  late final TextEditingController _firstNameController;
  late final TextEditingController _middleInitialController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _dobController;
  String? _selectedSex;
  late final TextEditingController _phoneController;
  late final TextEditingController _streetController;
  late final TextEditingController _experienceController;

  String? _educationLevel;
  List<String> _jobExperiences = [];
  final List<Map<String, String>> _educationLevelOptions = const [
    {'name': 'No Formal Education', 'code': 'No Formal Education'},
    {'name': 'Elementary Level', 'code': 'Elementary Level'},
    {'name': 'Elementary Graduate', 'code': 'Elementary Graduate'},
    {'name': 'Secondary Level', 'code': 'Secondary Level'},
    {'name': 'Secondary Graduate', 'code': 'Secondary Graduate'},
    {'name': 'Tertiary Level', 'code': 'Tertiary Level'},
    {'name': 'Tertiary Graduate', 'code': 'Tertiary Graduate'},
  ];
  bool _isSaving = false;
  Uint8List? _avatarUint8List;
  Uint8List? _pickedImageBytes;
  bool _isLoadingLocations = false;
  bool _updatingLocation = false; // Concurrency guard
  String? _locationError;
  static const String _psgcProvincesUrl =
      'https://psgc.gitlab.io/api/provinces/';
  static const String _cachePrefix = 'psgc_cache_v1_';

  List<Map<String, String>> _provinces = [];
  List<Map<String, String>> _cities = [];
  List<Map<String, String>> _barangays = [];

  String? _provinceCode;
  String? _provinceName;
  String? _cityCode;
  String? _cityName;
  String? _barangayCode;
  String? _barangayName;

  late String _initialFirstName;
  late String _initialMiddleInitial;
  late String _initialLastName;
  late String _initialDob;
  late String _initialPhone;
  late String _initialStreet;
  String? _initialSex;
  String? _initialEducationLevel;
  List<String> _initialJobExperiences = [];
  String? _initialProvinceCode;
  String? _initialCityCode;
  String? _initialBarangayCode;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    final session = UserSession();
    final firstFromSession = session.firstName?.trim() ?? '';
    final lastFromSession = session.lastName?.trim() ?? '';
    final sessionName = (session.name ?? '').trim();
    final nameParts =
        sessionName.isEmpty ? <String>[] : sessionName.split(RegExp(r'\s+'));
    final firstName = firstFromSession.isNotEmpty
        ? firstFromSession
        : (nameParts.isNotEmpty ? nameParts.first : '');
    final lastName = lastFromSession.isNotEmpty
        ? lastFromSession
        : (nameParts.length > 1 ? nameParts.skip(1).join(' ') : '');

    _firstNameController = TextEditingController(text: firstName);
    _middleInitialController =
        TextEditingController(text: session.middleInitial ?? '');
    _lastNameController = TextEditingController(text: lastName);
    _phoneController = TextEditingController(text: UserSession().phone ?? '');
    _streetController =
        TextEditingController(text: session.streetAddress ?? '');
    _dobController = TextEditingController(text: session.dateOfBirth ?? '');
    _selectedSex = session.gender;
    _experienceController = TextEditingController();

    // Parse comma-separated experience items saved as `job_experience`
    _educationLevel = UserSession().educationLevel;
    final rawExperience = UserSession().jobExperience ?? '';
    _jobExperiences = rawExperience
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    _initialFirstName = _firstNameController.text.trim();
    _initialMiddleInitial = _middleInitialController.text.trim();
    _initialLastName = _lastNameController.text.trim();
    _initialDob = _dobController.text.trim();
    _initialPhone = _phoneController.text.trim();
    _initialStreet = _streetController.text.trim();
    _initialSex = _selectedSex;
    _initialEducationLevel = _educationLevel;
    _initialJobExperiences = List<String>.from(_jobExperiences);
    _initialProvinceCode = session.provinceCode;
    _initialCityCode = session.cityCode;
    _initialBarangayCode = session.barangayCode;

    _loadAvatar();
    _loadProvinces();
  }

  Future<void> _loadAvatar() async {
    final token = UserSession().token;
    if (token == null || UserSession().avatarPath == null) return;
    final bytes = await ApiService.getAvatarBytes(token);
    if (mounted)
      setState(() {
        _avatarUint8List = bytes != null ? Uint8List.fromList(bytes) : null;
      });
  }

  Future<void> _pickImage() async {
    try {
      Uint8List? bytes;
      if (kIsWeb) {
        // On web, image_picker throws MissingPluginException; use file_picker instead
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          withData: true,
          withReadStream: false,
        );
        if (result == null || result.files.isEmpty || !mounted) return;
        final file = result.files.single;
        if (file.bytes != null && file.bytes!.isNotEmpty) {
          bytes = file.bytes;
        }
      } else {
        final picker = ImagePicker();
        final xFile = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 512,
          maxHeight: 512,
          imageQuality: 85,
        );
        if (xFile == null || !mounted) return;
        bytes = await xFile.readAsBytes();
      }
      if (bytes != null && bytes.isNotEmpty && mounted) {
        setState(() => _pickedImageBytes = bytes);
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          message: 'Could not pick image: $e',
          type: ToastType.error,
        );
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _firstNameController.dispose();
    _middleInitialController.dispose();
    _lastNameController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  Future<void> _cacheList(String key, List<Map<String, String>> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_cachePrefix$key', jsonEncode(list));
    } catch (_) {
      // Ignore cache write failures (e.g. platform plugin not ready).
    }
  }

  Future<List<Map<String, String>>> _readCachedList(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_cachePrefix$key');
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((e) => {
                'code': (e['code'] ?? '').toString(),
                'name': (e['name'] ?? '').toString(),
              })
          .where((e) => e['code']!.isNotEmpty && e['name']!.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  bool _isInitializingAddress = true;

  Future<List<Map<String, String>>> _fetchLocationList(
    String key,
    String url,
  ) async {
    final cached = await _readCachedList(key);
    if (cached.isNotEmpty) {
      return cached;
    }
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        return cached;
      }
      final data = jsonDecode(response.body);
      if (data is! List) return cached;
      final list = data
          .whereType<Map>()
          .map((e) => {
                'code': (e['code'] ?? '').toString(),
                'name': (e['name'] ?? '').toString(),
              })
          .where((e) => e['code']!.isNotEmpty && e['name']!.isNotEmpty)
          .toList();
      await _cacheList(key, list);
      return list;
    } catch (_) {
      return cached;
    }
  }

  Future<void> _loadProvinces() async {
    if (!mounted) return;
    _isInitializingAddress = true;
    setState(() {
      _isLoadingLocations = true;
      _locationError = null;
    });
    try {
      _provinces = await _fetchLocationList('provinces_all', _psgcProvincesUrl);
      if (!mounted) return;
      if (_provinces.isEmpty) {
        _locationError =
            'Unable to load address data. Check connection and try again.';
        return;
      }
      await _prefillAddressFromSession();
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocations = false;
          _isInitializingAddress = false;
        });
      }
    }
  }

  Future<void> _prefillAddressFromSession() async {
    final session = UserSession();
    final provinceCode = session.provinceCode;
    final cityCode = session.cityCode;
    final barangayCode = session.barangayCode;

    if (provinceCode != null && provinceCode.isNotEmpty) {
      await _onProvinceChanged(provinceCode, silent: true);
    }
    if (cityCode != null && cityCode.isNotEmpty) {
      await _onCityChanged(cityCode, silent: true);
    }
    if (barangayCode != null && barangayCode.isNotEmpty) {
      final hit = _barangays.where((e) => e['code'] == barangayCode).toList();
      if (mounted && hit.isNotEmpty) {
        _barangayCode = hit.first['code'];
        _barangayName = hit.first['name'];
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _onProvinceChanged(String? code, {bool silent = false}) async {
    if (code == null || code.isEmpty || _updatingLocation) return;
    if (!mounted) return;

    setState(() {
      _updatingLocation = true;
      _provinceCode = code;
      _provinceName = _provinces.firstWhere((e) => e['code'] == code,
          orElse: () => {'name': ''})['name'];
      if (!silent) {
        _cityCode = null;
        _cityName = null;
        _barangayCode = null;
        _barangayName = null;
        _cities = [];
        _barangays = [];
      }
      _isLoadingLocations = !silent;
    });

    try {
      final list = await _fetchLocationList(
        'cities_province_$code',
        'https://psgc.gitlab.io/api/provinces/$code/cities-municipalities/',
      );
      if (mounted) {
        setState(() {
          _cities = list;
          if (silent && _cityCode != null && _cityCode!.isNotEmpty) {
            final hit = _cities.where((e) => e['code'] == _cityCode).toList();
            if (hit.isNotEmpty) {
              _cityName = hit.first['name'];
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching cities: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocations = false;
          _updatingLocation = false;
        });
      }
    }
  }

  Future<void> _onCityChanged(String? code, {bool silent = false}) async {
    if (code == null || code.isEmpty || _updatingLocation) return;
    if (!mounted) return;

    setState(() {
      _updatingLocation = true;
      _cityCode = code;
      _cityName = _cities.firstWhere((e) => e['code'] == code,
          orElse: () => {'name': ''})['name'];
      if (!silent) {
        _barangayCode = null;
        _barangayName = null;
        _barangays = [];
      }
      _isLoadingLocations = !silent;
    });

    try {
      final list = await _fetchLocationList(
        'barangays_$code',
        'https://psgc.gitlab.io/api/cities-municipalities/$code/barangays/',
      );
      if (mounted) {
        setState(() {
          _barangays = list;
          if (silent && _barangayCode != null && _barangayCode!.isNotEmpty) {
            final hit =
                _barangays.where((e) => e['code'] == _barangayCode).toList();
            if (hit.isNotEmpty) {
              _barangayName = hit.first['name'];
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching barangays: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocations = false;
          _updatingLocation = false;
        });
      }
    }
  }

  Future<Map<String, String>?> _pickOption({
    required String title,
    required List<Map<String, String>> options,
    bool enableSearch = true,
  }) async {
    final queryController = enableSearch ? TextEditingController() : null;
    List<Map<String, String>> filtered =
        List<Map<String, String>>.from(options);
    bool alreadyPopped = false;
    bool picking = false;

    return showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocalState) {
            return PopScope(
              canPop: alreadyPopped,
              onPopInvokedWithResult: (didPop, result) async {
                if (didPop || alreadyPopped) return;

                // Block the instant pop and perform the smooth sequence
                primaryFocus?.unfocus();
                setLocalState(() => picking = true);

                await Future.delayed(const Duration(milliseconds: 600));

                if (ctx.mounted) {
                  alreadyPopped = true;
                  Navigator.of(ctx).pop(result);
                }
              },
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.85,
                ),
                padding: EdgeInsets.only(
                  bottom: MediaQuery.viewInsetsOf(ctx).bottom,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 18),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 12, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                    color: Color(0xFF0F172A))),
                          ),
                          IconButton(
                            onPressed: () async {
                              if (picking) return;
                              primaryFocus?.unfocus();
                              setLocalState(() => picking = true);
                              await Future.delayed(
                                  const Duration(milliseconds: 600));
                              if (!ctx.mounted) return;
                              Navigator.pop(ctx);
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    ),
                    if (enableSearch && !picking)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: TextField(
                          controller: queryController,
                          autofocus: false,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search_rounded),
                            hintText: 'Search...',
                            hintStyle: const TextStyle(fontSize: 14),
                            filled: true,
                            fillColor: const Color(0xFFF1F5F9),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none),
                          ),
                          onChanged: (q) {
                            final needle = q.trim().toLowerCase();
                            setLocalState(() {
                              filtered = options
                                  .where((o) => (o['name'] ?? '')
                                      .toLowerCase()
                                      .contains(needle))
                                  .toList();
                            });
                          },
                        ),
                      ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: picking
                          ? const Center(child: CircularProgressIndicator())
                          : (filtered.isEmpty
                              ? Center(
                                  child: Text(
                                    enableSearch
                                        ? 'No matching results'
                                        : 'No options available',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                )
                              : ListView.separated(
                                  padding:
                                      const EdgeInsets.fromLTRB(20, 0, 20, 20),
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, __) =>
                                      const Divider(height: 1),
                                  itemBuilder: (_, index) {
                                    final item = filtered[index];
                                    return ListTile(
                                      title: Text(item['name'] ?? '',
                                          style: const TextStyle(fontSize: 15)),
                                      trailing: const Icon(
                                          Icons.chevron_right_rounded,
                                          size: 18,
                                          color: Color(0xFF94A3B8)),
                                      onTap: () async {
                                        if (alreadyPopped || picking) return;

                                        setLocalState(() => picking = true);

                                        primaryFocus?.unfocus();
                                        FocusManager.instance.primaryFocus
                                            ?.unfocus();

                                        await Future.delayed(
                                            const Duration(milliseconds: 600));

                                        if (!ctx.mounted) return;
                                        alreadyPopped = true;

                                        if (Navigator.canPop(ctx)) {
                                          Navigator.of(ctx).pop(item);
                                        }
                                      },
                                    );
                                  },
                                )),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      try {
        queryController?.dispose();
      } catch (_) {}
    });
  }

  Widget _selectorField({
    required String label,
    required dynamic icon,
    required String? value,
    required String placeholder,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    final display = value?.trim() ?? '';
    return _labeledField(
      label,
      GestureDetector(
        onTap: enabled ? onTap : null,
        child: InputDecorator(
          decoration: _fieldDec(placeholder, icon),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  display.isNotEmpty ? display : placeholder,
                  style: TextStyle(
                    color: display.isNotEmpty
                        ? const Color(0xFF0F172A)
                        : const Color(0xFF94A3B8),
                    fontWeight:
                        display.isNotEmpty ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
              HugeIcon(
                icon: HugeIcons.strokeRoundedArrowDown01,
                size: 18,
                color:
                    enabled ? const Color(0xFF64748B) : const Color(0xFFCBD5E1),
                strokeWidth: 2.0,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _composeAddress() {
    final parts = <String>[
      _streetController.text.trim(),
      _barangayName ?? '',
      _cityName ?? '',
      _provinceName ?? '',
    ].where((p) => p.trim().isNotEmpty).toList();

    if (parts.isEmpty) return '';

    // Deduplicate adjacent duplicates like city/province with same labels.
    final deduped = <String>[];
    for (final p in parts) {
      if (deduped.isEmpty || deduped.last.toLowerCase() != p.toLowerCase()) {
        deduped.add(p);
      }
    }
    return deduped.join(', ');
  }

  void _addJobExperience() {
    final value = _experienceController.text.trim();
    if (value.isEmpty) return;

    if (value.length > 30) {
      CustomToast.show(
        context,
        message: 'Each experience item must be 30 characters max.',
        type: ToastType.error,
      );
      return;
    }

    AppHaptics.lightImpact();
    setState(() {
      if (!_jobExperiences.contains(value)) {
        _jobExperiences.add(value);
      }
      _experienceController.clear();
    });
  }

  void _removeJobExperience(String value) {
    AppHaptics.lightImpact();
    setState(() => _jobExperiences.remove(value));
  }

  InputDecoration _fieldDec(String label, dynamic icon) {
    return InputDecoration(
      hintText: label,
      hintStyle: const TextStyle(
        color: Color(0xFF94A3B8),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: icon != null
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: icon is IconData
                  ? Icon(icon, color: const Color(0xFF2563EB), size: 18)
                  : HugeIcon(
                      icon: icon as List<List<dynamic>>,
                      color: const Color(0xFF2563EB),
                      size: 18,
                      strokeWidth: 2.0,
                    ),
            )
          : null,
      prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
    );
  }

  Widget _labeledField(String label, Widget child, {String? helper}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF475569),
          ),
        ),
        if (helper != null) ...[
          const SizedBox(height: 3),
          Text(
            helper,
            style: const TextStyle(
              fontSize: 11.5,
              height: 1.25,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  bool _hasUnsavedChanges() {
    if (_isInitializingAddress) return false;
    if (_pickedImageBytes != null) return true;
    if (_firstNameController.text.trim() != _initialFirstName) return true;
    if (_middleInitialController.text.trim() != _initialMiddleInitial)
      return true;
    if (_lastNameController.text.trim() != _initialLastName) return true;
    if (_dobController.text.trim() != _initialDob) return true;
    if (_phoneController.text.trim() != _initialPhone) return true;
    if (_streetController.text.trim() != _initialStreet) return true;
    if ((_selectedSex ?? '') != (_initialSex ?? '')) return true;
    if ((_educationLevel ?? '') != (_initialEducationLevel ?? '')) return true;
    if (!listEquals(_jobExperiences, _initialJobExperiences)) return true;
    if ((_provinceCode ?? '') != (_initialProvinceCode ?? '')) return true;
    if ((_cityCode ?? '') != (_initialCityCode ?? '')) return true;
    if ((_barangayCode ?? '') != (_initialBarangayCode ?? '')) return true;
    return false;
  }

  Future<bool> _confirmDiscardUnsavedChanges() async {
    if (!_hasUnsavedChanges()) return true;
    final shouldLeave = await showAppDialog<bool>(
      context: context,
      type: AppDialogType.warning,
      icon: HugeIcons.strokeRoundedAlertCircle,
      title: 'Unsaved Changes',
      message: 'You have unsaved profile changes. Leave without saving?',
      confirmLabel: 'Leave',
      onConfirm: () => Navigator.of(context).pop(true),
      onCancel: () => Navigator.of(context).pop(false),
    );
    return shouldLeave == true;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final missingLocation =
        _provinceCode == null || _cityCode == null || _barangayCode == null;
    if (missingLocation) {
      CustomToast.show(
        context,
        message: 'Please complete Province, City/Municipality, and Barangay.',
        type: ToastType.error,
      );
      return;
    }
    setState(() => _isSaving = true);

    final token = UserSession().token ?? '';
    if (_pickedImageBytes != null) {
      final uploadResult = await ApiService.uploadAvatarBytes(
        token: token,
        fileBytes: _pickedImageBytes!,
        fileName: 'avatar.jpg',
      );
      if (uploadResult['success'] != true && mounted) {
        setState(() => _isSaving = false);
        CustomToast.show(
          context,
          message:
              uploadResult['message'] as String? ?? 'Failed to upload photo',
          type: ToastType.error,
        );
        return;
      }
    }

    final result = await ApiService.updateProfile(
      token: token,
      firstName: _firstNameController.text.trim(),
      middleInitial: _middleInitialController.text.trim(),
      lastName: _lastNameController.text.trim(),
      contact: _phoneController.text.trim(),
      address: _composeAddress(),
      educationLevel: _educationLevel,
      jobExperience:
          _jobExperiences.isEmpty ? null : _jobExperiences.join(', '),
      provinceCode: _provinceCode,
      provinceName: _provinceName,
      cityCode: _cityCode,
      cityName: _cityName,
      barangayCode: _barangayCode,
      barangayName: _barangayName,
      streetAddress: _streetController.text.trim(),
      dateOfBirth: _dobController.text.trim().isEmpty
          ? null
          : _dobController.text.trim(),
      sex: _selectedSex,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result['success'] == true) {
      final updatedUser = result['data'] as Map<String, dynamic>? ?? {};
      UserSession().updateFromUser(updatedUser);
      if (_pickedImageBytes != null) {
        final userResult = await ApiService.getUser(token);
        if (userResult['success'] == true && userResult['data'] != null) {
          UserSession()
              .updateFromUser(userResult['data'] as Map<String, dynamic>);
        }
      }
      widget.onUpdate();
      AppHaptics.mediumImpact();
      if (!mounted) return;
      Navigator.pop(context);
      CustomToast.show(
        context,
        message: 'Profile updated successfully!',
        type: ToastType.success,
      );
    } else {
      CustomToast.show(
        context,
        message: result['message'] as String? ?? 'Failed to update profile.',
        type: ToastType.error,
      );
    }
  }

  // ─── Tab bar ─────────────────────────────────────────────────────────────
  static const List<Map<String, dynamic>> _tabs = [
    {
      'label': 'Personal',
      'icon': HugeIcons.strokeRoundedUser,
    },
    {
      'label': 'Background',
      'icon': HugeIcons.strokeRoundedGraduateMale,
    },
    {
      'label': 'Address',
      'icon': HugeIcons.strokeRoundedLocation01,
    },
  ];

  void _switchTab(int index) {
    AppHaptics.lightImpact();
    FocusScope.of(context).unfocus();
    setState(() => _activeTab = index);
    _pageController.jumpToPage(index);
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final isActive = _activeTab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => _switchTab(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                margin: EdgeInsets.only(right: i < _tabs.length - 1 ? 8 : 0),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF2563EB)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color:
                                const Color(0xFF2563EB).withValues(alpha: 0.28),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    HugeIcon(
                      icon: _tabs[i]['icon'] as List<List<dynamic>>,
                      size: 14,
                      color: isActive ? Colors.white : const Color(0xFF64748B),
                      strokeWidth: 2.0,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _tabs[i]['label'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color:
                            isActive ? Colors.white : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ─── Avatar header (pinned, shared across all tabs) ───────────────────────
  Widget _buildAvatarHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 16),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: _isSaving ? null : _pickImage,
              child: Stack(
                children: [
                  Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFF2563EB).withValues(alpha: 0.25),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: _pickedImageBytes != null
                          ? Image.memory(
                              _pickedImageBytes!,
                              width: 86,
                              height: 86,
                              fit: BoxFit.cover,
                            )
                          : _avatarUint8List != null &&
                                  _avatarUint8List!.isNotEmpty
                              ? Image.memory(
                                  _avatarUint8List!,
                                  width: 86,
                                  height: 86,
                                  fit: BoxFit.cover,
                                  gaplessPlayback: true,
                                )
                              : Center(
                                  child: Text(
                                    UserSession().initials,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 30,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const HugeIcon(
                        icon: HugeIcons.strokeRoundedCamera01,
                        size: 13,
                        color: Colors.white,
                        strokeWidth: 2.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap to change photo',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Tab content pages ────────────────────────────────────────────────────
  Widget _buildPersonalTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _labeledField(
            'First name',
            TextFormField(
              controller: _firstNameController,
              decoration:
                  _fieldDec('Enter first name', HugeIcons.strokeRoundedUser),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                return null;
              },
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 88,
                child: _labeledField(
                  'M.I.',
                  TextFormField(
                    controller: _middleInitialController,
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 1,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(1),
                      UpperCaseTextFormatter(),
                    ],
                    decoration: _fieldDec('L.', null).copyWith(counterText: ''),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _labeledField(
                  'Last name',
                  TextFormField(
                    controller: _lastNameController,
                    decoration: _fieldDec(
                        'Enter last name', HugeIcons.strokeRoundedUser),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      return null;
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _labeledField(
            'Phone number',
            TextFormField(
              controller: _phoneController,
              decoration: _fieldDec('09XXXXXXXXX', HugeIcons.strokeRoundedCall),
              keyboardType: TextInputType.phone,
              validator: (v) {
                final value = v?.trim() ?? '';
                if (value.isEmpty) return null;
                final phPattern = RegExp(r'^0\d{10}$');
                if (!phPattern.hasMatch(value)) {
                  return 'Enter 11-digit PH number (e.g. 09XXXXXXXXX)';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _labeledField(
                  'Birthdate',
                  TextFormField(
                    controller: _dobController,
                    readOnly: true,
                    decoration: _fieldDec(
                        'YYYY-MM-DD', HugeIcons.strokeRoundedCalendar03),
                    onTap: () async {
                      final now = DateTime.now();
                      DateTime initial =
                          DateTime(now.year - 21, now.month, now.day);
                      final rawDob = _dobController.text.trim();
                      if (rawDob.isNotEmpty) {
                        final datePart = rawDob.split(RegExp(r'[T\s]')).first;
                        final parts = datePart.split('-');
                        if (parts.length == 3) {
                          final y = int.tryParse(parts[0]);
                          final m = int.tryParse(parts[1]);
                          final d = int.tryParse(parts[2]);
                          if (y != null && m != null && d != null) {
                            initial = DateTime(y, m, d);
                          }
                        }
                      }
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: initial,
                        firstDate: DateTime(1900, 1, 1),
                        lastDate: now,
                      );
                      if (picked == null || !mounted) return;
                      setState(() {
                        final pickedLocal =
                            DateTime(picked.year, picked.month, picked.day);
                        _dobController.text =
                            '${pickedLocal.year.toString().padLeft(4, '0')}-${pickedLocal.month.toString().padLeft(2, '0')}-${pickedLocal.day.toString().padLeft(2, '0')}';
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _labeledField(
                  'Sex',
                  DropdownButtonFormField<String>(
                    value:
                        ['male', 'female'].contains(_selectedSex?.toLowerCase())
                            ? _selectedSex?.toLowerCase()
                            : null,
                    decoration:
                        _fieldDec('Select sex', HugeIcons.strokeRoundedUser),
                    items: const [
                      DropdownMenuItem(value: 'male', child: Text('Male')),
                      DropdownMenuItem(value: 'female', child: Text('Female')),
                    ],
                    onChanged: (value) => setState(() => _selectedSex = value),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      return null;
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Email info card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const HugeIcon(
                    icon: HugeIcons.strokeRoundedMail01,
                    color: Color(0xFF2563EB),
                    size: 18,
                    strokeWidth: 2.0,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Email address',
                        style: TextStyle(
                          color: Color(0xFF1E40AF),
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (UserSession().email ?? '').trim().isEmpty
                            ? 'No email available'
                            : UserSession().email!.trim(),
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () async {
                          if (!mounted) return;
                          Navigator.of(context).pop();
                          await Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const SettingsPage(),
                            ),
                          );
                        },
                        icon: const HugeIcon(
                          icon: HugeIcons.strokeRoundedSettings01,
                          size: 16,
                          color: AppColors.blueAccent,
                          strokeWidth: 2.0,
                        ),
                        label: const Text('Change in Settings'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.blueAccent,
                          side: const BorderSide(color: Color(0xFF93C5FD)),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 9,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildEducationTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _selectorField(
            label: 'Education Level',
            icon: HugeIcons.strokeRoundedGraduateMale,
            value: _educationLevel,
            placeholder: 'Select education level',
            enabled: !_isSaving,
            onTap: () async {
              final picked = await _pickOption(
                title: 'Select Education Level',
                options: _educationLevelOptions,
                enableSearch: false,
              );
              if (picked == null || !mounted) return;
              setState(() => _educationLevel = picked['name']);
            },
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _labeledField(
                  'Job experience',
                  TextFormField(
                    controller: _experienceController,
                    maxLength: 30,
                    enabled: !_isSaving,
                    decoration: _fieldDec(
                      'Add item',
                      HugeIcons.strokeRoundedBriefcase01,
                    ).copyWith(counterText: ''),
                  ),
                  helper: 'One item at a time, max 30 characters.',
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _addJobExperience,
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedAdd01,
                    size: 18,
                    color: Colors.white,
                    strokeWidth: 2.0,
                  ),
                  label: const Text('Add'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_jobExperiences.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
              ),
              child: Column(
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedBriefcase01,
                    size: 28,
                    color: Colors.grey[400]!,
                    strokeWidth: 1.5,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No job experience added yet',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Type an item above and tap Add',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _jobExperiences.map((exp) {
                return Chip(
                  label: Text(
                    exp,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  backgroundColor: const Color(0xFFEFF6FF),
                  deleteIcon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedCancel01,
                    size: 14,
                    color: Color(0xFF64748B),
                    strokeWidth: 2.0,
                  ),
                  onDeleted: _isSaving ? null : () => _removeJobExperience(exp),
                );
              }).toList(),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildAddressTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _selectorField(
            label: 'Province',
            icon: HugeIcons.strokeRoundedBuilding01,
            value: _provinceName,
            placeholder:
                _provinces.isEmpty ? 'Loading provinces...' : 'Select province',
            enabled: !_isSaving && _provinces.isNotEmpty,
            onTap: () async {
              if (_isSaving || _provinces.isEmpty || _updatingLocation) return;
              FocusScope.of(context).unfocus();
              try {
                final picked = await _pickOption(
                    title: 'Select Province', options: _provinces);
                if (picked == null || !mounted) return;
                await _onProvinceChanged(picked['code']);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Could not select province: $e')));
                }
              }
            },
          ),
          const SizedBox(height: 16),
          _selectorField(
            label: 'City / Municipality',
            icon: HugeIcons.strokeRoundedBuilding01,
            value: _cityName,
            placeholder: 'Select province first',
            enabled: !_isSaving && _cities.isNotEmpty,
            onTap: () async {
              if (_isSaving || _cities.isEmpty || _updatingLocation) return;
              FocusScope.of(context).unfocus();
              try {
                final picked = await _pickOption(
                    title: 'Select City / Municipality', options: _cities);
                if (picked == null || !mounted) return;
                await _onCityChanged(picked['code']);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Could not select city: $e')));
                }
              }
            },
          ),
          const SizedBox(height: 16),
          _selectorField(
            label: 'Barangay',
            icon: HugeIcons.strokeRoundedHouse01,
            value: _barangayName,
            placeholder: 'Select city first',
            enabled: !_isSaving && _barangays.isNotEmpty,
            onTap: () async {
              if (_isSaving || _barangays.isEmpty || _updatingLocation) return;
              FocusScope.of(context).unfocus();
              try {
                final picked = await _pickOption(
                    title: 'Select Barangay', options: _barangays);
                if (picked == null || !mounted) return;
                setState(() {
                  _barangayCode = picked['code'];
                  _barangayName = picked['name'];
                });
              } catch (e) {
                if (mounted) {
                  CustomToast.show(
                    context,
                    message: 'Could not select barangay: $e',
                    type: ToastType.error,
                  );
                }
              }
            },
          ),
          const SizedBox(height: 16),
          _labeledField(
            'Street / House No. / Landmark',
            TextFormField(
              controller: _streetController,
              decoration: _fieldDec(
                'Optional',
                HugeIcons.strokeRoundedLocation01,
              ),
            ),
            helper: 'Optional',
          ),
          if (_isLoadingLocations) ...[
            const SizedBox(height: 10),
            const LinearProgressIndicator(
              color: Color(0xFF2563EB),
              minHeight: 3,
            ),
          ],
          if (_locationError != null) ...[
            const SizedBox(height: 10),
            Text(
              _locationError!,
              style: const TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ─── Main build ───────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return WillPopScope(
      onWillPop: _confirmDiscardUnsavedChanges,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── App bar ──
              SafeArea(
                bottom: false,
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const HugeIcon(
                          icon: HugeIcons.strokeRoundedPencilEdit01,
                          color: Color(0xFF2563EB),
                          size: 20,
                          strokeWidth: 2.0,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Edit Profile',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          final shouldLeave =
                              await _confirmDiscardUnsavedChanges();
                          if (!mounted || !shouldLeave) return;
                          Navigator.pop(context);
                        },
                        icon: const HugeIcon(
                          icon: HugeIcons.strokeRoundedCancel01,
                          size: 20,
                          color: Color(0xFF64748B),
                          strokeWidth: 2.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              // ── Avatar (pinned, shared) ──
              _buildAvatarHeader(),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              // ── Tab bar ──
              _buildTabBar(),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              // ── Tab content ──
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildPersonalTab(),
                    _buildEducationTab(),
                    _buildAddressTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + bottomInset),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
            border: const Border(
              top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _isSaving
                        ? null
                        : () async {
                            final shouldLeave =
                                await _confirmDiscardUnsavedChanges();
                            if (!mounted || !shouldLeave) return;
                            Navigator.pop(context);
                          },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF475569),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: (_isSaving || !_hasUnsavedChanges())
                        ? null
                        : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFF93C5FD),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// e.g. `May/27/2026` — full month name, no numeric month.
String _formatApplicationDate(DateTime dt) {
  const months = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${months[dt.month - 1]}/${dt.day}/${dt.year}';
}

// ─── Application Model ────────────────────────────────────────────────────────

class _Application {
  final int? id;
  final Job job;
  final String appliedDate;
  final String status;
  final String? rawStatus;
  final String? processingStage;
  final String? offerResponse;
  final DateTime? offerSentAt;
  final String? withdrawalReason;
  final String? withdrawalNotes;
  final DateTime? withdrawnAt;
  final Color statusColor;
  final IconData statusIcon;

  bool get isWithdrawn =>
      rawStatus == 'withdrawn' || status == 'Withdrawn';

  bool get canWithdraw =>
      !isWithdrawn &&
      rawStatus != 'hired' &&
      rawStatus != 'rejected' &&
      offerResponse != 'accepted' &&
      offerResponse != 'declined';

  String get statusWithStage =>
      status == 'Processing' && (processingStage?.isNotEmpty ?? false)
          ? '$status · $processingStage'
          : status;

  String get compactBadgeLabel {
    if (isWithdrawn) return 'WITHDRAWN';
    if (status == 'Processing' && (processingStage?.isNotEmpty ?? false)) {
      final stage = processingStage!;
      if (stage == 'For Job Offer') {
        if (offerResponse == 'accepted') return 'OFFER ACCEPTED';
        if (offerResponse == 'declined') return 'OFFER DECLINED';
        return 'JOB OFFER';
      }
      return stage.toUpperCase();
    }
    return status.toUpperCase();
  }

  _Application withOfferResponse(String response) {
    final normalized = response.trim().toLowerCase();
    final isAccept = normalized == 'accepted';
    return _Application(
      id: id,
      job: job,
      appliedDate: appliedDate,
      status: isAccept ? 'Placement/Hired' : 'Denied',
      rawStatus: isAccept ? 'hired' : 'rejected',
      processingStage: isAccept ? 'Placement' : 'Declined',
      offerResponse: normalized,
      offerSentAt: offerSentAt,
      withdrawalReason: withdrawalReason,
      withdrawalNotes: withdrawalNotes,
      withdrawnAt: withdrawnAt,
      statusColor:
          isAccept ? const Color(0xFF10B981) : const Color(0xFFEF4444),
      statusIcon: isAccept ? Icons.work_rounded : Icons.cancel_rounded,
    );
  }

  const _Application({
    this.id,
    required this.job,
    required this.appliedDate,
    required this.status,
    this.rawStatus,
    this.processingStage,
    this.offerResponse,
    this.offerSentAt,
    this.withdrawalReason,
    this.withdrawalNotes,
    this.withdrawnAt,
    required this.statusColor,
    this.statusIcon = Icons.info_outline_rounded,
  });
}

// Legacy demo lists kept for reference only have been removed

// ─── Saved Job Model ──────────────────────────────────────────────────────────

class _SavedJob {
  final Job job;
  final String savedDate;

  const _SavedJob({required this.job, required this.savedDate});
}

class _ProfileSkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const _ProfileSkeletonBox({
    required this.width,
    required this.height,
    this.radius = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _ApplicationsPageSkeleton extends StatelessWidget {
  const _ApplicationsPageSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, __) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProfileSkeletonBox(width: 56, height: 56, radius: 16),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ProfileSkeletonBox(width: double.infinity, height: 18),
                      SizedBox(height: 8),
                      _ProfileSkeletonBox(width: 170, height: 14),
                    ],
                  ),
                ),
                SizedBox(width: 12),
                _ProfileSkeletonBox(width: 88, height: 28, radius: 14),
              ],
            ),
            SizedBox(height: 16),
            _ProfileSkeletonBox(width: double.infinity, height: 14),
            SizedBox(height: 10),
            _ProfileSkeletonBox(width: 200, height: 14),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _ProfileSkeletonBox(
                    width: double.infinity,
                    height: 42,
                    radius: 14,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _ProfileSkeletonBox(
                    width: double.infinity,
                    height: 42,
                    radius: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate(onPlay: (controller) => controller.repeat(reverse: true)).fade(
          begin: 0.58,
          end: 1,
          duration: 900.ms,
        );
  }
}

class _SavedJobsPageSkeleton extends StatelessWidget {
  const _SavedJobsPageSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, __) => const _SavedJobSkeletonCard(),
    ).animate(onPlay: (controller) => controller.repeat(reverse: true)).fade(
          begin: 0.58,
          end: 1,
          duration: 900.ms,
        );
  }
}

class _SavedJobSkeletonCard extends StatelessWidget {
  const _SavedJobSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProfileSkeletonBox(width: 56, height: 56, radius: 16),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProfileSkeletonBox(width: double.infinity, height: 18),
                    SizedBox(height: 8),
                    _ProfileSkeletonBox(width: 150, height: 13),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          _ProfileSkeletonBox(width: 170, height: 24, radius: 12),
          SizedBox(height: 12),
          _ProfileSkeletonBox(width: double.infinity, height: 14),
          SizedBox(height: 8),
          _ProfileSkeletonBox(width: 240, height: 14),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ProfileSkeletonBox(
                  width: double.infinity,
                  height: 42,
                  radius: 14,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _ProfileSkeletonBox(
                  width: double.infinity,
                  height: 42,
                  radius: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// See SavedJobsPage which now loads from backend instead of demo data.

// ─── My Applications Page ────────────────────────────────────────────────────

class MyApplicationsPage extends StatefulWidget {
  const MyApplicationsPage({super.key});

  @override
  State<MyApplicationsPage> createState() => _MyApplicationsPageState();
}

class _MyApplicationsPageState extends State<MyApplicationsPage> {
  final List<_Application> _applications = [];
  bool _isLoading = true;
  String? _errorMessage;
  final _jobActionService = JobActionService();

  @override
  void initState() {
    super.initState();
    _fetchApplications();
    _jobActionService.addListener(_onJobActionsChanged);
  }

  void _onJobActionsChanged() {
    if (mounted) {
      bool hadLocalChanges = false;
      final updated = _applications.map((app) {
        if (app.id != null) {
          final liveOffer = _jobActionService.getOfferResponse(app.id!);
          if (liveOffer != null && liveOffer != app.offerResponse) {
            hadLocalChanges = true;
            return app.withOfferResponse(liveOffer);
          }
        }
        return app;
      }).toList();
      if (hadLocalChanges) {
        setState(() {
          _applications
            ..clear()
            ..addAll(updated);
        });
      }
      unawaited(_fetchApplications(showPageLoader: false));
    }
  }

  @override
  void dispose() {
    _jobActionService.removeListener(_onJobActionsChanged);
    super.dispose();
  }

  Future<void> _fetchApplications({bool showPageLoader = true}) async {
    if (showPageLoader) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    final token = UserSession().token;
    if (token == null || token.isEmpty) {
      if (mounted) {
        setState(() {
          _applications.clear();
          _isLoading = false;
        });
      }
      return;
    }

    final result = await ApiService.getApplications(token);
    if (!mounted) return;

    if (result['success'] == true) {
      final list = result['data'] as List<dynamic>? ?? [];
      final apps = <_Application>[];
      for (final item in list) {
        final map = item as Map<String, dynamic>;
        final jobData =
            (map['job_listing'] ?? map['job']) as Map<String, dynamic>? ?? {};
        final job = Job.fromJson(jobData);
        final createdAt = DateTime.tryParse(map['applied_at'] as String? ??
                map['created_at'] as String? ??
                '') ??
            DateTime.now();
        final appliedDate = _formatApplicationDate(createdAt);
        final rawId = map['id'];
        final appId =
            rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');
        final rawStatus = (map['status'] as String? ?? '').trim().toLowerCase();

        final serverOffer = map['offer_response']?.toString().toLowerCase();
        final localOffer =
            appId != null ? _jobActionService.getOfferResponse(appId) : null;
        final offerResponse = localOffer ?? serverOffer;

        final processingStage = switch (rawStatus) {
          'shortlisted' => 'Shortlisted',
          'interview' => 'Interview',
          'for_job_offer' => (offerResponse == 'accepted')
              ? 'Placement'
              : (offerResponse == 'declined' ? 'Declined' : 'For Job Offer'),
          _ => null,
        };

        // Map backend statuses → app display labels.
        // Backend: reviewing, shortlisted, interview, hired, rejected, withdrawn
        final normalizedStatus = (rawStatus == 'withdrawn')
            ? 'Withdrawn'
            : ((offerResponse == 'accepted')
                ? 'Placement/Hired'
                : (offerResponse == 'declined'
                    ? 'Denied'
                    : switch (rawStatus) {
                        // REGISTRATION = reviewing
                        'reviewing' => 'Registration',

                        // PROCESSING = interview, shortlisted
                        'shortlisted' => 'Processing',
                        'interview' => 'Processing',
                        'for_job_offer' => 'Processing',

                        // PLACEMENT/HIRED = hired / rejected
                        'hired' => 'Placement/Hired',
                        'rejected' => 'Placement/Hired',

                        // WITHDRAWN
                        'withdrawn' => 'Withdrawn',

                        // Backward compatibility with legacy labels
                        'submitted' => 'Registration',
                        'under review' => 'Processing',
                        'interview scheduled' => 'Processing',
                        'decision' => 'Processing',
                        _ => rawStatus.isEmpty ? 'Registration' : rawStatus,
                      }));

        Color statusColor;
        IconData statusIcon;
        switch (normalizedStatus) {
          case 'Registration':
            statusColor = const Color(0xFF3B82F6); // blue
            statusIcon = Icons.app_registration_rounded;
            break;
          case 'Processing':
            statusColor = const Color(0xFFF97316); // orange
            statusIcon = Icons.hourglass_top_rounded;
            break;
          case 'Placement/Hired':
          case 'Hired':
          case 'Placement':
            statusColor =
                const Color(0xFF10B981); // emerald green, matches buttons
            statusIcon = Icons.work_rounded;
            break;
          case 'Denied':
            statusColor = const Color(0xFFEF4444); // red
            statusIcon = Icons.cancel_rounded;
            break;
          case 'Withdrawn':
            statusColor = const Color(0xFF64748B); // slate grey
            statusIcon = Icons.archive_outlined;
            break;
          default:
            statusColor = const Color(0xFF3B82F6);
            statusIcon = Icons.app_registration_rounded;
        }

        final rawOfferSentAt = map['offer_sent_at']?.toString();
        final offerSentAt =
            rawOfferSentAt != null ? DateTime.tryParse(rawOfferSentAt) : null;

        final withdrawalReason = map['withdrawal_reason']?.toString();
        final withdrawalNotes = map['withdrawal_notes']?.toString();
        final rawWithdrawnAt = map['withdrawn_at']?.toString();
        final withdrawnAt =
            rawWithdrawnAt != null ? DateTime.tryParse(rawWithdrawnAt) : null;

        apps.add(_Application(
          id: appId,
          job: job,
          appliedDate: appliedDate,
          status: normalizedStatus,
          rawStatus: (offerResponse == 'accepted')
              ? 'hired'
              : ((offerResponse == 'declined') ? 'rejected' : rawStatus),
          processingStage: processingStage,
          offerResponse: offerResponse,
          offerSentAt: offerSentAt,
          withdrawalReason: withdrawalReason,
          withdrawalNotes: withdrawalNotes,
          withdrawnAt: withdrawnAt,
          statusColor: statusColor,
          statusIcon: statusIcon,
        ));
      }

      final prefs = await SharedPreferences.getInstance();
      for (final item in list) {
        final map = item as Map<String, dynamic>;
        final id = map['id']?.toString();
        final rawStatus = map['status']?.toString() ?? 'pending';
        if (id != null) {
          await prefs.setString('app_status_$id', rawStatus);
        }
      }

      if (mounted) {
        setState(() {
          _applications
            ..clear()
            ..addAll(apps);
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } else {
      if (mounted && showPageLoader) {
        setState(() {
          _errorMessage =
              result['message'] as String? ?? 'Failed to load applications.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ProfileTheme.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        title: const Text(
          'My Applications',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE2E8F0)),
        ),
      ),
      body: _isLoading
          ? const _ApplicationsPageSkeleton()
          : _errorMessage != null
              ? ErrorState(
                  message: _errorMessage!,
                  onRetry: _fetchApplications,
                )
              : _applications.isEmpty
                  ? const _EmptyListState(
                      icon: Icons.description_outlined,
                      title: 'No applications yet',
                      subtitle:
                          'Apply to jobs and your applications will appear here.',
                    )
                  : RefreshIndicator(
                      color: _ProfileTheme.primary,
                      onRefresh: _fetchApplications,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                        itemCount: _applications.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return _buildHeaderSummary();
                          }
                          final app = _applications[index - 1];
                          return _ApplicationCard(
                            application: app,
                            onRefresh: _fetchApplications,
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _buildHeaderSummary() {
    final count = _applications.length;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const HugeIcon(
              icon: HugeIcons.strokeRoundedFolder01,
              color: Color(0xFF2563EB),
              size: 20,
              strokeWidth: 2.0,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'APPLICATION TRACKER',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  count == 1
                      ? '1 Application Submitted'
                      : '$count Applications Submitted',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Application Card ────────────────────────────────────────────────────────

class _ApplicationCard extends StatelessWidget {
  final _Application application;
  final VoidCallback? onRefresh;

  const _ApplicationCard({
    required this.application,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final jobActionService = JobActionService();
    final liveOffer = application.id != null
        ? jobActionService.getOfferResponse(application.id!)
        : null;
    final effectiveApp =
        (liveOffer != null && liveOffer != application.offerResponse)
            ? application.withOfferResponse(liveOffer)
            : application;
    final job = effectiveApp.job;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openApplicationDetail(context, effectiveApp,
              onRefresh: onRefresh),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: CompanyLogoBox(
                        job: job,
                        size: 48,
                        borderRadius: 12,
                        boxShadow: const [],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.title,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            job.company,
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: AppColors.blueAccent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded,
                                  size: 13, color: Color(0xFF94A3B8)),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  job.location,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (effectiveApp.canWithdraw)
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded,
                            size: 20, color: Color(0xFF94A3B8)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        onSelected: (value) {
                          if (value == 'withdraw') {
                            _openWithdrawModal(
                              context,
                              effectiveApp,
                              onRefresh: onRefresh,
                            );
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            value: 'withdraw',
                            child: Row(
                              children: [
                                Icon(Icons.cancel_outlined,
                                    size: 16, color: Color(0xFFDC2626)),
                                SizedBox(width: 8),
                                Text(
                                  'Unable to proceed / Withdraw',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFDC2626),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(
                    height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: effectiveApp.statusColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color:
                              effectiveApp.statusColor.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(effectiveApp.statusIcon,
                              size: 13, color: effectiveApp.statusColor),
                          const SizedBox(width: 5),
                          Text(
                            effectiveApp.compactBadgeLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: effectiveApp.statusColor,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Applied ${effectiveApp.appliedDate}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _openWithdrawModal(
  BuildContext context,
  _Application application, {
  VoidCallback? onRefresh,
}) async {
  final appId = application.id;
  if (appId == null || appId <= 0) {
    CustomToast.show(
      context,
      message: 'Unable to locate application record.',
      type: ToastType.error,
    );
    return;
  }

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _WithdrawApplicationSheet(
      application: application,
      onWithdrawn: onRefresh,
    ),
  );
}

class _WithdrawApplicationSheet extends StatefulWidget {
  final _Application application;
  final VoidCallback? onWithdrawn;

  const _WithdrawApplicationSheet({
    required this.application,
    this.onWithdrawn,
  });

  @override
  State<_WithdrawApplicationSheet> createState() =>
      _WithdrawApplicationSheetState();
}

class _WithdrawApplicationSheetState extends State<_WithdrawApplicationSheet> {
  final TextEditingController _notesController = TextEditingController();
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _reasons = const [
    {
      'label': 'Accepted another job offer / Already employed',
      'icon': Icons.work_rounded,
    },
    {
      'label': 'Pursuing studies or skills training',
      'icon': Icons.school_rounded,
    },
    {
      'label': 'Location, distance, or transportation constraints',
      'icon': Icons.directions_bus_rounded,
    },
    {
      'label': 'Schedule or personal/family conflict',
      'icon': Icons.family_restroom_rounded,
    },
    {
      'label': 'Salary or benefits expectations not aligned',
      'icon': Icons.payments_rounded,
    },
    {
      'label': 'Medical or health reasons',
      'icon': Icons.healing_rounded,
    },
    {
      'label': 'Found another opportunity elsewhere',
      'icon': Icons.lightbulb_outline_rounded,
    },
    {
      'label': 'Other personal reasons',
      'icon': Icons.edit_note_rounded,
    },
  ];

  late String _selectedReason;

  @override
  void initState() {
    super.initState();
    _selectedReason = _reasons.first['label'] as String;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitWithdrawal() async {
    final appId = widget.application.id;
    if (appId == null) {
      CustomToast.show(
        context,
        message: 'Unable to locate application record.',
        type: ToastType.error,
      );
      return;
    }

    final token = UserSession().token;
    if (token == null || token.isEmpty) {
      CustomToast.show(
        context,
        message: 'Please sign in to withdraw your application.',
        type: ToastType.error,
      );
      return;
    }

    setState(() => _isSubmitting = true);
    AppHaptics.mediumImpact();

    try {
      final res = await ApiService.withdrawApplication(
        token: token,
        applicationId: appId,
        reason: _selectedReason,
        notes: _notesController.text.trim(),
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (res['success'] == true) {
        AppHaptics.heavyImpact();
        Navigator.of(context).pop();
        CustomToast.show(
          context,
          message:
              'Application withdrawn. PESO staff and employer have been notified.',
          type: ToastType.info,
          duration: const Duration(seconds: 4),
        );
        widget.onWithdrawn?.call();
      } else {
        AppHaptics.lightImpact();
        CustomToast.show(
          context,
          message:
              res['message']?.toString() ?? 'Failed to withdraw application.',
          type: ToastType.error,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      CustomToast.show(
        context,
        message: 'Connection error. Please try again.',
        type: ToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final job = widget.application.job;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Header banner
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFEE2E2)),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.cancel_outlined,
                      color: Color(0xFFDC2626),
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Withdraw Application',
                        style: TextStyle(
                          fontSize: 18.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Notify PESO Santiago staff that you can no longer proceed with this application.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.grey[600],
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Job target card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  CompanyLogoBox(
                    job: job,
                    size: 38,
                    borderRadius: 10,
                    boxShadow: const [],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.title,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          job.company,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.blueAccent,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Reason dropdown section
            const Text(
              'REASON FOR WITHDRAWAL',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedReason,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF64748B)),
                  borderRadius: BorderRadius.circular(16),
                  items: _reasons.map((r) {
                    final label = r['label'] as String;
                    final icon = r['icon'] as IconData;
                    return DropdownMenuItem<String>(
                      value: label,
                      child: Row(
                        children: [
                          Icon(icon, size: 18, color: const Color(0xFF2563EB)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              label,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: _isSubmitting
                      ? null
                      : (val) {
                          if (val != null) {
                            setState(() => _selectedReason = val);
                          }
                        },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Optional message notes
            const Text(
              'ADDITIONAL MESSAGE TO PESO (OPTIONAL)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              enabled: !_isSubmitting,
              maxLines: 3,
              maxLength: 500,
              style: const TextStyle(fontSize: 13.5, color: Color(0xFF0F172A)),
              decoration: InputDecoration(
                hintText:
                    'Provide any extra details or a thank-you note to PESO Santiago...',
                hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey[400]),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: AppColors.blueAccent, width: 1.5),
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 12),

            // Informational tip callout
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 16, color: Color(0xFF2563EB)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Withdrawing notifies PESO so that another applicant can be prioritized. You can always apply to future job openings anytime.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF1E40AF),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Keep Application',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitWithdrawal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Submit & Notify',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _openOfferModal(
  BuildContext context,
  _Application application, {
  VoidCallback? onRefresh,
}) async {
  final appId = application.id;
  if (appId == null || appId <= 0) {
    CustomToast.show(
      context,
      message: 'Unable to locate your application record for this offer.',
      type: ToastType.error,
    );
    return;
  }
  await showJobOfferDecisionSheet(
    context: context,
    applicationId: appId,
    jobTitle: application.job.title,
    companyName: application.job.company,
    startDate: 'To be agreed upon',
    salary: application.job.salaryDisplay,
    employmentType: application.job.employmentTypeLabel,
    initialResponse: application.offerResponse,
    onResponseSubmitted: () {
      Navigator.of(context).pop();
      onRefresh?.call();
    },
  );
}

void _openApplicationDetail(
  BuildContext context,
  _Application initialApp, {
  VoidCallback? onRefresh,
}) {
  final jobActionService = JobActionService();
  final job = initialApp.job;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return AnimatedBuilder(
        animation: jobActionService,
        builder: (modalCtx, _) {
          final liveOffer = initialApp.id != null
              ? jobActionService.getOfferResponse(initialApp.id!)
              : null;
          final app =
              (liveOffer != null && liveOffer != initialApp.offerResponse)
                  ? initialApp.withOfferResponse(liveOffer)
                  : initialApp;

          final isPendingOffer = app.rawStatus == 'for_job_offer' &&
              (app.offerResponse == null || app.offerResponse!.isEmpty);

          final banner = _ApplicationStatusBanner(
            application: app,
            onReviewOffer: isPendingOffer
                ? () => _openOfferModal(modalCtx, app, onRefresh: onRefresh)
                : null,
            onWithdraw: app.canWithdraw
                ? () async {
                    await _openWithdrawModal(
                      modalCtx,
                      app,
                      onRefresh: () {
                        Navigator.of(modalCtx).pop();
                        onRefresh?.call();
                      },
                    );
                  }
                : null,
          );

          final isOfferAccepted = app.offerResponse == 'accepted';
          final isOfferDeclined = app.offerResponse == 'declined';

          String? customLabel;
          dynamic customIcon;
          List<Color>? customGradient;
          VoidCallback? customTap;

          if (isPendingOffer) {
            customLabel = 'Review Job Offer';
            customIcon = Icons.gavel_rounded;
            customGradient = [
              const Color(0xFF0EA5E9),
              const Color(0xFF0284C7)
            ];
            customTap =
                () => _openOfferModal(modalCtx, app, onRefresh: onRefresh);
          } else if (isOfferAccepted) {
            customLabel = 'Offer Accepted';
            customIcon = Icons.check_circle_rounded;
            customGradient = [
              const Color(0xFF10B981),
              const Color(0xFF059669)
            ];
            customTap = null;
          } else if (isOfferDeclined) {
            customLabel = 'Offer Declined';
            customIcon = Icons.cancel_outlined;
            customGradient = [
              const Color(0xFF94A3B8),
              const Color(0xFF64748B)
            ];
            customTap = null;
          }

          return GestureDetector(
            onTap: () => Navigator.of(modalCtx).pop(),
            behavior: HitTestBehavior.opaque,
            child: SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: GestureDetector(
                  onTap: () {},
                  child: JobDetailSheet(
                    job: job,
                    headerBanner: banner,
                    isApplied: true,
                    isSaved: jobActionService.isSaved(job.id),
                    customActionLabel: customLabel,
                    customActionIcon: customIcon,
                    customActionGradientColors: customGradient,
                    onCustomActionTap: customTap,
                    onViewMap: () {
                      Navigator.of(modalCtx).pop();
                      Navigator.of(context).pop();
                      homeNavRequestNotifier.value = 2;
                      mapFocusRequestNotifier.value =
                          MapFocusRequest.fromJob(job);
                    },
                    onSave: () async {
                      final error = await jobActionService.toggleSave(job.id);
                      if (modalCtx.mounted) {
                        CustomToast.show(
                          modalCtx,
                          message: error ??
                              (jobActionService.isSaved(job.id)
                                  ? 'Job saved successfully.'
                                  : 'Job removed from saved.'),
                          type:
                              error == null ? ToastType.info : ToastType.error,
                        );
                      }
                    },
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

// ─── Saved Jobs Page ─────────────────────────────────────────────────────────

class SavedJobsPage extends StatefulWidget {
  const SavedJobsPage({super.key});

  @override
  State<SavedJobsPage> createState() => _SavedJobsPageState();
}

class _SavedJobsPageState extends State<SavedJobsPage> {
  final List<_SavedJob> _savedJobs = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _nextCursor;
  String? _errorMessage;
  final _jobActionService = JobActionService();
  final ScrollController _scrollController = ScrollController();

  String _savedDateLabel(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months[date.month - 1];
    return 'Saved $month/${date.day}/${date.year}';
  }

  @override
  void initState() {
    super.initState();
    _fetchSavedJobs();
    _jobActionService.addListener(_onJobActionsChanged);
    _scrollController.addListener(_onScroll);
  }

  void _onJobActionsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _jobActionService.removeListener(_onJobActionsChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isLoading || _isLoadingMore || !_hasMore) return;
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 280) {
      _fetchSavedJobs(loadMore: true);
    }
  }

  Future<void> _fetchSavedJobs({bool loadMore = false}) async {
    if (loadMore && (_isLoading || _isLoadingMore || !_hasMore)) return;
    if (!loadMore) {
      setState(() {
        _isLoading = true;
        _isLoadingMore = false;
        _hasMore = true;
        _nextCursor = null;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _isLoadingMore = true;
      });
    }

    final token = UserSession().token;
    if (token == null || token.isEmpty) {
      setState(() {
        _savedJobs.clear();
        _isLoading = false;
        _isLoadingMore = false;
        _hasMore = false;
      });
      return;
    }

    final result = await ApiService.getSavedJobs(
      token,
      cursor: loadMore ? _nextCursor : null,
      limit: 15,
    );
    if (!mounted) return;

    if (result['success'] == true) {
      final list = result['data'] as List<dynamic>? ?? [];
      final items = <_SavedJob>[];

      for (final item in list) {
        final map = item as Map<String, dynamic>;
        final rawJobData =
            (map['job_listing'] ?? map['job']) as Map<String, dynamic>? ?? {};
        final job = Job.fromJson({
          ...rawJobData,
          'match_percentage': (map['match_score'] as num?)?.toInt() ??
              (map['match_percentage'] as num?)?.toInt() ??
              (rawJobData['match_score'] as num?)?.toInt() ??
              (rawJobData['match_percentage'] as num?)?.toInt() ??
              0,
        });
        final createdAt =
            DateTime.tryParse(map['created_at'] as String? ?? '') ??
                DateTime.now();
        final savedDate = _savedDateLabel(createdAt);

        items.add(_SavedJob(job: job, savedDate: savedDate));
      }

      final meta = result['meta'] as Map<String, dynamic>? ?? {};
      final nextCursor = meta['next_cursor'] as String?;
      final hasMore = meta['has_more'] == true ||
          (nextCursor != null && nextCursor.isNotEmpty);
      setState(() {
        if (!loadMore) {
          _savedJobs
            ..clear()
            ..addAll(items);
        } else {
          _savedJobs.addAll(items);
        }
        _nextCursor = nextCursor;
        _hasMore = hasMore;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } else {
      setState(() {
        _errorMessage =
            result['message'] as String? ?? 'Failed to load saved jobs.';
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _applyToJob(Job job) async {
    final hasResume = await _jobActionService.hasResumeOnFile();
    if (!mounted) return;
    if (!hasResume) {
      final goToDocuments = await showAppDialog<bool>(
        context: context,
        type: AppDialogType.info,
        icon: Icons.description_outlined,
        title: 'Resume Required',
        message:
            'You need to upload your resume first before applying to jobs.',
        confirmLabel: 'Go to Documents',
        onConfirm: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      );
      if (goToDocuments == true && mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const MyDocumentsPage()),
        );
        if (!mounted) return;
        final hasResumeNow =
            await _jobActionService.hasResumeOnFile(forceRefresh: true);
        if (!hasResumeNow) return;
      } else {
        return;
      }
    }

    final confirmed = await showAppDialog<bool>(
      context: context,
      type: AppDialogType.confirm,
      icon: Icons.send_rounded,
      title: Localizations.localeOf(context).languageCode == 'tl'
          ? 'Kumpirmahin ang Aplikasyon'
          : 'Confirm Application',
      message: Localizations.localeOf(context).languageCode == 'tl'
          ? 'Mag-apply para sa ${job.title}?'
          : 'Apply for ${job.title}?',
      confirmLabel: S.of(context)?.apply ?? 'Apply',
      confirmBusyLabel: Localizations.localeOf(context).languageCode == 'tl'
          ? 'Nag-a-apply...'
          : 'Applying...',
      onConfirmAsync: () async {
        final error = await _jobActionService.applyToJob(job.id, job.title);
        if (error != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(error),
                backgroundColor: const Color(0xFFEF4444),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
          throw Exception(error);
        }
      },
    );
    if (confirmed != true || !mounted) return;

    microInteractionSuccess();
    await showApplySuccessFeedback(
      context,
      job: job,
      jobActionService: _jobActionService,
    );
  }

  Future<void> _unsaveJob(String jobId) async {
    final error = await _jobActionService.unsaveJob(jobId);
    if (!mounted) return;

    if (error == null) {
      _fetchSavedJobs();
      CustomToast.show(
        context,
        message: 'Job removed from saved.',
        type: ToastType.info,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ProfileTheme.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        title: const Text(
          'Saved Jobs',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE2E8F0)),
        ),
      ),
      body: _isLoading
          ? const _SavedJobsPageSkeleton()
          : _errorMessage != null
              ? ErrorState(
                  message: _errorMessage!,
                  onRetry: _fetchSavedJobs,
                )
              : _savedJobs.isEmpty
                  ? const _EmptyListState(
                      icon: Icons.bookmark_outline_rounded,
                      title: 'No saved jobs',
                      subtitle:
                          'Tap the bookmark on jobs you like to see them here.',
                    )
                  : RefreshIndicator(
                      color: _ProfileTheme.primary,
                      onRefresh: _fetchSavedJobs,
                      child: ListView.builder(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                        itemCount:
                            _savedJobs.length + 1 + (_isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return _buildHeaderSummary();
                          }
                          final jobIndex = index - 1;
                          if (jobIndex >= _savedJobs.length) {
                            return const Padding(
                              padding: EdgeInsets.only(top: 4, bottom: 12),
                              child: _SavedJobSkeletonCard(),
                            );
                          }
                          final saved = _savedJobs[jobIndex];
                          final isApplied =
                              _jobActionService.isApplied(saved.job.id);
                          return _SavedJobCard(
                            savedJob: saved,
                            isApplied: isApplied,
                            onApply: () => _applyToJob(saved.job),
                            onUnsave: () => _unsaveJob(saved.job.id),
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _buildHeaderSummary() {
    final count = _savedJobs.length;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const HugeIcon(
              icon: HugeIcons.strokeRoundedBookmark01,
              color: Color(0xFF2563EB),
              size: 20,
              strokeWidth: 2.0,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SAVED LISTINGS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  count == 1 ? '1 Job Saved' : '$count Jobs Saved',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Saved Job Card ───────────────────────────────────────────────────────────

class _SavedJobCard extends StatelessWidget {
  final _SavedJob savedJob;
  final bool isApplied;
  final VoidCallback onApply;
  final VoidCallback onUnsave;

  const _SavedJobCard({
    required this.savedJob,
    required this.isApplied,
    required this.onApply,
    required this.onUnsave,
  });

  @override
  Widget build(BuildContext context) {
    final job = savedJob.job;
    Future<void> openDetails() async {
      final jobActionService = JobActionService();
      Job detailJob = job;
      final token = UserSession().token;
      if (token != null && token.isNotEmpty) {
        final jobId = int.tryParse(job.id);
        final result = jobId == null
            ? const {'success': false}
            : await ApiService.getJobById(token, jobId);
        if (result['success'] == true) {
          final data = result['data'] as Map<String, dynamic>? ?? {};
          final listing = data['job_listing'] as Map<String, dynamic>? ?? {};
          if (listing.isNotEmpty) {
            detailJob = Job.fromJson({
              ...listing,
              if ((listing['employer'] == null ||
                      listing['employer'] is! Map) &&
                  job.company.isNotEmpty)
                'employer': {'company_name': job.company},
              if ((listing['location'] == null ||
                      listing['location'].toString().trim().isEmpty) &&
                  job.location.isNotEmpty)
                'location': job.location,
              'match_percentage': (data['match_score'] as num?)?.toInt() ??
                  (data['match_percentage'] as num?)?.toInt() ??
                  (listing['match_percentage'] as num?)?.toInt() ??
                  job.matchPercentage,
            });
          }
        }
      }
      if (!context.mounted) return;
      showJobDetailSheet(
        context,
        detailJob,
        isSaved: true,
        isApplied: jobActionService.isApplied(detailJob.id),
        onApply: onApply,
        onSave: onUnsave,
        onViewMap: () {
          Navigator.of(context).pop(); // Pop modal
          Navigator.of(context).pop(); // Pop SavedJobsPage to return home
          homeNavRequestNotifier.value = 2; // Switch to Map Tab
          mapFocusRequestNotifier.value = MapFocusRequest.fromJob(detailJob);
        },
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          highlightColor: Colors.transparent,
          splashColor: const Color(0x0D2563EB),
          onTap: openDetails,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: CompanyLogoBox(
                        job: job,
                        size: 48,
                        borderRadius: 12,
                        boxShadow: const [],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.title,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            job.company,
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: AppColors.blueAccent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded,
                                  size: 13, color: Color(0xFF94A3B8)),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  job.location,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (job.matchPercentage > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color:
                                const Color(0xFF10B981).withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded,
                                size: 12, color: Color(0xFF059669)),
                            const SizedBox(width: 2),
                            Text(
                              '${job.matchPercentage}%',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF059669),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(
                    height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.payments_outlined,
                        size: 15, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        job.salaryDisplay,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF334155),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: onUnsave,
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFFFECACA),
                          ),
                        ),
                        child: const Icon(
                          Icons.bookmark_remove_rounded,
                          size: 16,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    PressableButton(
                      onTap: openDetails,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: isApplied
                              ? const Color(0xFF10B981)
                              : AppColors.blueAccent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isApplied
                                  ? Icons.check_circle_outline_rounded
                                  : Icons.send_rounded,
                              size: 13,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              isApplied
                                  ? (S.of(context)?.applied ?? 'Applied')
                                  : (S.of(context)?.applyNow ?? 'Apply Now'),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.bookmark_rounded,
                        size: 12, color: Color(0xFFCBD5E1)),
                    const SizedBox(width: 4),
                    Text(
                      savedJob.savedDate,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Application Status Banner ────────────────────────────────────────────────

class _RotatingHourglassIcon extends StatefulWidget {
  final double size;
  final Color color;

  const _RotatingHourglassIcon({
    super.key,
    this.size = 16,
    required this.color,
  });

  @override
  State<_RotatingHourglassIcon> createState() => _RotatingHourglassIconState();
}

class _RotatingHourglassIconState extends State<_RotatingHourglassIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;
        // 0.0 -> 0.2307 is 0ms to 600ms (rotate 180 deg)
        // 0.2307 -> 1.0 is 600ms to 2600ms (pause for 2 seconds)
        double turns;
        if (progress <= 0.2307) {
          final t = progress / 0.2307;
          final curveT = Curves.easeInOutCubic.transform(t);
          turns = curveT * 0.5;
        } else {
          turns = 0.5;
        }
        return RotationTransition(
          turns: AlwaysStoppedAnimation(turns),
          child: child,
        );
      },
      child: Icon(
        Icons.hourglass_top_rounded,
        size: widget.size,
        color: widget.color,
      ),
    );
  }
}

class _ApplicationStatusBanner extends StatelessWidget {
  final _Application application;
  final VoidCallback? onReviewOffer;
  final VoidCallback? onWithdraw;

  const _ApplicationStatusBanner({
    required this.application,
    this.onReviewOffer,
    this.onWithdraw,
  });

  @override
  Widget build(BuildContext context) {
    final steps = ['Registration', 'Processing', 'Placement/Hired'];
    final statusToStep = {
      'Registration': 0,
      'Processing': 1,
      // Final bucket in the UI (maps from backend hired/rejected)
      'Placement/Hired': 2,

      // Backward compatibility (older labels)
      'Accepted': 1,
      'Denied': 2,
      'Hired': 2,
      'Placement': 2,
      'Withdrawn': 2,
    };
    final currentStep = statusToStep[application.status] ?? 0;
    final isProcessing = application.status == 'Processing';
    final isWithdrawn = application.isWithdrawn;
    final isPendingOffer = application.rawStatus == 'for_job_offer' &&
        (application.offerResponse == null ||
            application.offerResponse!.isEmpty);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPendingOffer
            ? const Color(0xFF0284C7).withValues(alpha: 0.06)
            : application.statusColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPendingOffer
              ? const Color(0xFF0284C7).withValues(alpha: 0.35)
              : application.statusColor.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status header
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isPendingOffer
                      ? const Color(0xFF0284C7).withValues(alpha: 0.15)
                      : application.statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(
                    isPendingOffer
                        ? Icons.gavel_rounded
                        : application.statusIcon,
                    size: 17,
                    color: isPendingOffer
                        ? const Color(0xFF0284C7)
                        : application.statusColor,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Application Status',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      application.status,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: isPendingOffer
                            ? const Color(0xFF0284C7)
                            : application.statusColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isProcessing &&
                        (application.processingStage?.isNotEmpty ?? false))
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '• ${application.processingStage!}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isPendingOffer
                                ? const Color(0xFF0284C7)
                                : application.statusColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Applied ${application.appliedDate}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  ),
                ),
              ),
            ],
          ),

          if (isWithdrawn) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 15, color: Color(0xFF64748B)),
                      SizedBox(width: 6),
                      Text(
                        'Application Discontinued',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                  if (application.withdrawalReason != null &&
                      application.withdrawalReason!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Reason: ${application.withdrawalReason}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ],
                  if (application.withdrawalNotes != null &&
                      application.withdrawalNotes!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Note: "${application.withdrawalNotes}"',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),

            // Progress timeline
            Row(
              children: List.generate(steps.length, (index) {
                final isPassed = index < currentStep;
                final isCurrent = index == currentStep;
                final isLast = index == steps.length - 1;

                Widget stepNodeIcon;
                if (isPassed) {
                  stepNodeIcon = const Icon(Icons.check_rounded,
                      size: 12, color: Colors.white);
                } else if (isCurrent) {
                  if (index == 1) {
                    stepNodeIcon = isPendingOffer
                        ? const Icon(Icons.gavel_rounded,
                            size: 12, color: Colors.white)
                        : const _RotatingHourglassIcon(
                            size: 12, color: Colors.white);
                  } else if (index == 0) {
                    stepNodeIcon = const Icon(Icons.edit_note_rounded,
                        size: 12, color: Colors.white);
                  } else {
                    stepNodeIcon = const Icon(Icons.work_rounded,
                        size: 12, color: Colors.white);
                  }
                } else {
                  stepNodeIcon = Text(
                    '${index + 1}',
                    style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w700),
                  );
                }

                final nodeColor = isPendingOffer && isCurrent
                    ? const Color(0xFF0284C7)
                    : application.statusColor;

                final nodeCircle = AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: (isPassed || isCurrent)
                        ? nodeColor
                        : const Color(0xFFE2E8F0),
                    shape: BoxShape.circle,
                  ),
                  child: Center(child: stepNodeIcon),
                );

                Widget nodeWidget;
                if (isCurrent) {
                  nodeWidget = SizedBox(
                    width: 32,
                    height: 32,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Expanding sonar aura behind node circle
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: nodeColor.withValues(alpha: 0.20),
                          ),
                        )
                            .animate(
                              onPlay: (controller) =>
                                  controller.repeat(reverse: true),
                            )
                            .scale(
                              begin: const Offset(0.85, 0.85),
                              end: const Offset(1.22, 1.22),
                              duration: 1200.ms,
                              curve: Curves.easeInOut,
                            )
                            .fadeIn(
                              duration: 400.ms,
                              curve: Curves.easeIn,
                            ),
                        nodeCircle,
                      ],
                    ),
                  );
                } else {
                  nodeWidget = SizedBox(
                    width: 32,
                    height: 32,
                    child: Center(child: nodeCircle),
                  );
                }

                return Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            nodeWidget,
                            const SizedBox(height: 6),
                            Text(
                              steps[index],
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: (isPassed || isCurrent)
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: (isPassed || isCurrent)
                                    ? nodeColor
                                    : const Color(0xFF94A3B8),
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            height: 2,
                            margin: const EdgeInsets.only(bottom: 18),
                            color: isPassed
                                ? application.statusColor
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),

            const SizedBox(height: 14),

            // Next steps advice
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    isPendingOffer
                        ? Icons.celebration_rounded
                        : Icons.info_outline_rounded,
                    size: 16,
                    color: isPendingOffer
                        ? const Color(0xFF0284C7)
                        : application.statusColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getNextStepAdvice(application),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF475569),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (application.canWithdraw && onWithdraw != null) ...[
            const SizedBox(height: 12),
            Center(
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: onWithdraw,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFEE2E2)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cancel_outlined,
                          size: 14, color: Color(0xFFDC2626)),
                      SizedBox(width: 6),
                      Text(
                        'Unable to proceed? Notify PESO & Withdraw',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getNextStepAdvice(_Application app) {
    if (app.isWithdrawn) {
      return 'You have withdrawn this application (${app.withdrawalReason ?? "No longer proceeding"}). PESO staff and the employer have been notified.';
    }
    if (app.rawStatus == 'for_job_offer') {
      final response = app.offerResponse?.toLowerCase();
      if (response == 'accepted') {
        return 'Congratulations! You accepted this job offer. The employer will reach out regarding onboarding details.';
      } else if (response == 'declined') {
        return 'You declined this job offer. Keep applying to other opportunities.';
      }
      return ' You have received a job offer for this role! Tap "Review Job Offer" below to review terms and accept or decline.';
    }
    switch (app.status) {
      case 'Registration':
        return 'Your application has been registered. It will be processed by the employer for acceptance or denial.';
      case 'Processing':
        return 'Your application is being reviewed. The employer will decide to accept or deny. This typically takes 3–5 business days.';
      case 'Accepted':
        return 'Congratulations! You have been accepted. Awaiting placement confirmation.';
      case 'Denied':
        return 'Your application was not accepted for this position. Keep applying to other opportunities.';
      case 'Hired':
      case 'Placement':
      case 'Placement/Hired':
        return 'Congratulations! You have been hired/placed. Follow up with the employer for onboarding details.';
      default:
        return 'You will be notified via email once there are updates to your application.';
    }
  }
}

// ─── Shared Empty State Widget ─────────────────────────────────────────────────

class _EmptyListState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyListState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 56,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
