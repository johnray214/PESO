import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import 'api_service.dart';
import 'home_pages.dart';
import 'onboarding_prefs.dart';
import 'user_session.dart';

/// After registration: goal → location & experience → skills → notifications → tour → Home.
class PostAuthOnboardingScreen extends StatefulWidget {
  const PostAuthOnboardingScreen({super.key});

  @override
  State<PostAuthOnboardingScreen> createState() => _PostAuthOnboardingScreenState();
}

class _PostAuthOnboardingScreenState extends State<PostAuthOnboardingScreen> {
  int _step = 0;
  bool _busy = false;

  String? _goal;
  final _streetController = TextEditingController();
  String? _experienceLevel;
  final Set<String> _selectedSkills = {};
  Map<String, List<String>> _skillCatalog = {};
  final Map<String, int> _skillNameToId = {};
  bool _skillsLoading = true;
  final _skillSearchController = TextEditingController();
  String _skillQuery = '';

  List<Map<String, String>> _provinces = [];
  List<Map<String, String>> _cities = [];
  List<Map<String, String>> _barangays = [];
  String? _provinceCode;
  String? _provinceName;
  String? _cityCode;
  String? _cityName;
  String? _barangayCode;
  String? _barangayName;
  bool _locationLoading = false;
  String? _locationError;
  static const String _psgcProvincesUrl = 'https://psgc.gitlab.io/api/provinces/';

  static const _goals = [
    'Full-time',
    'Part-time',
    'Contract',
    'Freelance',
  ];

  static const _experienceLevels = [
    'No Formal Education',
    'Elementary Level',
    'Elementary Graduate',
    'Secondary Level',
    'Secondary Graduate',
    'Tertiary Level',
    'Tertiary Graduate',
  ];

  static const _fallbackSkills = [
    'Customer Service',
    'Microsoft Office',
    'Communication',
    'Sales',
    'Retail',
    'Food Service',
    'Data Entry',
    'Driving',
  ];

  List<String> _visibleSkills(List<String> source) {
    final filtered = source.where((s) {
      if (_skillQuery.isEmpty) return true;
      return s.toLowerCase().contains(_skillQuery);
    }).toList();
    if (_skillQuery.isEmpty && filtered.length > 120) {
      return filtered.take(120).toList();
    }
    return filtered;
  }

  @override
  void initState() {
    super.initState();
    _goal = _mapGoalFromJobExperience(UserSession().jobExperience);
    final sessionEducation = UserSession().educationLevel;
    _experienceLevel = _experienceLevels.contains(sessionEducation)
        ? sessionEducation
        : _experienceLevels.last;
    _skillSearchController.addListener(() {
      if (!mounted) return;
      setState(() => _skillQuery = _skillSearchController.text.trim().toLowerCase());
    });
    _loadSkills();
    _loadLocations();
  }

  String? _mapGoalFromJobExperience(String? raw) {
    final text = (raw ?? '').toLowerCase();
    for (final goal in _goals) {
      if (text.contains(goal.toLowerCase())) return goal;
    }
    return null;
  }

  Future<void> _loadSkills() async {
    final result = await ApiService.getPublicSkills();
    if (!mounted) return;
    if (result['success'] == true) {
      final list = result['data'] as List<dynamic>? ?? [];
      final byCategory = <String, List<String>>{};
      final nameToId = <String, int>{};
      for (final raw in list) {
        final m = raw as Map<String, dynamic>;
        final id = (m['id'] as num?)?.toInt();
        final name = (m['name'] as String?)?.trim();
        final categoryRaw = m['category']?.toString().trim() ?? '';
        final category = categoryRaw.isNotEmpty ? categoryRaw : 'Other';
        if (id == null || name == null || name.isEmpty) continue;
        nameToId[name.toLowerCase()] = id;
        byCategory.putIfAbsent(category, () => <String>[]).add(name);
      }
      setState(() {
        _skillCatalog = byCategory;
        _skillNameToId
          ..clear()
          ..addAll(nameToId);
        _skillsLoading = false;
      });
    } else {
      setState(() => _skillsLoading = false);
    }
  }

