import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'api_service.dart';
import 'auth_gate.dart';
import 'event_models.dart';
import 'user_session.dart';
import 'job_models.dart';
import 'job_action_service.dart';
import 'home_pages.dart';
import 'skill_match_utils.dart';
import 'micro_interactions.dart';
import 'my_documents_page.dart';
import 'app_haptics.dart';
import 'main.dart';
import 'l10n/app_localizations.dart';

/// Primary brand blue (matches Explore header gradient mid-stop).
const Color _kExplorePrimaryBlue = Color(0xFF2563EB);
const String _kExploreHeaderMascotAsset = 'assets/empoy_explore.png';
const double _kExploreHeaderMascotImageSize = 130;
const double _kExploreHeaderMascotOffsetX = -5;
const double _kExploreHeaderMascotOffsetY = 23;

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
        _topCompanies = companies
            .cast<Map<String, dynamic>>()
            .where((c) {
              final name = (c['name'] as String? ?? '').toLowerCase();
              final isDole = name.contains('dole') ||
                  name.contains('department of labor');
              final isPeso = name.contains('peso') ||
                  name.contains('santiago') ||
                  name == 'employer';
              return !isDole && !isPeso;
            })
            .toList();

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

        // Build top companies from job data (excluding DOLE & direct PESO posts)
        final companyMap = <String, Map<String, dynamic>>{};
        for (final job in jobs) {
          if (job.isDoleProgram || job.isPesoOffice) continue;
          companyMap.putIfAbsent(
              job.company,
              () => {
                    'name': job.company,
                    'initial': job.companyInitial,
                    'photo_url': job.companyPhotoPath,
                    'asset_logo': job.assetLogoPath,
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
        if (status != 'upcoming') continue;
        final e = PesoEvent.fromJson(map, isRegistered: false);
        final day =
            DateTime(e.eventDate.year, e.eventDate.month, e.eventDate.day);
        if (day.isBefore(today)) continue;
        eligible.add(e);
      }

      eligible.sort((a, b) {
        final cmpDate = a.eventDate.compareTo(b.eventDate);
        if (cmpDate != 0) return cmpDate;
        final ta = a.eventTime ?? '';
        final tb = b.eventTime ?? '';
        final byTime = ta.compareTo(tb);
        if (byTime != 0) return byTime;
        return a.title.compareTo(b.title);
      });

      setState(() {
        _nearestDayEvents = eligible;
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
          message: S.of(context)?.exploreNoOpenJobsForEmployer ??
              'No open jobs found for this employer.',
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
    AppHaptics.lightImpact();
    exploreSearchTextNotifier.value = query.trim();
    homeNavRequestNotifier.value = 0;
    scheduleMicrotask(() => homeNavRequestNotifier.value = null);
  }

  void _openAllJobs() => _openHomeSearch('');

  void _openRecentlyPostedJobs() {
    exploreSortOptionNotifier.value = 'Latest';
    _openAllJobs();
  }

  void _openIndustrySearch(String industryName) {
    final query = industryName.trim();
    if (query.isEmpty) return;
    _openHomeSearch(query);
  }

  Future<void> _refreshExploreData() async {
    AppHaptics.lightImpact();
    await _loadExploreData(silent: true, userInitiated: true);
  }

  Future<bool> _ensureResumeReadyForApply() async {
    final s = S.of(context);
    final isSignedIn = await requireAuthenticatedSession(
      context,
      message: s?.exploreSignInToApply ??
          'Please sign in or create an account before applying to jobs.',
    );
    if (!isSignedIn) return false;

    final hasResume = await _jobActionService.hasResumeOnFile();
    if (hasResume) return true;
    if (!mounted) return false;

    final goToDocuments = await showAppDialog<bool>(
      context: context,
      type: AppDialogType.info,
      icon: Icons.description_outlined,
      title: s?.resumeRequired ?? 'Resume required',
      message: s?.resumeRequiredMessage ??
          'Upload your resume before applying to jobs.',
      confirmLabel: s?.goToDocuments ?? 'Go to Documents',
      onConfirm: () => Navigator.of(context).pop(true),
      onCancel: () => Navigator.of(context).pop(false),
    );

    if (goToDocuments == true && mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const MyDocumentsPage()),
      );
      if (mounted) {
        return await _jobActionService.hasResumeOnFile(forceRefresh: true);
      }
    }
    return false;
  }

  Future<void> _applyToJob(Job job) async {
    final s = S.of(context);
    final canApply = await _ensureResumeReadyForApply();
    if (!canApply || !mounted) return;

    final confirmed = await showAppDialog<bool>(
      context: context,
      type: AppDialogType.confirm,
      icon: Icons.send_rounded,
      title: s?.exploreConfirmApplication ?? 'Confirm application',
      message: s?.exploreApplyForJob(job.title, job.company) ??
          'Apply for ${job.title} at ${job.company}?',
      confirmLabel: s?.apply ?? 'Apply',
      confirmBusyLabel: Localizations.localeOf(context).languageCode == 'tl'
          ? 'Nag-a-apply...'
          : 'Applying...',
      onConfirmAsync: () async {
        final error = await _jobActionService.applyToJob(job.id, job.title);
        if (error != null) {
          if (mounted) {
            CustomToast.show(context, message: error, type: ToastType.error);
          }
          throw Exception(error);
        }
      },
    );
    if (confirmed != true || !mounted) return;

    microInteractionSuccess();
    CustomToast.show(
      context,
      message:
          s?.exploreAppliedToJob(job.title) ?? 'Applied to ${job.title}.',
      type: ToastType.success,
    );
  }

  Future<void> _toggleSaveJob(Job job) async {
    final s = S.of(context);
    final isSignedIn = await requireAuthenticatedSession(
      context,
      message: s?.exploreSignInToSave ??
          'Please sign in or create an account to save jobs.',
    );
    if (!isSignedIn || !mounted) return;

    final wasSaved = _jobActionService.isSaved(job.id);
    final error = await _jobActionService.toggleSave(job.id);
    if (!mounted) return;
    if (error == null) {
      microInteractionSuccess();
      CustomToast.show(
        context,
        message: wasSaved
            ? (s?.jobUnsaved ?? 'Job removed from saved.')
            : (s?.jobSaved ?? 'Job saved.'),
        type: ToastType.info,
      );
    } else {
      CustomToast.show(context, message: error, type: ToastType.error);
    }
  }

  void _openJobDetails(Job job) {
    AppHaptics.lightImpact();
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
    return jobs.take(3).toList();
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
              ? _buildErrorState(topPadding, bottomPadding)
              : _buildContent(topPadding, bottomPadding),
    );
  }

  Widget _buildLoadingState(double topPadding, double bottomPadding) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: _buildHeader(topPadding),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              children: const [
                _SkeletonSnapshotStrip(),
                SizedBox(height: 20),
                _SkeletonCard(height: 136),
                SizedBox(height: 12),
                _SkeletonCard(height: 136),
                SizedBox(height: 20),
                _SkeletonCard(height: 180),
                SizedBox(height: 20),
                _SkeletonCard(height: 120),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: bottomPadding + 140)),
      ],
    );
  }

  Widget _buildErrorState(double topPadding, double bottomPadding) {
    final s = S.of(context);
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: _buildHeader(topPadding),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
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
                    _localizedExploreError(context, _errorMessage),
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
                    label: Text(s?.retry ?? 'Retry'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
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
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildHeader(topPadding),
                  ),
                  SliverToBoxAdapter(
                    child: _buildSnapshotStrip(),
                  ),
                  SliverToBoxAdapter(
                    child: _buildRecommendedJobsSection(),
                  ),
                  SliverToBoxAdapter(
                    child: _buildEventsSection(),
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
                    child: SizedBox(height: bottomPadding + 140),
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
    final s = S.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(20, topPadding + 16, 20, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E3A8A),
            Color(0xFF2563EB),
            Color(0xFF3B82F6),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Transform.translate(
                offset: const Offset(
                  _kExploreHeaderMascotOffsetX,
                  _kExploreHeaderMascotOffsetY,
                ),
                child: Image.asset(
                  _kExploreHeaderMascotAsset,
                  width: _kExploreHeaderMascotImageSize,
                  height: _kExploreHeaderMascotImageSize,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.explore_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s?.navExplore ?? 'Explore',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      s?.exploreHeaderSubtitle ??
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
        ],
      ),
    );
  }

  // ─── Snapshot stats (one bar, vertical separators) ────────────────────────

  Widget _buildSnapshotStrip() {
    final s = S.of(context);
    final openJobsLabel = _totalOpenPositions > 999
        ? '${(_totalOpenPositions / 1000).toStringAsFixed(1)}k'
        : _totalOpenPositions.toString();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: _SnapshotStripCell(
                icon: HugeIcons.strokeRoundedBriefcase01,
                iconColor: const Color(0xFF2563EB),
                label: s?.exploreNewJobsThisWeek ?? 'New jobs',
                value: _newJobsThisWeek.toString(),
              ),
            ),
            Container(
              width: 1,
              height: 48,
              color: const Color(0xFFF1F5F9),
            ),
            Expanded(
              child: _SnapshotStripCell(
                icon: HugeIcons.strokeRoundedBuilding01,
                iconColor: const Color(0xFF059669),
                label: s?.exploreEmployers ?? 'Employers',
                value: _activeEmployers.toString(),
              ),
            ),
            Container(
              width: 1,
              height: 48,
              color: const Color(0xFFF1F5F9),
            ),
            Expanded(
              child: _SnapshotStripCell(
                icon: HugeIcons.strokeRoundedUserGroup,
                iconColor: const Color(0xFF7C3AED),
                label: s?.exploreOpenJobs ?? 'Openings',
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
    final s = S.of(context);
    final jobs = _recommendedJobs;
    if (jobs.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ExploreSectionHeader(
            icon: HugeIcons.strokeRoundedMapsLocation01,
            iconColor: const Color(0xFF0D9488),
            title: s?.exploreRecommendedNearYou ?? 'Recommended near you',
            trailingLabel: s?.exploreSeeAll ?? 'See all',
            onTrailingTap: _openAllJobs,
          ),
          const SizedBox(height: 12),
          Column(
            children: jobs.asMap().entries.map((entry) {
              final index = entry.key;
              final job = entry.value;
              return Padding(
                padding: EdgeInsets.only(
                    bottom: index == jobs.length - 1 ? 0 : 8),
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
    final s = S.of(context);
    if (!_eventsLoaded && _nearestDayEvents.isEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: _SkeletonCard(height: 220),
      );
    }

    if (_nearestDayEvents.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: _ExploreSectionHeader(
            icon: HugeIcons.strokeRoundedCalendar03,
            iconColor: _kExplorePrimaryBlue,
            title: s?.exploreUpcomingPesoEvents ?? 'Upcoming PESO events',
            trailingLabel: s?.exploreCalendar ?? 'Calendar',
            onTrailingTap: () {
              AppHaptics.lightImpact();
              shellOpenEventsRequestNotifier.value++;
            },
          ),
        ),
        const SizedBox(height: 12),
        _AutoGlideEventsCarousel(
          events: _nearestDayEvents,
          onEventTap: (event) {
            AppHaptics.lightImpact();
            openEventDetailModal(
              context,
              event,
              onRegistrationChanged: () => _loadNearestDayEvents(),
            );
          },
        ),
      ],
    );
  }

  // ─── Top Hiring Companies ──────────────────────────────────────────────────

  Widget _buildTopCompaniesSection() {
    final s = S.of(context);
    if (_topCompanies.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: _ExploreSectionHeader(
              icon: HugeIcons.strokeRoundedTradeUp,
              iconColor: _kExplorePrimaryBlue,
              title: s?.exploreTopHiringCompanies ?? 'Top hiring companies',
            ),
          ),
          const SizedBox(height: 12),
          _AutoGlideCompanyCarousel(
            companies: _topCompanies,
            onCompanyTap: (name, photoUrl) => _openExploreCompanyJobs(name, photoUrl),
          ),
        ],
      ),
    );
  }

  // ─── In-Demand Skills ──────────────────────────────────────────────────────

  Widget _buildInDemandSkillsSection() {
    final s = S.of(context);
    if (_inDemandSkills.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ExploreSectionHeader(
            icon: HugeIcons.strokeRoundedBrain01,
            iconColor: const Color(0xFF10B981),
            title: s?.exploreInDemandSkills ?? 'In-demand skills',
          ),
          const SizedBox(height: 12),
          _SkillDemandChart(skills: _inDemandSkills.take(8).toList()),
        ],
      ),
    );
  }

  // ─── Browse by industry (employer.industry) ───────────────────────────────

  Widget _buildIndustriesSection() {
    final s = S.of(context);
    final sectorIcons = <String, dynamic>{
      'Full-time': HugeIcons.strokeRoundedClock01,
      'Part-time': HugeIcons.strokeRoundedClock02,
      'Contract': HugeIcons.strokeRoundedFile01,
      'Freelance': HugeIcons.strokeRoundedComputer,
      'BPO': HugeIcons.strokeRoundedHeadphones,
      'IT': HugeIcons.strokeRoundedBinaryCode,
      'Healthcare': HugeIcons.strokeRoundedHospital01,
      'Education': HugeIcons.strokeRoundedGraduateMale,
      'Construction': HugeIcons.strokeRoundedBuilding01,
      'Retail': HugeIcons.strokeRoundedStore01,
      'Manufacturing': HugeIcons.strokeRoundedAccountSetting01,
      'Government': HugeIcons.strokeRoundedBuilding01,
      'Food & Beverage': HugeIcons.strokeRoundedRestaurant01,
      'Transportation': HugeIcons.strokeRoundedDeliveryTruck01,
      'Agriculture': HugeIcons.strokeRoundedGlobal,
      'Other': HugeIcons.strokeRoundedBriefcase01,
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
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ExploreSectionHeader(
            icon: HugeIcons.strokeRoundedBuilding01,
            iconColor: const Color(0xFF0D9488),
            title: s?.exploreBrowseByIndustry ?? 'Browse by industry',
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
              final icon = sectorIcons[name] ?? HugeIcons.strokeRoundedBriefcase01;
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
    final s = S.of(context);
    final jobs = _featuredJobs.take(4).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ExploreSectionHeader(
            icon: HugeIcons.strokeRoundedClock01,
            iconColor: const Color(0xFFF59E0B),
            title: s?.exploreRecentlyPosted ?? 'Recently posted',
            trailingLabel: s?.exploreSeeAll ?? 'See all',
            onTrailingTap: _openRecentlyPostedJobs,
          ),
          const SizedBox(height: 12),
          if (jobs.isEmpty)
            _ExploreEmptyStateCard(
              icon: HugeIcons.strokeRoundedBriefcase01,
              title: s?.exploreNoRecentJobs ?? 'No recent jobs yet',
              message: s?.exploreNoRecentJobsMessage ??
                  'New job posts will appear here.',
              actionLabel: s?.exploreBrowseJobs ?? 'Browse jobs',
              onAction: _openRecentlyPostedJobs,
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

class _ExploreSectionHeader extends StatelessWidget {
  final dynamic icon;
  final Color iconColor;
  final String title;
  final String? trailingLabel;
  final VoidCallback? onTrailingTap;

  const _ExploreSectionHeader({
    required this.icon,
    required this.iconColor,
    required this.title,
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
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: icon is IconData
              ? Icon(icon, color: iconColor, size: 16)
              : HugeIcon(
                  icon: icon as List<List<dynamic>>,
                  color: iconColor,
                  size: 16,
                  strokeWidth: 2.0,
                ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              maxLines: 1,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
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
  final dynamic icon;
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
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: icon is IconData
                ? Icon(icon, size: 18, color: const Color(0xFF64748B))
                : HugeIcon(
                    icon: icon as List<List<dynamic>>,
                    size: 18,
                    color: const Color(0xFF64748B),
                    strokeWidth: 2.0,
                  ),
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

class _SkeletonSnapshotStrip extends StatelessWidget {
  const _SkeletonSnapshotStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                _SkeletonBox(width: 22, height: 22),
                SizedBox(height: 8),
                _SkeletonBox(width: 36, height: 16),
                SizedBox(height: 4),
                _SkeletonBox(width: 56, height: 10),
              ],
            ),
          ),
          Container(width: 1, height: 48, color: const Color(0xFFF1F5F9)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                _SkeletonBox(width: 22, height: 22),
                SizedBox(height: 8),
                _SkeletonBox(width: 36, height: 16),
                SizedBox(height: 4),
                _SkeletonBox(width: 56, height: 10),
              ],
            ),
          ),
          Container(width: 1, height: 48, color: const Color(0xFFF1F5F9)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                _SkeletonBox(width: 22, height: 22),
                SizedBox(height: 8),
                _SkeletonBox(width: 36, height: 16),
                SizedBox(height: 4),
                _SkeletonBox(width: 56, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  final double height;
  final double borderRadius;

  const _SkeletonCard({
    required this.height,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          final maxHeight = constraints.maxHeight;
          double lineWidth(double desired) =>
              desired.clamp(24.0, maxWidth).toDouble();

          if (maxHeight < 50) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _SkeletonBox(width: lineWidth(140), height: 14),
                const Spacer(),
                _SkeletonBox(width: lineWidth(40), height: 14),
              ],
            );
          }

          if (maxHeight < 85) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SkeletonBox(width: lineWidth(160), height: 14),
                const SizedBox(height: 8),
                _SkeletonBox(width: lineWidth(240), height: 12),
              ],
            );
          }

          final showBottomRow = maxHeight >= 110;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SkeletonBox(width: lineWidth(150), height: 14),
              const SizedBox(height: 10),
              const _SkeletonBox(width: double.infinity, height: 16),
              const SizedBox(height: 8),
              _SkeletonBox(width: lineWidth(220), height: 12),
              if (showBottomRow) ...[
                const Spacer(),
                Row(
                  children: const [
                    Expanded(
                      child: _SkeletonBox(
                        width: double.infinity,
                        height: 22,
                      ),
                    ),
                    SizedBox(width: 8),
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

String _explorePostedLabelForLocale(BuildContext? context, DateTime date) {
  final s = context == null ? null : S.of(context);
  final daysAgo = DateTime.now().difference(date).inDays;
  if (daysAgo <= 0) return s?.today ?? 'Today';
  if (daysAgo == 1) return s?.exploreOneDayAgo ?? '1 day ago';
  if (daysAgo < 7) {
    return s?.exploreDaysAgo(daysAgo) ?? '$daysAgo days ago';
  }
  return DateFormat('MMM d', s?.localeName).format(date);
}

String _localizedExploreError(BuildContext context, String? message) {
  final s = S.of(context);
  final normalized = message?.trim().toLowerCase();
  if (normalized == 'connection error') {
    return s?.exploreConnectionError ?? 'Connection error';
  }
  if (normalized == 'failed to load') {
    return s?.exploreFailedToLoad ?? 'Failed to load';
  }
  if (message != null && message.trim().isNotEmpty) return message;
  return s?.exploreSomethingWentWrong ?? 'Something went wrong';
}

class _EmployerLogo extends StatelessWidget {
  final String? photoUrl;
  final String? assetLogo;
  final String initial;
  final Color color;
  final double size;

  const _EmployerLogo({
    required this.photoUrl,
    this.assetLogo,
    required this.initial,
    required this.color,
    this.size = 42,
  });

  @override
  Widget build(BuildContext context) {
    if (assetLogo != null) {
      final isDole = assetLogo!.contains('DOLE');
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDole
                ? const Color(0xFF1E3A8A).withValues(alpha: 0.18)
                : const Color(0xFF2563EB).withValues(alpha: 0.20),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: EdgeInsets.all(isDole ? size * 0.08 : 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Image.asset(
              assetLogo!,
              fit: isDole ? BoxFit.contain : BoxFit.cover,
            ),
          ),
        ),
      );
    }

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
        color: color.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: resolvedUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(9),
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
    final s = S.of(context);
    final showMatch = job.matchPercentage > 0;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        highlightColor: Colors.transparent,
        splashColor: const Color(0x0D2563EB),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.025),
                blurRadius: 8,
                offset: const Offset(0, 2),
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
                    assetLogo: job.assetLogoPath,
                    initial: job.companyInitial,
                    color: job.companyColor,
                    size: 34,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      job.company,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  AnimatedBookmarkButton(
                    isSaved: isSaved,
                    onTap: onSave,
                    tooltip: isSaved
                        ? (s?.exploreSaved ?? 'Saved')
                        : (s?.save ?? 'Save'),
                    activeColor: _kExplorePrimaryBlue,
                    inactiveColor: const Color(0xFF64748B),
                    size: 17,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                job.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _MiniMetaPill(
                    icon: HugeIcons.strokeRoundedClock01,
                    label: job.employmentTypeLabel,
                  ),
                  _MiniMetaPill(
                    icon: HugeIcons.strokeRoundedMoney01,
                    label: job.salaryDisplay,
                  ),
                  if (showMatch)
                    _MiniMetaPill(
                      icon: HugeIcons.strokeRoundedCheckmarkCircle01,
                      label: s?.exploreMatchPercent(job.matchPercentage) ??
                          '${job.matchPercentage}% match',
                      color: const Color(0xFF0D9488),
                    ),
                  if (job.isDoleProgram)
                    _MiniMetaPill(
                      icon: HugeIcons.strokeRoundedBerlin,
                      label: job.program != null &&
                              job.program!.trim().isNotEmpty &&
                              job.program!.toLowerCase() != 'none'
                          ? 'DOLE • ${job.program}'
                          : 'DOLE',
                      color: const Color(0xFF1D4ED8),
                    )
                  else if (job.isPesoOffice)
                    const _MiniMetaPill(
                      icon: HugeIcons.strokeRoundedCheckmarkCircle01,
                      label: 'PESO Santiago',
                      color: Color(0xFF0284C7),
                    ),
                  if (job.isOverseas)
                    _MiniMetaPill(
                      icon: HugeIcons.strokeRoundedGlobe02,
                      label: 'Overseas',
                      color: const Color(0xFF4F46E5),
                    ),
                  if (job.isUrgent)
                    _MiniMetaPill(
                      icon: HugeIcons.strokeRoundedAlertCircle,
                      label: s?.exploreUrgent ?? 'Urgent',
                      color: const Color(0xFFDC2626),
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
    final s = S.of(context);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        highlightColor: Colors.transparent,
        splashColor: const Color(0x0D2563EB),
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
                assetLogo: job.assetLogoPath,
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
                      '${_explorePostedLabelForLocale(context, job.postedDate)} · ${job.employmentTypeLabel}',
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
              AnimatedBookmarkButton(
                isSaved: isSaved,
                onTap: onSave,
                tooltip: isSaved
                    ? (s?.exploreSaved ?? 'Saved')
                    : (s?.save ?? 'Save'),
                activeColor: _kExplorePrimaryBlue,
                inactiveColor: const Color(0xFF64748B),
                size: 19,
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
  final dynamic icon;
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon is IconData
              ? Icon(icon, size: 11, color: color)
              : HugeIcon(
                  icon: icon as List<List<dynamic>>,
                  size: 11,
                  color: color,
                  strokeWidth: 1.8,
                ),
          const SizedBox(width: 3.5),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10.5,
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
    final s = S.of(context);

    final dateLabel =
        DateFormat('EEEE, MMM d', s?.localeName).format(events.first.eventDate);
    final monthLabel =
        DateFormat('MMM', s?.localeName).format(events.first.eventDate);
    final dayLabel = DateFormat('d').format(events.first.eventDate);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onOpenEvents,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Cover Banner Image Header
              SizedBox(
                height: 125,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (events.first.imageUrl != null &&
                        events.first.imageUrl!.isNotEmpty) ...[
                      Image.network(
                        events.first.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                            ),
                          ),
                        ),
                      ),
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.black38, Colors.transparent, Colors.black54],
                          ),
                        ),
                      ),
                    ] else ...[
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                          ),
                        ),
                      ),
                      Positioned(
                        right: -10,
                        bottom: -20,
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedCalendar03,
                          size: 100,
                          color: Colors.white.withValues(alpha: 0.12),
                          strokeWidth: 1.5,
                        ),
                      ),
                    ],

                    // Top-Left Floating Date Badge
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              dayLabel,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF1E40AF),
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              monthLabel.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1E40AF),
                                height: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Top-Right Floating Category Badge
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _kExplorePrimaryBlue,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          events.first.typeLabel.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ),

                    // Date subtitle overlay at bottom of cover photo
                    Positioned(
                      left: 12,
                      bottom: 8,
                      right: 12,
                      child: Text(
                        dateLabel,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          shadows: [
                            const Shadow(
                              color: Colors.black54,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Details Section
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 64,
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
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0F172A),
                                    height: 1.2,
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
                    const SizedBox(height: 8),
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
                          s?.exploreViewDetails ?? 'View details',
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
            ],
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
  final dynamic icon;
  final Color iconColor;

  const _SnapshotStripCell({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: icon is IconData
                ? Icon(icon, color: iconColor, size: 14)
                : HugeIcon(
                    icon: icon as List<List<dynamic>>,
                    color: iconColor,
                    size: 14,
                    strokeWidth: 2.0,
                  ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Auto-Glide Events Carousel ──────────────────────────────────────────────

class _AutoGlideEventsCarousel extends StatefulWidget {
  final List<PesoEvent> events;
  final void Function(PesoEvent event) onEventTap;

  const _AutoGlideEventsCarousel({
    required this.events,
    required this.onEventTap,
  });

  @override
  State<_AutoGlideEventsCarousel> createState() =>
      __AutoGlideEventsCarouselState();
}

class __AutoGlideEventsCarouselState extends State<_AutoGlideEventsCarousel> {
  late final ScrollController _scrollController;
  Timer? _glideTimer;
  Timer? _resumeTimer;
  bool _isUserInteracting = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _startAutoGlide();
  }

  @override
  void dispose() {
    _glideTimer?.cancel();
    _resumeTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  bool _isWidgetInViewport() {
    if (!mounted) return false;
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.attached) return false;

    final position = renderBox.localToGlobal(Offset.zero);
    final screenHeight = MediaQuery.of(context).size.height;

    return position.dy < screenHeight &&
        (position.dy + renderBox.size.height) > 0;
  }

  void _startAutoGlide() {
    if (widget.events.length <= 1) return;
    _glideTimer?.cancel();
    _glideTimer = Timer.periodic(const Duration(milliseconds: 3800), (_) {
      if (_isUserInteracting ||
          !_scrollController.hasClients ||
          !_isWidgetInViewport()) {
        return;
      }

      final maxExtent = _scrollController.position.maxScrollExtent;
      final currentOffset = _scrollController.offset;
      // step = itemExtent = cardWidth + gap = (screen - 20 - 48) + 12
      final screenW = MediaQuery.sizeOf(context).width;
      final step = (screenW - 20.0 - 48.0) + 12.0;

      final currentIndex = (currentOffset / step).round();
      final nextIndex = currentIndex + 1;
      double targetOffset = nextIndex * step;

      if (targetOffset >= maxExtent + 20) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
        );
      } else {
        _scrollController.animateTo(
          targetOffset.clamp(0.0, maxExtent),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _snapToNearestCard() {
    if (!_scrollController.hasClients) return;
    final maxExtent = _scrollController.position.maxScrollExtent;
    final currentOffset = _scrollController.offset;
    // step = itemExtent = cardWidth + gap = (screen - 20 - 48) + 12
    final screenW = MediaQuery.sizeOf(context).width;
    final step = (screenW - 20.0 - 48.0) + 12.0;

    final targetIndex = (currentOffset / step).round();
    final targetOffset = (targetIndex * step).clamp(0.0, maxExtent);

    if ((currentOffset - targetOffset).abs() > 1.0) {
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _pauseAutoGlide() {
    _isUserInteracting = true;
    _glideTimer?.cancel();
    _resumeTimer?.cancel();
  }

  void _scheduleResume() {
    _snapToNearestCard();
    _resumeTimer?.cancel();
    _resumeTimer = Timer(const Duration(milliseconds: 3500), () {
      if (mounted) {
        setState(() {
          _isUserInteracting = false;
        });
        _startAutoGlide();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    // Visible card width: screen - leftPadding(20) - rightPeek(48)
    const kGap = 12.0;
    const kLeftPad = 20.0;
    const kPeek = 48.0;
    final cardWidth = screenWidth - kLeftPad - kPeek;
    // Each item = card + gap, so the ListView item width is cardWidth + gap
    final itemWidth = cardWidth + kGap;

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollStartNotification &&
            notification.dragDetails != null) {
          _pauseAutoGlide();
        } else if (notification is ScrollEndNotification) {
          _scheduleResume();
        }
        return false;
      },
      child: SizedBox(
        height: 235,
        child: ListView.builder(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(left: kLeftPad),
          itemCount: widget.events.length,
          itemExtent: itemWidth, // exact item width for perfect snapping
          itemBuilder: (context, index) {
            final e = widget.events[index];
            return Padding(
              padding: const EdgeInsets.only(right: kGap),
              child: _EventCarouselCard(
                event: e,
                onTap: () => widget.onEventTap(e),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _EventCarouselCard extends StatelessWidget {
  final PesoEvent event;
  final VoidCallback onTap;

  const _EventCarouselCard({
    required this.event,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final hasImage = event.imageUrl != null && event.imageUrl!.isNotEmpty;
    final dateLabel =
        DateFormat('EEEE, MMM d', s?.localeName).format(event.eventDate);
    final monthLabel =
        DateFormat('MMM', s?.localeName).format(event.eventDate);
    final dayLabel = DateFormat('d').format(event.eventDate);

    final meta = <String>[];
    final t = event.eventTime?.trim();
    if (t != null && t.isNotEmpty) meta.add(t);
    if (event.location.trim().isNotEmpty) {
      meta.add(event.location.trim());
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Cover Banner Image Header
              Hero(
                tag: 'event_header_${event.id}',
                child: Material(
                  color: Colors.transparent,
                  child: SizedBox(
                    height: 125,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (hasImage) ...[
                          Image.network(
                            event.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF1E3A8A),
                                    Color(0xFF2563EB)
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black38,
                                  Colors.transparent,
                                  Colors.black54
                                ],
                              ),
                            ),
                          ),
                        ] else ...[
                          Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                              ),
                            ),
                          ),
                          Positioned(
                            right: -10,
                            bottom: -20,
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedCalendar03,
                              size: 100,
                              color: Colors.white.withValues(alpha: 0.12),
                              strokeWidth: 1.5,
                            ),
                          ),
                        ],

                        // Top-Left Floating Date Badge
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  dayLabel,
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF1E40AF),
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  monthLabel.toUpperCase(),
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF1E40AF),
                                    height: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Top-Right Floating Category Badge
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: _kExplorePrimaryBlue,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              event.typeLabel.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ),

                        // Date subtitle overlay at bottom of cover photo
                        Positioned(
                          left: 12,
                          bottom: 8,
                          right: 12,
                          child: Text(
                            dateLabel,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              shadows: [
                                const Shadow(
                                  color: Colors.black54,
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom Details Section
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                              height: 1.2,
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            s?.exploreViewDetails ?? 'View details',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: _kExplorePrimaryBlue,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 10,
                            color: _kExplorePrimaryBlue,
                          ),
                        ],
                      ),
                    ],
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

// ─── Continuous Marquee Company Carousel ────────────────────────────────────
// Continuous smooth gliding ticker (infinite loop). Touch pauses instantly;
// lifting finger keeps it stationary for 4 seconds before resuming.

class _AutoGlideCompanyCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> companies;
  final void Function(String name, String? photoUrl) onCompanyTap;

  const _AutoGlideCompanyCarousel({
    required this.companies,
    required this.onCompanyTap,
  });

  @override
  State<_AutoGlideCompanyCarousel> createState() =>
      __AutoGlideCompanyCarouselState();
}

class __AutoGlideCompanyCarouselState extends State<_AutoGlideCompanyCarousel>
    with SingleTickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final AnimationController _ticker;
  Timer? _resumeTimer;

  /// Speed of continuous sliding marquee in pixels per second
  static const double _kVelocity = 48.0;

  /// Card width (176) + padding (12)
  static const double _kItemWidth = 188.0;

  bool _isPaused = false;
  bool _isFingerDown = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(days: 365),
    )..addListener(_onTick);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.companies.isEmpty) return;
      final mid = _oneLoopWidth;
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(mid);
      }
      _ticker.forward();
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    _resumeTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  double get _oneLoopWidth => widget.companies.length * _kItemWidth;

  bool _isWidgetInViewport() {
    if (!mounted) return false;
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.attached) return false;

    final position = renderBox.localToGlobal(Offset.zero);
    final screenHeight = MediaQuery.of(context).size.height;

    return position.dy < screenHeight &&
        (position.dy + renderBox.size.height) > 0;
  }

  void _onTick() {
    if (_isPaused ||
        _isFingerDown ||
        !mounted ||
        !_scrollController.hasClients ||
        !_isWidgetInViewport()) {
      return;
    }

    const frameMs = 1000.0 / 60.0;
    final step = _kVelocity * (frameMs / 1000.0);

    double next = _scrollController.offset + step;
    final loopWidth = _oneLoopWidth;

    if (loopWidth > 0 && next >= loopWidth * 2) {
      next -= loopWidth;
      _scrollController.jumpTo(next);
      return;
    }
    _scrollController.jumpTo(next);
  }

  void _pauseMarquee() {
    _resumeTimer?.cancel();
    _isPaused = true;
  }

  void _scheduleResume() {
    _resumeTimer?.cancel();
    // Keep stationary for 4 full seconds after finger is lifted / drag ends
    _resumeTimer = Timer(const Duration(milliseconds: 4000), () {
      if (mounted && !_isFingerDown) {
        setState(() {
          _isPaused = false;
        });
      }
    });
  }

  void _onPointerDown(PointerDownEvent _) {
    _isFingerDown = true;
    _pauseMarquee();
  }

  void _onPointerUp(PointerUpEvent _) {
    _isFingerDown = false;
    _scheduleResume();
  }

  void _onPointerCancel(PointerCancelEvent _) {
    _isFingerDown = false;
    _scheduleResume();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.companies.isEmpty) return const SizedBox.shrink();

    // Triple list for seamless infinite loop [copy A][copy B][copy C]
    final looped = [
      ...widget.companies,
      ...widget.companies,
      ...widget.companies,
    ];

    return Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: SizedBox(
        height: 118,
        child: ListView.builder(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: looped.length,
          itemExtent: _kItemWidth,
          itemBuilder: (context, index) {
            final company = looped[index];
            final realIndex = index % widget.companies.length;
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _CompanyCard(
                name: company['name'] as String? ?? '',
                initial: (company['initial'] as String?) ?? '',
                photoUrl: company['photo_url'] as String?,
                assetLogo: company['asset_logo'] as String?,
                jobCount: (company['job_count'] as num?)?.toInt() ?? 0,
                delay: realIndex * 40,
                onTap: () => widget.onCompanyTap(
                  company['name'] as String? ?? '',
                  company['photo_url'] as String?,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── Company Card Widget ──────────────────────────────────────────────────────


class _CompanyCard extends StatelessWidget {
  final String name;
  final String initial;
  final String? photoUrl;
  final String? assetLogo;
  final int jobCount;
  final int delay;
  final VoidCallback onTap;

  const _CompanyCard({
    required this.name,
    required this.initial,
    required this.photoUrl,
    this.assetLogo,
    required this.jobCount,
    required this.delay,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final resolvedUrl = ApiService.storageOrAbsoluteUrl(photoUrl);
    final logo = _EmployerLogo(
      photoUrl: resolvedUrl,
      assetLogo: assetLogo,
      initial: initial,
      color: _kExplorePrimaryBlue,
      size: 42,
    );

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () {
            AppHaptics.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 176,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
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
                        s?.exploreJobCount(jobCount) ??
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
    final gradientColors = isUserSkill
        ? const [Color(0xFF059669), Color(0xFF10B981)]
        : const [Color(0xFF2563EB), Color(0xFF3B82F6)];
    final shadowColor = isUserSkill
        ? const Color(0xFF10B981).withValues(alpha: 0.35)
        : const Color(0xFF2563EB).withValues(alpha: 0.35);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
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
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.1,
                  ),
                ),
              ),
              if (isUserSkill) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: const Color(0xFFA7F3D0),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 11,
                        color: Color(0xFF059669),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'Matched',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF334155),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              return Container(
                height: 10,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 450 + delay),
                    curve: Curves.easeOutCubic,
                    height: 10,
                    width: constraints.maxWidth * ratio,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: LinearGradient(
                        colors: gradientColors,
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: shadowColor,
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
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
  final dynamic icon;
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
    final s = S.of(context);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () {
          AppHaptics.lightImpact();
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
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: icon is IconData
                    ? Icon(icon, color: color, size: 14)
                    : HugeIcon(
                        icon: icon as List<List<dynamic>>,
                        color: color,
                        size: 14,
                        strokeWidth: 2.0,
                      ),
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
                      s?.exploreJobCount(jobCount) ??
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
