import 'dart:typed_data';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'job_models.dart';
import 'user_session.dart';
import 'api_service.dart';
import '_error_state_widget.dart';
import 'job_action_service.dart';
import 'skills_profile_page.dart';
import 'resume_upload_page.dart';

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

  @override
  void initState() {
    super.initState();
    _loadStats();
    _loadAvatar();
  }

  Future<void> _loadAvatar() async {
    final token = UserSession().token;
    if (token == null || UserSession().avatarPath == null) return;
    final bytes = await ApiService.getAvatarBytes(token);
    if (mounted) setState(() => _avatarBytes = bytes);
  }

  Future<void> _loadStats() async {
    final token = UserSession().token;
    if (token == null || token.isEmpty) {
      setState(() {
        _appliedCount = 0;
        _interviewCount = 0;
        _savedCount = 0;
      });
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
          final status = (map['status'] as String? ?? '').trim();
          return status == 'Processing';
        }).length;
      }

      if (savedResult['success'] == true) {
        final list = savedResult['data'] as List<dynamic>? ?? [];
        saved = list.length;
      }

      if (!mounted) return;
      setState(() {
        _appliedCount = applied;
        _interviewCount = interview;
        _savedCount = saved;
      });
    } catch (_) {
      // Keep existing counts on error; profile still loads.
    }
  }

  @override
  Widget build(BuildContext context) {
    const coverHeight = 170.0;
    const avatarSize = 90.0;
    const avatarTop = coverHeight - avatarSize / 2;
    const headerHeight = coverHeight + avatarSize / 2 + 72.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Column(
        children: [
          // ── Cover + Avatar + Name/Stats side by side ────────────────────────
          SizedBox(
            height: headerHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Cover gradient (full bleed to top)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: coverHeight,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1E3A8A), Color(0xFF2563EB), Color(0xFF60A5FA)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: GestureDetector(
                            onTap: () => _showEditProfileSheet(context),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.35),
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.edit_rounded,
                                color: Colors.white,
                                size: 17,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Light grey background beneath cover (matches page)
                Positioned(
                  top: coverHeight,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(color: const Color(0xFFF1F5F9)),
                ),

                // Avatar straddling the cover boundary, centered
                Positioned(
                  top: avatarTop,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                    width: avatarSize,
                    height: avatarSize,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withOpacity(0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: _avatarBytes != null && _avatarBytes!.isNotEmpty
                          ? Image.memory(
                              Uint8List.fromList(_avatarBytes!),
                              width: avatarSize,
                              height: avatarSize,
                              fit: BoxFit.cover,
                            )
                          : Center(
                              child: Text(
                                UserSession().initials,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
              ),

                // Name + email centered under avatar
                Positioned(
                  top: coverHeight + avatarSize / 2 + 8,
                  left: 20,
                  right: 20,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          UserSession().displayName,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          UserSession().email ?? '',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF64748B),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Scrollable content ──────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).padding.bottom + 96,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // Status counts - punchy white card
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildCompactStat('$_appliedCount', 'Applied'),
                        _buildCompactStat('$_interviewCount', 'Processing'),
                        _buildCompactStat('$_savedCount', 'Saved'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Menu items
                  _buildMenuItem(
                    icon: Icons.folder_outlined,
                    title: 'My Applications',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MyApplicationsPage()),
                    ),
                  ),
                  _buildMenuItem(
                    icon: Icons.bookmark_outline_rounded,
                    title: 'Saved Jobs',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SavedJobsPage()),
                    ),
                  ),
                  _buildMenuItem(
                    icon: Icons.psychology_outlined,
                    title: 'Skills Profile',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SkillsProfilePage()),
                    ),
                  ),
                  _buildMenuItem(
                    icon: Icons.upload_file_rounded,
                    title: 'My Resume',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ResumeUploadPage()),
                    ),
                  ),
                  _buildMenuItem(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    icon: Icons.help_outline_rounded,
                    title: 'Help & Support',
                    onTap: () {},
                  ),

                  const SizedBox(height: 8),

                  _buildMenuItem(
                    icon: Icons.logout_rounded,
                    title: 'Sign Out',
                    isSignOut: true,
                    onTap: () => _confirmSignOut(context),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
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

  void _showEditProfileSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const EditProfileSheet(),
    ).then((_) {
      if (mounted) {
        _loadAvatar();
        setState(() {});
      }
    });
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Sign Out',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
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

    if (!mounted) return;
    Navigator.pop(context); // close loading
    // Return all the way to the initial landing page
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSignOut = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSignOut ? const Color(0xFFFEF2F2) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
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
                Icon(
                  icon,
                  size: 22,
                  color: isSignOut
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF64748B),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isSignOut
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF0F172A),
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: isSignOut
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Edit Profile Sheet ───────────────────────────────────────────────────────
class EditProfileSheet extends StatefulWidget {
  const EditProfileSheet({super.key});

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _streetController;
  bool _isSaving = false;
  List<int>? _avatarBytes;
  Uint8List? _pickedImageBytes;
  bool _isLoadingLocations = false;
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
    _lastNameController = TextEditingController(text: lastName);
    _emailController = TextEditingController(text: UserSession().email ?? '');
    _phoneController = TextEditingController(text: UserSession().phone ?? '');
    _streetController = TextEditingController(text: session.streetAddress ?? '');
    _loadAvatar();
    _loadProvinces();
  }

  Future<void> _loadAvatar() async {
    final token = UserSession().token;
    if (token == null || UserSession().avatarPath == null) return;
    final bytes = await ApiService.getAvatarBytes(token);
    if (mounted) setState(() => _avatarBytes = bytes);
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick image: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
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
    setState(() {
      _isLoadingLocations = true;
      _locationError = null;
    });
    try {
      _provinces = await _fetchLocationList('provinces_all', _psgcProvincesUrl);
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
      if (hit.isNotEmpty) {
        _barangayCode = hit.first['code'];
        _barangayName = hit.first['name'];
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _onProvinceChanged(String? code, {bool silent = false}) async {
    setState(() {
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

    if (code == null || code.isEmpty) {
      if (mounted && !silent) setState(() => _isLoadingLocations = false);
      return;
    }

    try {
      _cities = await _fetchLocationList(
        'cities_province_$code',
        'https://psgc.gitlab.io/api/provinces/$code/cities-municipalities/',
      );
    } finally {
      if (mounted && !silent) setState(() => _isLoadingLocations = false);
    }
  }

  Future<void> _onCityChanged(String? code, {bool silent = false}) async {
    setState(() {
      _cityCode = code;
      _cityName = _cities
          .firstWhere((e) => e['code'] == code, orElse: () => {'name': ''})['name'];
      _barangayCode = null;
      _barangayName = null;
      _barangays = [];
      _isLoadingLocations = !silent;
    });

    if (code == null || code.isEmpty) {
      if (mounted && !silent) setState(() => _isLoadingLocations = false);
      return;
    }

    try {
      _barangays = await _fetchLocationList(
        'barangays_$code',
        'https://psgc.gitlab.io/api/cities-municipalities/$code/barangays/',
      );
    } finally {
      if (mounted && !silent) setState(() => _isLoadingLocations = false);
    }
  }

  Future<Map<String, String>?> _pickOption({
    required String title,
    required List<Map<String, String>> options,
  }) async {
    final queryController = TextEditingController();
    List<Map<String, String>> filtered = List<Map<String, String>>.from(options);
    return showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocalState) {
            return AlertDialog(
              title: Text(title),
              content: SizedBox(
                width: 420,
                height: 420,
                child: Column(
                  children: [
                    TextField(
                      controller: queryController,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search_rounded),
                        hintText: 'Search...',
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
                    const SizedBox(height: 12),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(child: Text('No matching results'))
                          : ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (_, index) {
                                final item = filtered[index];
                                return ListTile(
                                  dense: true,
                                  title: Text(item['name'] ?? ''),
                                  onTap: () => Navigator.of(ctx).pop(item),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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

  InputDecoration _fieldDec(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
      prefixIcon: Icon(icon, color: const Color(0xFF2563EB)),
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
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(20),
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

              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
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
                                        : _avatarBytes != null && _avatarBytes!.isNotEmpty
                                            ? Image.memory(
                                                Uint8List.fromList(_avatarBytes!),
                                                width: 100,
                                                height: 100,
                                                fit: BoxFit.cover,
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
                              child: TextFormField(
                                controller: _firstNameController,
                                decoration:
                                    _fieldDec('First Name', Icons.person_outline_rounded),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _lastNameController,
                                decoration:
                                    _fieldDec('Last Name', Icons.badge_outlined),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _emailController,
                          decoration: _fieldDec('Email', Icons.email_outlined),
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Please enter your email';
                            return null;
                          },
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

                        _selectorField(
                          label: 'Province',
                          icon: Icons.location_city_outlined,
                          value: _provinceName,
                          placeholder:
                              _provinces.isEmpty ? 'Loading provinces...' : 'Select province',
                          enabled: !_isSaving && _provinces.isNotEmpty,
                          onTap: () async {
                            final picked = await _pickOption(
                                title: 'Select Province', options: _provinces);
                            if (picked == null) return;
                            await _onProvinceChanged(picked['code']);
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
                            final picked = await _pickOption(
                                title: 'Select City / Municipality', options: _cities);
                            if (picked == null) return;
                            await _onCityChanged(picked['code']);
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
                            final picked = await _pickOption(
                                title: 'Select Barangay', options: _barangays);
                            if (picked == null) return;
                            setState(() {
                              _barangayCode = picked['code'];
                              _barangayName = picked['name'];
                            });
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
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Please complete Province, City/Municipality, and Barangay.'),
                                          backgroundColor: Color(0xFFEF4444),
                                        ),
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
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              uploadResult['message'] as String? ?? 'Failed to upload photo',
                                            ),
                                          ),
                                        );
                                        return;
                                      }
                                    }

                                    final result = await ApiService.updateProfile(
                                      token: token,
                                      email: _emailController.text.trim(),
                                      firstName: _firstNameController.text.trim(),
                                      lastName: _lastNameController.text.trim(),
                                      contact: _phoneController.text.trim(),
                                      address: _composeAddress(),
                                      provinceCode: _provinceCode,
                                      provinceName: _provinceName,
                                      cityCode: _cityCode,
                                      cityName: _cityName,
                                      barangayCode: _barangayCode,
                                      barangayName: _barangayName,
                                      streetAddress: _streetController.text.trim(),
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
                                      if (!mounted) return;
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: const Row(
                                            children: [
                                              Icon(Icons.check_circle_rounded,
                                                  color: Colors.white, size: 18),
                                              SizedBox(width: 8),
                                              Text('Profile updated successfully!'),
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
                                          content: Text(
                                            result['message'] as String? ??
                                                'Failed to update profile.',
                                          ),
                                          backgroundColor: const Color(0xFFEF4444),
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
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
      },
    );
  }
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
        final appliedDate = 'Applied ${createdAt.month}/${createdAt.day}/${createdAt.year}';
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
      backgroundColor: const Color(0xFFF8FAFC),
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
              child: CircularProgressIndicator(color: Color(0xFF2563EB)),
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
                      color: const Color(0xFF2563EB),
                      onRefresh: _fetchApplications,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _openApplicationDetail(context, application),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row: avatar + title + status pill
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: job.companyColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          job.companyInitial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            job.company,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF2563EB),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  size: 12, color: Color(0xFF94A3B8)),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  job.location,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF64748B)),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: application.statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: application.statusColor.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(application.statusIcon,
                              size: 11, color: application.statusColor),
                          const SizedBox(width: 4),
                          Text(
                            application.status,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: application.statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 10),

                // Bottom row: salary, type chip, applied date
                Row(
                  children: [
                    Icon(Icons.payments_outlined,
                        size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${job.salaryMin} – ${job.salaryMax}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        job.employmentType,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.access_time_rounded,
                        size: 12, color: Colors.grey[400]),
                    const SizedBox(width: 3),
                    Text(
                      application.appliedDate,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
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
        final savedDate = 'Saved ${createdAt.month}/${createdAt.day}/${createdAt.year}';

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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Application'),
        content: Text(
          'Apply for $jobTitle?',
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Apply'),
          ),
        ],
      ),
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
      backgroundColor: const Color(0xFFF8FAFC),
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
              child: CircularProgressIndicator(color: Color(0xFF2563EB)),
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
                      color: const Color(0xFF2563EB),
                      onRefresh: _fetchSavedJobs,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            final jobActionService = JobActionService();
            showJobDetailSheet(
              context,
              job,
              isSaved: true,
              isApplied: jobActionService.isApplied(job.id),
              onApply: onApply,
              onSave: onUnsave,
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: avatar + title + match badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: job.companyColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          job.companyInitial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            job.company,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF2563EB),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  size: 12, color: Color(0xFF94A3B8)),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  job.location,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF64748B)),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded,
                                size: 12, color: Colors.white),
                            Text(
                              '${job.matchPercentage}%',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 10),

                // Bottom: salary + type + actions
                Row(
                  children: [
                    Icon(Icons.payments_outlined,
                        size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${job.salaryMin} – ${job.salaryMax}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        job.employmentType,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                    const Spacer(),
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
                              ? const Color(0xFF10B981)
                              : const Color(0xFF2563EB),
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
                    ),
                  ],
                ),
              ),
              Text(
                application.appliedDate,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF94A3B8),
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
