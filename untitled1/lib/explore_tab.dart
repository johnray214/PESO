import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'api_service.dart';
import 'event_models.dart';
import 'user_session.dart';
import 'job_models.dart';
import 'job_action_service.dart';
import 'home_pages.dart';
import 'skill_match_utils.dart';
import 'micro_interactions.dart';
import 'my_documents_page.dart';
import 'main.dart';

/// Primary brand blue (matches Explore header gradient mid-stop).
const Color _kExplorePrimaryBlue = Color(0xFF2563EB);

class ExploreTab extends StatefulWidget {
  const ExploreTab({super.key});

  @override
  State<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<ExploreTab>
    with AutomaticKeepAliveClientMixin {
  bool _isLoading = false;
  String? _errorMessage;

  /// One successful load per app process; skip auto fetches after that.
  bool _exploreSessionDataLoaded = false;

  bool _exploreFetchInFlight = false;

  bool _resolvingCompanySheet = false;
  bool _eventsLoaded = false;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final JobActionService _jobActionService = JobActionService();

  // Snapshot stats
  int _newJobsThisWeek = 0;
  int _activeEmployers = 0;
  int _totalOpenPositions = 0;

  // Top hiring companies
  List<Map<String, dynamic>> _topCompanies = [];

  // In-demand skills
  List<Map<String, dynamic>> _inDemandSkills = [];

  /// Nearest calendar day with an upcoming/ongoing event; all events on that day.
  List<PesoEvent> _nearestDayEvents = [];

  /// Employer industry (BPO, Retail, …) when API provides it.
  List<Map<String, dynamic>> _industries = [];

  // Recent featured jobs
  List<Job> _featuredJobs = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    activeHomeTabIndexNotifier.addListener(_onMainTabChanged);
    _jobActionService.addListener(_onJobActionsChanged);
    if (activeHomeTabIndexNotifier.value == 1) {
      _scheduleExploreSessionLoadIfNeeded();
    }
  }

