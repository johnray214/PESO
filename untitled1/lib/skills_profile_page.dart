import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:showcaseview/showcaseview.dart';
import 'api_service.dart';
import 'user_session.dart';
import 'job_models.dart';
import 'job_action_service.dart';
import 'home_pages.dart'; // Added for map navigation notifiers
import 'skill_match_utils.dart';
import 'my_documents_page.dart';
import 'main.dart';
import 'onboarding_prefs.dart';
import 'l10n/app_localizations.dart';

class SkillsProfilePage extends StatefulWidget {
  const SkillsProfilePage({super.key});

  @override
  State<SkillsProfilePage> createState() => _SkillsProfilePageState();
}

class _SkillsProfilePageState extends State<SkillsProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<String> _selectedSkills = [];
  Map<String, List<String>> _skillCatalog = {};
  Map<String, int> _skillNameToId = {};
  bool _isLoadingCatalog = true;
  bool _isSaving = false;
  bool _hasChanges = false;
  List<String> _lastSavedSkills = [];
  /// When false, selected chips have no remove (X); browse/search add is locked too.
  /// New users with no skills yet can always browse/add (`_canChangeSkills`).
  bool _editingSelectedSkills = false;

  List<Job> _matchedJobs = [];
  bool _isLoadingMatched = false;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _skillsScrollController = ScrollController();
  Timer? _searchDebounce;
  String _searchQuery = '';
  String? _activeCategoryFilter;

  // Job Matches sorting & filtering
  String _sortOption = 'Best Match';
  final Set<String> _selectedEmploymentTypes = <String>{};
  final Set<String> _selectedSkillFilters = <String>{};
  String _skillFilterQuery = '';

  static const List<String> _sortOptions = [
    'Best Match',
    'Latest',
  ];
  static const List<String> _employmentTypes = [
    'Full-time',
    'Part-time',
    'Contract',
    'Freelance',
  ];

  final Map<String, GlobalKey> _categoryKeys = {};

  // ─── Guided tutorial (action-based) ────────────────────────────────────────
  bool _skillsGuideDone = false;
  bool _skillsGuideActive = false;
  int _skillsGuideStep = 0;
  final GlobalKey _guideSearchKey = GlobalKey();
  final GlobalKey _guideEditKey = GlobalKey();
  final GlobalKey _guideSaveKey = GlobalKey();
  final GlobalKey _guideMatchesTabKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onSkillsProfileTabChanged);
    _selectedSkills = List.from(UserSession().skills);
    _lastSavedSkills = List.from(_selectedSkills);
    _loadSavedSkills();
    _loadSkillCatalog();
    if (_selectedSkills.isNotEmpty) {
      _loadMatchedJobs();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeStartSkillsGuide();
    });
  }

  Future<void> _maybeStartSkillsGuide() async {
    final token = UserSession().token;
    final done = await OnboardingPrefs.isSkillsProfileGuideDone(token: token);
    if (!mounted) return;
    setState(() => _skillsGuideDone = done);

    // Auto-trigger only for newly created accounts (explicit pending flag set on registration).
    if (done) return;
    final pending =
        await OnboardingPrefs.isSkillsProfileGuidePending(token: token);
    if (!mounted || !pending) return;
    _startSkillsGuide(force: false);
  }

  void _startSkillsGuide({required bool force}) {
    if (!mounted) return;
    if (force && _skillsGuideActive) {
      _showToast(
        'Finish the tutorial first.',
        type: ToastType.info,
      );
      return;
    }
    _skillsScrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
    setState(() {
      _skillsGuideActive = true;
      _skillsGuideStep = 0;
      _tabController.index = 0;
      _editingSelectedSkills = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showCurrentGuideStep();
    });
  }

  void _showCurrentGuideStep() {
    if (!_skillsGuideActive || !mounted) return;
    switch (_skillsGuideStep) {
      case 0:
        // Step 0: Search bar — tap search bar to continue
        ShowcaseView.get().startShowCase([_guideSearchKey]);
        break;
      case 1:
        // Step 1: Edit button — user MUST click to advance (handled by onTargetClick)
        ShowcaseView.get().startShowCase([_guideEditKey]);
        break;
      case 2:
        // Step 2: No highlight. Show a floating instruction card while user browses/adds skills.
        ShowcaseView.get().dismiss();
        break;
      case 3:
        // Step 3: Save button — user MUST click to advance
        ShowcaseView.get().startShowCase([_guideSaveKey]);
        break;
      case 4:
        // Step 4: Job Matches tab — user MUST click to complete
        ShowcaseView.get().startShowCase([_guideMatchesTabKey]);
        break;
    }
  }

  void _advanceGuideStep() {
    if (!mounted || !_skillsGuideActive) return;
    setState(() => _skillsGuideStep++);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showCurrentGuideStep();
    });
  }

  Future<void> _completeSkillsGuide() async {
    final token = UserSession().token;
    await OnboardingPrefs.setSkillsProfileGuideDone(token: token);
    await OnboardingPrefs.clearSkillsProfileGuidePending(token: token);
    if (!mounted) return;
    setState(() {
      _skillsGuideDone = true;
      _skillsGuideActive = false;
    });
    ShowcaseView.get().dismiss();
  }

  bool _isActionAllowedDuringGuide(String action) {
    if (!_skillsGuideActive) return true;
    switch (action) {
      case 'edit':
        return _skillsGuideStep == 1;
      case 'open_category':
        return _skillsGuideStep == 2;
      case 'add_skill':
        return _skillsGuideStep == 2;
      case 'save':
        return _skillsGuideStep == 3;
      case 'job_matches':
        return _skillsGuideStep == 4;
      default:
        return false;
    }
  }

  void _showToast(String message, {ToastType type = ToastType.info}) {
    if (!mounted) return;
    CustomToast.show(
      context,
      message: message,
      type: type,
      duration: const Duration(milliseconds: 1300),
    );
  }

  bool _hasSameSkillsAsSaved() {
    final current = _selectedSkills.toSet();
    final saved = _lastSavedSkills.toSet();
    if (current.length != saved.length) return false;
    return current.containsAll(saved);
  }

  Future<bool> _confirmLeaveWithUnsavedChanges() async {
    if (!_hasChanges) return true;
    final shouldLeave = await showAppDialog<bool>(
      context: context,
      type: AppDialogType.warning,
      icon: Icons.warning_amber_rounded,
      title: 'Unsaved Changes',
      message:
          'You have unsaved skill changes. Are you sure you want to go back without saving?',
      confirmLabel: 'Leave',
      onConfirm: () => Navigator.of(context).pop(true),
      onCancel: () => Navigator.of(context).pop(false),
    );
    return shouldLeave == true;
  }

  void _onSkillsProfileTabChanged() {
    if (!_skillsGuideActive) return;
    if (_tabController.index != 1) return;
    if (_isActionAllowedDuringGuide('job_matches')) return;
    // TabBar ink targets the full tab slot; expand the tab body (SizedBox.expand) so
    // AbsorbPointer covers it — this listener is a backup if the index still changes.
    _tabController.index = 0;
    _showToast('Follow the tutorial steps first.', type: ToastType.info);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onSkillsProfileTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    _skillsScrollController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadSkillCatalog() async {
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

        final key = name.toLowerCase();
        nameToId[key] = id;
        byCategory.putIfAbsent(category, () => <String>[]).add(name);
      }

      // Only keep already-selected skills that exist in the catalog.
      final filteredSelected = _selectedSkills
          .where((s) => nameToId.containsKey(s.toLowerCase()))
          .toList();

      setState(() {
        _skillCatalog = byCategory;
        _skillNameToId = nameToId;
        _selectedSkills = filteredSelected;
        _isLoadingCatalog = false;
        _hasChanges = false;
      });
    } else {
      setState(() => _isLoadingCatalog = false);
    }
  }

  Future<void> _loadSavedSkills() async {
    final token = UserSession().token;
    if (token == null || token.isEmpty) return;

    final result = await ApiService.getJobseekerSkills(token);
    if (!mounted) return;

    if (result['success'] == true) {
      final list = result['data'] as List<dynamic>? ?? [];
      final names = list
          .map((e) => (e as Map<String, dynamic>)['name']?.toString().trim() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();

      setState(() {
        _selectedSkills = names;
        _lastSavedSkills = List.from(names);
        _hasChanges = false;
      });

      // Keep session copy in sync so other pages can use it.
      UserSession().skills = List<String>.from(names);

      if (_selectedSkills.isNotEmpty) {
        _loadMatchedJobs();
      }
    }
  }

  Future<void> _loadMatchedJobs() async {
    final token = UserSession().token;
    if (token == null || token.isEmpty) return;

    setState(() => _isLoadingMatched = true);
    final result = await ApiService.getMatchedJobs(
      token,
      skills: _selectedSkills,
    );
    if (!mounted) return;

    if (result['success'] == true) {
      final list = result['data'] as List<dynamic>? ?? [];
      setState(() {
        _matchedJobs = list.map((e) => Job.fromJson(e as Map<String, dynamic>)).toList();
        _isLoadingMatched = false;
      });
    } else {
      setState(() => _isLoadingMatched = false);
    }
  }

  List<Job> get _sortedFilteredMatchedJobs {
    List<Job> jobs = _matchedJobs.where((job) {
      String normType(String s) => s.toLowerCase().replaceAll(' ', '').trim();
      final matchesType = _selectedEmploymentTypes.isEmpty ||
          _selectedEmploymentTypes.map(normType).contains(normType(job.employmentType));
      final matchesSkill = _selectedSkillFilters.isEmpty ||
          _selectedSkillFilters.any((selected) =>
              job.skills.any((s) => s.toLowerCase() == selected.toLowerCase()));
      return matchesType && matchesSkill;
    }).toList();

    switch (_sortOption) {
      case 'Best Match':
        jobs.sort((a, b) => b.matchPercentage.compareTo(a.matchPercentage));
        break;
      case 'Latest':
        jobs.sort((a, b) => b.postedDate.compareTo(a.postedDate));
        break;
    }
    return jobs;
  }

  bool get _hasActiveMatchFilters =>
      _selectedEmploymentTypes.isNotEmpty || _selectedSkillFilters.isNotEmpty;

  List<String> get _availableMatchSkillFilters {
    final unique = <String>{};
    for (final job in _matchedJobs) {
      for (final skill in job.skills) {
        final s = skill.trim();
        if (s.isNotEmpty) unique.add(s);
      }
    }
    final list = unique.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list.take(30).toList();
  }

  List<String> get _visibleMatchSkillFilters {
    final q = _skillFilterQuery.trim().toLowerCase();
    if (q.isEmpty) return _availableMatchSkillFilters;
    return _availableMatchSkillFilters
        .where((s) => s.toLowerCase().contains(q))
        .toList();
  }

  void _showMatchSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Sort By',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 16),
              ...(_sortOptions.map((opt) {
                final isSelected = _sortOption == opt;
                return GestureDetector(
                  onTap: () {
                    setState(() => _sortOption = opt);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF2563EB).withOpacity(0.08)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF2563EB)
                            : const Color(0xFFE2E8F0),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          opt,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? const Color(0xFF2563EB)
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        const Spacer(),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF2563EB),
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                );
              })),
            ],
          ),
        );
      },
    );
  }

  void _showMatchFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Text(
                        'Filter Matches',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          setSheetState(() {
                            _selectedEmploymentTypes.clear();
                            _selectedSkillFilters.clear();
                            _skillFilterQuery = '';
                          });
                          setState(() {});
                        },
                        child: const Text(
                          'Clear All',
                          style: TextStyle(
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Employment Type',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _employmentTypes.map((type) {
                      final isSelected = _selectedEmploymentTypes.contains(type);
                      return GestureDetector(
                        onTap: () {
                          setSheetState(() {
                            if (isSelected) {
                              _selectedEmploymentTypes.remove(type);
                            } else {
                              _selectedEmploymentTypes.add(type);
                            }
                          });
                          setState(() {});
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFDBEAFE)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF93C5FD)
                                  : const Color(0xFFE2E8F0),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Text(
                            type,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? const Color(0xFF1D4ED8) : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Skills',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    onChanged: (value) {
                      setSheetState(() => _skillFilterQuery = value);
                    },
                    decoration: InputDecoration(
                      hintText: 'Search skills...',
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        size: 20,
                        color: Color(0xFF94A3B8),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2563EB)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _visibleMatchSkillFilters.map((skill) {
                      final isSelected = _selectedSkillFilters.contains(skill);
                      return GestureDetector(
                        onTap: () {
                          setSheetState(() {
                            if (isSelected) {
                              _selectedSkillFilters.remove(skill);
                            } else {
                              _selectedSkillFilters.add(skill);
                            }
                          });
                          setState(() {});
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFDBEAFE)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF93C5FD)
                                  : const Color(0xFFE2E8F0),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Text(
                            skill,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? const Color(0xFF1D4ED8) : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Apply Filters',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _saveSkills() async {
    if (!_isActionAllowedDuringGuide('save')) {
      _showToast(
        'Continue the tutorial steps first.',
        type: ToastType.info,
      );
      return;
    }
    final token = UserSession().token;
    if (token == null || token.isEmpty) return;

    final currentSkills = List<String>.from(_lastSavedSkills);
    final previouslySaved = Set<String>.from(_lastSavedSkills);
    final newlyAdded = _selectedSkills
        .where((s) => !previouslySaved.contains(s))
        .toList();

    String summarize(List<String> items, {int max = 10}) {
      if (items.isEmpty) return 'None';
      final shown = items.take(max).join(', ');
      final remaining = items.length - max;
      return remaining > 0 ? '$shown, +$remaining more' : shown;
    }

    final shouldSave = await showAppDialog<bool>(
      context: context,
      type: AppDialogType.confirm,
      icon: Icons.save_rounded,
      title: 'Save Skills?',
      message:
          'Current skills (${currentSkills.length}): ${summarize(currentSkills)}\n\n'
          'Newly added (${newlyAdded.length}): ${summarize(newlyAdded)}',
      confirmLabel: S.of(context)?.saveSkills ?? 'Save Skills',
      onConfirm: () => Navigator.of(context).pop(true),
      onCancel: () => Navigator.of(context).pop(false),
    );
    if (shouldSave != true || !mounted) return;

    setState(() => _isSaving = true);

    final skillIds = _selectedSkills
        .map((name) => _skillNameToId[name.toLowerCase()])
        .whereType<int>()
        .toList();

    // If for some reason current selections are not present in the catalog,
    // don't save them as ids (prevents bad/free-text skills from entering).
    if (skillIds.isEmpty && _selectedSkills.isNotEmpty) {
      setState(() => _isSaving = false);
      if (!mounted) return;
      _showToast(
        'Please select skills from the catalog before saving.',
        type: ToastType.error,
      );
      return;
    }

    final result = await ApiService.saveJobseekerSkills(
      token: token,
      skillIds: skillIds,
    );
    if (!mounted) return;

    if (result['success'] == true) {
      // Refresh profile so UserSession().skills matches what backend stored.
      final refreshed = await ApiService.getUser(token);
      final userData = refreshed['data'] as Map<String, dynamic>? ?? {};
      if (refreshed['success'] == true) {
        UserSession().updateFromUser(userData);
        SkillMatchUtils.invalidateUserSkillsCache();
        mapUserSkillsRevisionNotifier.value++;
      }
      setState(() {
        _hasChanges = false;
        _isSaving = false;
        _editingSelectedSkills = false;
        _lastSavedSkills = List.from(_selectedSkills);
      });
      _loadMatchedJobs();
      if (mounted) {
        _showToast(
          'Skills saved! Finding matched jobs...',
          type: ToastType.success,
        );
      }
      if (_skillsGuideActive && _skillsGuideStep == 3) {
        _advanceGuideStep();
      }
    } else {
      setState(() => _isSaving = false);
      if (mounted) {
        _showToast(
          result['message'] as String? ?? 'Failed to save skills.',
          type: ToastType.error,
        );
      }
    }
  }

  /// Browse / search can change skills when empty (onboarding) or in edit mode.
  bool get _canChangeSkills =>
      _selectedSkills.isEmpty || _editingSelectedSkills;

  void _toggleSkill(String skill) {
    if (_skillsGuideActive && !_isActionAllowedDuringGuide('add_skill')) {
      _showToast('Follow the tutorial steps first.', type: ToastType.info);
      return;
    }
    if (!_canChangeSkills) return;
    if (_skillsGuideActive && _skillsGuideStep == 2 && _selectedSkills.contains(skill)) {
      _showToast('Add at least one skill to continue.', type: ToastType.info);
      return;
    }
    bool added = false;
    setState(() {
      final wasEmpty = _selectedSkills.isEmpty;
      if (_selectedSkills.contains(skill)) {
        _selectedSkills.remove(skill);
        added = false;
      } else {
        _selectedSkills.add(skill);
        added = true;
      }
      _hasChanges = !_hasSameSkillsAsSaved();
      // First pick from empty: stay in an open "picking" session so browse doesn't lock.
      if (wasEmpty && _selectedSkills.isNotEmpty) {
        _editingSelectedSkills = true;
      }
      if (_selectedSkills.isEmpty) {
        _editingSelectedSkills = false;
      }
    });
    HapticFeedback.selectionClick();
    _showToast(
      added ? '$skill added' : '$skill removed',
      type: added ? ToastType.success : ToastType.info,
    );

    // Tutorial: if we added a skill during step 2, advance to Save step
    if (_skillsGuideActive && _skillsGuideStep == 2 && added && _selectedSkills.isNotEmpty) {
      Future<void>.delayed(const Duration(milliseconds: 400), () {
        if (mounted && _skillsGuideActive && _skillsGuideStep == 2) {
          _advanceGuideStep();
        }
      });
    }
  }

  Future<void> _confirmEnableSkillEditing() async {
    if (_canChangeSkills) return;
    final shouldEdit = await showAppDialog<bool>(
      context: context,
      type: AppDialogType.confirm,
      icon: Icons.edit_rounded,
      title: 'Edit Skills?',
      message: 'Skill editing is currently disabled. Do you want to switch to edit mode?',
      confirmLabel: 'Edit',
      onConfirm: () => Navigator.of(context).pop(true),
      onCancel: () => Navigator.of(context).pop(false),
    );

    if (shouldEdit == true && mounted) {
      setState(() => _editingSelectedSkills = true);
    }
  }

  List<String> get _allCatalogSkills {
    final all = <String>{};
    for (final skills in _skillCatalog.values) {
      all.addAll(skills);
    }
    return all.toList();
  }

  /// Returns catalog entries sorted so categories containing search matches come first.
  /// Within each category, matching skills are ordered before non-matching ones.
  List<MapEntry<String, List<String>>> get _sortedFilteredCatalog {
    final q = _searchQuery.toLowerCase();
    final entries = _skillCatalog.entries
        .where((entry) => _activeCategoryFilter == null || entry.key == _activeCategoryFilter)
        .map((entry) => MapEntry<String, List<String>>(entry.key, List<String>.from(entry.value)))
        .toList();

    if (q.isEmpty) return entries;

    int skillScore(String s) {
      final k = s.toLowerCase();
      if (k.startsWith(q)) return 3;
      if (k.contains(q)) return 2;
      return 0;
    }

    int scoreEntry(MapEntry<String, List<String>> entry) {
      final cat = entry.key.toLowerCase();
      final catMatch = cat.startsWith(q)
          ? 4
          : cat.contains(q)
              ? 2
              : 0;
      final skillMatches = entry.value.map(skillScore).fold<int>(0, (a, b) => a + b);
      return catMatch + skillMatches;
    }

    for (final entry in entries) {
      entry.value.sort((a, b) {
        final byScore = skillScore(b).compareTo(skillScore(a));
        if (byScore != 0) return byScore;
        return a.toLowerCase().compareTo(b.toLowerCase());
      });
    }

    entries.sort((a, b) {
      final byScore = scoreEntry(b).compareTo(scoreEntry(a));
      if (byScore != 0) return byScore;
      return a.key.toLowerCase().compareTo(b.key.toLowerCase());
    });

    return entries.where((entry) {
      final cat = entry.key.toLowerCase();
      if (cat.startsWith(q) || cat.contains(q)) return true;
      return entry.value.any((s) => s.toLowerCase().contains(q));
    }).toList();
  }

  /// Returns flat list of catalog skills matching the search query that aren't in any visible category.
  List<String> get _searchSuggestions {
    final q = _searchQuery.toLowerCase();
    if (q.isEmpty) return [];
    final selectedSet = _selectedSkills.toSet();
    final matches = _allCatalogSkills
        .where((s) => s.toLowerCase().contains(q) && !selectedSet.contains(s))
        .toList();
    matches.sort((a, b) {
      final ak = a.toLowerCase();
      final bk = b.toLowerCase();
      final aStarts = ak.startsWith(q);
      final bStarts = bk.startsWith(q);
      if (aStarts && !bStarts) return -1;
      if (!aStarts && bStarts) return 1;
      return ak.compareTo(bk);
    });
    return matches;
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    final nextQuery = value.trim();
    _searchDebounce = Timer(const Duration(milliseconds: 150), () {
      if (!mounted || _searchQuery == nextQuery) return;
      setState(() => _searchQuery = nextQuery);
    });
  }

  @override
  Widget build(BuildContext context) {
    final jobMatchesGuideLocked =
        _skillsGuideActive && !_isActionAllowedDuringGuide('job_matches');

    return WillPopScope(
      onWillPop: _confirmLeaveWithUnsavedChanges,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () async {
              final shouldLeave = await _confirmLeaveWithUnsavedChanges();
              if (!mounted || !shouldLeave) return;
              Navigator.of(context).pop();
            },
          ),
          title: Text(
            S.of(context)?.skillsProfile ?? 'Skills Profile',
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w800,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(49),
            child: Column(
              children: [
                Container(height: 1, color: const Color(0xFFE2E8F0)),
                TabBar(
                  controller: _tabController,
                  onTap: (index) {
                    if (!_skillsGuideActive) return;
                    final canOpenMatches = index == 1 && _isActionAllowedDuringGuide('job_matches');
                    final canOpenSkills = index == 0;
                    if (canOpenMatches || canOpenSkills) return;
                    _showToast('Follow the tutorial step first.', type: ToastType.info);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      _tabController.index = 0;
                    });
                  },
                  labelColor: const Color(0xFF2563EB),
                  unselectedLabelColor: const Color(0xFF94A3B8),
                  labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                  indicatorColor: const Color(0xFF2563EB),
                  indicatorWeight: 3,
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.psychology_outlined, size: 18),
                          const SizedBox(width: 6),
                          Text(S.of(context)?.skillsTab ?? 'My Skills'),
                          if (_selectedSkills.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${_selectedSkills.length}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Tab(
                      child: AbsorbPointer(
                        absorbing: jobMatchesGuideLocked,
                        child: Opacity(
                          opacity: jobMatchesGuideLocked ? 0.45 : 1,
                          child: SizedBox.expand(
                            child: Showcase(
                              key: _guideMatchesTabKey,
                              title: 'Job Matches',
                              description:
                                  'Tap this tab after saving to view jobs matched to your skills.',
                              tooltipActions: const [],
                              disableBarrierInteraction: true,
                              disposeOnTap: true,
                              onTargetClick: () {
                                if (!_isActionAllowedDuringGuide('job_matches')) return;
                                if (_tabController.index != 1) {
                                  _tabController.animateTo(1);
                                }
                                _completeSkillsGuide();
                              },
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.work_outline_rounded, size: 18),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        S.of(context)?.jobMatchesTab ??
                                            'Job Matches',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (_matchedJobs.isNotEmpty) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color:
                                              const Color(0xFF10B981).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          '${_matchedJobs.length}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF10B981),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          physics: (_skillsGuideActive && !_isActionAllowedDuringGuide('job_matches'))
              ? const NeverScrollableScrollPhysics()
              : null,
          children: [
            _buildSkillsTab(),
            _buildMatchedJobsTab(),
          ],
        ),
      ),
    );
  }

  // ─── Skills Tab ─────────────────────────────────────────────────────────────

  Widget _buildSkillsTab() {
    final filteredCatalog = _sortedFilteredCatalog;
    final isSearching = _searchQuery.isNotEmpty;
    final suggestions = _searchSuggestions;
    final selectedSkillSet = _selectedSkills.toSet();

    return Stack(
      children: [
        Column(
          children: [
        Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFDBEAFE)),
            ),
            child: Row(
              children: [
                const Icon(Icons.tips_and_updates_outlined,
                    color: Color(0xFF2563EB)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _skillsGuideDone
                        ? (S.of(context)?.replayTourSubtitle ??
                            'Need a refresher? Replay the Skills Profile tutorial.')
                        : (Localizations.localeOf(context).languageCode == 'tl'
                            ? 'Bago ka ba? Kumpletuhin ang Profile ng Kasanayan para sa mas magandang job matches.'
                            : 'New here? Complete your Skills Profile to unlock better matches.'),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                      height: 1.25,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => _startSkillsGuide(force: true),
                  child: Text(
                    _skillsGuideDone
                        ? (S.of(context)?.replayTour ?? 'Replay')
                        : (Localizations.localeOf(context).languageCode == 'tl'
                            ? 'Simulan'
                            : 'Start'),
                  ),
                ),
              ],
            ),
          ),
        // Persistent search bar
        Showcase(
          key: _guideSearchKey,
          title: 'Search Skills',
          description: 'Use the search bar to find specific skills by keyword. Tap anywhere on the screen to continue.',
          tooltipActions: const [],
          disableBarrierInteraction: false,
          onBarrierClick: () {
            if (!mounted || !_skillsGuideActive || _skillsGuideStep != 0) return;
            _advanceGuideStep();
          },
          disposeOnTap: true,
          onTargetClick: () {
            if (!mounted || !_skillsGuideActive || _skillsGuideStep != 0) return;
            _advanceGuideStep();
          },
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: S.of(context)?.searchSkills ?? 'Search skills...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 22),
                suffixIcon: _searchQuery.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchDebounce?.cancel();
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        child: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8), size: 20),
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              ),
            ),
          ),
        ),
        Container(height: 1, color: const Color(0xFFE2E8F0)),
        if (_hasChanges)
          Container(
            width: double.infinity,
            color: const Color(0xFFFFFBEB),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Row(
              children: [
                const Icon(Icons.edit_note_rounded, size: 16, color: Color(0xFFD97706)),
                const SizedBox(width: 8),
                Text(
                  'Unsaved changes',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.orange[800],
                  ),
                ),
              ],
            ),
          ),

        Expanded(
          child: _isLoadingCatalog
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF2563EB)),
                )
              : SingleChildScrollView(
                  controller: _skillsScrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    20,
                    16,
                    20,
                    120 + MediaQuery.viewInsetsOf(context).bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Your selected skills — always visible when not searching (incl. empty state)
                      if (!isSearching) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildSectionHeader(
                                'Your Selected Skills',
                                Icons.check_circle_outline_rounded,
                                subtitle: _selectedSkills.isEmpty
                                    ? 'None yet — tap skills under Browse to add them here'
                                    : _editingSelectedSkills
                                        ? '${_selectedSkills.length} skill${_selectedSkills.length == 1 ? '' : 's'} — tap × to remove, keep browsing to add more, then tap Done'
                                        : '${_selectedSkills.length} skill${_selectedSkills.length == 1 ? '' : 's'} added · Tap Edit to change',
                              ),
                            ),
                            ...[
                              const SizedBox(width: 8),
                              Showcase(
                                key: _guideEditKey,
                                title: 'Step 1: Tap Edit',
                                description: 'Tap Edit to unlock adding/removing skills.',
                                tooltipActions: const [],
                                disableBarrierInteraction: true,
                                disposeOnTap: true,
                                onTargetClick: () {
                                  if (!mounted || !_skillsGuideActive || _skillsGuideStep != 1) return;
                                  setState(() {
                                    _editingSelectedSkills = true;
                                  });
                                  _advanceGuideStep();
                                },
                                child: TextButton.icon(
                                onPressed: () {
                                  if (_skillsGuideActive && _skillsGuideStep == 1) {
                                    setState(() {
                                      _editingSelectedSkills = true;
                                    });
                                    _advanceGuideStep();
                                  } else if (_skillsGuideActive) {
                                    _showToast('Follow the tutorial step first.', type: ToastType.info);
                                  } else {
                                    setState(() {
                                      _editingSelectedSkills = !_editingSelectedSkills;
                                    });
                                  }
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF2563EB),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                icon: Icon(
                                  _editingSelectedSkills ? Icons.check_rounded : Icons.edit_rounded,
                                  size: 18,
                                ),
                                label: Text(
                                  _editingSelectedSkills ? 'Done' : 'Edit',
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                ),
                              ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_selectedSkills.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.add_task_rounded, size: 22, color: Colors.grey[400]),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Start by adding 3-5 key skills to improve match quality. Open a category below and tap skills to add them here.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _selectedSkills.map((skill) {
                              return _SelectedSkillChip(
                                skill: skill,
                                onRemove: _editingSelectedSkills ? () => _toggleSkill(skill) : null,
                              );
                            }).toList(),
                          ),
                        const SizedBox(height: 24),
                      ],

                      // Header card (hidden while searching)
                      if (!isSearching) ...[
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2563EB).withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.auto_awesome_rounded,
                                  color: Colors.white,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      Localizations.localeOf(context).languageCode ==
                                              'tl'
                                          ? 'Buuin ang Profile ng Kasanayan'
                                          : 'Build Your Skills Profile',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      Localizations.localeOf(context)
                                                  .languageCode ==
                                              'tl'
                                          ? 'Maghanap o mag-browse ng mga kasanayan sa ibaba at hahanapan ka namin ng pinakaangkop na oportunidad sa trabaho.'
                                          : 'Search or browse skills below and we\'ll match you with the best job opportunities.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white70,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Search results summary
                      if (isSearching) ...[
                        if (_selectedSkills.isNotEmpty && !_canChangeSkills)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Material(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                child: Row(
                                  children: [
                                    const Icon(Icons.lock_outline_rounded, size: 18, color: Color(0xFF2563EB)),
                                    const SizedBox(width: 10),
                                    const Expanded(
                                      child: Text(
                                        'Editing is locked. Tap Edit to add or remove skills from search or categories.',
                                        style: TextStyle(fontSize: 12, color: Color(0xFF1E40AF), height: 1.35),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () => setState(() => _editingSelectedSkills = true),
                                      style: TextButton.styleFrom(
                                        foregroundColor: const Color(0xFF2563EB),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: const Text('Edit', style: TextStyle(fontWeight: FontWeight.w800)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        Row(
                          children: [
                            const Icon(Icons.filter_list_rounded, size: 18, color: Color(0xFF2563EB)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                                  children: [
                                    TextSpan(
                                      text: '${suggestions.length} skill${suggestions.length == 1 ? '' : 's'} ',
                                      style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                                    ),
                                    const TextSpan(text: 'matching "'),
                                    TextSpan(
                                      text: _searchQuery,
                                      style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                                    ),
                                    const TextSpan(text: '" in '),
                                    TextSpan(
                                      text: '${filteredCatalog.length} categor${filteredCatalog.length == 1 ? 'y' : 'ies'}',
                                      style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Quick-add suggestion chips when searching
                        if (suggestions.isNotEmpty) ...[
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: suggestions.take(10).map((skill) {
                              return GestureDetector(
                                onTap: _canChangeSkills ? () => _toggleSkill(skill) : null,
                                child: Opacity(
                                  opacity: _canChangeSkills ? 1 : 0.45,
                                  child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFF10B981).withOpacity(0.25)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.add_circle_outline_rounded, size: 14, color: Color(0xFF10B981)),
                                      const SizedBox(width: 6),
                                      Text(
                                        skill,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF10B981),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              );
                            }).toList(),
                          ),
                          if (!_canChangeSkills && suggestions.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            const Text(
                              'Tap Edit above to add these skills.',
                              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                            ),
                          ],
                          const SizedBox(height: 20),
                        ],
                      ],

                      // Skill categories (sorted and filtered)
                      if (!isSearching)
                        _buildSectionHeader(
                          'Browse Skills by Category',
                          Icons.category_outlined,
                          subtitle: 'Skills sourced from available job listings',
                        ),
                      if (!isSearching) const SizedBox(height: 16),
                      if (!isSearching && _skillCatalog.isNotEmpty) ...[
                        SizedBox(
                          height: 38,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: const Text('All categories'),
                                  selected: _activeCategoryFilter == null,
                                  onSelected: (_) {
                                    setState(() => _activeCategoryFilter = null);
                                  },
                                ),
                              ),
                              ..._skillCatalog.keys.map((category) {
                                final isActive = _activeCategoryFilter == category;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    label: Text(category),
                                    selected: isActive,
                                    onSelected: (_) {
                                      setState(() => _activeCategoryFilter = category);
                                      final key = _categoryKeys[category];
                                      final ctx = key?.currentContext;
                                      if (ctx != null) {
                                        WidgetsBinding.instance.addPostFrameCallback((_) {
                                          Scrollable.ensureVisible(
                                            ctx,
                                            duration: const Duration(milliseconds: 280),
                                            curve: Curves.easeOutCubic,
                                            alignment: 0.02,
                                          );
                                        });
                                      }
                                    },
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      if (isSearching && filteredCatalog.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Column(
                              children: [
                                Icon(Icons.search_off_rounded, size: 48, color: Colors.grey[300]),
                                const SizedBox(height: 12),
                                Text(
                                  'No skills found for "$_searchQuery"',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Try a different keyword',
                                  style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                                ),
                              ],
                            ),
                          ),
                        ),

                      ...(isSearching
                              ? filteredCatalog
                              : _skillCatalog.entries
                                  .where((entry) =>
                                      _activeCategoryFilter == null ||
                                      entry.key == _activeCategoryFilter)
                                  .toList())
                          .map((entry) {
                        final key = _categoryKeys.putIfAbsent(entry.key, () => GlobalKey());
                        return KeyedSubtree(
                          key: key,
                          child: _SkillCategoryCard(
                            category: entry.key,
                            skills: entry.value,
                            selectedSkillSet: selectedSkillSet,
                            onToggle: _toggleSkill,
                            onDisabledTap: _confirmEnableSkillEditing,
                            searchQuery: _searchQuery,
                            forceExpanded: isSearching,
                            allowExpandCollapse: !_skillsGuideActive || _skillsGuideStep == 2,
                            skillsEditable: _canChangeSkills,
                            onExpandedChanged: (expanded) {
                              if (!expanded) return;
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
        ),

        // Save button
        if (_hasChanges)
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: Showcase(
                  key: _guideSaveKey,
                  title: 'Step 3: Save skills',
                  description: 'Tap Save Skills to store your selected skills.',
                  tooltipActions: const [],
                  disableBarrierInteraction: true,
                  disposeOnTap: true,
                  onTargetClick: () {
                    if (!_isActionAllowedDuringGuide('save') || _isSaving) return;
                    _saveSkills();
                  },
                  child: ElevatedButton(
                  onPressed: _isSaving
                      ? null
                      : () {
                          if (_skillsGuideActive && !_isActionAllowedDuringGuide('save')) {
                            _showToast('Follow the tutorial step first.', type: ToastType.info);
                            return;
                          }
                          _saveSkills();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF2563EB).withOpacity(0.6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.save_rounded, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Save Skills & Find Matches (${_selectedSkills.length})',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                ),
                ),
              ),
            ),
          ),
      ],
    ),
        if (_skillsGuideActive && _skillsGuideStep == 2)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: IgnorePointer(
                  ignoring: true,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: const _Step2GuideFloatingCard(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, {String? subtitle}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF2563EB)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ─── Matched Jobs Tab ───────────────────────────────────────────────────────

  Widget _buildMatchedJobsTab() {
    if (_selectedSkills.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.psychology_outlined,
                  size: 40,
                  color: Color(0xFF2563EB),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Add your skills first',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Go to the "My Skills" tab and add your skills to see job matches.',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _tabController.animateTo(0),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Add Skills'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoadingMatched) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF2563EB)),
      );
    }

    if (_matchedJobs.isEmpty && !_hasChanges) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_rounded, size: 56, color: Colors.grey[300]),
              const SizedBox(height: 16),
              const Text(
                'No matches found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try adding more skills to improve your matches.',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_hasChanges) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.sync_rounded,
                  size: 40,
                  color: Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Save to update matches',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You have unsaved skill changes. Save your skills to see updated job matches.',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveSkills,
                icon: const Icon(Icons.save_rounded, size: 20),
                label: const Text('Save & Match'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final jobs = _sortedFilteredMatchedJobs;

    return Stack(
      children: [
        Column(
          children: [
        // Sort + Filter row
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Row(
            children: [
              Text(
                '${jobs.length} Match${jobs.length == 1 ? '' : 'es'}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              // Filter button
              GestureDetector(
                onTap: _showMatchFilterSheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _hasActiveMatchFilters
                        ? const Color(0xFF2563EB)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _hasActiveMatchFilters
                          ? const Color(0xFF2563EB)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        size: 16,
                        color: _hasActiveMatchFilters
                            ? Colors.white
                            : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _hasActiveMatchFilters ? 'Filtered' : 'Filter',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _hasActiveMatchFilters
                              ? Colors.white
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Sort button
              GestureDetector(
                onTap: _showMatchSortSheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _sortOption,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: Color(0xFF2563EB),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(height: 1, color: const Color(0xFFE2E8F0)),

        // Job list
        Expanded(
          child: jobs.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.filter_alt_off_rounded, size: 56, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        const Text(
                          'No matches for current filters',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try changing your sort or filter options.',
                          style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                          textAlign: TextAlign.center,
                        ),
                        if (_hasActiveMatchFilters) ...[
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedEmploymentTypes.clear();
                                _selectedSkillFilters.clear();
                                _skillFilterQuery = '';
                              });
                            },
                            child: const Text(
                              'Clear All Filters',
                              style: TextStyle(
                                color: Color(0xFF2563EB),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: const Color(0xFF2563EB),
                  onRefresh: _loadMatchedJobs,
                  child: Builder(
                    builder: (context) {
                      final normalizedUserSkills =
                          SkillMatchUtils.normalizeSkillTerms(_selectedSkills);
                      return ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                        itemCount: jobs.length,
                        itemBuilder: (context, index) {
                          return _MatchedJobCard(
                            job: jobs[index],
                            normalizedUserSkills: normalizedUserSkills,
                          );
                        },
                      );
                    },
                  ),
                ),
        ),
          ],
        ),
      ],
    );
  }
}

/// Pulsing glow + subtle vertical bob so Step 2 instructions stay noticeable without blocking taps.
class _Step2GuideFloatingCard extends StatefulWidget {
  const _Step2GuideFloatingCard();

  @override
  State<_Step2GuideFloatingCard> createState() => _Step2GuideFloatingCardState();
}

class _Step2GuideFloatingCardState extends State<_Step2GuideFloatingCard>
    with SingleTickerProviderStateMixin {
  static const Color _accent = Color(0xFF2563EB);

  late final AnimationController _motion;

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _motion,
      builder: (context, child) {
        final phase = math.sin(_motion.value * math.pi);
        final dy = -5.0 * phase;
        final glowAlpha = 0.26 + 0.14 * phase;
        final blur = 16.0 + 14.0 * phase;
        return Transform.translate(
          offset: Offset(0, dy),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: _accent.withValues(alpha: glowAlpha),
                  blurRadius: blur,
                  spreadRadius: 2,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: _accent.withValues(alpha: glowAlpha * 0.5),
                  blurRadius: blur * 1.85,
                  spreadRadius: -4,
                  offset: Offset.zero,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Step 2: Browse and add skills',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Browse any category and add at least 1 skill to continue.',
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                color: Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Selected Skill Chip ────────────────────────────────────────────────────

class _SelectedSkillChip extends StatelessWidget {
  final String skill;
  final VoidCallback? onRemove;

  const _SelectedSkillChip({required this.skill, this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2563EB).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            skill,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2563EB),
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded, size: 12, color: Color(0xFF2563EB)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Skill Category Card ────────────────────────────────────────────────────

class _SkillCategoryCard extends StatefulWidget {
  final String category;
  final List<String> skills;
  final Set<String> selectedSkillSet;
  final void Function(String) onToggle;
  final String searchQuery;
  final bool forceExpanded;
  final bool allowExpandCollapse;
  final bool skillsEditable;
  final VoidCallback? onDisabledTap;
  final ValueChanged<bool>? onExpandedChanged;

  const _SkillCategoryCard({
    required this.category,
    required this.skills,
    required this.selectedSkillSet,
    required this.onToggle,
    this.searchQuery = '',
    this.forceExpanded = false,
    this.allowExpandCollapse = true,
    this.skillsEditable = true,
    this.onDisabledTap,
    this.onExpandedChanged,
  });

  @override
  State<_SkillCategoryCard> createState() => _SkillCategoryCardState();
}

class _SkillCategoryCardState extends State<_SkillCategoryCard> {
  bool _expanded = false;

  IconData _categoryIcon(String cat) {
    switch (cat) {
      case 'IT & Software':
        return Icons.code_rounded;
      case 'Sales & Marketing':
        return Icons.storefront_rounded;
      case 'Healthcare':
        return Icons.local_hospital_rounded;
      case 'Education':
        return Icons.school_rounded;
      case 'Construction':
        return Icons.construction_rounded;
      case 'Manufacturing':
        return Icons.precision_manufacturing_rounded;
      default:
        return Icons.work_outline_rounded;
    }
  }

  Color _categoryColor(String cat) {
    switch (cat) {
      case 'IT & Software':
        return const Color(0xFF3B82F6);
      case 'Sales & Marketing':
        return const Color(0xFFF59E0B);
      case 'Healthcare':
        return const Color(0xFFEF4444);
      case 'Education':
        return const Color(0xFF8B5CF6);
      case 'Construction':
        return const Color(0xFFF97316);
      case 'Manufacturing':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.searchQuery.toLowerCase();
    final isSearching = q.isNotEmpty;
    final isExpanded = widget.forceExpanded || _expanded;

    // Sort skills: search matches first, then selected, then the rest
    final sortedSkills = List<String>.from(widget.skills);
    if (isSearching) {
      int score(String s) {
        final k = s.toLowerCase();
        if (k.startsWith(q)) return 3;
        if (k.contains(q)) return 2;
        return 0;
      }
      sortedSkills.sort((a, b) {
        final byScore = score(b).compareTo(score(a));
        if (byScore != 0) return byScore;
        final aSelected = widget.selectedSkillSet.contains(a);
        final bSelected = widget.selectedSkillSet.contains(b);
        if (aSelected && !bSelected) return -1;
        if (!aSelected && bSelected) return 1;
        return a.toLowerCase().compareTo(b.toLowerCase());
      });
    }

    final selectedInCat = widget.skills.where((s) => widget.selectedSkillSet.contains(s)).length;
    final matchingCount = isSearching
        ? widget.skills.where((s) => s.toLowerCase().contains(q)).length
        : 0;
    final color = _categoryColor(widget.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSearching && matchingCount > 0
              ? color.withOpacity(0.3)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              if (!widget.allowExpandCollapse) return;
              if (widget.forceExpanded) return;
              setState(() => _expanded = !_expanded);
              widget.onExpandedChanged?.call(_expanded);
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_categoryIcon(widget.category), color: color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.category,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          isSearching
                              ? '$matchingCount match${matchingCount == 1 ? '' : 'es'}${selectedInCat > 0 ? ' · $selectedInCat selected' : ''}'
                              : '${widget.skills.length} skills${selectedInCat > 0 ? ' · $selectedInCat selected' : ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: (isSearching && matchingCount > 0) || selectedInCat > 0
                                ? color
                                : const Color(0xFF94A3B8),
                            fontWeight: (isSearching && matchingCount > 0) || selectedInCat > 0
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!widget.forceExpanded)
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 200),
                      turns: isExpanded ? 0.5 : 0,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Colors.grey[400],
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            Container(height: 1, color: const Color(0xFFF1F5F9)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: sortedSkills.map((skill) {
                  final isSelected = widget.selectedSkillSet.contains(skill);
                  final isSearchMatch = isSearching && skill.toLowerCase().contains(q);
                  final canTap = widget.skillsEditable;
                  return GestureDetector(
                    onTap: canTap
                        ? () => widget.onToggle(skill)
                        : () => widget.onDisabledTap?.call(),
                    child: Opacity(
                      opacity: canTap ? 1.0 : 0.55,
                      child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withOpacity(0.12)
                            : isSearchMatch
                                ? const Color(0xFFFFFBEB)
                                : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? color.withOpacity(0.4)
                              : isSearchMatch
                                  ? const Color(0xFFF59E0B).withOpacity(0.4)
                                  : const Color(0xFFE2E8F0),
                          width: (isSelected || isSearchMatch) ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSelected)
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Icon(Icons.check_rounded, size: 14, color: color),
                            )
                          else if (isSearchMatch)
                            const Padding(
                              padding: EdgeInsets.only(right: 6),
                              child: Icon(Icons.add_rounded, size: 14, color: Color(0xFFF59E0B)),
                            ),
                          if (isSearchMatch && !isSelected)
                            _HighlightedText(text: skill, query: q)
                          else
                            Text(
                              skill,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                color: isSelected ? color : const Color(0xFF475569),
                              ),
                            ),
                        ],
                      ),
                    ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Search Highlight Text ──────────────────────────────────────────────────

class _HighlightedText extends StatelessWidget {
  final String text;
  final String query;

  const _HighlightedText({required this.text, required this.query});

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF475569)));
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final start = lowerText.indexOf(lowerQuery);

    if (start == -1) {
      return Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF475569)));
    }

    final end = start + query.length;
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF475569)),
        children: [
          if (start > 0) TextSpan(text: text.substring(0, start)),
          TextSpan(
            text: text.substring(start, end),
            style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFD97706), backgroundColor: Color(0xFFFEF3C7)),
          ),
          if (end < text.length) TextSpan(text: text.substring(end)),
        ],
      ),
    );
  }
}

// ─── Matched Job Card ─────────────────────────────────────────────────────────

class _MatchedJobCard extends StatelessWidget {
  final Job job;
  final Set<String> normalizedUserSkills;

  const _MatchedJobCard({
    required this.job,
    required this.normalizedUserSkills,
  });

  Future<bool> _ensureResumeReadyForApply(
      BuildContext context, JobActionService jobActionService) async {
    final hasResume = await jobActionService.hasResumeOnFile();
    if (hasResume) return true;
    if (!context.mounted) return false;

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

    if (goToDocuments == true && context.mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const MyDocumentsPage()),
      );
    }
    return false;
  }

  Future<void> _confirmAndApply(
      BuildContext context, JobActionService jobActionService) async {
    final canApply = await _ensureResumeReadyForApply(context, jobActionService);
    if (!canApply || !context.mounted) return;

    final confirmed = await showAppDialog<bool>(
      context: context,
      type: AppDialogType.confirm,
      icon: Icons.send_rounded,
      title: 'Confirm Application',
      message: 'Apply for ${job.title} at ${job.company}?',
      confirmLabel: 'Apply',
      onConfirm: () => Navigator.pop(context, true),
      onCancel: () => Navigator.pop(context, false),
    );
    if (confirmed != true || !context.mounted) return;

    final error = await jobActionService.applyToJob(job.id, job.title);
    if (!context.mounted) return;

    if (error == null) {
      CustomToast.show(
        context,
        message: 'Applied to ${job.title}!',
        type: ToastType.success,
      );
    } else {
      CustomToast.show(
        context,
        message: error,
        type: ToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final jobActionService = JobActionService();
    final isApplied = jobActionService.isApplied(job.id);
    final isSaved = jobActionService.isSaved(job.id);
    void openDetails() {
      final saved = jobActionService.isSaved(job.id);
      final applied = jobActionService.isApplied(job.id);
      showJobDetailSheet(
        context,
        job,
        isApplied: applied,
        isSaved: saved,
        onApply: () async {
          await _confirmAndApply(context, jobActionService);
        },
        onViewMap: () {
          Navigator.of(context).pop(); // Pop detail sheet
          Navigator.of(context).pop(); // Pop SkillsProfilePage to return to Home tabs
          homeNavRequestNotifier.value = 1; // Select Map tab
          mapFocusRequestNotifier.value = MapFocusRequest.fromJob(job);
        },
      );
    }

    const matchColor = Color(0xFF059669);
    const matchBg = Color(0xFFF0FDF4);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: openDetails,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Logo + Title + Match
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
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
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            job.company,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF2563EB),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Match Badge (Synced Design)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: matchBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: matchColor.withOpacity(0.2)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_rounded, size: 12, color: matchColor),
                          const SizedBox(height: 1),
                          Text(
                            '${job.matchPercentage}%',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: matchColor,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'Match',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: matchColor,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Metadata Row (Synced Design)
                Row(
                  children: [
                    Flexible(child: _buildBadgeCell(Icons.location_on_rounded, job.location)),
                    const SizedBox(width: 8),
                    _buildBadgeCell(Icons.work_rounded, job.employmentTypeLabel),
                  ],
                ),

                const SizedBox(height: 12),

                // Salary Band (Synced Design)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.payments_rounded, size: 14, color: Color(0xFF64748B)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          job.salaryDisplay,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF334155),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Skill Chips showing match state
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: job.skills.take(5).map((skill) {
                    final isMatch = SkillMatchUtils.matchesSingleSkillLabel(
                      normalizedUserSkills: normalizedUserSkills,
                      jobSkill: skill,
                    );
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isMatch
                            ? const Color(0xFF10B981).withOpacity(0.08)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isMatch
                              ? const Color(0xFF10B981).withOpacity(0.2)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isMatch)
                            const Padding(
                              padding: EdgeInsets.only(right: 4),
                              child: Icon(Icons.verified_rounded, size: 11, color: Color(0xFF10B981)),
                            ),
                          Text(
                            skill,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isMatch ? const Color(0xFF059669) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                // Footer with localized actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Save Button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => jobActionService.toggleSave(job.id),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isSaved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                            size: 18,
                            color: isSaved ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Apply Now button (opens details modal first)
                    GestureDetector(
                      onTap: openDetails,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2563EB).withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.send_rounded, size: 16, color: Colors.white),
                            const SizedBox(width: 6),
                            const Text(
                              'Apply Now',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            if (isApplied) ...[
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.check_circle_outline_rounded,
                                size: 15,
                                color: Colors.white,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, curve: Curves.easeOutQuad).slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOutQuad);
  }

  Widget _buildBadgeCell(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF64748B)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
