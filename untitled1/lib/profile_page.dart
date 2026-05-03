import 'dart:typed_data';
import 'dart:convert';
import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'job_models.dart';
import 'user_session.dart';
import 'api_service.dart';
import '_error_state_widget.dart';
import 'job_action_service.dart';
import 'skills_profile_page.dart';
import 'my_documents_page.dart';
import 'session_prefs.dart';
import 'settings_page.dart';
import 'app_nav.dart';
import 'notification_service.dart';
import 'main.dart';
import 'home_pages.dart'; // Added to access global map notifiers

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

      if (appsResult['success'] == true) {
        final list = appsResult['data'] as List<dynamic>? ?? [];
        applied = list.length;
        interview = list.where((item) {
          final map = item as Map<String, dynamic>;
          final rawStatus = (map['status'] as String? ?? '')
              .trim()
              .toLowerCase()
              .replaceAll('_', ' ')
              .replaceAll('-', ' ')
              .replaceAll(RegExp(r'\s+'), ' ');
          // Processing should count ONLY shortlisted + interview.
          return rawStatus == 'shortlisted' || rawStatus == 'interview';
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
        if (user['resume_path'] == null || user['resume_path'].toString().isEmpty) missing++;
        if (user['certificate_path'] == null || user['certificate_path'].toString().isEmpty) missing++;
        if (user['barangay_clearance_path'] == null || user['barangay_clearance_path'].toString().isEmpty) missing++;
      }

      if (!mounted) return;
      final hasChanges = _appliedCount != applied ||
          _interviewCount != interview ||
          _savedCount != saved ||
          _missingDocsCount != missing;
      if (hasChanges) {
        setState(() {
          _appliedCount = applied;
          _interviewCount = interview;
          _savedCount = saved;
          _missingDocsCount = missing;
        });
      }
    } catch (_) {
      // Keep existing counts on error; profile still loads.
    } finally {
      _isStatsRefreshing = false;
    }
  }

  void _showEditProfileSheet(BuildContext context) async {
    final token = UserSession().token;
    if (token == null) return;
    
    // We need to reload data to ensure we have current state
    final userResult = await ApiService.getUser(token);
    if (userResult['success'] == true && userResult['data'] != null) {
       UserSession().updateFromUser(userResult['data'] as Map<String, dynamic>);
    }

    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (ctx) => EditProfileSheet(
          onUpdate: () {
            _loadStats();
            _loadAvatar();
          },
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    const coverHeight = 180.0;
    const avatarSize = 100.0;
    const avatarTop = coverHeight - avatarSize / 2;

    return Scaffold(
      backgroundColor: _ProfileTheme.scaffoldBg,
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(
              height: coverHeight + avatarSize / 2 + 20,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
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
                              icon: const Icon(Icons.edit_rounded,
                                  color: Colors.white, size: 20),
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
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.blueAccent.withOpacity(0.22),
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
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildCompactStat('$_appliedCount', 'Applied'),
                        Container(
                            width: 1,
                            height: 28,
                            color: AppColors.divider),
                        _buildCompactStat('$_interviewCount', 'Processing'),
                        Container(
                            width: 1,
                            height: 28,
                            color: AppColors.divider),
                        _buildCompactStat('$_savedCount', 'Saved'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildMenuItem(
                  icon: Icons.folder_rounded,
                  title: 'My Applications',
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MyApplicationsPage()),
                    );
                    _loadStats();
                  },
                ),
                _buildMenuItem(
                  icon: Icons.bookmark_rounded,
                  title: 'Saved Jobs',
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SavedJobsPage()),
                    );
                    _loadStats();
                  },
                ),
                _buildMenuItem(
                  icon: Icons.workspace_premium_outlined,
                  title: 'Skills Profile',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SkillsProfilePage()),
                  ),
                ),
                _buildMenuItem(
                  icon: Icons.description_rounded,
                  title: 'My Documents',
                  trailing: _missingDocsCount > 0
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFEE2E2), width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline_rounded, size: 14, color: Color(0xFFEF4444)),
                              const SizedBox(width: 4),
                              Text(
                                '$_missingDocsCount more',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFEF4444),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFDCFCE7), width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle_outline_rounded, size: 14, color: Color(0xFF16A34A)),
                              const SizedBox(width: 4),
                              const Text(
                                'Complete',
                                style: TextStyle(
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
                      MaterialPageRoute(builder: (_) => const MyDocumentsPage()),
                    );
                    _loadStats();
                  },
                ),
                _buildMenuItem(
                  icon: Icons.settings_rounded,
                  title: 'Settings',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsPage()),
                  ),
                ),
                _buildMenuItem(
                  icon: Icons.help_center_rounded,
                  title: 'Help & Support',
                  onTap: () {},
                ),
                const SizedBox(height: 12),
                _buildMenuItem(
                  icon: Icons.logout_rounded,
                  title: 'Sign Out',
                  isSignOut: true,
                  onTap: () => _confirmSignOut(context),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStat(String value, String label) {
    return Column(
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
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // Removed redundant _showEditProfileSheet


  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showAppDialog<bool>(
      context: context,
      type: AppDialogType.destructive,
      icon: Icons.logout_rounded,
      title: 'Sign Out',
      message: 'Are you sure you want to sign out?',
      confirmLabel: 'Sign Out',
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
    await SessionPrefs.clear();

    if (!mounted) return;
    Navigator.pop(context); // close loading
    // Home is already the root route — popUntil does nothing. Replace stack with auth.
    navigateToAuthEntryReplacingStack();
  }

  Widget _buildMenuItem({
    required IconData icon,
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
                  child: Icon(icon, size: 20, color: iconFg),
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
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 24,
                  color: Color(0xFFCBD5E1),
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
  static const String _psgcProvincesUrl = 'https://psgc.gitlab.io/api/provinces/';
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

  @override
  void initState() {
    super.initState();
    final session = UserSession();
    final firstFromSession = session.firstName?.trim() ?? '';
    final lastFromSession = session.lastName?.trim() ?? '';
    final sessionName = (session.name ?? '').trim();
    final nameParts =
        sessionName.isEmpty ? <String>[] : sessionName.split(RegExp(r'\s+'));
    final firstName =
        firstFromSession.isNotEmpty ? firstFromSession : (nameParts.isNotEmpty ? nameParts.first : '');
    final lastName = lastFromSession.isNotEmpty
        ? lastFromSession
        : (nameParts.length > 1 ? nameParts.skip(1).join(' ') : '');

    _firstNameController = TextEditingController(text: firstName);
    _middleInitialController = TextEditingController(text: session.middleInitial ?? '');
    _lastNameController = TextEditingController(text: lastName);
    _phoneController = TextEditingController(text: UserSession().phone ?? '');
    _streetController = TextEditingController(text: session.streetAddress ?? '');
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

    _loadAvatar();
    _loadProvinces();
  }

  Future<void> _loadAvatar() async {
    final token = UserSession().token;
    if (token == null || UserSession().avatarPath == null) return;
    final bytes = await ApiService.getAvatarBytes(token);
    if (mounted) setState(() {
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

  Future<List<Map<String, String>>> _fetchLocationList(
    String key,
    String url,
  ) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        return _readCachedList(key);
      }
      final data = jsonDecode(response.body);
      if (data is! List) return _readCachedList(key);
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
      return _readCachedList(key);
    }
  }

  Future<void> _loadProvinces() async {
    if (!mounted) return;
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
      if (mounted) setState(() => _isLoadingLocations = false);
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
      _provinceName = _provinces
          .firstWhere((e) => e['code'] == code, orElse: () => {'name': ''})['name'];
      _cityCode = null;
      _cityName = null;
      _barangayCode = null;
      _barangayName = null;
      _cities = [];
      _barangays = [];
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
      _cityName = _cities
          .firstWhere((e) => e['code'] == code, orElse: () => {'name': ''})['name'];
      _barangayCode = null;
      _barangayName = null;
      _barangays = [];
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
    List<Map<String, String>> filtered = List<Map<String, String>>.from(options);
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
                          child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Color(0xFF0F172A))),
                        ),
                        IconButton(
                          onPressed: () async {
                            if (picking) return;
                            primaryFocus?.unfocus();
                            setLocalState(() => picking = true);
                            await Future.delayed(const Duration(milliseconds: 600));
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
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        onChanged: (q) {
                          final needle = q.trim().toLowerCase();
                          setLocalState(() {
                            filtered = options
                                .where((o) => (o['name'] ?? '').toLowerCase().contains(needle))
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
                                  enableSearch ? 'No matching results' : 'No options available',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (_, index) {
                                  final item = filtered[index];
                                  return ListTile(
                                    title: Text(item['name'] ?? '', style: const TextStyle(fontSize: 15)),
                                    trailing: const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF94A3B8)),
                                    onTap: () async {
                                      if (alreadyPopped || picking) return;
                                      
                                      setLocalState(() => picking = true);
                                      
                                      primaryFocus?.unfocus();
                                      FocusManager.instance.primaryFocus?.unfocus();
                                      
                                      await Future.delayed(const Duration(milliseconds: 600));
                                      
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
    required IconData icon,
    required String? value,
    required String placeholder,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    final display = (value ?? '').trim();
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: InputDecorator(
        decoration: _fieldDec(label, icon),
        child: Row(
          children: [
            Expanded(
              child: Text(
                display.isNotEmpty ? display : placeholder,
                style: TextStyle(
                  color: display.isNotEmpty
                      ? const Color(0xFF0F172A)
                      : const Color(0xFF94A3B8),
                ),
              ),
            ),
            Icon(
              Icons.expand_more_rounded,
              color: enabled ? const Color(0xFF64748B) : const Color(0xFFCBD5E1),
            ),
          ],
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

    setState(() {
      if (!_jobExperiences.contains(value)) {
        _jobExperiences.add(value);
      }
      _experienceController.clear();
    });
  }

  void _removeJobExperience(String value) {
    setState(() => _jobExperiences.remove(value));
  }

  InputDecoration _fieldDec(String label, IconData? icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
      prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF2563EB)) : null,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
              child: Padding(
                padding: const EdgeInsets.only(left: 8, right: 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        color: Color(0xFF2563EB),
                        size: 22,
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
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close_rounded, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottomInset),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                        // Avatar edit (tap to change photo)
                        Center(
                          child: GestureDetector(
                            onTap: _isSaving ? null : _pickImage,
                            child: Stack(
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2563EB),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF2563EB).withOpacity(0.3),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: _pickedImageBytes != null
                                        ? Image.memory(
                                            _pickedImageBytes!,
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover,
                                          )
                                        : _avatarUint8List != null && _avatarUint8List!.isNotEmpty
                                            ? Image.memory(
                                                _avatarUint8List!,
                                                width: 100,
                                                height: 100,
                                                fit: BoxFit.cover,
                                                gaplessPlayback: true,
                                              )
                                            : Center(
                                                child: Text(
                                                  UserSession().initials,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 36,
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
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2563EB),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt_rounded,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Form fields
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: _firstNameController,
                                decoration:
                                    _fieldDec('First Name', Icons.person_outline_rounded),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Required';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _middleInitialController,
                                textCapitalization: TextCapitalization.characters,
                                maxLength: 1,
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(1),
                                  UpperCaseTextFormatter(),
                                ],
                                decoration: _fieldDec('M.I.', null).copyWith(counterText: ''),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: _lastNameController,
                                decoration:
                                    _fieldDec('Last Name', Icons.badge_outlined),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Required';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Email address',
                                style: TextStyle(
                                  color: Color(0xFF1E40AF),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                (UserSession().email ?? '').trim().isEmpty
                                    ? 'No email available'
                                    : UserSession().email!.trim(),
                                style: const TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontWeight: FontWeight.w600,
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
                                icon: const Icon(Icons.settings_rounded, size: 18),
                                label: const Text('Change email in Settings'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.blueAccent,
                                  side: const BorderSide(color: Color(0xFF93C5FD)),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _phoneController,
                          decoration: _fieldDec('Phone Number', Icons.phone_outlined),
                          keyboardType: TextInputType.phone,
                          validator: (v) {
                            final value = v?.trim() ?? '';
                            if (value.isEmpty) return null; // optional
                            final phPattern = RegExp(r'^0\d{10}$');
                            if (!phPattern.hasMatch(value)) {
                              return 'Enter 11-digit PH number (e.g. 09XXXXXXXXX)';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _dobController,
                                readOnly: true,
                                decoration: _fieldDec('Birthdate (YYYY-MM-DD)', Icons.cake_outlined),
                                onTap: () async {
                                  final now = DateTime.now();
                                  DateTime initial = DateTime(now.year - 21, now.month, now.day);
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
                                    final pickedLocal = DateTime(picked.year, picked.month, picked.day);
                                    _dobController.text =
                                        '${pickedLocal.year.toString().padLeft(4, '0')}-${pickedLocal.month.toString().padLeft(2, '0')}-${pickedLocal.day.toString().padLeft(2, '0')}';
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: ['male', 'female'].contains(_selectedSex?.toLowerCase()) ? _selectedSex?.toLowerCase() : null,
                                decoration: _fieldDec('Sex', Icons.person_outline),
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
                          ],
                        ),

                        const SizedBox(height: 16),

                        _selectorField(
                          label: 'Education Level',
                          icon: Icons.school_outlined,
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

                        const SizedBox(height: 16),

                        Text(
                          'Add one experience at a time. Type an item (max 30 chars) and tap Add.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),

                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _experienceController,
                                maxLength: 30,
                                enabled: !_isSaving,
                                decoration: _fieldDec(
                                  'Job Experience (max 30 chars)',
                                  Icons.work_outline_rounded,
                                ).copyWith(counterText: ''),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              height: 56,
                              child: ElevatedButton.icon(
                                onPressed: _isSaving ? null : _addJobExperience,
                                icon: const Icon(Icons.add_rounded, size: 20),
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

                        const SizedBox(height: 10),

                        if (_jobExperiences.isEmpty)
                          Text(
                            'No job experience added yet.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.grey[600],
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
                                deleteIcon: const Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                ),
                                onDeleted: _isSaving
                                    ? null
                                    : () => _removeJobExperience(exp),
                              );
                            }).toList(),
                          ),

                        const SizedBox(height: 16),

                        _selectorField(
                          label: 'Province',
                          icon: Icons.location_city_outlined,
                          value: _provinceName,
                          placeholder:
                              _provinces.isEmpty ? 'Loading provinces...' : 'Select province',
                          enabled: !_isSaving && _provinces.isNotEmpty,
                        onTap: () async {
                          if (_isSaving || _provinces.isEmpty || _updatingLocation) return;
                          FocusScope.of(context).unfocus();
                          try {
                            final picked = await _pickOption(title: 'Select Province', options: _provinces);
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
                          icon: Icons.location_city_outlined,
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
                          icon: Icons.home_work_outlined,
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

                        TextFormField(
                          controller: _streetController,
                          decoration: _fieldDec(
                            'Street / House No. / Landmark (Optional)',
                            Icons.location_on_outlined,
                          ),
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

                        const SizedBox(height: 30),

                        // Save button
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _isSaving
                                ? null
                                : () async {
                                    if (!_formKey.currentState!.validate()) return;
                                    final missingLocation = _provinceCode == null ||
                                        _cityCode == null ||
                                        _barangayCode == null;
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
                                          message: uploadResult['message'] as String? ?? 'Failed to upload photo',
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
                                      jobExperience: _jobExperiences.isEmpty
                                          ? null
                                          : _jobExperiences.join(', '),
                                      provinceCode: _provinceCode,
                                      provinceName: _provinceName,
                                      cityCode: _cityCode,
                                      cityName: _cityName,
                                      barangayCode: _barangayCode,
                                      barangayName: _barangayName,
                                      streetAddress: _streetController.text.trim(),
                                      dateOfBirth: _dobController.text.trim().isEmpty ? null : _dobController.text.trim(),
                                      sex: _selectedSex,
                                    );

                                    if (!mounted) return;
                                    setState(() => _isSaving = false);

                                    if (result['success'] == true) {
                                      final updatedUser =
                                          result['data'] as Map<String, dynamic>? ?? {};
                                      UserSession().updateFromUser(updatedUser);
                                      if (_pickedImageBytes != null) {
                                        final userResult = await ApiService.getUser(token);
                                        if (userResult['success'] == true && userResult['data'] != null) {
                                          UserSession().updateFromUser(userResult['data'] as Map<String, dynamic>);
                                        }
                                      }
                                      widget.onUpdate(); // <--- This triggers the immediate UI refresh
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
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  const Color(0xFF2563EB).withOpacity(0.6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text(
                                    'Save Changes',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Cancel button
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF64748B),
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
            ],
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
  final Job job;
  final String appliedDate;
  final String status;
  final Color statusColor;
  final IconData statusIcon;

  const _Application({
    required this.job,
    required this.appliedDate,
    required this.status,
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
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _jobActionService.removeListener(_onJobActionsChanged);
    super.dispose();
  }

  Future<void> _fetchApplications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final token = UserSession().token;
    if (token == null || token.isEmpty) {
      setState(() {
        _applications.clear();
        _isLoading = false;
      });
      return;
    }

    final result = await ApiService.getApplications(token);
    if (!mounted) return;

    if (result['success'] == true) {
      final list = result['data'] as List<dynamic>? ?? [];
      final apps = <_Application>[];
      for (final item in list) {
        final map = item as Map<String, dynamic>;
        final jobData = (map['job_listing'] ?? map['job']) as Map<String, dynamic>? ?? {};
        final job = Job.fromJson(jobData);
        final createdAt =
            DateTime.tryParse(map['applied_at'] as String? ?? map['created_at'] as String? ?? '') ??
                DateTime.now();
        final appliedDate = _formatApplicationDate(createdAt);
        final rawStatus = (map['status'] as String? ?? '').trim().toLowerCase();
        // Map backend statuses → app display labels.
        // Backend: reviewing, shortlisted, interview, hired, rejected
        final normalizedStatus = switch (rawStatus) {
          // REGISTRATION = reviewing
          'reviewing' => 'Registration',

          // PROCESSING = interview, shortlisted
          'shortlisted' => 'Processing',
          'interview' => 'Processing',

          // PLACEMENT/HIRED = hired / rejected
          'hired' => 'Placement/Hired',
          'rejected' => 'Placement/Hired',

          // Backward compatibility with legacy labels
          'submitted' => 'Registration',
          'under review' => 'Processing',
          'interview scheduled' => 'Processing',
          'decision' => 'Processing',
          _ => rawStatus.isEmpty ? 'Registration' : rawStatus,
        };

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
            statusColor = const Color(0xFF10B981); // emerald green, matches buttons
            statusIcon = Icons.work_rounded;
            break;
          case 'Denied':
            statusColor = const Color(0xFFEF4444); // red
            statusIcon = Icons.cancel_rounded;
            break;
          default:
            statusColor = const Color(0xFF3B82F6);
            statusIcon = Icons.app_registration_rounded;
        }

        apps.add(_Application(
          job: job,
          appliedDate: appliedDate,
          status: normalizedStatus,
          statusColor: statusColor,
          statusIcon: statusIcon,
        ));
      }

      setState(() {
        _applications
          ..clear()
          ..addAll(apps);
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = result['message'] as String? ?? 'Failed to load applications.';
        _isLoading = false;
      });
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
          ? const Center(
              child: CircularProgressIndicator(color: _ProfileTheme.primary),
            )
          : _errorMessage != null
              ? ErrorState(
                  message: _errorMessage!,
                  onRetry: _fetchApplications,
                )
              : _applications.isEmpty
                  ? const _EmptyListState(
                      icon: Icons.description_outlined,
                      title: 'No applications yet',
                      subtitle: 'Apply to jobs and your applications will appear here.',
                    )
                  : RefreshIndicator(
                      color: _ProfileTheme.primary,
                      onRefresh: _fetchApplications,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: ClampingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                        itemCount: _applications.length,
                        itemBuilder: (context, index) {
                          final app = _applications[index];
                          return _ApplicationCard(application: app);
                        },
                      ),
                    ),
    );
  }
}

// ─── Application Card ────────────────────────────────────────────────────────

class _ApplicationCard extends StatelessWidget {
  final _Application application;

  const _ApplicationCard({required this.application});

  @override
  Widget build(BuildContext context) {
    final job = application.job;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _openApplicationDetail(context, application),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CompanyLogoBox(
                        job: job,
                        size: 52,
                        borderRadius: 14,
                        boxShadow: const [],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            job.company,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.blueAccent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF94A3B8)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  job.location,
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: application.statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: application.statusColor.withOpacity(0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(application.statusIcon, size: 14, color: application.statusColor),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  application.status.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: application.statusColor,
                                    letterSpacing: 0.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Applied ${application.appliedDate}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[500],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
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

void _openApplicationDetail(BuildContext context, _Application application) {
  final job = application.job;
  final banner = _ApplicationStatusBanner(application: application);
  final jobActionService = JobActionService();
  showJobDetailSheet(
    context,
    job,
    headerBanner: banner,
    isApplied: true,
    isSaved: jobActionService.isSaved(job.id),
    onViewMap: () {
      Navigator.of(context).pop(); // Pop modal
      Navigator.of(context).pop(); // Pop the Applications/Detail page to return home
      homeNavRequestNotifier.value = 1; // Switch to Map Tab
      mapFocusRequestNotifier.value = MapFocusRequest.fromJob(job);
    },
    onSave: () async {
      final error = await jobActionService.toggleSave(job.id);
      if (context.mounted) {
        if (error == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(jobActionService.isSaved(job.id)
                  ? 'Job saved successfully.'
                  : 'Job removed from saved.'),
              backgroundColor: jobActionService.isSaved(job.id)
                  ? const Color(0xFF2563EB)
                  : const Color(0xFF64748B),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
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
  String? _errorMessage;
  final _jobActionService = JobActionService();

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
  }

  void _onJobActionsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _jobActionService.removeListener(_onJobActionsChanged);
    super.dispose();
  }

  Future<void> _fetchSavedJobs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final token = UserSession().token;
    if (token == null || token.isEmpty) {
      setState(() {
        _savedJobs.clear();
        _isLoading = false;
      });
      return;
    }

    final result = await ApiService.getSavedJobs(token);
    if (!mounted) return;

    if (result['success'] == true) {
      final list = result['data'] as List<dynamic>? ?? [];
      final items = <_SavedJob>[];

      for (final item in list) {
        final map = item as Map<String, dynamic>;
        final jobData =
            (map['job_listing'] ?? map['job']) as Map<String, dynamic>? ?? {};
        final job = Job.fromJson(jobData);
        final createdAt =
            DateTime.tryParse(map['created_at'] as String? ?? '') ??
                DateTime.now();
        final savedDate = _savedDateLabel(createdAt);

        items.add(_SavedJob(job: job, savedDate: savedDate));
      }

      setState(() {
        _savedJobs
          ..clear()
          ..addAll(items);
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = result['message'] as String? ?? 'Failed to load saved jobs.';
        _isLoading = false;
      });
    }
  }

  Future<void> _applyToJob(String jobId, String jobTitle) async {
    final hasResume = await _jobActionService.hasResumeOnFile();
    if (!mounted) return;
    if (!hasResume) {
      final goToDocuments = await showAppDialog<bool>(
        context: context,
        type: AppDialogType.info,
        icon: Icons.description_outlined,
        title: 'Resume Required',
        message: 'You need to upload your resume first before applying to jobs.',
        confirmLabel: 'Go to Documents',
        onConfirm: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      );
      if (goToDocuments == true && mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const MyDocumentsPage()),
        );
      }
      return;
    }

    final confirmed = await showAppDialog<bool>(
      context: context,
      type: AppDialogType.confirm,
      icon: Icons.send_rounded,
      title: 'Confirm Application',
      message: 'Apply for $jobTitle?',
      confirmLabel: 'Apply',
      onConfirm: () => Navigator.pop(context, true),
      onCancel: () => Navigator.pop(context, false),
    );
    if (confirmed != true || !mounted) return;

    final error = await _jobActionService.applyToJob(jobId, jobTitle);
    if (!mounted) return;

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('Applied to $jobTitle!'),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
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

  Future<void> _unsaveJob(String jobId) async {
    final error = await _jobActionService.unsaveJob(jobId);
    if (!mounted) return;

    if (error == null) {
      _fetchSavedJobs();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Job removed from saved.'),
          backgroundColor: const Color(0xFF64748B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
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
          ? const Center(
              child: CircularProgressIndicator(color: _ProfileTheme.primary),
            )
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
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: ClampingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                        itemCount: _savedJobs.length,
                        itemBuilder: (context, index) {
                          final saved = _savedJobs[index];
                          final isApplied = _jobActionService.isApplied(saved.job.id);
                          return _SavedJobCard(
                            savedJob: saved,
                            isApplied: isApplied,
                            onApply: () => _applyToJob(saved.job.id, saved.job.title),
                            onUnsave: () => _unsaveJob(saved.job.id),
                          );
                        },
                      ),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            final jobActionService = JobActionService();
            showJobDetailSheet(
              context,
              job,
              isSaved: true,
              isApplied: jobActionService.isApplied(job.id),
              onApply: onApply,
              onSave: onUnsave,
              onViewMap: () {
                Navigator.of(context).pop(); // Pop modal
                Navigator.of(context).pop(); // Pop SavedJobsPage to return home
                homeNavRequestNotifier.value = 1; // Switch to Map Tab
                mapFocusRequestNotifier.value = MapFocusRequest.fromJob(job);
              },
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CompanyLogoBox(
                        job: job,
                        size: 52,
                        borderRadius: 14,
                        boxShadow: const [],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            job.company,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.blueAccent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF94A3B8)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  job.location,
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (job.matchPercentage > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${job.matchPercentage}%',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'match',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.payments_outlined, size: 16, color: Colors.grey[500]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        job.salaryDisplay,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[700],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: onUnsave,
                      child: Container(
                        padding: const EdgeInsets.all(8),
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
                    GestureDetector(
                      onTap: isApplied ? null : onApply,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isApplied
                              ? const Color(0xFF64748B)
                              : AppColors.blueAccent,
                          borderRadius: BorderRadius.circular(999),
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
                              isApplied ? 'Applied' : 'Apply Now',
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

                // Saved date
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(Icons.bookmark_rounded,
                          size: 12, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(
                        savedJob.savedDate,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
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

class _ApplicationStatusBanner extends StatelessWidget {
  final _Application application;

  const _ApplicationStatusBanner({required this.application});

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
    };
    final currentStep = statusToStep[application.status] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: application.statusColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: application.statusColor.withOpacity(0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status header
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: application.statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(application.statusIcon,
                    size: 16, color: application.statusColor),
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
                    Text(
                      application.status,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: application.statusColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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

          const SizedBox(height: 14),

          // Progress timeline
          Row(
            children: List.generate(steps.length, (index) {
              final isDone = index <= currentStep;
              final isLast = index == steps.length - 1;
              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: isDone
                                  ? application.statusColor
                                  : const Color(0xFFE2E8F0),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: isDone
                                  ? const Icon(Icons.check_rounded,
                                      size: 12, color: Colors.white)
                                  : Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF94A3B8),
                                          fontWeight: FontWeight.w700),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            steps[index],
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: isDone
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isDone
                                  ? application.statusColor
                                  : const Color(0xFF94A3B8),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          height: 2,
                          margin: const EdgeInsets.only(bottom: 18),
                          color: index < currentStep
                              ? application.statusColor
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),

          const SizedBox(height: 12),

          // Next steps advice
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 16, color: application.statusColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getNextStepAdvice(application.status),
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
      ),
    );
  }

  String _getNextStepAdvice(String status) {
    switch (status) {
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