  @override
  void dispose() {
    activeHomeTabIndexNotifier.removeListener(_onMainTabChanged);
    _jobActionService.removeListener(_onJobActionsChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onJobActionsChanged() {
    if (mounted) setState(() {});
  }

  /// Explore tab index is 1. Load at most once per app session unless [userInitiated].
  void _onMainTabChanged() {
    if (activeHomeTabIndexNotifier.value == 1) {
      _scheduleExploreSessionLoadIfNeeded();
    }
  }

  void _scheduleExploreSessionLoadIfNeeded() {
    if (_exploreFetchInFlight) return;
    if (_exploreSessionDataLoaded) return;
    unawaited(_loadExploreData());
  }

  /// [userInitiated] bypasses the one-shot session guard (Retry button).
  Future<void> _loadExploreData({
    bool silent = false,
    bool userInitiated = false,
  }) async {
    if (_exploreSessionDataLoaded && !userInitiated) return;
    if (_exploreFetchInFlight) return;

    _exploreFetchInFlight = true;
    try {
      if (!silent) {
        if (mounted) {
          setState(() {
            _isLoading = true;
            _errorMessage = null;
          });
        }
      }

      Map<String, dynamic> result;
      try {
        result = await ApiService.getExploreData();
      } catch (_) {
        if (mounted && !silent) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Connection error';
          });
        }
        return;
      }

      if (!mounted) return;

      var ok = false;
      if (result['success'] == true) {
        final data = result['data'] as Map<String, dynamic>? ?? {};

        final snapshot = data['snapshot'] as Map<String, dynamic>? ?? {};
        _newJobsThisWeek =
            (snapshot['new_jobs_this_week'] as num?)?.toInt() ?? 0;
        _activeEmployers = (snapshot['active_employers'] as num?)?.toInt() ?? 0;
        _totalOpenPositions =
            (snapshot['total_open_positions'] as num?)?.toInt() ?? 0;

        final companies = data['top_companies'] as List<dynamic>? ?? [];
        _topCompanies = companies.cast<Map<String, dynamic>>();

        final skills = data['in_demand_skills'] as List<dynamic>? ?? [];
        _inDemandSkills = skills.cast<Map<String, dynamic>>();

        final industries = data['industries'] as List<dynamic>? ?? [];
        _industries = industries.cast<Map<String, dynamic>>();

        final featured = data['featured_jobs'] as List<dynamic>? ?? [];
        _featuredJobs = featured
            .map((j) => Job.fromJson(j as Map<String, dynamic>))
            .toList();

        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = null;
          });
        }
        ok = true;
      } else {
        ok = await _buildFromExistingEndpoints(silent: silent);
      }

      if (!mounted) return;
      if (ok) {
        _exploreSessionDataLoaded = true;
        setState(() => _eventsLoaded = false);
        unawaited(_loadNearestDayEvents());
      }
    } finally {
      _exploreFetchInFlight = false;
    }
  }

  Future<bool> _buildFromExistingEndpoints({bool silent = false}) async {
    try {
      final jobsResult = await ApiService.getJobListings(page: 1);
      if (!mounted) return false;

      if (jobsResult['success'] == true) {
        final jobsList = jobsResult['data'] as List<dynamic>? ?? [];
        final meta = jobsResult['meta'] as Map<String, dynamic>? ?? {};
        final total = (meta['total'] as num?)?.toInt() ?? jobsList.length;

        final jobs = jobsList
            .map((j) => Job.fromJson(j as Map<String, dynamic>))
            .toList();

        // Build snapshot
        final now = DateTime.now();
        final weekAgo = now.subtract(const Duration(days: 7));
        _newJobsThisWeek =
            jobs.where((j) => j.postedDate.isAfter(weekAgo)).length;
        _totalOpenPositions = total;

        // Build top companies from job data
        final companyMap = <String, Map<String, dynamic>>{};
        for (final job in jobs) {
          companyMap.putIfAbsent(
              job.company,
              () => {
                    'name': job.company,
                    'initial': job.companyInitial,
                    'photo_url': job.companyPhotoPath,
                    'job_count': 0,
                  });
          companyMap[job.company]!['job_count'] =
              (companyMap[job.company]!['job_count'] as int) + 1;
        }
        _topCompanies = companyMap.values.toList()
          ..sort((a, b) =>
              (b['job_count'] as int).compareTo(a['job_count'] as int));
        if (_topCompanies.length > 10) {
          _topCompanies = _topCompanies.sublist(0, 10);
        }
        _activeEmployers = companyMap.length;

        // Build in-demand skills
        final skillCount = <String, int>{};
        for (final job in jobs) {
          for (final skill in job.skills) {
            skillCount[skill] = (skillCount[skill] ?? 0) + 1;
          }
        }
        final skillEntries = skillCount.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        _inDemandSkills = skillEntries
            .take(15)
            .map((e) => {'name': e.key, 'job_count': e.value})
            .toList();

        _industries = [];

        // Featured = most recent
        _featuredJobs = jobs.take(5).toList();

        setState(() {
          _isLoading = false;
          _errorMessage = null;
        });
        return true;
      } else {
        if (!silent && mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage =
                jobsResult['message'] as String? ?? 'Failed to load';
          });
        }
        return false;
      }
    } catch (e) {
      if (mounted && !silent) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Connection error';
        });
      }
      return false;
    }
  }

  Future<void> _loadNearestDayEvents() async {
    try {
      final res = await ApiService.getEvents();
      if (!mounted) return;
      if (res['success'] != true) {
        setState(() {
          _nearestDayEvents = [];
          _eventsLoaded = true;
        });
        return;
      }
      final raw = res['data'] as List<dynamic>? ?? [];
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final eligible = <PesoEvent>[];
      for (final item in raw) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final status = (map['status'] ?? '').toString().toLowerCase();
        if (status != 'upcoming' && status != 'ongoing') continue;
        final e = PesoEvent.fromJson(map, isRegistered: false);
        final day =
            DateTime(e.eventDate.year, e.eventDate.month, e.eventDate.day);
        if (day.isBefore(today)) continue;
        eligible.add(e);
      }
      if (eligible.isEmpty) {
        setState(() {
          _nearestDayEvents = [];
          _eventsLoaded = true;
        });
        return;
      }

      DateTime? nearestDay;
      for (final e in eligible) {
        final day =
            DateTime(e.eventDate.year, e.eventDate.month, e.eventDate.day);
        if (nearestDay == null || day.isBefore(nearestDay)) {
          nearestDay = day;
        }
      }
      if (nearestDay == null) {
        setState(() {
          _nearestDayEvents = [];
          _eventsLoaded = true;
        });
        return;
      }

      var sameDay = eligible.where((e) {
        final day =
            DateTime(e.eventDate.year, e.eventDate.month, e.eventDate.day);
        return day.year == nearestDay!.year &&
            day.month == nearestDay.month &&
            day.day == nearestDay.day;
      }).toList();

      sameDay.sort((a, b) {
        final ta = a.eventTime ?? '';
        final tb = b.eventTime ?? '';
        final byTime = ta.compareTo(tb);
        if (byTime != 0) return byTime;
        return a.title.compareTo(b.title);
      });

      setState(() {
        _nearestDayEvents = sameDay;
        _eventsLoaded = true;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _nearestDayEvents = [];
          _eventsLoaded = true;
        });
      }
    }
  }

  Future<void> _openExploreCompanyJobs(
      String companyName, String? photoUrl) async {
    final name = companyName.trim();
    if (name.isEmpty || _resolvingCompanySheet) return;
    setState(() => _resolvingCompanySheet = true);
    try {
      final business = await _resolveExploreCompany(name, photoUrl);
      if (!mounted) return;
      if (business == null || business.availableJobs.isEmpty) {
        CustomToast.show(
          context,
          message: 'No open jobs found for this employer.',
          type: ToastType.info,
        );
        return;
      }
      showEmployerJobsMapStyleSheet(context, business: business);
    } finally {
      if (mounted) setState(() => _resolvingCompanySheet = false);
    }
  }

  /// Prefer map employers payload (same jobs as Map tab); else search job listings.
  Future<Business?> _resolveExploreCompany(
      String companyName, String? photoUrl) async {
    final fromMap = await _tryBusinessFromMapEmployers(companyName);
    if (fromMap != null && fromMap.availableJobs.isNotEmpty) {
      return fromMap;
    }
    return _businessFromJobListingsForCompany(companyName, photoUrl);
  }

  Future<Business?> _tryBusinessFromMapEmployers(String companyName) async {
    final normalized = SkillMatchUtils.normalizeCompanyName(companyName);
    try {
      final response = await ApiService.getMapEmployers(limit: 400);
      if (response['success'] != true) return null;
      final raw = response['data'] as List<dynamic>? ?? [];
      for (final item in raw) {
        final emp = item as Map<String, dynamic>;
        final cn = emp['company_name']?.toString() ?? 'Employer';
        if (SkillMatchUtils.normalizeCompanyName(cn) != normalized) continue;

        final lat = switch (emp['latitude']) {
          final num v => v.toDouble(),
          final String v => double.tryParse(v),
          _ => null,
        };
        final lng = switch (emp['longitude']) {
          final num v => v.toDouble(),
          final String v => double.tryParse(v),
          _ => null,
        };
        if (lat == null || lng == null) continue;

        final photoUrlRaw = emp['photo_url']?.toString().trim();
        final photoRaw = emp['photo']?.toString().trim();
        final imageUrl = (photoUrlRaw != null && photoUrlRaw.isNotEmpty)
            ? photoUrlRaw
            : (photoRaw != null && photoRaw.isNotEmpty)
                ? (ApiService.storageOrAbsoluteUrl(photoRaw) ?? '')
                : '';
        final address = emp['address_full']?.toString();
        final city = emp['city']?.toString();
        final province = emp['province']?.toString();
        final locationText = [address, city, province]
            .where((s) => s != null && s.trim().isNotEmpty)
            .cast<String>()
            .join(', ');

        final jobsRaw = emp['job_listings'] as List<dynamic>? ?? [];
        final jobs = jobsRaw.map((j) {
          final map = j as Map<String, dynamic>;
          return Job.fromJson({
            ...map,
            if (imageUrl.isNotEmpty) 'employer_photo_url': imageUrl,
            'employer': {
              'company_name': cn,
              if (photoRaw != null && photoRaw.isNotEmpty) 'photo': photoRaw,
            },
          });
        }).toList();

        return Business(
          id: 'emp_${emp['id']}',
          name: cn,
          description: locationText.isNotEmpty
              ? locationText
              : (emp['tagline']?.toString() ?? ''),
          imageUrl: imageUrl,
          latitude: lat,
          longitude: lng,
          availableJobs: jobs,
        );
      }
    } catch (_) {}
    return null;
  }

  Future<Business?> _businessFromJobListingsForCompany(
    String companyName,
    String? photoUrlFallback,
  ) async {
    final normalized = SkillMatchUtils.normalizeCompanyName(companyName);
    final collected = <Job>[];
    var page = 1;
    var lastPage = 1;
    try {
      do {
        final res =
            await ApiService.getJobListings(search: companyName, page: page);
        if (res['success'] != true) break;
        final meta = res['meta'] as Map<String, dynamic>? ?? {};
        lastPage = (meta['last_page'] as num?)?.toInt() ?? 1;
        final list = res['data'] as List<dynamic>? ?? [];
        for (final j in list) {
          final job = Job.fromJson(j as Map<String, dynamic>);
          if (SkillMatchUtils.normalizeCompanyName(job.company) == normalized) {
            collected.add(job);
          }
        }
        page++;
        if (page > lastPage) break;
        if (page > 30) break;
      } while (true);
    } catch (_) {
      return null;
    }

    if (collected.isEmpty) return null;

    double? lat;
    double? lng;
    final locs = <String>{};
    for (final j in collected) {
      if (j.latitude != null && j.longitude != null) {
        lat = j.latitude;
        lng = j.longitude;
        break;
      }
      if (j.location.isNotEmpty) locs.add(j.location);
    }
    final p = currentUserPoint();
    final useLat = lat ?? p.lat;
    final useLng = lng ?? p.lng;
    final desc =
        locs.isEmpty ? collected.first.location : locs.take(3).join(', ');

    var imageUrl = photoUrlFallback?.trim() ?? '';
    if (imageUrl.isEmpty) {
      final path = collected.first.companyPhotoPath;
      imageUrl = ApiService.storageOrAbsoluteUrl(path) ?? '';
    }

    return Business(
      id: 'explore_${companyName.hashCode}',
      name: companyName,
      description: desc,
      imageUrl: imageUrl,
      latitude: useLat,
      longitude: useLng,
      availableJobs: collected,
    );
  }

  void _openHomeSearch(String query) {
    HapticFeedback.selectionClick();
    exploreSearchTextNotifier.value = query.trim();
    homeNavRequestNotifier.value = 0;
    scheduleMicrotask(() => homeNavRequestNotifier.value = null);
  }

  void _openAllJobs() => _openHomeSearch('');

  void _openIndustrySearch(String industryName) {
    final query = industryName.trim();
    if (query.isEmpty) return;
    _openHomeSearch(query);
  }

  Future<void> _refreshExploreData() async {
    HapticFeedback.selectionClick();
    await _loadExploreData(silent: true, userInitiated: true);
  }

  Future<bool> _ensureResumeReadyForApply() async {
    final hasResume = await _jobActionService.hasResumeOnFile();
    if (hasResume) return true;
    if (!mounted) return false;

    final goToDocuments = await showAppDialog<bool>(
      context: context,
      type: AppDialogType.info,
      icon: Icons.description_outlined,
      title: 'Resume required',
      message: 'Upload your resume before applying to jobs.',
      confirmLabel: 'Go to Documents',
      onConfirm: () => Navigator.of(context).pop(true),
      onCancel: () => Navigator.of(context).pop(false),
    );

    if (goToDocuments == true && mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const MyDocumentsPage()),
      );
    }
    return false;
  }

  Future<void> _applyToJob(Job job) async {
    final canApply = await _ensureResumeReadyForApply();
    if (!canApply || !mounted) return;

    final confirmed = await showAppDialog<bool>(
      context: context,
      type: AppDialogType.confirm,
      icon: Icons.send_rounded,
      title: 'Confirm application',
      message: 'Apply for ${job.title} at ${job.company}?',
      confirmLabel: 'Apply',
      onConfirm: () => Navigator.of(context).pop(true),
      onCancel: () => Navigator.of(context).pop(false),
    );
    if (confirmed != true || !mounted) return;

    final error = await _jobActionService.applyToJob(job.id, job.title);
    if (!mounted) return;
    if (error == null) {
      microInteractionSuccess();
      CustomToast.show(
        context,
        message: 'Applied to ${job.title}.',
        type: ToastType.success,
      );
    } else {
      CustomToast.show(context, message: error, type: ToastType.error);
    }
  }

  Future<void> _toggleSaveJob(Job job) async {
    final wasSaved = _jobActionService.isSaved(job.id);
    final error = await _jobActionService.toggleSave(job.id);
    if (!mounted) return;
    if (error == null) {
      microInteractionSuccess();
      CustomToast.show(
        context,
        message: wasSaved ? 'Job removed from saved.' : 'Job saved.',
        type: ToastType.info,
      );
    } else {
      CustomToast.show(context, message: error, type: ToastType.error);
    }
  }

  void _openJobDetails(Job job) {
    HapticFeedback.selectionClick();
    showJobDetailSheet(
      context,
      job,
      isSaved: _jobActionService.isSaved(job.id),
      isApplied: _jobActionService.isApplied(job.id),
      onSave: () => _toggleSaveJob(job),
      onApply: () => _applyToJob(job),
      onViewMap: () {
        Navigator.of(context).pop();
        mapFocusRequestNotifier.value = MapFocusRequest.fromJob(job);
        homeNavRequestNotifier.value = 2;
        scheduleMicrotask(() => homeNavRequestNotifier.value = null);
      },
    );
  }

  List<Job> get _recommendedJobs {
    final jobs = [..._featuredJobs];
    jobs.sort((a, b) {
      final byMatch = b.matchPercentage.compareTo(a.matchPercentage);
      if (byMatch != 0) return byMatch;
      return b.postedDate.compareTo(a.postedDate);
    });
    return jobs.take(2).toList();
  }

  String get _locationLabel {
    final session = UserSession();
    final city = session.cityName?.trim();
    final province = session.provinceName?.trim();
    if (city != null && city.isNotEmpty) return 'Near $city';
    if (province != null && province.isNotEmpty) return 'Near $province';
    return 'Near you';
  }

  bool get _showIndustrySection {
    if (_industries.isEmpty) return false;
    if (_industries.length == 1) {
      final n = (_industries.first['name'] as String? ?? '').trim();
      if (n.toLowerCase() == 'other') return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final topPadding = MediaQuery.paddingOf(context).top;

    return Container(
      color: const Color(0xFFF8FAFC),
      child: _isLoading
          ? _buildLoadingState(topPadding, bottomPadding)
          : _errorMessage != null
              ? _buildErrorState()
              : _buildContent(topPadding, bottomPadding),
    );
  }

  Widget _buildLoadingState(double topPadding, double bottomPadding) {
    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            padding: EdgeInsets.fromLTRB(20, topPadding + 18, 20, 18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1E40AF),
                  Color(0xFF2563EB),
                  Color(0xFF3B82F6),
                ],
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkeletonBox(width: 150, height: 28, color: Colors.white24),
                SizedBox(height: 10),
                _SkeletonBox(
                  width: double.infinity,
                  height: 48,
                  color: Colors.white24,
                ),
                SizedBox(height: 10),
                _SkeletonBox(width: 230, height: 28, color: Colors.white24),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Column(
              children: const [
                _SkeletonCard(height: 136),
                SizedBox(height: 12),
                _SkeletonCard(height: 96),
                SizedBox(height: 12),
                _SkeletonCard(height: 112),
                SizedBox(height: 24),
                _SkeletonRowCards(),
                SizedBox(height: 20),
                _SkeletonCard(height: 120),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: bottomPadding + 100)),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.explore_off_rounded,
              size: 64,
              color: const Color(0xFFCBD5E1),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _loadExploreData(userInitiated: true),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Same bottom fade as [HomeTab] job list — content softens above the pill nav.
  static const Color _explorePageBg = Color(0xFFF8FAFC);

  Widget _buildContent(double topPadding, double bottomPadding) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: NotificationListener<OverscrollIndicatorNotification>(
            onNotification: (OverscrollIndicatorNotification n) {
              n.disallowIndicator();
              return true;
            },
            child: RefreshIndicator(
              color: _kExplorePrimaryBlue,
              onRefresh: _refreshExploreData,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: ClampingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildHeader(topPadding),
                  ),
                  SliverToBoxAdapter(
                    child: _buildRecommendedJobsSection(),
                  ),
                  SliverToBoxAdapter(
                    child: _buildEventsSection(),
                  ),
                  SliverToBoxAdapter(
                    child: _buildSnapshotStrip(),
                  ),
                  SliverToBoxAdapter(
                    child: _buildTopCompaniesSection(),
                  ),
                  SliverToBoxAdapter(
                    child: _buildInDemandSkillsSection(),
                  ),
                  if (_showIndustrySection)
                    SliverToBoxAdapter(
                      child: _buildIndustriesSection(),
                    ),
                  SliverToBoxAdapter(
                    child: _buildFeaturedJobsSection(),
                  ),
                  // Bottom spacer for nav bar
                  SliverToBoxAdapter(
                    child: SizedBox(height: bottomPadding + 100),
                  ),
                ],
              ),
            ),
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
                    _explorePageBg.withValues(alpha: 0.0),
                    _explorePageBg.withValues(alpha: 0.85),
                    _explorePageBg,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader(double topPadding) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, topPadding + 16, 20, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E40AF), Color(0xFF2563EB), Color(0xFF3B82F6)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.explore_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Explore',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Discover opportunities that fit your next move',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 48,
            padding: const EdgeInsets.only(left: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF64748B),
                  size: 21,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    textInputAction: TextInputAction.search,
                    onSubmitted: _openHomeSearch,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      hintText: 'Search jobs, companies, skills',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Search',
                  onPressed: () => _openHomeSearch(_searchController.text),
                  icon: const Icon(
                    Icons.arrow_forward_rounded,
                    color: _kExplorePrimaryBlue,
                    size: 21,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _ExploreQuickActionChip(
                  icon: Icons.location_on_rounded,
                  label: _locationLabel,
                  onTap: _openAllJobs,
                ),
                const SizedBox(width: 8),
                _ExploreQuickActionChip(
                  icon: Icons.work_outline_rounded,
                  label: 'All jobs',
                  onTap: _openAllJobs,
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0);
  }

  // ─── Snapshot stats (one bar, vertical separators) ────────────────────────

  Widget _buildSnapshotStrip() {
    final openJobsLabel = _totalOpenPositions > 999
        ? '${(_totalOpenPositions / 1000).toStringAsFixed(1)}k'
        : _totalOpenPositions.toString();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        6,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.025),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: _SnapshotStripCell(
                label: 'New jobs this week',
                value: _newJobsThisWeek.toString(),
              ),
            ),
            Container(
              width: 1,
              height: 44,
              margin: const EdgeInsets.symmetric(vertical: 10),
              color: const Color(0xFFE2E8F0),
            ),
            Expanded(
              child: _SnapshotStripCell(
                label: 'Employers',
                value: _activeEmployers.toString(),
              ),
            ),
            Container(
              width: 1,
              height: 44,
              margin: const EdgeInsets.symmetric(vertical: 10),
              color: const Color(0xFFE2E8F0),
            ),
            Expanded(
              child: _SnapshotStripCell(
                label: 'Open jobs',
                value: openJobsLabel,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08, end: 0);
  }

  // ─── Recommended Jobs ──────────────────────────────────────────────────────

  Widget _buildRecommendedJobsSection() {
    final jobs = _recommendedJobs;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ExploreSectionHeader(
            icon: Icons.near_me_rounded,
            iconColor: const Color(0xFF0D9488),
            title: 'Recommended near you',
            subtitle: 'Recent openings ranked by fit and freshness',
            trailingLabel: 'See all',
            onTrailingTap: _openAllJobs,
          ),
          const SizedBox(height: 12),
          if (jobs.isEmpty)
            _ExploreEmptyStateCard(
              icon: Icons.work_outline_rounded,
              title: 'No job recommendations yet',
              message: 'Open jobs will appear here once the listings load.',
              actionLabel: 'Browse jobs',
              onAction: _openAllJobs,
            )
          else
            Column(
              children: jobs.asMap().entries.map((entry) {
                final index = entry.key;
                final job = entry.value;
                return Padding(
                  padding: EdgeInsets.only(
                      bottom: index == jobs.length - 1 ? 0 : 10),
                  child: _RecommendedJobCard(
                    job: job,
                    isSaved: _jobActionService.isSaved(job.id),
                    onTap: () => _openJobDetails(job),
                    onSave: () => _toggleSaveJob(job),
                    delay: index * 70,
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // ─── Upcoming events ───────────────────────────────────────────────────────

  Widget _buildEventsSection() {
    if (!_eventsLoaded && _nearestDayEvents.isEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: _SkeletonCard(height: 124),
      );
    }

    if (_nearestDayEvents.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ExploreSectionHeader(
              icon: Icons.event_available_rounded,
              iconColor: _kExplorePrimaryBlue,
              title: 'Upcoming PESO events',
              subtitle: 'Workshops, hiring events, and livelihood programs',
              trailingLabel: 'Calendar',
              onTrailingTap: () {
                HapticFeedback.selectionClick();
                shellOpenEventsRequestNotifier.value++;
              },
            ),
            const SizedBox(height: 12),
            _ExploreEmptyStateCard(
              icon: Icons.event_busy_rounded,
              title: 'No upcoming events',
              message: 'Check the calendar for new PESO activities.',
              actionLabel: 'View calendar',
              onAction: () {
                HapticFeedback.selectionClick();
                shellOpenEventsRequestNotifier.value++;
              },
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ExploreSectionHeader(
            icon: Icons.event_available_rounded,
            iconColor: _kExplorePrimaryBlue,
            title: 'Upcoming PESO events',
            subtitle: 'Nearest activity on your calendar',
            trailingLabel: 'Calendar',
            onTrailingTap: () {
              HapticFeedback.selectionClick();
              shellOpenEventsRequestNotifier.value++;
            },
          ),
          const SizedBox(height: 12),
          _ExploreUpcomingEventsCard(
            events: _nearestDayEvents,
            onOpenEvents: () {
              HapticFeedback.selectionClick();
              shellOpenEventsRequestNotifier.value++;
            },
          ),
        ],
      ),
    );
  }

  // ─── Top Hiring Companies ──────────────────────────────────────────────────

  Widget _buildTopCompaniesSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: _ExploreSectionHeader(
              icon: Icons.trending_up_rounded,
              iconColor: _kExplorePrimaryBlue,
              title: 'Top hiring companies',
              subtitle: 'Employers with the most open roles',
            ),
          ),
          const SizedBox(height: 12),
          if (_topCompanies.isEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: _ExploreEmptyStateCard(
                icon: Icons.business_rounded,
                title: 'No employer trends yet',
                message:
                    'Hiring companies will appear here once jobs are available.',
                actionLabel: 'Browse jobs',
                onAction: _openAllJobs,
              ),
            )
          else
            SizedBox(
              height: 118,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(right: 20),
                itemCount: _topCompanies.length,
                itemBuilder: (context, index) {
                  final company = _topCompanies[index];
                  return _CompanyCard(
                    name: company['name'] as String? ?? '',
                    initial: (company['initial'] as String?) ?? '',
                    photoUrl: company['photo_url'] as String?,
                    jobCount: (company['job_count'] as num?)?.toInt() ?? 0,
                    delay: index * 60,
                    onTap: () => _openExploreCompanyJobs(
                      company['name'] as String? ?? '',
                      company['photo_url'] as String?,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // ─── In-Demand Skills ──────────────────────────────────────────────────────

  Widget _buildInDemandSkillsSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ExploreSectionHeader(
            icon: Icons.auto_awesome_rounded,
            iconColor: Color(0xFF10B981),
            title: 'In-demand skills',
            subtitle: 'Trending across open jobs',
          ),
          const SizedBox(height: 12),
          if (_inDemandSkills.isEmpty)
            _ExploreEmptyStateCard(
              icon: Icons.auto_awesome_outlined,
              title: 'No skill trends yet',
              message: 'Skill demand will appear here after jobs are indexed.',
              actionLabel: 'Browse jobs',
              onAction: _openAllJobs,
            )
          else
            _SkillDemandChart(skills: _inDemandSkills.take(8).toList()),
        ],
      ),
    );
  }

  // ─── Browse by industry (employer.industry) ───────────────────────────────

  Widget _buildIndustriesSection() {
    final sectorIcons = <String, IconData>{
      'Full-time': Icons.schedule_rounded,
      'Part-time': Icons.timelapse_rounded,
      'Contract': Icons.assignment_rounded,
      'Freelance': Icons.laptop_mac_rounded,
      'BPO': Icons.headset_mic_rounded,
      'IT': Icons.computer_rounded,
      'Healthcare': Icons.health_and_safety_rounded,
      'Education': Icons.school_rounded,
      'Construction': Icons.construction_rounded,
      'Retail': Icons.storefront_rounded,
      'Manufacturing': Icons.precision_manufacturing_rounded,
      'Government': Icons.account_balance_rounded,
      'Food & Beverage': Icons.restaurant_rounded,
      'Transportation': Icons.local_shipping_rounded,
      'Agriculture': Icons.agriculture_rounded,
      'Other': Icons.apartment_rounded,
    };

    final sectorColors = <String, Color>{
      'Full-time': const Color(0xFF2563EB),
      'Part-time': const Color(0xFF7C3AED),
      'Contract': const Color(0xFFDC2626),
      'Freelance': const Color(0xFF059669),
      'BPO': const Color(0xFF0891B2),
      'IT': const Color(0xFF4F46E5),
      'Healthcare': const Color(0xFFDB2777),
      'Education': const Color(0xFFCA8A04),
      'Construction': const Color(0xFFEA580C),
      'Retail': const Color(0xFF0D9488),
      'Manufacturing': const Color(0xFF6D28D9),
      'Government': const Color(0xFF1D4ED8),
      'Food & Beverage': const Color(0xFFE11D48),
      'Transportation': const Color(0xFF4338CA),
      'Agriculture': const Color(0xFF16A34A),
      'Other': const Color(0xFF64748B),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ExploreSectionHeader(
            icon: Icons.domain_rounded,
            iconColor: Color(0xFF0D9488),
            title: 'Browse by industry',
            subtitle: 'Open roles grouped by employer sector',
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.4,
            ),
            itemCount: _industries.length > 8 ? 8 : _industries.length,
            itemBuilder: (context, index) {
              final sector = _industries[index];
              final name = sector['name'] as String? ?? '';
              final count = (sector['job_count'] as num?)?.toInt() ?? 0;
              final icon = sectorIcons[name] ?? Icons.work_outline_rounded;
              final color = sectorColors[name] ?? const Color(0xFF64748B);

              return _SectorTile(
                name: name,
                jobCount: count,
                icon: icon,
                color: color,
                delay: index * 60,
                onTap: () => _openIndustrySearch(name),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── Featured Jobs ─────────────────────────────────────────────────────────

  Widget _buildFeaturedJobsSection() {
    final jobs = _featuredJobs.take(4).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ExploreSectionHeader(
            icon: Icons.schedule_rounded,
            iconColor: const Color(0xFFF59E0B),
            title: 'Recently posted',
            subtitle: 'Fresh opportunities from employers',
            trailingLabel: 'See all',
            onTrailingTap: _openAllJobs,
          ),
          const SizedBox(height: 12),
          if (jobs.isEmpty)
            _ExploreEmptyStateCard(
              icon: Icons.work_history_outlined,
              title: 'No recent jobs yet',
              message: 'New job posts will appear here.',
              actionLabel: 'Browse jobs',
              onAction: _openAllJobs,
            )
          else
            Column(
              children: jobs.asMap().entries.map((entry) {
                final index = entry.key;
                final job = entry.value;
                return Padding(
                  padding: EdgeInsets.only(
                      bottom: index == jobs.length - 1 ? 0 : 10),
                  child: _RecentJobCard(
                    job: job,
                    isSaved: _jobActionService.isSaved(job.id),
                    onTap: () => _openJobDetails(job),
                    onSave: () => _toggleSaveJob(job),
                    delay: index * 55,
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _ExploreQuickActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ExploreQuickActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 190),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: Colors.white),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
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

class _ExploreSectionHeader extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final String? trailingLabel;
  final VoidCallback? onTrailingTap;

  const _ExploreSectionHeader({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailingLabel,
    this.onTrailingTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                const SizedBox(height: 1),
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailingLabel != null && onTrailingTap != null) ...[
          const SizedBox(width: 10),
          TextButton(
            onPressed: onTrailingTap,
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 34),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              foregroundColor: _kExplorePrimaryBlue,
              textStyle: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            child: Text(trailingLabel!),
          ),
        ],
      ],
    );
  }
}

class _ExploreEmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _ExploreEmptyStateCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF64748B)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: _kExplorePrimaryBlue,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              textStyle: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final Color color;

  const _SkeletonBox({
    required this.width,
    required this.height,
    this.color = const Color(0xFFE2E8F0),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
    ).animate(onPlay: (controller) => controller.repeat(reverse: true)).fade(
          begin: 0.55,
          end: 1,
          duration: 900.ms,
        );
  }
}

class _SkeletonCard extends StatelessWidget {
  final double height;

  const _SkeletonCard({required this.height});

  @override
  Widget build(BuildContext context) {
    final compact = height < 120;

    return Container(
      width: double.infinity,
      height: height,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          double lineWidth(double desired) =>
              desired.clamp(24.0, maxWidth).toDouble();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SkeletonBox(width: lineWidth(150), height: 14),
              const SizedBox(height: 10),
              const _SkeletonBox(width: double.infinity, height: 18),
              const SizedBox(height: 8),
              _SkeletonBox(width: lineWidth(220), height: 14),
              if (!compact) ...[
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: _SkeletonBox(
                        width: double.infinity,
                        height: 22,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SkeletonBox(
                        width: double.infinity,
                        height: 22,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SkeletonRowCards extends StatelessWidget {
  const _SkeletonRowCards();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, __) => const SizedBox(
          width: 132,
          child: _SkeletonCard(height: 132),
        ),
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemCount: 3,
      ),
    );
  }
}

String _explorePostedLabel(DateTime date) {
  final daysAgo = DateTime.now().difference(date).inDays;
  if (daysAgo <= 0) return 'Today';
  if (daysAgo == 1) return '1 day ago';
  if (daysAgo < 7) return '$daysAgo days ago';
  return DateFormat('MMM d').format(date);
}

class _EmployerLogo extends StatelessWidget {
  final String? photoUrl;
  final String initial;
  final Color color;
  final double size;

  const _EmployerLogo({
    required this.photoUrl,
    required this.initial,
    required this.color,
    this.size = 42,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = ApiService.storageOrAbsoluteUrl(photoUrl);
    final fallback = Center(
      child: Text(
        initial.isNotEmpty ? initial[0] : '?',
        style: GoogleFonts.inter(
          fontSize: size * 0.38,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: resolvedUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                resolvedUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => fallback,
              ),
            )
          : fallback,
    );
  }
}

class _RecommendedJobCard extends StatelessWidget {
  final Job job;
  final bool isSaved;
  final VoidCallback onTap;
  final VoidCallback onSave;
  final int delay;

  const _RecommendedJobCard({
    required this.job,
    required this.isSaved,
    required this.onTap,
    required this.onSave,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final showMatch = job.matchPercentage > 0;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.025),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _EmployerLogo(
                    photoUrl: job.companyPhotoPath,
                    initial: job.companyInitial,
                    color: job.companyColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.company,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          job.location.isEmpty
                              ? 'Location not specified'
                              : job.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: isSaved ? 'Saved' : 'Save',
                    visualDensity: VisualDensity.compact,
                    onPressed: onSave,
                    icon: Icon(
                      isSaved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_outline_rounded,
                      color: isSaved
                          ? _kExplorePrimaryBlue
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                job.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MiniMetaPill(
                    icon: Icons.schedule_rounded,
                    label: job.employmentTypeLabel,
                  ),
                  _MiniMetaPill(
                    icon: Icons.payments_outlined,
                    label: job.salaryDisplay,
                  ),
                  if (showMatch)
                    _MiniMetaPill(
                      icon: Icons.verified_rounded,
                      label: '${job.matchPercentage}% match',
                      color: const Color(0xFF0D9488),
                    ),
                  if (job.isUrgent)
                    const _MiniMetaPill(
                      icon: Icons.priority_high_rounded,
                      label: 'Urgent',
                      color: Color(0xFFDC2626),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 320.ms, delay: Duration(milliseconds: delay))
        .slideY(begin: 0.04, end: 0);
  }
}

class _RecentJobCard extends StatelessWidget {
  final Job job;
  final bool isSaved;
  final VoidCallback onTap;
  final VoidCallback onSave;
  final int delay;

  const _RecentJobCard({
    required this.job,
    required this.isSaved,
    required this.onTap,
    required this.onSave,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              _EmployerLogo(
                photoUrl: job.companyPhotoPath,
                initial: job.companyInitial,
                color: job.companyColor,
                size: 40,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      job.company,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${_explorePostedLabel(job.postedDate)} · ${job.employmentTypeLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: isSaved ? 'Saved' : 'Save',
                visualDensity: VisualDensity.compact,
                onPressed: onSave,
                icon: Icon(
                  isSaved
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_outline_rounded,
                  color:
                      isSaved ? _kExplorePrimaryBlue : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms, delay: Duration(milliseconds: delay))
        .slideY(begin: 0.04, end: 0);
  }
}

class _MiniMetaPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MiniMetaPill({
    required this.icon,
    required this.label,
    this.color = const Color(0xFF64748B),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Upcoming event(s) on nearest day (carousel if multiple) ───────────────

class _ExploreUpcomingEventsCard extends StatefulWidget {
  final List<PesoEvent> events;
  final VoidCallback onOpenEvents;

  const _ExploreUpcomingEventsCard({
    required this.events,
    required this.onOpenEvents,
  });

  @override
  State<_ExploreUpcomingEventsCard> createState() =>
      _ExploreUpcomingEventsCardState();
}

class _ExploreUpcomingEventsCardState
    extends State<_ExploreUpcomingEventsCard> {
  late final PageController _pageController;
  int _pageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _ExploreUpcomingEventsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.events.isEmpty) return;
    final lenChanged = oldWidget.events.length != widget.events.length;
    final firstChanged = oldWidget.events.isEmpty ||
        oldWidget.events.first.id != widget.events.first.id;
    if (lenChanged || firstChanged) {
      _pageIndex = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pageController.hasClients) {
          _pageController.jumpToPage(0);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final events = widget.events;
    if (events.isEmpty) return const SizedBox.shrink();

    final dateLabel = DateFormat('EEEE, MMM d').format(events.first.eventDate);
    final monthLabel = DateFormat('MMM').format(events.first.eventDate);
    final dayLabel = DateFormat('d').format(events.first.eventDate);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onOpenEvents,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.025),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _kExplorePrimaryBlue.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            monthLabel.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: _kExplorePrimaryBlue,
                            ),
                          ),
                          Text(
                            dayLabel,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            events.length > 1
                                ? '${events.length} events this day'
                                : 'Upcoming event',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dateLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF94A3B8),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 68,
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => _pageIndex = i),
                    children: events.map((e) {
                      final meta = <String>[];
                      final t = e.eventTime?.trim();
                      if (t != null && t.isNotEmpty) meta.add(t);
                      if (e.location.trim().isNotEmpty) {
                        meta.add(e.location.trim());
                      }
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              e.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                                height: 1.25,
                              ),
                            ),
                            if (meta.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                meta.join(' · '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                Row(
                  children: [
                    if (events.length > 1)
                      Expanded(
                        child: Row(
                          children: List.generate(events.length, (i) {
                            final active = i == _pageIndex;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: active ? 14 : 6,
                              height: 6,
                              margin: const EdgeInsets.only(right: 5),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(3),
                                color: active
                                    ? _kExplorePrimaryBlue
                                    : const Color(0xFFE2E8F0),
                              ),
                            );
                          }),
                        ),
                      )
                    else
                      const Spacer(),
                    Text(
                      'View details',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: _kExplorePrimaryBlue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.05, end: 0);
  }
}

// ─── Snapshot strip cell (inside merged stats bar) ──────────────────────────

class _SnapshotStripCell extends StatelessWidget {
  final String label;
  final String value;

  const _SnapshotStripCell({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              height: 1.2,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Company Card Widget ──────────────────────────────────────────────────────

class _CompanyCard extends StatelessWidget {
  final String name;
  final String initial;
  final String? photoUrl;
  final int jobCount;
  final int delay;
  final VoidCallback onTap;

  const _CompanyCard({
    required this.name,
    required this.initial,
    required this.photoUrl,
    required this.jobCount,
    required this.delay,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = ApiService.storageOrAbsoluteUrl(photoUrl);
    final logo = _EmployerLogo(
      photoUrl: resolvedUrl,
      initial: initial,
      color: _kExplorePrimaryBlue,
      size: 40,
    );

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 172,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    logo,
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                          height: 1.15,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _kExplorePrimaryBlue.withValues(alpha: 0.09),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$jobCount ${jobCount == 1 ? 'job' : 'jobs'}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: _kExplorePrimaryBlue,
                        ),
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: Color(0xFF94A3B8),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 320.ms, delay: Duration(milliseconds: delay))
        .slideX(begin: 0.08, end: 0);
  }
}

// ─── Skill Demand Chart ──────────────────────────────────────────────────────

class _SkillDemandChart extends StatelessWidget {
  final List<Map<String, dynamic>> skills;

  const _SkillDemandChart({required this.skills});

  @override
  Widget build(BuildContext context) {
    final rows = skills
        .map((skill) => _SkillDemandDatum(
              name: (skill['name'] as String? ?? '').trim(),
              count: (skill['job_count'] as num?)?.toInt() ?? 0,
            ))
        .where((skill) => skill.name.isNotEmpty)
        .toList();
    final maxCount = rows.fold<int>(
      1,
      (max, skill) => skill.count > max ? skill.count : max,
    );
    final userSkills = UserSession().skills.map((s) => s.toLowerCase()).toSet();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: rows.asMap().entries.map((entry) {
          final index = entry.key;
          final skill = entry.value;
          final isUserSkill = userSkills.contains(skill.name.toLowerCase());
          return _SkillDemandBar(
            name: skill.name,
            count: skill.count,
            maxCount: maxCount,
            isUserSkill: isUserSkill,
            delay: index * 45,
          );
        }).toList(),
      ),
    );
  }
}

class _SkillDemandDatum {
  final String name;
  final int count;

  const _SkillDemandDatum({
    required this.name,
    required this.count,
  });
}

class _SkillDemandBar extends StatelessWidget {
  final String name;
  final int count;
  final int maxCount;
  final bool isUserSkill;
  final int delay;

  const _SkillDemandBar({
    required this.name,
    required this.count,
    required this.maxCount,
    required this.isUserSkill,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = maxCount <= 0 ? 0.0 : (count / maxCount).clamp(0.08, 1.0);
    final barColor =
        isUserSkill ? const Color(0xFF10B981) : _kExplorePrimaryBlue;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
              if (isUserSkill) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.check_circle_rounded,
                  size: 14,
                  color: barColor,
                ),
              ],
              const SizedBox(width: 8),
              Text(
                '$count',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF475569),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    Container(
                      height: 8,
                      width: double.infinity,
                      color: const Color(0xFFEFF6FF),
                    ),
                    AnimatedContainer(
                      duration: Duration(milliseconds: 420 + delay),
                      curve: Curves.easeOutCubic,
                      height: 8,
                      width: constraints.maxWidth * ratio,
                      color: barColor,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms, delay: Duration(milliseconds: delay))
        .slideX(begin: 0.03, end: 0);
  }
}

// ─── Sector Tile Widget ───────────────────────────────────────────────────────

class _SectorTile extends StatelessWidget {
  final String name;
  final int jobCount;
  final IconData icon;
  final Color color;
  final int delay;
  final VoidCallback onTap;

  const _SectorTile({
    required this.name,
    required this.jobCount,
    required this.icon,
    required this.color,
    required this.delay,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.14), width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: color, size: 17),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$jobCount ${jobCount == 1 ? 'job' : 'jobs'}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: Color(0xFFCBD5E1),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 320.ms, delay: Duration(milliseconds: delay))
        .slideY(begin: 0.06, end: 0);
  }
}
