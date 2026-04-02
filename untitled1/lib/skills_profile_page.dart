import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'api_service.dart';
import 'user_session.dart';
import 'job_models.dart';
import 'job_action_service.dart';

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
  /// When false, selected chips have no remove (X); browse/search add is locked too.
  /// New users with no skills yet can always browse/add (`_canChangeSkills`).
  bool _editingSelectedSkills = false;

  List<Job> _matchedJobs = [];
  bool _isLoadingMatched = false;

  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _searchQuery = '';

  // Job Matches sorting & filtering
  String _sortOption = 'Best Match';
  final Set<String> _selectedEmploymentTypes = <String>{};
  final Set<String> _selectedSkillFilters = <String>{};
  String _skillFilterQuery = '';

  static const List<String> _sortOptions = [
    'Best Match',
    'Highest Salary',
    'Lowest Salary',
    'Latest',
  ];
  static const List<String> _employmentTypes = [
    'Full-time',
    'Part-time',
    'Contract',
    'Freelance',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedSkills = List.from(UserSession().skills);
    _loadSavedSkills();
    _loadSkillCatalog();
    if (_selectedSkills.isNotEmpty) {
      _loadMatchedJobs();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
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
      case 'Highest Salary':
        jobs.sort((a, b) {
          final aVal = int.tryParse(a.salaryMax.replaceAll(RegExp(r'[₱,]'), '')) ?? 0;
          final bVal = int.tryParse(b.salaryMax.replaceAll(RegExp(r'[₱,]'), '')) ?? 0;
          return bVal.compareTo(aVal);
        });
        break;
      case 'Lowest Salary':
        jobs.sort((a, b) {
          final aVal = int.tryParse(a.salaryMin.replaceAll(RegExp(r'[₱,]'), '')) ?? 0;
          final bVal = int.tryParse(b.salaryMin.replaceAll(RegExp(r'[₱,]'), '')) ?? 0;
          return aVal.compareTo(bVal);
        });
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
    final token = UserSession().token;
    if (token == null || token.isEmpty) return;

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select skills from the catalog before saving.'),
          backgroundColor: Color(0xFFEF4444),
        ),
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
      }
      setState(() {
        _hasChanges = false;
        _isSaving = false;
        _editingSelectedSkills = false;
      });
      _loadMatchedJobs();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Skills saved! Finding matched jobs...'),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } else {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] as String? ?? 'Failed to save skills.'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  /// Browse / search can change skills when empty (onboarding) or in edit mode.
  bool get _canChangeSkills =>
      _selectedSkills.isEmpty || _editingSelectedSkills;

  void _toggleSkill(String skill) {
    if (!_canChangeSkills) return;
    setState(() {
      final wasEmpty = _selectedSkills.isEmpty;
      if (_selectedSkills.contains(skill)) {
        _selectedSkills.remove(skill);
      } else {
        _selectedSkills.add(skill);
      }
      _hasChanges = true;
      // First pick from empty: stay in an open "picking" session so browse doesn't lock.
      if (wasEmpty && _selectedSkills.isNotEmpty) {
        _editingSelectedSkills = true;
      }
      if (_selectedSkills.isEmpty) {
        _editingSelectedSkills = false;
      }
    });
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
    final entries = _skillCatalog.entries.toList();

    if (q.isEmpty) return entries;

    int scoreEntry(MapEntry<String, List<String>> entry) {
      final catMatch = entry.key.toLowerCase().contains(q) ? 2 : 0;
      final skillMatches = entry.value.where((s) => s.toLowerCase().contains(q)).length;
      return catMatch + skillMatches;
    }

    entries.sort((a, b) => scoreEntry(b).compareTo(scoreEntry(a)));

    return entries.where((entry) {
      if (entry.key.toLowerCase().contains(q)) return true;
      return entry.value.any((s) => s.toLowerCase().contains(q));
    }).toList();
  }

  /// Returns flat list of catalog skills matching the search query that aren't in any visible category.
  List<String> get _searchSuggestions {
    final q = _searchQuery.toLowerCase();
    if (q.isEmpty) return [];
    final selectedSet = _selectedSkills.toSet();
    return _allCatalogSkills
        .where((s) => s.toLowerCase().contains(q) && !selectedSet.contains(s))
        .toList();
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        title: const Text(
          'Skills Profile',
          style: TextStyle(
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
                        const Text('My Skills'),
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.work_outline_rounded, size: 18),
                        const SizedBox(width: 6),
                        const Text('Job Matches'),
                        if (_matchedJobs.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.1),
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
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSkillsTab(),
          _buildMatchedJobsTab(),
        ],
      ),
    );
  }

  // ─── Skills Tab ─────────────────────────────────────────────────────────────

  Widget _buildSkillsTab() {
    final filteredCatalog = _sortedFilteredCatalog;
    final isSearching = _searchQuery.isNotEmpty;
    final suggestions = _searchSuggestions;
    final selectedSkillSet = _selectedSkills.toSet();

    return Column(
      children: [
        // Persistent search bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search skills (e.g. Flutter, Sales, Nursing...)',
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
        Container(height: 1, color: const Color(0xFFE2E8F0)),

        Expanded(
          child: _isLoadingCatalog
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF2563EB)),
                )
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
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
                            if (_selectedSkills.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _editingSelectedSkills = !_editingSelectedSkills;
                                  });
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
                                    'Your chosen skills will appear here. Open a category below and tap any skill to add it.',
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
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Build Your Skills Profile',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Search or browse skills below and we\'ll match you with the best job opportunities.',
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

                      ...(isSearching ? filteredCatalog : _skillCatalog.entries.toList()).map((entry) {
                        return _SkillCategoryCard(
                          category: entry.key,
                          skills: entry.value,
                          selectedSkillSet: selectedSkillSet,
                          onToggle: _toggleSkill,
                          searchQuery: _searchQuery,
                          forceExpanded: isSearching,
                          skillsEditable: _canChangeSkills,
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
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveSkills,
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

    return Column(
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
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    itemCount: jobs.length,
                    itemBuilder: (context, index) {
                      return _MatchedJobCard(
                        job: jobs[index],
                        userSkills: _selectedSkills,
                      );
                    },
                  ),
                ),
        ),
      ],
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
  final bool skillsEditable;

  const _SkillCategoryCard({
    required this.category,
    required this.skills,
    required this.selectedSkillSet,
    required this.onToggle,
    this.searchQuery = '',
    this.forceExpanded = false,
    this.skillsEditable = true,
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
      sortedSkills.sort((a, b) {
        final aMatch = a.toLowerCase().contains(q);
        final bMatch = b.toLowerCase().contains(q);
        if (aMatch && !bMatch) return -1;
        if (!aMatch && bMatch) return 1;
        final aSelected = widget.selectedSkillSet.contains(a);
        final bSelected = widget.selectedSkillSet.contains(b);
        if (aSelected && !bSelected) return -1;
        if (!aSelected && bSelected) return 1;
        return 0;
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
            onTap: widget.forceExpanded ? null : () => setState(() => _expanded = !_expanded),
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
                    onTap: canTap ? () => widget.onToggle(skill) : null,
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
  final List<String> userSkills;

  const _MatchedJobCard({required this.job, required this.userSkills});

  @override
  Widget build(BuildContext context) {
    final jobActionService = JobActionService();
    final percentage = job.matchPercentage;
    final isApplied = jobActionService.isApplied(job.id);
    final isSaved = jobActionService.isSaved(job.id);

    const matchColor = Color(0xFF059669);
    const matchBg = Color(0xFFF0FDF4);

    final userSkillsLower = userSkills.map((s) => s.toLowerCase()).toSet();

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
          onTap: () {
            showJobDetailSheet(
              context,
              job,
              isApplied: isApplied,
              isSaved: isSaved,
              onApply: () async {
                 // confirm flow...
              },
            );
          },
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
                      child: CompanyLogoBox(job: job, size: 52, boxShadow: const []),
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
                    _buildBadgeCell(Icons.work_rounded, job.employmentType),
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
                          '${job.salaryMin} - ${job.salaryMax}',
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
                    final isMatch = userSkillsLower.contains(skill.toLowerCase());
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
                    // Apply Button
                    GestureDetector(
                      onTap: isApplied ? null : () {}, // confirm flow...
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isApplied ? const Color(0xFF10B981) : const Color(0xFF2563EB),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: (isApplied ? const Color(0xFF10B981) : const Color(0xFF2563EB)).withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isApplied ? Icons.check_circle_outline_rounded : Icons.arrow_forward_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isApplied ? 'Applied' : 'Apply',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
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
