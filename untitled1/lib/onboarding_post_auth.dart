import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
  final _locationController = TextEditingController(text: 'Santiago City, Isabela');
  String? _experienceLevel;
  final Set<String> _selectedSkills = {};
  Map<String, List<String>> _skillCatalog = {};
  final Map<String, int> _skillNameToId = {};
  bool _skillsLoading = true;

  static const _goals = [
    'Full-time work',
    'Part-time / flexible',
    'First job / fresh grad',
    'Returning to work',
    'Contract / project',
  ];

  static const _experienceLevels = [
    'High school',
    'Vocational / technical',
    'College undergraduate',
    'College graduate',
    'With prior work experience',
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

  @override
  void initState() {
    super.initState();
    _experienceLevel = _experienceLevels[3];
    _loadSkills();
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

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _saveProfileAndContinue() async {
    final token = UserSession().token;
    if (token == null || token.isEmpty) return;

    setState(() => _busy = true);
    final goal = _goal ?? _goals.first;
    final loc = _locationController.text.trim();
    final exp = _experienceLevel ?? _experienceLevels.first;

    final res = await ApiService.updateProfile(
      token: token,
      jobExperience: 'Seeking: $goal',
      educationLevel: exp,
      cityName: loc.isNotEmpty ? loc : 'Santiago City',
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
        TextField(
          controller: _locationController,
          decoration: InputDecoration(
            labelText: 'City / municipality',
            prefixIcon: const Icon(Icons.location_on_outlined, color: Color(0xFF2563EB)),
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
          onPressed: _busy ? null : _saveProfileAndContinue,
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
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: flat.map((s) {
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
}