  Future<List<Map<String, String>>> _fetchLocationList(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.body);
      if (data is! List) return [];
      final list = data
          .whereType<Map>()
          .map((e) => {
                'code': (e['code'] ?? '').toString(),
                'name': (e['name'] ?? '').toString(),
              })
          .where((e) => e['code']!.isNotEmpty && e['name']!.isNotEmpty)
          .toList();
      list.sort((a, b) => a['name']!.toLowerCase().compareTo(b['name']!.toLowerCase()));
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<void> _loadLocations() async {
    setState(() {
      _locationLoading = true;
      _locationError = null;
    });
    try {
      _provinces = await _fetchLocationList(_psgcProvincesUrl);
      if (_provinces.isEmpty) {
        _locationError = 'Unable to load location data. Check connection and try again.';
        return;
      }

      final session = UserSession();
      _streetController.text = session.streetAddress ?? '';

      final sessionProvince = session.provinceCode;
      final sessionCity = session.cityCode;
      final sessionBarangay = session.barangayCode;

      if (sessionProvince != null && sessionProvince.isNotEmpty) {
        await _onProvinceChanged(sessionProvince, silent: true);
      }
      if (sessionCity != null && sessionCity.isNotEmpty) {
        await _onCityChanged(sessionCity, silent: true);
      }
      if (sessionBarangay != null && sessionBarangay.isNotEmpty) {
        final hit = _barangays.where((e) => e['code'] == sessionBarangay).toList();
        if (hit.isNotEmpty) {
          _barangayCode = hit.first['code'];
          _barangayName = hit.first['name'];
        }
      }
    } finally {
      if (!mounted) return;
      setState(() => _locationLoading = false);
    }
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
      _locationLoading = !silent;
    });

    if (code == null || code.isEmpty) {
      if (mounted && !silent) setState(() => _locationLoading = false);
      return;
    }

    try {
      _cities = await _fetchLocationList(
        'https://psgc.gitlab.io/api/provinces/$code/cities-municipalities/',
      );
    } finally {
      if (mounted && !silent) setState(() => _locationLoading = false);
    }
  }

  Future<void> _onCityChanged(String? code, {bool silent = false}) async {
    setState(() {
      _cityCode = code;
      _cityName =
          _cities.firstWhere((e) => e['code'] == code, orElse: () => {'name': ''})['name'];
      _barangayCode = null;
      _barangayName = null;
      _barangays = [];
      _locationLoading = !silent;
    });

    if (code == null || code.isEmpty) {
      if (mounted && !silent) setState(() => _locationLoading = false);
      return;
    }

    try {
      _barangays = await _fetchLocationList(
        'https://psgc.gitlab.io/api/cities-municipalities/$code/barangays/',
      );
    } finally {
      if (mounted && !silent) setState(() => _locationLoading = false);
    }
  }

  @override
  void dispose() {
    _streetController.dispose();
    _skillSearchController.dispose();
    super.dispose();
  }

  Future<void> _saveProfileAndContinue() async {
    final token = UserSession().token;
    if (token == null || token.isEmpty) return;

    setState(() => _busy = true);
    final goal = _goal ?? _goals.first;
    final exp = _experienceLevel ?? _experienceLevels.first;

    final res = await ApiService.updateProfile(
      token: token,
      jobExperience: 'Seeking: $goal',
      educationLevel: exp,
      provinceCode: _provinceCode,
      provinceName: _provinceName,
      cityCode: _cityCode,
      cityName: _cityName,
      barangayCode: _barangayCode,
      barangayName: _barangayName,
      streetAddress: _streetController.text.trim(),
    );

    if (res['success'] == true) {
      final prof = await ApiService.getUser(token);
      if (prof['success'] == true && prof['data'] is Map<String, dynamic>) {
        final data = prof['data'] as Map<String, dynamic>;
        final u = data['jobseeker'] as Map<String, dynamic>? ??
            data['user'] as Map<String, dynamic>? ??
            data;
        UserSession().updateFromUser(u);
      }
    }

    if (!mounted) return;
    setState(() {
      _busy = false;
      _step = 2;
    });
  }

  Future<void> _saveSkillsAndContinue() async {
    final token = UserSession().token;
    if (token == null || token.isEmpty) return;

    if (_selectedSkills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pick at least one skill to improve matching.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _busy = true);
    final list = _selectedSkills.toList();
    final ids = <int>[];
    for (final name in list) {
      final id = _skillNameToId[name.toLowerCase()];
      if (id != null) ids.add(id);
    }

    Map<String, dynamic> res;
    if (ids.isNotEmpty) {
      res = await ApiService.saveJobseekerSkills(token: token, skillIds: ids);
    } else {
      res = await ApiService.updateSkills(token: token, skills: list);
    }

    if (res['success'] == true) {
      UserSession().skills = list;
      final prof = await ApiService.getUser(token);
      if (prof['success'] == true && prof['data'] is Map<String, dynamic>) {
        final data = prof['data'] as Map<String, dynamic>;
        final u = data['jobseeker'] as Map<String, dynamic>? ??
            data['user'] as Map<String, dynamic>? ??
            data;
        UserSession().updateFromUser(u);
      }
    }

    if (!mounted) return;
    setState(() {
      _busy = false;
      _step = 3;
    });
  }

  Future<void> _completeOnboarding() async {
    await OnboardingPrefs.setPostAuthComplete();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomePage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _step > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
                onPressed: _busy ? null : () => setState(() => _step--),
              )
            : null,
        title: Text(
          'Step ${_step + 1} of 5',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF64748B),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: _buildStep(),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _stepGoal();
      case 1:
        return _stepLocationExperience();
      case 2:
        return _stepSkills();
      case 3:
        return _stepNotifications();
      default:
        return _stepTour();
    }
  }

  Widget _stepGoal() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'What are you looking for?',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'We’ll tailor job suggestions and reminders to your goal.',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: const Color(0xFF64748B),
            height: 1.45,
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: ListView.separated(
            itemCount: _goals.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final g = _goals[i];
              final sel = _goal == g;
              return Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: () => setState(() => _goal = g),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: sel ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                        width: sel ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          sel ? Icons.check_circle_rounded : Icons.circle_outlined,
                          color: sel ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            g,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _busy
              ? null
              : () {
                  if (_goal == null) {
                    setState(() => _goal = _goals.first);
                  }
                  setState(() => _step = 1);
                },
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Text('Continue', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _stepLocationExperience() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Location & background',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Helps us show realistic listings and workshops near you.',
          style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF64748B),
              height: 1.45),
        ),
        const SizedBox(height: 20),
        if (_locationLoading) ...[
          const LinearProgressIndicator(color: Color(0xFF2563EB), minHeight: 3),
          const SizedBox(height: 12),
        ],
        if (_locationError != null) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFCA5A5)),
            ),
            child: Text(
              _locationError!,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF991B1B),
              ),
            ),
          ),
        ],
        _selectorField(
          label: 'Province',
          icon: Icons.location_city_outlined,
          value: _provinceName,
          placeholder: _provinces.isEmpty ? 'Loading provinces...' : 'Select province',
          enabled: !_busy && _provinces.isNotEmpty,
          onTap: () async {
            final picked = await _pickOption(title: 'Select Province', options: _provinces);
            if (picked == null) return;
            await _onProvinceChanged(picked['code']);
            if (!mounted) return;
            setState(() {});
          },
        ),
        const SizedBox(height: 12),
        _selectorField(
          label: 'City / Municipality',
          icon: Icons.location_on_outlined,
          value: _cityName,
          placeholder: _provinceCode == null
              ? 'Select province first'
              : (_cities.isEmpty ? 'Loading cities...' : 'Select city / municipality'),
          enabled: !_busy && _provinceCode != null && _cities.isNotEmpty,
          onTap: () async {
            final picked = await _pickOption(
              title: 'Select City / Municipality',
              options: _cities,
            );
            if (picked == null) return;
            await _onCityChanged(picked['code']);
            if (!mounted) return;
            setState(() {});
          },
        ),
        const SizedBox(height: 12),
        _selectorField(
          label: 'Barangay',
          icon: Icons.home_work_outlined,
          value: _barangayName,
          placeholder: _cityCode == null
              ? 'Select city first'
              : (_barangays.isEmpty ? 'Loading barangays...' : 'Select barangay'),
          enabled: !_busy && _cityCode != null && _barangays.isNotEmpty,
          onTap: () async {
            final picked = await _pickOption(title: 'Select Barangay', options: _barangays);
            if (picked == null) return;
            setState(() {
              _barangayCode = picked['code'];
              _barangayName = picked['name'];
            });
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _streetController,
          decoration: InputDecoration(
            labelText: 'Street / House No. / Landmark (Optional)',
            prefixIcon: const Icon(Icons.pin_drop_outlined, color: Color(0xFF2563EB)),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _experienceLevel,
          decoration: InputDecoration(
            labelText: 'Education / experience',
            prefixIcon: const Icon(Icons.school_outlined, color: Color(0xFF2563EB)),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
          items: _experienceLevels
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) => setState(() => _experienceLevel = v),
        ),
        const Spacer(),
        FilledButton(
          onPressed: _busy
              ? null
              : () {
                  if (_provinceCode == null || _cityCode == null || _barangayCode == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Please select province, city/municipality, and barangay.',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }
                  _saveProfileAndContinue();
                },
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: _busy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text('Continue', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _stepSkills() {
    if (_skillsLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)));
    }

    final flat = <String>[];
    if (_skillCatalog.isEmpty) {
      flat.addAll(_fallbackSkills);
    } else {
      for (final list in _skillCatalog.values) {
        flat.addAll(list);
      }
      flat.sort();
    }
    final visibleSkills = _visibleSkills(flat);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Your top skills',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Pick at least one — we use these for job match scores.',
          style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF64748B),
              height: 1.45),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _skillSearchController,
          decoration: InputDecoration(
            hintText: 'Search skills (e.g. customer service, welding)',
            prefixIcon: const Icon(Icons.search_rounded),
            filled: true,
            fillColor: Colors.white,
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
              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.6),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: visibleSkills.map((s) {
                final sel = _selectedSkills.contains(s);
                return FilterChip(
                  label: Text(s),
                  selected: sel,
                  onSelected: (v) {
                    setState(() {
                      if (v) {
                        if (_selectedSkills.length < 12) _selectedSkills.add(s);
                      } else {
                        _selectedSkills.remove(s);
                      }
                    });
                  },
                  selectedColor: const Color(0xFFDBEAFE),
                  checkmarkColor: const Color(0xFF2563EB),
                    labelStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        if (_skillQuery.isEmpty && flat.length > 120) ...[
          const SizedBox(height: 6),
          Text(
            'Showing top 120 skills. Use search to find more.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 12.5, color: const Color(0xFF64748B)),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          '${_selectedSkills.length} selected',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF64748B)),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _busy ? null : _saveSkillsAndContinue,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: _busy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text('Continue', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _stepNotifications() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Icon(Icons.notifications_active_rounded,
            size: 72, color: const Color(0xFF2563EB).withOpacity(0.9)),
        const SizedBox(height: 20),
        Text(
          'Stay in the loop',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Turn on notifications in your device settings so we can alert you about new job matches, event reminders, and messages from PESO.\n\nYou can change this anytime in system settings.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 14,
            height: 1.5,
            color: const Color(0xFF64748B),
          ),
        ),
        const Spacer(),
        FilledButton(
          onPressed: _busy ? null : () => setState(() => _step = 4),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Text('Continue', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _stepTour() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'You’re all set!',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Here’s where to find things:',
          style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF64748B)),
        ),
        const SizedBox(height: 20),
        _tourRow(Icons.home_rounded, 'Home', 'Jobs, search, and apply.'),
        _tourRow(Icons.event_rounded, 'Events', 'Floating button — workshops & job fairs.'),
        _tourRow(Icons.map_rounded, 'Map', 'Explore employers and locations.'),
        _tourRow(Icons.person_rounded, 'Profile', 'Resume, skills, and documents.'),
        const Spacer(),
        FilledButton(
          onPressed: _busy ? null : _completeOnboarding,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: _busy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text('Go to Home', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _tourRow(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF2563EB), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700, fontSize: 16, color: const Color(0xFF0F172A))),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: GoogleFonts.poppins(
                        fontSize: 13, height: 1.4, color: const Color(0xFF64748B))),
              ],
            ),
          ),
        ],
      ),
    );
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
                height: 430,
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
    ).whenComplete(queryController.dispose);
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
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF2563EB)),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.6),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                display.isNotEmpty ? display : placeholder,
                style: TextStyle(
                  color: display.isNotEmpty ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
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
}
