import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:showcaseview/showcaseview.dart';
import 'profile_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'job_models.dart';
import 'event_models.dart';
import 'user_session.dart';
import 'api_service.dart';
import 'notification_service.dart';
import 'job_action_service.dart';
import 'micro_interactions.dart';
import 'my_documents_page.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';
import 'location_controller.dart';
import 'skill_match_utils.dart';
import 'onboarding_prefs.dart';
import 'package:geolocator/geolocator.dart' show LocationPermission;
import 'l10n/app_localizations.dart';
import 'locale_service.dart';

final String mapboxToken = dotenv.env['MAPBOX_TOKEN'] ?? '';

final String mapboxAccessToken = mapboxToken.isNotEmpty ? mapboxToken : '';

// ─── Coach-mark tour keys & notifiers ────────────────────────────────────────

/// Set to `true` from Help page to replay the home tour on next visit.
final ValueNotifier<bool> replayHomeTourNotifier = ValueNotifier<bool>(false);
/// Increment this to request Home tab list scroll reset.
final ValueNotifier<int> homeTourScrollResetNotifier = ValueNotifier<int>(0);

/// GlobalKeys shared between _HomePageState and _HomeTabState.
final GlobalKey _showcaseMascot = GlobalKey();
final GlobalKey _showcaseBell = GlobalKey();
final GlobalKey _showcaseSearch = GlobalKey();
final GlobalKey _showcaseJobCard = GlobalKey();
final GlobalKey _showcaseEventsFab = GlobalKey();
final GlobalKey _showcaseNavBar = GlobalKey();

/// Map-tour keys (used in _MapTabState).
final GlobalKey _showcaseMapBestMatch = GlobalKey();
final GlobalKey _showcaseMapLocProfiles = GlobalKey();

Future<bool> _ensureResumeReadyForApply(
    BuildContext context, JobActionService jobActionService) async {
  final hasResume = await jobActionService.hasResumeOnFile();
  if (hasResume) return true;
  if (!context.mounted) return false;

  final l10n = S.of(context);
  final goToDocuments = await showAppDialog<bool>(
    context: context,
    type: AppDialogType.info,
    icon: Icons.description_outlined,
    title: l10n?.resumeRequired ?? 'Resume Required',
    message: l10n?.resumeRequiredMessage ?? 'You need to upload your resume first before applying to jobs.',
    confirmLabel: l10n?.goToDocuments ?? 'Go to Documents',
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

class MapFocusRequest {
  final String companyName;
  final String locationText;
  final double? latitude;
  final double? longitude;

  const MapFocusRequest({
    required this.companyName,
    required this.locationText,
    this.latitude,
    this.longitude,
  });

  factory MapFocusRequest.fromJob(Job job) {
    return MapFocusRequest(
      companyName: job.company,
      locationText: job.location,
      latitude: job.latitude,
      longitude: job.longitude,
    );
  }
}

final ValueNotifier<int?> homeNavRequestNotifier = ValueNotifier<int?>(null);
/// Current selected tab index on HomePage (0=Home, 1=Map, 2=Profile).
final ValueNotifier<int> activeHomeTabIndexNotifier = ValueNotifier<int>(0);
final ValueNotifier<MapFocusRequest?> mapFocusRequestNotifier =
    ValueNotifier<MapFocusRequest?>(null);

/// Increment when jobseeker skills in session change so [MapTab] repaints matches.
final ValueNotifier<int> mapUserSkillsRevisionNotifier = ValueNotifier<int>(0);

/// Reliable live updates after register/unregister (StatefulBuilder can miss rebuilds on web).
class _EventDetailDialog extends StatefulWidget {
  final PesoEvent initialEvent;
  final VoidCallback onRegistrationChanged;
  final BuildContext hostContext;

  const _EventDetailDialog({
    required this.initialEvent,
    required this.onRegistrationChanged,
    required this.hostContext,
  });

  @override
  State<_EventDetailDialog> createState() => _EventDetailDialogState();
}

class _EventDetailDialogState extends State<_EventDetailDialog> {
  late PesoEvent _event;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _event = widget.initialEvent;
  }

  Future<void> _onPrimaryAction(BuildContext dialogContext) async {
    final token = UserSession().token;
    if (token == null || token.isEmpty) {
      Navigator.of(dialogContext).pop();
      CustomToast.show(
        widget.hostContext,
        message: 'Please log in to register for events.',
        type: ToastType.error,
      );
      return;
    }
    setState(() => _busy = true);
    final Map<String, dynamic> res = _event.isRegistered
        ? await ApiService.unregisterFromEvent(token: token, eventId: _event.id)
        : await ApiService.registerForEvent(token: token, eventId: _event.id);
    if (!mounted) return;
    setState(() => _busy = false);
    if (res['success'] == true) {
      HapticFeedback.lightImpact(); // Added subtle buzz for event registration toggle
      final data = res['data'];
      final pc = data is Map<String, dynamic>
          ? (data['participants_count'] as num?)?.toInt()
          : null;
      final nextRegistered = !_event.isRegistered;
      setState(() {
        _event = _event.copyWith(
          isRegistered: nextRegistered,
          participantsCount: pc ??
              (nextRegistered
                  ? _event.participantsCount + 1
                  : (_event.participantsCount > 0
                      ? _event.participantsCount - 1
                      : 0)),
        );
      });
      microInteractionSuccess();
      widget.onRegistrationChanged();
      CustomToast.show(
        widget.hostContext,
        message: _event.isRegistered
            ? 'Registered for ${_event.title}'
            : 'Cancelled registration',
        type: ToastType.success,
      );
    } else {
      CustomToast.show(
        widget.hostContext,
        message: res['message']?.toString() ?? 'Something went wrong',
        type: ToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryDisabled = _busy || (!_event.isRegistered && _event.isFull);

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Image/Color area
              Container(
                height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                  ),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20,
                      top: -20,
                      child: Icon(
                        Icons.event_note_rounded,
                        size: 140,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    Positioned(
                      top: 16,
                      right: 16,
                      child: IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white12,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _event.typeLabel.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _event.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _detailInfoRow(
                        Icons.calendar_today_rounded, _event.formattedDate),
                    if (_event.eventTime != null)
                      _detailInfoRow(
                          Icons.access_time_rounded, _event.eventTime!),
                    _detailInfoRow(Icons.location_on_rounded, _event.location),
                    _detailInfoRow(Icons.people_alt_rounded, _event.slotsLabel),
                    if (_event.organizer != null)
                      _detailInfoRow(Icons.business_rounded,
                          'Organized by ${_event.organizer}'),
                    const SizedBox(height: 20),
                    const Text(
                      'About this Event',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _event.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: primaryDisabled
                          ? null
                          : () => _onPrimaryAction(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: _event.isRegistered
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF2563EB),
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: _busy
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: Colors.white),
                            )
                          : Text(
                              _event.isRegistered
                                  ? 'Cancel Registration'
                                  : 'Register Now',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF2563EB)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                  height: 1.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Events page keeps its own [Future] so register/cancel updates the list
/// immediately (parent [_reloadEventsFuture] alone does not rebuild an open page).
class _EventsPage extends StatefulWidget {
  final BuildContext homeContext;
  final VoidCallback onParentReloadEvents;
  final List<PesoEvent> Function(Map<String, dynamic>) parseEventsPayload;

  const _EventsPage({
    required this.homeContext,
    required this.onParentReloadEvents,
    required this.parseEventsPayload,
  });

  @override
  State<_EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<_EventsPage> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService.getEventsWithRegistration();
  }

  void _afterRegistrationChanged() {
    widget.onParentReloadEvents();
    setState(() {
      _future = ApiService.getEventsWithRegistration();
    });
  }

  void _openEventDetail(PesoEvent e) {
    showDialog(
      context: context,
      builder: (ctx) => _EventDetailDialog(
        initialEvent: e,
        onRegistrationChanged: _afterRegistrationChanged,
        hostContext: widget.homeContext,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.event_note_rounded,
                color: Color(0xFF2563EB),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  S.of(context)?.events ?? 'Events',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  LocaleService.instance.locale.languageCode == 'tl'
                      ? 'Manatiling updated sa job fairs at seminars'
                      : 'Stay updated on job fairs and seminars',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF2563EB)));
          }
          final data = snapshot.data;
          if (data == null || data['success'] != true) {
            return const Center(child: Text('Failed to load events'));
          }
          final events = widget.parseEventsPayload(data);
          if (events.isEmpty) {
            return const Center(
              child: Text('No upcoming events found',
                  style: TextStyle(color: Colors.grey)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final e = events[index];
              return _buildEventCard(e)
                  .animate()
                  .fadeIn(delay: (index * 50).ms, duration: 400.ms)
                  .slideY(begin: 0.1, curve: Curves.easeOutCubic);
            },
          );
        },
      ),
    );
  }

  Widget _buildEventCard(PesoEvent e) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openEventDetail(e),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Date Section
                Container(
                  width: 80,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        e.dateBadgeDay,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        e.dateBadgeMonthUpper,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white70,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        e.dateBadgeYear,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
                // Content Section
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              e.typeLabel.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF2563EB),
                                letterSpacing: 1,
                              ),
                            ),
                            const Spacer(),
                            if (e.isRegistered)
                              const Icon(Icons.check_circle_rounded,
                                  size: 16, color: Colors.green)
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          e.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.access_time_rounded,
                                size: 14, color: Color(0xFF64748B)),
                            const SizedBox(width: 4),
                            Text(
                              e.eventTime ?? 'TBA',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded,
                                size: 14, color: Color(0xFF64748B)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                e.location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500),
                              ),
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
      ),
    );
  }
}

// ─── User Location ────────────────────────────────────────────────────────────
//
// These constants are only used as a *fallback* (e.g. before the user has
// granted GPS permission). The real, live user position is provided by
// [LocationController.instance.effectiveLocation].
const double userLatitude = 16.689315116453432;
const double userLongitude = 121.55584211537534;

/// Returns the current user point that all distance/ranking logic should
/// be based on: prefers the user's manual override, falls back to live GPS,
/// and finally to the demo Santiago City coordinates.
({double lat, double lng}) currentUserPoint() {
  final p = LocationController.instance.effectiveLocation;
  if (p != null) return (lat: p.latitude, lng: p.longitude);
  return (lat: userLatitude, lng: userLongitude);
}

// ─── Business Model ───────────────────────────────────────────────────────────
class Business {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final double latitude;
  final double longitude;
  final List<Job> availableJobs;

  const Business({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.latitude,
    required this.longitude,
    required this.availableJobs,
  });

  /// Distance in meters from the current effective user location.
  ///
  /// Optionally pass [fromLat]/[fromLng] (e.g. the live GPS reading captured
  /// in a State) to avoid reading the global controller while building lists.
  double getDistanceFromUser({double? fromLat, double? fromLng}) {
    final lat = fromLat ?? currentUserPoint().lat;
    final lng = fromLng ?? currentUserPoint().lng;
    return _calculateDistance(lat, lng, latitude, longitude);
  }

  static double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000;
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);
    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }
}

// ─── Demo Business Data ───────────────────────────────────────────────────────
final List<Business> demoBusinesses = [
  Business(
    id: 'sm_savemore',
    name: 'SM SaveMore Market Fourlanes',
    description:
        'SM SaveMore Market is a supermarket chain in the Philippines. We offer various career opportunities in retail, customer service, and management.',
    imageUrl:
        'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6d/SM_Savemore_logo.svg/1200px-SM_Savemore_logo.svg.png',
    latitude: 16.691563823014416,
    longitude: 121.55501604272028,
    availableJobs: [
      Job(
        id: 'sm1',
        title: 'Cashier',
        company: 'SM SaveMore Market',
        companyInitial: 'S',
        companyColor: const Color(0xFFE11D48),
        location: 'Santiago City, Isabela',
        description:
            'We are looking for friendly and efficient cashiers to provide excellent customer service and handle transactions accurately.',
        requirements: [
          'High school graduate',
          'Good communication skills',
          'Basic math skills',
          'Customer service oriented',
          'Willing to work in shifts',
        ],
        skills: ['Cash Handling', 'Customer Service', 'POS System'],
        experienceLevel: 'No experience required',
        salaryMin: '₱12,000',
        salaryMax: '₱15,000',
        employmentType: 'Full-time',
        postedDate: DateTime.now().subtract(const Duration(days: 1)),
        matchPercentage: 85,
        isUrgent: true,
      ),
      Job(
        id: 'sm2',
        title: 'Stock Clerk',
        company: 'SM SaveMore Market',
        companyInitial: 'S',
        companyColor: const Color(0xFFE11D48),
        location: 'Santiago City, Isabela',
        description:
            'Responsible for organizing and stocking merchandise, maintaining inventory levels, and ensuring products are properly displayed.',
        requirements: [
          'High school graduate',
          'Physically fit',
          'Can lift heavy items',
          'Team player',
          'Willing to work in shifts',
        ],
        skills: ['Inventory Management', 'Organization', 'Physical Stamina'],
        experienceLevel: 'No experience required',
        salaryMin: '₱11,000',
        salaryMax: '₱14,000',
        employmentType: 'Full-time',
        postedDate: DateTime.now().subtract(const Duration(days: 3)),
        matchPercentage: 75,
        isUrgent: false,
      ),
    ],
  ),
  Business(
    id: 'robinsons',
    name: 'Robinsons Place Santiago',
    description:
        'Robinsons Place Santiago is a shopping mall offering retail, dining, and entertainment options. Join our team and be part of a dynamic work environment.',
    imageUrl:
        'https://upload.wikimedia.org/wikipedia/en/thumb/c/cc/Robinsons_Malls_logo.svg/1200px-Robinsons_Malls_logo.svg.png',
    latitude: 16.69708186022431,
    longitude: 121.56100412697754,
    availableJobs: [
      Job(
        id: 'rob1',
        title: 'Sales Associate',
        company: 'Robinsons Department Store',
        companyInitial: 'R',
        companyColor: const Color(0xFF7C3AED),
        location: 'Santiago City, Isabela',
        description:
            'Be part of our sales team! Assist customers in finding products, provide product information, and ensure excellent shopping experience.',
        requirements: [
          'At least high school graduate',
          'Good communication skills',
          'Pleasant personality',
          'Sales oriented',
          'Can work on weekends and holidays',
        ],
        skills: ['Sales', 'Customer Service', 'Product Knowledge'],
        experienceLevel: 'Entry level',
        salaryMin: '₱13,000',
        salaryMax: '₱16,000',
        employmentType: 'Full-time',
        postedDate: DateTime.now().subtract(const Duration(days: 2)),
        matchPercentage: 88,
        isUrgent: true,
      ),
      Job(
        id: 'rob2',
        title: 'Security Guard',
        company: 'Robinsons Place Santiago',
        companyInitial: 'R',
        companyColor: const Color(0xFF7C3AED),
        location: 'Santiago City, Isabela',
        description:
            'Maintain safety and security of the mall premises. Monitor CCTV, conduct patrols, and respond to emergencies.',
        requirements: [
          'High school graduate',
          'With security training/license',
          'Physically fit',
          'Good observation skills',
          'Can work in rotating shifts',
        ],
        skills: ['Security', 'CCTV Monitoring', 'Emergency Response'],
        experienceLevel: '1 year experience',
        salaryMin: '₱14,000',
        salaryMax: '₱18,000',
        employmentType: 'Full-time',
        postedDate: DateTime.now().subtract(const Duration(days: 4)),
        matchPercentage: 70,
        isUrgent: false,
      ),
      Job(
        id: 'rob3',
        title: 'Customer Service Representative',
        company: 'Robinsons Place Santiago',
        companyInitial: 'R',
        companyColor: const Color(0xFF7C3AED),
        location: 'Santiago City, Isabela',
        description:
            'Handle customer inquiries, complaints, and requests. Provide information about mall services and promotions.',
        requirements: [
          'College graduate preferred',
          'Excellent communication skills',
          'Patient and courteous',
          'Computer literate',
          'Can work on flexible schedule',
        ],
        skills: ['Customer Service', 'Communication', 'Problem Solving'],
        experienceLevel: 'Entry level',
        salaryMin: '₱15,000',
        salaryMax: '₱18,000',
        employmentType: 'Full-time',
        postedDate: DateTime.now(),
        matchPercentage: 92,
        isUrgent: true,
      ),
    ],
  ),
];

// ─── Home Page with Bottom Navigation ────────────────────────────────────────
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  late Future<Map<String, dynamic>> _eventsFuture;

  /// Tracks event list length to pulse FAB when new events appear (count increases).
  int _lastSeenEventCount = -1;
  double _fabPulseScale = 1.0;

  void _pulseEventsFab() {
    setState(() => _fabPulseScale = 1.12);
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _fabPulseScale = 1.0);
    });
  }

  List<PesoEvent> _parseEventsPayload(Map<String, dynamic> data) {
    final raw = data['data'] as List<dynamic>? ?? [];
    final regIds = <int>{};
    final rid = data['registered_ids'];
    if (rid is List) {
      for (final x in rid) {
        if (x is num) regIds.add(x.toInt());
      }
    }
    final now = DateTime.now();

    return raw.map((item) {
      final e = item as Map<String, dynamic>;
      final id = (e['id'] as num).toInt();
      return PesoEvent.fromJson(e, isRegistered: regIds.contains(id));
    }).where((event) {
      // Match public API intent: only events that are not finished or cancelled
      // and with an eventDate that is today or in the future.
      final s = event.status.toLowerCase();
      final isActiveStatus = s == 'upcoming' || s == 'ongoing';

      // Normalize both dates to midnight to avoid off‑by‑one from time parts / time zones.
      final eventDay = DateTime(
          event.eventDate.year, event.eventDate.month, event.eventDate.day);
      final today = DateTime(now.year, now.month, now.day);

      final isTodayOrFuture = !eventDay.isBefore(today);

      return isActiveStatus && isTodayOrFuture;
    }).toList();
  }

  void _reloadEventsFuture() {
    setState(() {
      _eventsFuture = ApiService.getEventsWithRegistration();
    });
  }

  /// Keep all tabs mounted so switching pill nav does not dispose HomeTab
  /// (avoids full-screen "Loading jobs..." on every return to Home).
  late final List<Widget> _tabPages = [
    HomeTab(onOpenMapRequested: _openMapForJob),
    const MapTab(),
    const ProfileTab(),
  ];

  @override
  void initState() {
    super.initState();
    _eventsFuture = ApiService.getEventsWithRegistration();
    activeHomeTabIndexNotifier.value = _selectedIndex;
    homeNavRequestNotifier.addListener(_onHomeNavRequested);
    replayHomeTourNotifier.addListener(_onReplayHomeTour);

    _registerShowcase();

    // Kick off global background sync tasks immediately (non-blocking)
    _startGlobalBackgroundSync();

    // Auto-start the coach-mark tour for first-time users
    _maybeStartHomeTour();
  }

  // ── Showcase registration ─────────────────────────────────────────────────

  void _registerShowcase() {
    ShowcaseView.register(
      blurValue: 1,
      globalTooltipActionConfig: const TooltipActionConfig(
        position: TooltipActionPosition.inside,
        alignment: MainAxisAlignment.spaceBetween,
      ),
      globalTooltipActions: [
        TooltipActionButton(
          type: TooltipDefaultActionType.previous,
          textStyle: const TextStyle(color: Colors.white),
          hideActionWidgetForShowcase: [_showcaseMascot],
        ),
        TooltipActionButton(
          type: TooltipDefaultActionType.next,
          textStyle: const TextStyle(color: Colors.white),
          hideActionWidgetForShowcase: [_showcaseNavBar],
        ),
        TooltipActionButton(
          type: TooltipDefaultActionType.next,
          name: 'Finish',
          textStyle: const TextStyle(color: Colors.white),
          hideActionWidgetForShowcase: [
            _showcaseMascot,
            _showcaseBell,
            _showcaseSearch,
            _showcaseJobCard,
            _showcaseEventsFab,
            _showcaseMapBestMatch,
            _showcaseMapLocProfiles,
          ],
        ),
      ],
      globalFloatingActionWidget: (ctx) => FloatingActionWidget(
        left: 16,
        bottom: 16,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () {
              ShowcaseView.get().dismiss();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
            ),
            child: const Text(
              'Skip tour',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
      hideFloatingActionWidgetForShowcase: [_showcaseNavBar],
      onComplete: (index, key) {
        if (key == _showcaseNavBar) {
          OnboardingPrefs.setHomeTourDone(token: UserSession().token);
        }
      },
      onDismiss: (key) {
        OnboardingPrefs.setHomeTourDone(token: UserSession().token);
      },
    );
  }

  Future<void> _maybeStartHomeTour() async {
    final token = UserSession().token;
    final done = await OnboardingPrefs.isHomeTourDone(token: token);
    if (done || !mounted) return;
    // Short delay so widgets are laid out and jobs have started loading
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    _startHomeTour();
  }

  void _startHomeTour() {
    // Reset Home list scroll so first job card showcase is aligned.
    homeTourScrollResetNotifier.value++;
    Future<void>.delayed(const Duration(milliseconds: 320), () {
      if (!mounted) return;
      ShowcaseView.get().startShowCase([
        _showcaseMascot,
        _showcaseBell,
        _showcaseSearch,
        _showcaseJobCard,
        _showcaseEventsFab,
        _showcaseNavBar,
      ]);
    });
  }

  void _onReplayHomeTour() {
    if (!replayHomeTourNotifier.value) return;
    replayHomeTourNotifier.value = false;
    if (!mounted) return;
    // Ensure we're on the Home tab
    setState(() {
      _selectedIndex = 0;
      activeHomeTabIndexNotifier.value = _selectedIndex;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startHomeTour();
    });
  }

  void _startGlobalBackgroundSync() {
    final token = UserSession().token;
    if (token != null && token.isNotEmpty) {
      // Sync saved/applied jobs list in background
      JobActionService().loadFromBackend();
      // Ensure FCM/Push token is fresh and synced
      NotificationService().syncTokenNow();
    }
  }

  @override
  void dispose() {
    homeNavRequestNotifier.removeListener(_onHomeNavRequested);
    replayHomeTourNotifier.removeListener(_onReplayHomeTour);
    ShowcaseView.get().unregister();
    super.dispose();
  }

  void _onHomeNavRequested() {
    final requestedIndex = homeNavRequestNotifier.value;
    if (requestedIndex == null) return;
    homeNavRequestNotifier.value = null;
    if (!mounted) return;
    setState(() {
      _selectedIndex = requestedIndex.clamp(0, 2);
      activeHomeTabIndexNotifier.value = _selectedIndex;
    });
  }

  void _openMapForJob(MapFocusRequest request) {
    if (!mounted) return;
    setState(() {
      _selectedIndex = 1;
      activeHomeTabIndexNotifier.value = _selectedIndex;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      mapFocusRequestNotifier.value = request;
    });
  }

  void _openEventsPage() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _EventsPage(
          homeContext: context,
          onParentReloadEvents: _reloadEventsFuture,
          parseEventsPayload: _parseEventsPayload,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBody: true,
      body: Stack(
        // Keep child order stable: IndexedStack → nav → events FAB.
        // If FAB is inserted *before* the nav when Home is selected, the nav's
        // Stack slot changes and the pill widget is recreated → no animation.
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: _tabPages,
          ),
          // Floating pill navigation bar (always 2nd child — stable for AnimatedPositioned)
          Positioned(
            left: 20,
            right: 20,
            bottom: bottomPadding + 12,
            child: Showcase(
              key: _showcaseNavBar,
              title: 'Navigation',
              description: 'Home for jobs, Map to explore nearby employers, Profile for documents and settings.',
              targetBorderRadius: BorderRadius.circular(40),
              tooltipBackgroundColor: const Color(0xFF1D4ED8),
              textColor: Colors.white,
              titleTextStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
              descTextStyle: const TextStyle(fontSize: 13.5, height: 1.4, color: Colors.white),
              child: _buildFloatingNavBar(context),
            ),
          ),
          // Floating Events button: always 3rd child; hide off-Home so Stack order never shifts
          Positioned(
            right: 20,
            bottom: bottomPadding + 92,
              child: Visibility(
                visible: _selectedIndex == 0,
                maintainState: true,
                maintainAnimation: true,
                maintainSize: false,
                child: FutureBuilder<Map<String, dynamic>>(
                  future: _eventsFuture,
                  builder: (context, snapshot) {
                    final count = snapshot.hasData &&
                            snapshot.data!['success'] == true &&
                            snapshot.data!['data'] != null
                        ? _parseEventsPayload(snapshot.data!).length
                        : 0;
                    if (snapshot.connectionState == ConnectionState.done &&
                        snapshot.hasData &&
                        snapshot.data!['success'] == true) {
                      if (_lastSeenEventCount != count) {
                        final prev = _lastSeenEventCount;
                        _lastSeenEventCount = count;
                        if (prev >= 0 && count > prev) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) _pulseEventsFab();
                          });
                        }
                      }
                    }
                    return Showcase(
                      key: _showcaseEventsFab,
                      title: 'Events',
                      description: 'Workshops, job fairs, and PESO events. The badge shows how many are upcoming.',
                      targetBorderRadius: BorderRadius.circular(16),
                      tooltipBackgroundColor: const Color(0xFF1D4ED8),
                      textColor: Colors.white,
                      titleTextStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                      descTextStyle: const TextStyle(fontSize: 13.5, height: 1.4, color: Colors.white),
                      child: AnimatedScale(
                        scale: _fabPulseScale,
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeOutBack,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _openEventsPage,
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF2563EB),
                                        Color(0xFF1D4ED8)
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF2563EB)
                                            .withOpacity(0.4),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.event_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                if (count > 0)
                                  Positioned(
                                    top: -4,
                                    right: -4,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.2),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      constraints:
                                          const BoxConstraints(minWidth: 24),
                                      child: Text(
                                        count > 99 ? '99+' : '$count',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFloatingNavBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2563EB),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const pillWidth = 108.0;
          final width = constraints.maxWidth;
          final itemWidth = width / 3;
          final pillLeft =
              itemWidth * _selectedIndex + (itemWidth - pillWidth) / 2;

          return SizedBox(
            height: 52,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedPositioned(
                  key: const ValueKey('bottom_nav_pill'),
                  left: pillLeft,
                  top: 4,
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.elasticOut,
                  child: Container(
                    height: 44,
                    width: pillWidth,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Builder(builder: (navCtx) {
                  final l10n = S.of(navCtx);
                  return Row(
                    children: [
                      Expanded(
                        child: _buildNavItem(
                            0, Icons.home_rounded, Icons.home_outlined, l10n?.navHome ?? 'Home'),
                      ),
                      Expanded(
                        child: _buildNavItem(
                            1, Icons.map_rounded, Icons.map_outlined, l10n?.navMap ?? 'Map'),
                      ),
                      Expanded(
                        child: _buildNavItem(2, Icons.person_rounded,
                            Icons.person_outline_rounded, l10n?.navProfile ?? 'Profile'),
                      ),
                    ],
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNavItem(
      int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isSelected = _selectedIndex == index;
    final iconColor =
        isSelected ? const Color(0xFF2563EB) : Colors.white.withOpacity(0.7);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (_selectedIndex != index) {
          HapticFeedback.selectionClick();
          setState(() {
            _selectedIndex = index;
            activeHomeTabIndexNotifier.value = _selectedIndex;
          });
        }
      },
      child: Center(
        child: AnimatedScale(
          scale: isSelected ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.elasticOut,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? activeIcon : inactiveIcon,
                color: iconColor,
                size: 22,
              ),
              if (isSelected) ...[
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Home Tab ─────────────────────────────────────────────────────────────────
class HomeTab extends StatefulWidget {
  final ValueChanged<MapFocusRequest>? onOpenMapRequested;

  const HomeTab({super.key, this.onOpenMapRequested});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _jobListScrollController = ScrollController();
  final FocusNode _searchFocus = FocusNode();
  final ValueNotifier<bool> _searchFocusNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String> _searchTextNotifier = ValueNotifier<String>('');
  String _searchText = ''; // Still keep for getter convenience if needed
  String _sortOption = 'Latest';
  final Set<String> _selectedEmploymentTypes = <String>{};
  final Set<String> _selectedSkillFilters = <String>{};
  String _skillFilterQuery = '';
  Map<String, List<String>> _skillCatalogByCategory = <String, List<String>>{};
  final Set<String> _expandedSkillFilterCategories = <String>{};

  /// Robot mascot on greeting banner — swaps art while tapped / long‑pressed.
  bool _homeMascotPoked = false;

  /// Idle mascot (`empoyhomepagev2.png`) — [Positioned] + image box.
  static const double _mascotIdleLeft = -21;
  static const double _mascotIdleBottom = -65.5;
  static const double _mascotIdleWidth = 153;
  static const double _mascotIdleHeight = 163;

  /// Poked mascot (`empoy_poked.png`) — tweak independently of idle.
  static const double _mascotPokedLeft = -21;
  static const double _mascotPokedBottom = -59.3;
  static const double _mascotPokedWidth = 147;
  static const double _mascotPokedHeight = 157;

  List<Job> _jobs = [];
  bool _isLoading = true;
  String? _errorMessage;
  final _jobActionService = JobActionService();
  List<int>? _avatarBytes;
  bool _isAvatarLoading = false;
  int _unreadNotificationCount = 0;

  /// -1 before first successful read; ring when count increases vs previous.
  int _previousUnreadForBell = -1;
  late AnimationController _bellRingController;
  late Animation<double> _bellAngle;
  int _jobListSerial = 0;
  String _greetingText = '';
  Timer? _notificationPollTimer;
  Timer? _greetingTimer;
  Timer? _searchDebounce;
  bool _isUnreadLoading = false;
  bool _isLoadingMoreJobs = false;
  int _jobsCurrentPage = 0;
  int _jobsLastPage = 1;
  int? _jobsTotalCount;
  bool _isGridView = false;

  static const List<String> _sortOptions = [
    'Latest',
    'Oldest',
    'Best Match',
  ];
  static const List<String> _employmentTypes = [
    'Full-time',
    'Part-time',
    'Contract',
    'Freelance',
  ];

  String? _preferredEmploymentTypeFromSession() {
    final raw = (UserSession().jobExperience ?? '').toLowerCase();
    for (final type in _employmentTypes) {
      if (raw.contains(type.toLowerCase())) return type;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _bellRingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 820),
    );
    _bellAngle = TweenSequence<double>([
      TweenSequenceItem<double>(
          tween: Tween<double>(begin: 0, end: 0.14), weight: 1),
      TweenSequenceItem<double>(
          tween: Tween<double>(begin: 0.14, end: -0.16), weight: 1),
      TweenSequenceItem<double>(
          tween: Tween<double>(begin: -0.16, end: 0.11), weight: 1),
      TweenSequenceItem<double>(
          tween: Tween<double>(begin: 0.11, end: -0.07), weight: 1),
      TweenSequenceItem<double>(
          tween: Tween<double>(begin: -0.07, end: 0), weight: 1),
    ]).animate(
        CurvedAnimation(parent: _bellRingController, curve: Curves.easeInOut));
    _bellRingController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _bellRingController.reset();
      }
    });
    _searchFocus.addListener(() {
      _searchFocusNotifier.value = _searchFocus.hasFocus;
    });
    final preferredType = _preferredEmploymentTypeFromSession();
    if (preferredType != null) {
      _selectedEmploymentTypes.add(preferredType);
    }
    _greetingText = _buildGreeting(null);
    _fetchJobs();
    _loadSkillCatalogFilters();
    _jobListScrollController.addListener(_onJobListScroll);
    homeTourScrollResetNotifier.addListener(_onHomeTourScrollResetRequested);
    _loadAvatar();
    _jobActionService.addListener(_onJobActionsChanged);
    _loadUnreadNotifications();
    // Listen for real-time notification arrivals to refresh the red badge
    NotificationService.addListener(_onPushReceived);

    _startLiveUpdates();
  }

  void _onPushReceived() {
    if (mounted) _loadUnreadNotifications();
  }

  void _ringBell() {
    HapticFeedback.lightImpact();
    _bellRingController.forward(from: 0);
  }

  Future<void> _loadAvatar() async {
    if (_isAvatarLoading) return;
    _isAvatarLoading = true;
    final token = UserSession().token;
    if (token == null || UserSession().avatarPath == null) {
      _isAvatarLoading = false;
      return;
    }
    try {
      final bytes = await ApiService.getAvatarBytes(token);
      if (mounted) setState(() => _avatarBytes = bytes);
    } finally {
      if (mounted) _isAvatarLoading = false;
    }
  }

  void _onJobActionsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    NotificationService.removeListener(_onPushReceived);
    _notificationPollTimer?.cancel();
    _greetingTimer?.cancel();
    _searchDebounce?.cancel();
    _jobListScrollController.dispose();
    homeTourScrollResetNotifier.removeListener(_onHomeTourScrollResetRequested);
    _jobActionService.removeListener(_onJobActionsChanged);
    _bellRingController.dispose();
    _searchFocus.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _startLiveUpdates() {
    // FCM handles real-time notification updates now. No polling needed.

    _greetingTimer?.cancel();
    _greetingTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) return;
      final next = _buildGreeting(context.mounted ? S.of(context) : null);
      if (next != _greetingText) {
        setState(() => _greetingText = next);
      }
    });
  }

  void _openNotifications() {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (_) => NotificationsTab(
          onOpenMapRequested: (focus) {
            Navigator.of(context).pop();
            widget.onOpenMapRequested?.call(focus);
          },
        ),
      ),
    )
        .then((_) {
      if (mounted) {
        _loadUnreadNotifications();
      }
    });
  }

  String _buildGreeting(S? l10n) {
    final hour = nowInPhilippines().hour;
    String greeting;
    if (hour >= 5 && hour < 12) {
      greeting = l10n?.greetingMorning ?? 'Good Morning';
    } else if (hour >= 12 && hour < 18) {
      greeting = l10n?.greetingAfternoon ?? 'Good Afternoon';
    } else {
      greeting = l10n?.greetingEvening ?? 'Good Evening';
    }
    return '$greeting, Kabsat';
  }

  String _getPhilippinesGreeting() => _greetingText;

  Future<void> _loadUnreadNotifications() async {
    if (_isUnreadLoading) return;
    final token = UserSession().token;
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      _previousUnreadForBell = -1;
      if (_unreadNotificationCount != 0) {
        setState(() => _unreadNotificationCount = 0);
      }
      return;
    }
    _isUnreadLoading = true;
    try {
      final count = await ApiService.getJobseekerUnreadNotificationCount(token);
      if (!mounted) return;
      final prevBell = _previousUnreadForBell;
      final shouldRing = prevBell >= 0 && count > prevBell;
      _previousUnreadForBell = count;
      if (_unreadNotificationCount != count) {
        setState(() => _unreadNotificationCount = count);
      }
      if (shouldRing) {
        _ringBell();
      }
    } finally {
      _isUnreadLoading = false;
    }
  }

  void _onJobListScroll() {
    if (_isLoading || _isLoadingMoreJobs) return;
    if (_jobsCurrentPage >= _jobsLastPage) return;
    if (!_jobListScrollController.hasClients) return;
    final pos = _jobListScrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 360) {
      unawaited(_fetchJobs(showPageLoader: false, loadMore: true));
    }
  }

  void _onHomeTourScrollResetRequested() {
    if (_isGridView && mounted) {
      setState(() => _isGridView = false);
    }
    if (!_jobListScrollController.hasClients) return;
    _jobListScrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _scheduleSearchApply(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      setState(() {
        _searchText = value;
      });
      // Server-side filtering: re-fetch from page 1 when search changes
      unawaited(_fetchJobs(showPageLoader: false));
    });
  }

  Future<void> _fetchJobs({
    bool showPageLoader = true,
    bool loadMore = false,
  }) async {
    if (loadMore && (_isLoading || _isLoadingMoreJobs)) return;
    final targetPage = loadMore ? (_jobsCurrentPage + 1) : 1;
    if (showPageLoader) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        if (!loadMore) {
          _isLoadingMoreJobs = false;
        }
      });
    } else if (loadMore) {
      setState(() => _isLoadingMoreJobs = true);
    }
    final token = UserSession().token;
    // Server-side filtering: pass search, employment types, and skills
    final searchQuery = _searchText.trim().isNotEmpty ? _searchText.trim() : null;
    final empTypes = _selectedEmploymentTypes.isNotEmpty
        ? _selectedEmploymentTypes.toList()
        : null;
    final skillFilters = _selectedSkillFilters.isNotEmpty
        ? _selectedSkillFilters.toList()
        : null;

    final result = (token != null && token.isNotEmpty)
        ? await ApiService.getMatchedJobs(
            token,
            page: targetPage,
            search: searchQuery,
            employmentTypes: empTypes,
            skills: skillFilters,
          )
        : await ApiService.getJobListings(
            page: targetPage,
            search: searchQuery,
            employmentTypes: empTypes,
            skills: skillFilters,
          );
    if (!mounted) return;
    if (result['success'] == true) {
      final rawList = result['data'] as List<dynamic>? ?? [];
      final meta = result['meta'] as Map<String, dynamic>? ?? {};
      final currentPage = (meta['current_page'] as num?)?.toInt() ?? targetPage;
      final lastPage = (meta['last_page'] as num?)?.toInt() ?? currentPage;
      final totalCount = (meta['total'] as num?)?.toInt();
      final nextJobs = rawList
          .map((e) => Job.fromJson(e as Map<String, dynamic>))
          .toList();
      setState(() {
        if (!loadMore) {
          _jobs = nextJobs;
        } else {
          final known = _jobs.map((e) => e.id).toSet();
          _jobs = [..._jobs, ...nextJobs.where((j) => !known.contains(j.id))];
        }
        _jobsCurrentPage = currentPage;
        _jobsLastPage = lastPage;
        _jobsTotalCount = totalCount ?? _jobs.length;
        if (showPageLoader) _isLoading = false;
        _isLoadingMoreJobs = false;
        _jobListSerial++;
      });
    } else {
      if (showPageLoader) {
        setState(() {
          _errorMessage =
              result['message'] as String? ?? 'Failed to load jobs.';
          _isLoading = false;
          _isLoadingMoreJobs = false;
        });
      } else {
        setState(() => _isLoadingMoreJobs = false);
        CustomToast.show(
          context,
          message: result['message'] as String? ?? 'Failed to refresh jobs.',
          type: ToastType.error,
        );
      }
    }
  }

  Future<void> _applyToJob(Job job) async {
    final canApply = await _ensureResumeReadyForApply(context, _jobActionService);
    if (!canApply || !mounted) return;

    final confirmed = await showAppDialog<bool>(
      context: context,
      type: AppDialogType.confirm,
      icon: Icons.send_rounded,
      title: Localizations.localeOf(context).languageCode == 'tl'
          ? 'Kumpirmahin ang Aplikasyon'
          : 'Confirm Application',
      message: Localizations.localeOf(context).languageCode == 'tl'
          ? 'Mag-apply para sa ${job.title} sa ${job.company}?'
          : 'Apply for ${job.title} at ${job.company}?',
      confirmLabel: S.of(context)?.apply ?? 'Apply',
      onConfirm: () => Navigator.pop(context, true),
      onCancel: () => Navigator.pop(context, false),
    );
    if (confirmed != true || !mounted) return;

    final error = await _jobActionService.applyToJob(job.id, job.title);
    if (!mounted) return;

    if (error == null) {
      microInteractionSuccess();
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

  Future<void> _toggleSaveJob(Job job) async {
    final wasSaved = _jobActionService.isSaved(job.id);
    final error = await _jobActionService.toggleSave(job.id);
    if (!mounted) return;

    if (error == null) {
      microInteractionSuccess();
      CustomToast.show(
        context,
        message:
            wasSaved ? 'Job removed from saved.' : 'Job saved successfully.',
        type: ToastType.info,
      );
    } else {
      CustomToast.show(
        context,
        message: error,
        type: ToastType.error,
      );
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    if (difference == 0) return 'Today';
    if (difference == 1) return '1d ago';
    if (difference < 7) return '${difference}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Returns jobs sorted client-side. Filtering is done server-side.
  List<Job> get _sortedJobs {
    final jobs = List<Job>.from(_jobs);
    switch (_sortOption) {
      case 'Latest':
        jobs.sort((a, b) => b.postedDate.compareTo(a.postedDate));
        break;
      case 'Oldest':
        jobs.sort((a, b) => a.postedDate.compareTo(b.postedDate));
        break;
      case 'Best Match':
        jobs.sort((a, b) => b.matchPercentage.compareTo(a.matchPercentage));
        break;
    }
    return jobs;
  }

  bool get _hasActiveFilters =>
      _searchText.trim().isNotEmpty ||
      _selectedEmploymentTypes.isNotEmpty ||
      _selectedSkillFilters.isNotEmpty;

  Future<void> _loadSkillCatalogFilters() async {
    Future<List<dynamic>> loadRawSkills() async {
      final publicResult = await ApiService.getPublicSkills();
      if (publicResult['success'] == true) {
        return publicResult['data'] as List<dynamic>? ?? const [];
      }
      // Backward-compatible fallback endpoint used in older builds.
      final legacyResult = await ApiService.getSkillCatalog();
      if (legacyResult['success'] == true) {
        return legacyResult['data'] as List<dynamic>? ?? const [];
      }
      return const [];
    }

    final raw = await loadRawSkills();
    if (!mounted || raw.isEmpty) return;
    final byCategory = <String, List<String>>{};
    for (final item in raw) {
      final skill = item as Map<String, dynamic>;
      final name = (skill['name'] ?? skill['skill'])?.toString().trim() ?? '';
      if (name.isEmpty) continue;
      final categoryRaw = (skill['category'] ?? skill['category_name'])
              ?.toString()
              .trim() ??
          '';
      final category = categoryRaw.isNotEmpty ? categoryRaw : 'Other';
      byCategory.putIfAbsent(category, () => <String>[]).add(name);
    }
    byCategory.updateAll((_, list) {
      final uniqueSorted = list.toSet().toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      return uniqueSorted;
    });
    if (!mounted) return;
    setState(() => _skillCatalogByCategory = byCategory);
  }

  Map<String, List<String>> get _availableSkillFiltersByCategory {
    if (_skillCatalogByCategory.isNotEmpty) return _skillCatalogByCategory;
    final unique = <String>[];
    for (final job in _jobs) {
      for (final skill in job.skills) {
        final s = skill.trim();
        if (s.isNotEmpty) unique.add(s);
      }
    }
    final list = unique.toSet().toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    if (list.isEmpty) return const {};
    return {'Other': list};
  }

  Map<String, List<String>> get _visibleSkillFiltersByCategory {
    final q = _skillFilterQuery.trim().toLowerCase();
    final source = _availableSkillFiltersByCategory;
    if (q.isEmpty) return source;
    final filtered = <String, List<String>>{};
    for (final entry in source.entries) {
      final matches = entry.value
          .where((s) => s.toLowerCase().contains(q))
          .toList(growable: false);
      if (matches.isNotEmpty) {
        filtered[entry.key] = matches;
      }
    }
    return filtered;
  }

  int get _visibleSkillFilterCount =>
      _visibleSkillFiltersByCategory.values.fold<int>(
          0, (sum, skills) => sum + skills.length);

  void _showSortSheet() {
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
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
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
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

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final fl10n = S.of(ctx);
            final sheetHeight = (MediaQuery.sizeOf(ctx).height * 0.78)
                .clamp(480.0, 680.0)
                .toDouble();
            return Container(
              height: sheetHeight,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 12),
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
                              Text(
                                fl10n?.filterApply != null ? (LocaleService.instance.locale.languageCode == 'tl' ? 'I-filter ang Trabaho' : 'Filter Jobs') : 'Filter Jobs',
                                style: const TextStyle(
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
                                  // Re-fetch from server without filters
                                  unawaited(_fetchJobs(showPageLoader: false));
                                },
                                child: Text(
                                  fl10n?.filterClearAll ?? 'Clear All',
                                  style: TextStyle(
                                    color: Color(0xFF2563EB),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            fl10n?.filterEmploymentType ?? 'Employment Type',
                            style: const TextStyle(
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
                              final isSelected =
                                  _selectedEmploymentTypes.contains(type);
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
                                child: AnimatedScale(
                                  scale: isSelected ? 1.04 : 1.0,
                                  duration: const Duration(milliseconds: 180),
                                  curve: Curves.easeOutCubic,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 9),
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
                                        color: isSelected
                                            ? const Color(0xFF1D4ED8)
                                            : const Color(0xFF0F172A),
                                      ),
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
                                borderSide:
                                    const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: Color(0xFF2563EB)),
                              ),
                            ),
                          ),
                          if (_skillFilterQuery.trim().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              '$_visibleSkillFilterCount skills matching "${_skillFilterQuery.trim()}" in ${_visibleSkillFiltersByCategory.length} categories',
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF2563EB),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Builder(
                            builder: (_) {
                              final visibleByCategory =
                                  _visibleSkillFiltersByCategory;
                              if (visibleByCategory.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.only(top: 4, bottom: 8),
                                  child: Text(
                                    'No skills found for this search.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }
                              final categories = visibleByCategory.keys.toList()
                                ..sort((a, b) =>
                                    a.toLowerCase().compareTo(b.toLowerCase()));
                              return Column(
                                children: categories.map((category) {
                                  final skills = visibleByCategory[category]!;
                                  final selectedCount = skills
                                      .where(_selectedSkillFilters.contains)
                                      .length;
                                  final hasSearch =
                                      _skillFilterQuery.trim().isNotEmpty;
                                  final isExpanded = hasSearch ||
                                      _expandedSkillFilterCategories
                                          .contains(category);
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: Column(
                                      children: [
                                        InkWell(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          onTap: () {
                                            if (hasSearch) return;
                                            setSheetState(() {
                                              if (isExpanded) {
                                                _expandedSkillFilterCategories
                                                    .remove(category);
                                              } else {
                                                _expandedSkillFilterCategories
                                                    .add(category);
                                              }
                                            });
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 14, vertical: 12),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    category,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Color(0xFF0F172A),
                                                    ),
                                                  ),
                                                ),
                                                if (selectedCount > 0)
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8,
                                                        vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                          0xFFDBEAFE),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              999),
                                                    ),
                                                    child: Text(
                                                      '$selectedCount',
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color:
                                                            Color(0xFF1D4ED8),
                                                      ),
                                                    ),
                                                  ),
                                                const SizedBox(width: 8),
                                                Icon(
                                                  isExpanded
                                                      ? Icons
                                                          .keyboard_arrow_up_rounded
                                                      : Icons
                                                          .keyboard_arrow_down_rounded,
                                                  color:
                                                      const Color(0xFF64748B),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        if (isExpanded)
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                12, 0, 12, 12),
                                            child: Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              children: skills.map((skill) {
                                                final isSelected =
                                                    _selectedSkillFilters
                                                        .contains(skill);
                                                return GestureDetector(
                                                  onTap: () {
                                                    setSheetState(() {
                                                      if (isSelected) {
                                                        _selectedSkillFilters
                                                            .remove(skill);
                                                      } else {
                                                        _selectedSkillFilters
                                                            .add(skill);
                                                      }
                                                    });
                                                    setState(() {});
                                                  },
                                                  child: Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 14,
                                                        vertical: 9),
                                                    decoration: BoxDecoration(
                                                      color: isSelected
                                                          ? const Color(
                                                              0xFFDBEAFE)
                                                          : const Color(
                                                              0xFFF1F5F9),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                      border: Border.all(
                                                        color: isSelected
                                                            ? const Color(
                                                                0xFF93C5FD)
                                                            : const Color(
                                                                0xFFE2E8F0),
                                                        width:
                                                            isSelected ? 1.5 : 1,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      skill,
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: isSelected
                                                            ? const Color(
                                                                0xFF1D4ED8)
                                                            : const Color(
                                                                0xFF0F172A),
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF1E88E5)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.pop(ctx);
                            // Re-fetch from server with new filters
                            unawaited(_fetchJobs(showPageLoader: false));
                          },
                          child: Center(
                            child: Text(
                              fl10n?.filterApply ?? 'Apply Filters',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF1F5F9),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF2563EB)),
              SizedBox(height: 16),
              Text(
                'Loading jobs...',
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off_rounded,
                    size: 72, color: Colors.grey[300]),
                const SizedBox(height: 16),
                const Text(
                  'Could not load jobs',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _fetchJobs,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
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
      );
    }

    // Reload avatar when user has one but we haven't loaded it yet (e.g. after updating profile)
    if (UserSession().avatarPath != null &&
        _avatarBytes == null &&
        !_isAvatarLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadAvatar();
      });
    }

    final l10n = S.of(context);
    _greetingText = _buildGreeting(l10n);
    // Server returns filtered total in meta.total, so use it directly
    final totalJobs = _jobsTotalCount ?? _jobs.length;
    final jobsCountLabel = l10n?.jobsFound(totalJobs) ?? '$totalJobs Jobs Found';
    final topPadding = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        top: false,
        left: false,
        right: false,
        child: Column(
          children: [
            // Greeting banner: full-width blue card with mascot peeking from left
            Showcase(
              key: _showcaseMascot,
              title: 'Meet Empoy!',
              description: 'Your job-search buddy. He\'ll keep you posted on new matches.',
              targetPadding: EdgeInsets.zero,
              tooltipBackgroundColor: const Color(0xFF1D4ED8),
              textColor: Colors.white,
              titleTextStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
              descTextStyle: const TextStyle(fontSize: 13.5, height: 1.4, color: Colors.white),
              child: Container(
              width: double.infinity,
              height: 155 + topPadding,
              padding: EdgeInsets.fromLTRB(20, 12 + topPadding, 16, 32),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF2563EB),
                    Color(0xFF1D4ED8),
                  ],
                ),
                borderRadius: BorderRadius.zero,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Robot mascot — idle vs poked use separate position/size (see _mascotIdle* / _mascotPoked*).
                  Positioned(
                    left: _homeMascotPoked ? _mascotPokedLeft : _mascotIdleLeft,
                    bottom:
                        _homeMascotPoked ? _mascotPokedBottom : _mascotIdleBottom,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (_) {
                        HapticFeedback.lightImpact();
                        setState(() => _homeMascotPoked = true);
                      },
                      onTapUp: (_) =>
                          setState(() => _homeMascotPoked = false),
                      onTapCancel: () =>
                          setState(() => _homeMascotPoked = false),
                      onLongPressStart: (_) {
                        HapticFeedback.selectionClick();
                        setState(() => _homeMascotPoked = true);
                      },
                      onLongPressEnd: (_) =>
                          setState(() => _homeMascotPoked = false),
                      child: Image.asset(
                        _homeMascotPoked
                            ? 'assets/empoy_poked.png'
                            : 'assets/empoyhomepagev2.png',
                        width: _homeMascotPoked
                            ? _mascotPokedWidth
                            : _mascotIdleWidth,
                        height: _homeMascotPoked
                            ? _mascotPokedHeight
                            : _mascotIdleHeight,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint('Image load error: $error');
                          return Icon(
                            Icons.smart_toy_rounded,
                            size: 72,
                            color: Colors.white.withOpacity(0.9),
                          );
                        },
                      ),
                    ),
                  ),
                  // Greeting text + notifications
                  // Vertical position: Alignment(x, y) — y: -1=top, 0=center, 1=bottom
                  Align(
                    alignment: const Alignment(0, 0.3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(width: 120),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getPhilippinesGreeting(),
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white.withOpacity(0.98),
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                UserSession().displayName,
                                style: GoogleFonts.poppins(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.2,
                                  height: 1.2,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ],
                          ),
                        ),
                        Showcase(
                          key: _showcaseBell,
                          title: 'Notifications',
                          description: 'Application updates and PESO alerts land here. Red dot means unread.',
                          targetShapeBorder: const CircleBorder(),
                          tooltipBackgroundColor: const Color(0xFF1D4ED8),
                          textColor: Colors.white,
                          titleTextStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                          descTextStyle: const TextStyle(fontSize: 13.5, height: 1.4, color: Colors.white),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              AnimatedBuilder(
                                animation: _bellAngle,
                                builder: (context, child) {
                                  return Transform.rotate(
                                    angle: _bellAngle.value,
                                    alignment: Alignment.topCenter,
                                    child: child,
                                  );
                                },
                                child: IconButton(
                                  onPressed: _openNotifications,
                                  icon: const Icon(
                                    Icons.notifications_none_rounded,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                ),
                              ),
                              if (_unreadNotificationCount > 0)
                                Positioned(
                                  right: 8,
                                  top: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEF4444),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 16,
                                      minHeight: 16,
                                    ),
                                    child: Center(
                                      child: Text(
                                        _unreadNotificationCount > 9
                                            ? '9+'
                                            : '$_unreadNotificationCount',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ), // end Showcase (mascot)
            // Search & Filter section: punchy white card with quick filters
            Showcase(
              key: _showcaseSearch,
              title: 'Search & Filter',
              description: 'Search by job title or company. Tap the filter icon to narrow by type, sort, and skills.',
              targetBorderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              tooltipBackgroundColor: const Color(0xFF1D4ED8),
              textColor: Colors.white,
              titleTextStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
              descTextStyle: const TextStyle(fontSize: 13.5, height: 1.4, color: Colors.white),
              child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(0, 14, 0, 16),
              margin: const EdgeInsets.only(top: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      l10n?.homeFindJobTitle ?? 'Find a job',
                      style: TextStyle(
                        fontSize: Localizations.localeOf(context).languageCode == 'tl'
                            ? 21
                            : 24,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Integrated Search bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: ValueListenableBuilder<bool>(
                            valueListenable: _searchFocusNotifier,
                            builder: (context, isFocused, child) {
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isFocused
                                        ? const Color(0xFF2563EB)
                                            .withOpacity(0.5)
                                        : Colors.transparent,
                                    width: 1.5,
                                  ),
                                ),
                                child: child,
                              );
                            },
                            child: TextField(
                              focusNode: _searchFocus,
                              controller: _searchController,
                              onChanged: (v) {
                                _searchTextNotifier.value = v;
                                _scheduleSearchApply(v);
                              },
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF0F172A),
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                icon: Icon(
                                  Icons.search_rounded,
                                  color: const Color(0xFF64748B),
                                  size: 22,
                                ),
                                hintText: l10n?.searchJobsHint ?? 'Search jobs, companies...',
                                hintStyle: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                ),
                                suffixIcon: ValueListenableBuilder<String>(
                                  valueListenable: _searchTextNotifier,
                                  builder: (context, text, _) {
                                    return text.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(
                                              Icons.clear_rounded,
                                              color: Color(0xFF64748B),
                                              size: 20,
                                            ),
                                            onPressed: () {
                                              _searchController.clear();
                                              _searchText = '';
                                              _searchTextNotifier.value = '';
                                              _searchDebounce?.cancel();
                                              setState(() {});
                                            },
                                          )
                                        : Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                height: 24,
                                                width: 1,
                                                color: const Color(0xFFCBD5E1),
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                  Icons.tune_rounded,
                                                  color: _hasActiveFilters
                                                      ? const Color(0xFF2563EB)
                                                      : const Color(0xFF64748B),
                                                  size: 20,
                                                ),
                                                onPressed: _showFilterSheet,
                                              ),
                                            ],
                                          );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Horizontal Quick Filters
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: _employmentTypes.map((type) {
                        final isSelected =
                            _selectedEmploymentTypes.contains(type);
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                if (isSelected) {
                                  _selectedEmploymentTypes.remove(type);
                                } else {
                                  _selectedEmploymentTypes.add(type);
                                }
                              });
                              // Re-fetch from server with updated filter
                              unawaited(_fetchJobs(showPageLoader: false));
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF2563EB)
                                      : const Color(0xFFE2E8F0),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                type,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF475569),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            ), // end Showcase (search)

            const SizedBox(height: 16),

            // Job count + sort
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      jobsCountLabel,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _isGridView = !_isGridView);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                          key: ValueKey(_isGridView),
                          size: 20,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _showSortSheet();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
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

            const SizedBox(height: 16),

            // Job listings locked in a RepaintBoundary for smooth scrolling and faster keyboard response
            Expanded(
              child: ValueListenableBuilder<String>(
                valueListenable: _searchTextNotifier,
                builder: (context, _, __) {
                  final jobs = _sortedJobs;
                  return Stack(
                    children: [
                      RefreshIndicator(
                        onRefresh: () async {
                          await _fetchJobs(showPageLoader: false);
                          if (mounted) microInteractionSelection();
                        },
                        color: const Color(0xFF2563EB),
                        child: jobs.isEmpty
                            ? ListView(
                                children: [
                                  SizedBox(
                                    height: MediaQuery.sizeOf(context).height *
                                        0.35,
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.search_off_rounded,
                                            size: 64,
                                            color: Colors.grey[300],
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            l10n?.noJobsFound ?? 'No jobs found',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.grey[400],
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            l10n?.tryAdjustingFilters ?? 'Try adjusting your search or filters',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[400],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : _isGridView
                              ? GridView.builder(
                                  controller: _jobListScrollController,
                                  physics: const AlwaysScrollableScrollPhysics(
                                    parent: BouncingScrollPhysics(),
                                  ),
                                  padding: EdgeInsets.only(
                                    left: 20,
                                    right: 20,
                                    bottom:
                                        MediaQuery.paddingOf(context).bottom +
                                            96,
                                  ),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    childAspectRatio: 0.78,
                                  ),
                                  itemCount: jobs.length +
                                      (_isLoadingMoreJobs ? 1 : 0),
                                  itemBuilder: (context, index) {
                                    if (index >= jobs.length) {
                                      return const Center(
                                        child: SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2.2),
                                        ),
                                      );
                                    }
                                    final job = jobs[index];
                                    final isSaved =
                                        _jobActionService.isSaved(job.id);
                                    return RepaintBoundary(
                                      child: _JobCardCompact(
                                        key: ValueKey(
                                            'grid_${job.id}_$_jobListSerial'),
                                        job: job,
                                        isSaved: isSaved,
                                        onTap: () =>
                                            _showJobDetails(context, job),
                                        onSave: () => _toggleSaveJob(job),
                                      )
                                          .animate()
                                          .fadeIn(
                                            duration: 280.ms,
                                            delay: (index * 30).ms,
                                            curve: Curves.easeOutCubic,
                                          )
                                          .scale(
                                            begin: const Offset(0.95, 0.95),
                                            end: const Offset(1, 1),
                                            duration: 280.ms,
                                            delay: (index * 30).ms,
                                            curve: Curves.easeOutCubic,
                                          ),
                                    );
                                  },
                                )
                              : ListView.builder(
                                controller: _jobListScrollController,
                                physics: const AlwaysScrollableScrollPhysics(
                                  parent: BouncingScrollPhysics(),
                                ),
                                padding: EdgeInsets.only(
                                  left: 20,
                                  right: 20,
                                  bottom:
                                      MediaQuery.paddingOf(context).bottom +
                                          96,
                                ),
                                itemCount: jobs.length + (_isLoadingMoreJobs ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index >= jobs.length) {
                                    return const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 12),
                                      child: Center(
                                        child: SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(strokeWidth: 2.2),
                                        ),
                                      ),
                                    );
                                  }
                                  final job = jobs[index];
                                  final isSaved =
                                      _jobActionService.isSaved(job.id);
                                  final isApplied =
                                      _jobActionService.isApplied(job.id);
                                  Widget card = RepaintBoundary(
                                    child: _JobCard(
                                      key:
                                          ValueKey('${job.id}_$_jobListSerial'),
                                      job: job,
                                      formattedDate:
                                          _formatDate(job.postedDate),
                                      isSaved: isSaved,
                                      isApplied: isApplied,
                                      onTap: () =>
                                          _showJobDetails(context, job),
                                      onSave: () => _toggleSaveJob(job),
                                      onApply: () =>
                                          _showJobDetails(context, job),
                                    )
                                        .animate()
                                        .fadeIn(
                                          duration: 320.ms,
                                          delay: (index * 42).ms,
                                          curve: Curves.easeOutCubic,
                                        )
                                        .slideY(
                                          begin: 0.07,
                                          end: 0,
                                          duration: 320.ms,
                                          delay: (index * 42).ms,
                                          curve: Curves.easeOutCubic,
                                        ),
                                  );
                                  if (index == 0) {
                                    card = Showcase(
                                      key: _showcaseJobCard,
                                      title: 'Job Listings',
                                      description: 'Tap a job to see details, then Apply. Tap the bookmark icon to save it for later.',
                                      targetBorderRadius: BorderRadius.circular(16),
                                      tooltipBackgroundColor: const Color(0xFF1D4ED8),
                                      textColor: Colors.white,
                                      titleTextStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                                      descTextStyle: const TextStyle(fontSize: 13.5, height: 1.4, color: Colors.white),
                                      child: card,
                                    );
                                  }
                                  return card;
                                },
                              ),
                      ),
                      // Gradient fade overlay at bottom of list
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 100,
                        child: IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  const Color(0xFFF8FAFC).withOpacity(0.0),
                                  const Color(0xFFF8FAFC).withOpacity(0.85),
                                  const Color(0xFFF8FAFC),
                                ],
                                stops: const [0.0, 0.5, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showJobDetails(BuildContext context, Job job) {
    final isSaved = _jobActionService.isSaved(job.id);
    final isApplied = _jobActionService.isApplied(job.id);

    showJobDetailSheet(
      context,
      job,
      isSaved: isSaved,
      isApplied: isApplied,
      onSave: () => _toggleSaveJob(job),
      onApply: () => _applyToJob(job),
      onViewMap: () {
        Navigator.of(context).pop();
        widget.onOpenMapRequested?.call(MapFocusRequest.fromJob(job));
      },
    );
  }
}

// ─── Job Card Widget ──────────────────────────────────────────────────────────
class _JobCard extends StatefulWidget {
  final Job job;
  final String formattedDate;
  final VoidCallback onTap;
  final VoidCallback onSave;
  final VoidCallback onApply;
  final bool isSaved;
  final bool isApplied;

  const _JobCard({
    super.key,
    required this.job,
    required this.formattedDate,
    required this.onTap,
    required this.onSave,
    required this.onApply,
    required this.isSaved,
    required this.isApplied,
  });

  @override
  State<_JobCard> createState() => _JobCardState();
}

class _JobCardState extends State<_JobCard> {
  double _savePulse = 1.0;
  double _applyPulse = 1.0;

  @override
  void didUpdateWidget(covariant _JobCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isSaved && widget.isSaved) _pulseSave();
    if (!oldWidget.isApplied && widget.isApplied) _pulseApply();
  }

  void _pulseSave() {
    setState(() => _savePulse = 1.06);
    Future.delayed(const Duration(milliseconds: 170), () {
      if (mounted) setState(() => _savePulse = 1.0);
    });
  }

  void _pulseApply() {
    setState(() => _applyPulse = 1.05);
    Future.delayed(const Duration(milliseconds: 170), () {
      if (mounted) setState(() => _applyPulse = 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final isSaved = widget.isSaved;
    final isApplied = widget.isApplied;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Logo and Primary Info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CompanyLogoBox(
                      job: job,
                      size: 50,
                      borderRadius: 14,
                      boxShadow: [
                        BoxShadow(
                          color: job.companyColor.withOpacity(0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
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
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            job.company,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (job.matchPercentage > 0) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFF10B981).withOpacity(0.2)),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded,
                                size: 12, color: Color(0xFF059669)),
                            const SizedBox(height: 1),
                            Text(
                              '${job.matchPercentage}%',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF059669),
                                letterSpacing: -0.5,
                              ),
                            ),
                            const Text(
                              'Match',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF059669),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),

                // Metadata Row
                Row(
                  children: [
                    Flexible(
                        child: _buildChip(
                            Icons.location_on_rounded, job.location)),
                    const SizedBox(width: 8),
                    _buildChip(Icons.work_rounded, job.employmentTypeLabel),
                  ],
                ),
                const SizedBox(height: 12),

                // Salary Band (Full Width)
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.payments_rounded,
                          size: 16, color: Color(0xFF2563EB)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          job.salaryDisplay,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Description
                Text(
                  job.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF475569),
                    height: 1.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                // Footer Buttons (Anchored to Right)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildActionButton(
                      icon: isSaved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_outline_rounded,
                      color: isSaved
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF64748B),
                      isSelected: isSaved,
                      onTap: widget.onSave,
                      pulseScale: _savePulse,
                    ),
                    const SizedBox(width: 10),
                    _buildActionButton(
                      icon: isApplied
                          ? Icons.check_circle_rounded
                          : Icons.arrow_forward_rounded,
                      color: isApplied
                          ? const Color(0xFF10B981)
                          : const Color(0xFF2563EB),
                      isSelected: isApplied,
                      label: isApplied
                          ? (S.of(context)?.applied ?? 'Applied')
                          : (S.of(context)?.apply ?? 'Apply'),
                      onTap: widget.onApply,
                      pulseScale: _applyPulse,
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

  Widget _buildChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF64748B)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
    required double pulseScale,
    String? label,
  }) {
    return AnimatedScale(
      scale: pulseScale,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutBack,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: label != null ? 16 : 12,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : color,
              ),
              if (label != null) ...[
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? Colors.white : color,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Compact Job Card (Grid View) ─────────────────────────────────────────────
class _JobCardCompact extends StatelessWidget {
  final Job job;
  final bool isSaved;
  final VoidCallback onTap;
  final VoidCallback onSave;

  const _JobCardCompact({
    super.key,
    required this.job,
    required this.isSaved,
    required this.onTap,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CompanyLogoBox(
                      job: job,
                      size: 36,
                      borderRadius: 10,
                    ),
                    const Spacer(),
                    if (job.matchPercentage > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: const Color(0xFF10B981).withOpacity(0.2)),
                        ),
                        child: Text(
                          '${job.matchPercentage}%',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF059669),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  job.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    height: 1.25,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  job.company,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.payments_rounded,
                        size: 11,
                        color: Color(0xFF2563EB),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          job.salaryDisplay,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        size: 12, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        job.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        job.employmentTypeLabel,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: onSave,
                      child: Icon(
                        isSaved
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_outline_rounded,
                        size: 20,
                        color: isSaved
                            ? const Color(0xFF2563EB)
                            : const Color(0xFF94A3B8),
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

// ─── Map Tab ──────────────────────────────────────────────────────────────────
class MapTab extends StatefulWidget {
  const MapTab({super.key});

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> with TickerProviderStateMixin {
  static const String _locationProfilesPrefKey = 'map_location_profiles_v1';

  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  Business? _selectedBusiness;
  List<Business> _allBusinesses = [];
  List<Business> _filteredBusinesses = [];
  bool _isLoading = true;
  String? _errorMessage;
  MapFocusRequest? _pendingMapFocusRequest;

  // ─── GPS state ─────────────────────────────────────────────────────────────
  /// The location the user is currently picking with the "Set exact location"
  /// flow. While non-null, tapping the map updates this point instead of
  /// closing the popup, and a Confirm/Cancel banner is shown.
  LatLng? _exactPickPreview;
  bool _saveExactAsProfile = false;
  final TextEditingController _exactProfileNameController =
      TextEditingController();
  bool _isPickingExactLocation = false;
  /// After we've auto-centered on live GPS (only used when there is no manual pin).
  bool _hasAutoCenteredOnLiveGps = false;
  /// Manual point we last ran the opening auto-center for (null = none yet).
  LocationPoint? _autoCenteredManualPoint;
  bool _isRequestingPermission = false;
  LatLng? _mapCenterForAreaSearch;
  double _currentMapZoom = 15;
  /// Drives [ListenableBuilder] around company markers so clustering updates when
  /// zoom crosses thresholds (marker layer otherwise only listened to GPS).
  final ValueNotifier<double> _mapClusterZoomNotifier = ValueNotifier(15);
  bool _showSearchAreaCta = false;
  bool _isApplyingAreaSearch = false;
  LatLng? _areaSearchReference;
  List<_LocationProfile> _locationProfiles = [];
  Set<String> _matchedCompanyNames = <String>{};
  String? _mapNextCursor;
  bool _mapHasMore = true;
  bool _mapLoadingMore = false;
  String? _inflightMapCursor;
  int _mapDataVersion = 0;
  Timer? _mapLoadMoreDebounce;
  bool _bestMatchOnly = false;
  final Set<String> _compareBusinessIds = <String>{};
  bool _mapTourStarted = false;

  // ─── Map animation ─────────────────────────────────────────────────────────
  AnimationController? _moveAnimController;

  @override
  void initState() {
    super.initState();
    SkillMatchUtils.invalidateUserSkillsCache();
    mapUserSkillsRevisionNotifier.addListener(_onMapUserSkillsRevision);
    // Start location controller only when Map tab is opened, so permission
    // prompts are scoped to this screen.
    unawaited(LocationController.instance.start());
    _loadBusinessesFromApi();
    unawaited(_hydrateSessionSkillsIfNeededThenRefreshMatches());
    unawaited(_loadLocationProfiles());
    mapFocusRequestNotifier.addListener(_onMapFocusRequested);
    _onMapFocusRequested();

    final lc = LocationController.instance;
    lc.liveLocation.addListener(_onLocationChanged);
    lc.manualLocation.addListener(_onLocationChanged);
    lc.permission.addListener(_onPermissionChanged);
    activeHomeTabIndexNotifier.addListener(_onActiveHomeTabChanged);

    // Kick off a permission request the first time the user opens the Map
    // tab. If it's already granted this is essentially a no-op and just
    // makes sure the position stream is running.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureLocationReady();
    });

    _onActiveHomeTabChanged();
  }

  void _onActiveHomeTabChanged() {
    if (!mounted || _mapTourStarted) return;
    if (activeHomeTabIndexNotifier.value != 1) return;
    _mapTourStarted = true;
    unawaited(_maybeStartMapTour());
  }

  Future<void> _maybeStartMapTour() async {
    final token = UserSession().token;
    final done = await OnboardingPrefs.isMapTourDone(token: token);
    if (done || !mounted) return;
    // Persist immediately once eligible so hot reload/rebuild timing doesn't
    // accidentally re-trigger the map tour on the next entry.
    await OnboardingPrefs.setMapTourDone(token: token);
    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted || activeHomeTabIndexNotifier.value != 1) return;
    ShowcaseView.get().startShowCase([
      _showcaseMapBestMatch,
      _showcaseMapLocProfiles,
    ]);
  }

  Future<void> _ensureLocationReady() async {
    if (_isRequestingPermission) return;
    _isRequestingPermission = true;
    try {
      final lc = LocationController.instance;
      final perm = await lc.requestPermission();
      if (!mounted) return;
      if (perm == LocationPermission.always ||
          perm == LocationPermission.whileInUse) {
        // One-shot fast read so cards/sort have a real point quickly.
        await lc.getCurrentOnce();
      }
      if (mounted) setState(() {});
    } finally {
      _isRequestingPermission = false;
    }
  }

  void _onLocationChanged() {
    if (!mounted) return;
    setState(() {});

    final lc = LocationController.instance;
    final manual = lc.manualLocation.value;
    final live = lc.liveLocation.value;

    if (manual == null && _autoCenteredManualPoint != null) {
      _autoCenteredManualPoint = null;
      _hasAutoCenteredOnLiveGps = false;
    }

    void scheduleUserCenter(LatLng target) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _animatedMove(target, 15, durationMs: 500);
        }
      });
    }

    if (manual != null) {
      if (_autoCenteredManualPoint != manual) {
        _autoCenteredManualPoint = manual;
        _hasAutoCenteredOnLiveGps = true;
        scheduleUserCenter(LatLng(manual.latitude, manual.longitude));
      }
      return;
    }

    if (live != null && !_hasAutoCenteredOnLiveGps) {
      _hasAutoCenteredOnLiveGps = true;
      scheduleUserCenter(LatLng(live.latitude, live.longitude));
    }
  }

  void _onPermissionChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _loadBusinessesFromApi({bool loadMore = false}) async {
    if (loadMore && (_mapLoadingMore || !_mapHasMore)) return;
    if (!mounted) return;
    final requestVersion = loadMore ? _mapDataVersion : (++_mapDataVersion);
    final requestedCursor = loadMore ? _mapNextCursor : null;
    if (loadMore && requestedCursor != null && requestedCursor == _inflightMapCursor) {
      return;
    }
    setState(() {
      if (!loadMore) {
        _isLoading = true;
        _errorMessage = null;
        _mapNextCursor = null;
        _mapHasMore = true;
        _inflightMapCursor = null;
      } else {
        _mapLoadingMore = true;
        _inflightMapCursor = requestedCursor;
      }
    });

    try {
      final response = await ApiService.getMapEmployers(
        cursor: requestedCursor,
      );
      if (!mounted) return;
      if (requestVersion != _mapDataVersion) return;
      if (response['success'] == true) {
        final raw = response['data'] as List<dynamic>? ?? [];

        final businesses = <Business>[];
        for (final item in raw) {
          final emp = item as Map<String, dynamic>;
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

          final company = emp['company_name']?.toString() ?? 'Employer';
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
            // Provide employer context + absolute photo URL for CompanyLogoBox.
            return Job.fromJson({
              ...map,
              if (imageUrl.isNotEmpty) 'employer_photo_url': imageUrl,
              'employer': {
                'company_name': company,
                if (photoRaw != null && photoRaw.isNotEmpty) 'photo': photoRaw,
              },
            });
          }).toList();

          businesses.add(
            Business(
              id: 'emp_${emp['id']}',
              name: company,
              description: locationText.isNotEmpty
                  ? locationText
                  : (emp['tagline']?.toString() ?? ''),
              imageUrl: imageUrl,
              latitude: lat,
              longitude: lng,
              availableJobs: jobs,
            ),
          );
        }

        if (!mounted) return;
        final meta = response['meta'] as Map<String, dynamic>? ?? {};
        final nextCursor = meta['next_cursor'] as String?;
        final hasMore = meta['has_more'] == true || (nextCursor != null && nextCursor.isNotEmpty);
        setState(() {
          if (!loadMore) {
            _allBusinesses = businesses;
          } else {
            final known = _allBusinesses.map((e) => e.id).toSet();
            final appended = businesses.where((b) => !known.contains(b.id)).toList();
            _allBusinesses = [..._allBusinesses, ...appended];
          }
          _mapNextCursor = nextCursor;
          _mapHasMore = hasMore;
          _filteredBusinesses = _applyBestMatchFilter(_allBusinesses);
          _isLoading = false;
          _mapLoadingMore = false;
        });
        unawaited(_loadMatchedCompanyNames());
        _tryApplyPendingMapFocus();
      } else {
        if (!mounted) return;
        if (requestVersion != _mapDataVersion) return;
        setState(() {
          _errorMessage =
              response['message'] as String? ?? 'Failed to load map data.';
          _isLoading = false;
          _mapLoadingMore = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      if (requestVersion != _mapDataVersion) return;
      setState(() {
        _errorMessage = 'Failed to load map data.';
        _isLoading = false;
        _mapLoadingMore = false;
      });
    } finally {
      if (mounted && loadMore) {
        setState(() {
          _inflightMapCursor = null;
        });
      }
    }
  }

  void _maybeLoadMoreBusinessesForSearch(String query) {
    if (query.isEmpty) return;
    if (!_mapHasMore || _mapLoadingMore) return;
    if (_filteredBusinesses.length >= 6) return;
    _mapLoadMoreDebounce?.cancel();
    _mapLoadMoreDebounce = Timer(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      unawaited(_loadBusinessesFromApi(loadMore: true));
    });
  }

  Future<void> _loadLocationProfiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_locationProfilesPrefKey);
      if (raw == null || raw.trim().isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      final profiles = decoded
          .whereType<Map>()
          .map((e) => _LocationProfile.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      if (!mounted) return;
      setState(() {
        _locationProfiles = profiles;
      });
    } catch (_) {}
  }

  Future<void> _persistLocationProfiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = _locationProfiles.map((e) => e.toJson()).toList();
      await prefs.setString(_locationProfilesPrefKey, jsonEncode(data));
    } catch (_) {}
  }

  Future<void> _showLocationProfilesSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return SafeArea(
              child: Container(
                margin: EdgeInsets.only(
                  left: 12,
                  right: 12,
                  bottom: MediaQuery.viewInsetsOf(ctx).bottom + 12,
                ),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.layers_rounded, color: Color(0xFF2563EB)),
                        const SizedBox(width: 8),
                        const Text(
                          'Location Profiles',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            _startPickingExactLocation();
                          },
                          icon: const Icon(Icons.add_location_alt_rounded, size: 16),
                          label: const Text('Pick exact pin'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            _useLiveGps();
                            Navigator.of(ctx).pop();
                          },
                          icon: const Icon(Icons.gps_fixed_rounded, size: 16),
                          label: const Text('Use live GPS'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_locationProfiles.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text(
                          'No saved profiles yet. Save a location like Home or Boarding House.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      )
                    else
                      ..._locationProfiles.map((profile) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: ListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                            leading: const Icon(Icons.place_rounded,
                                color: Color(0xFF2563EB)),
                            title: Text(
                              profile.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            subtitle: Text(
                              '${profile.latitude.toStringAsFixed(5)}, ${profile.longitude.toStringAsFixed(5)}',
                              style: const TextStyle(fontSize: 11),
                            ),
                            onTap: () {
                              _useLocationProfile(profile);
                              Navigator.of(ctx).pop();
                            },
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () async {
                                    final renamed = await _promptRenameProfile(profile);
                                    if (!mounted) return;
                                    if (renamed) setSheetState(() {});
                                  },
                                  icon: const Icon(Icons.edit_rounded,
                                      color: Color(0xFF64748B)),
                                ),
                                IconButton(
                                  onPressed: () async {
                                    final removed = await _removeLocationProfile(profile.id);
                                    if (!mounted) return;
                                    if (removed) setSheetState(() {});
                                  },
                                  icon: const Icon(Icons.delete_outline_rounded,
                                      color: Color(0xFFDC2626)),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<bool> _saveLocationProfile({
    required LatLng initialPoint,
    required String name,
    bool showToast = true,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      if (showToast) {
        CustomToast.show(
          context,
          message: 'Please provide a profile name.',
          type: ToastType.info,
        );
      }
      return false;
    }
    if (_locationProfiles
        .any((e) => e.name.toLowerCase() == trimmedName.toLowerCase())) {
      if (showToast) {
        CustomToast.show(
          context,
          message: 'A profile with this name already exists.',
          type: ToastType.info,
        );
      }
      return false;
    }
    setState(() {
      _locationProfiles = [
        ..._locationProfiles,
        _LocationProfile(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: trimmedName,
          latitude: initialPoint.latitude,
          longitude: initialPoint.longitude,
        ),
      ];
    });
    await _persistLocationProfiles();
    if (!mounted) return true;
    if (showToast) {
      CustomToast.show(
        context,
        message: 'Location profile "$trimmedName" saved.',
        type: ToastType.success,
      );
    }
    return true;
  }

  Future<bool> _promptRenameProfile(_LocationProfile profile) async {
    final controller = TextEditingController(text: profile.name);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Profile'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Profile name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (confirmed != true) return false;
    final nextName = controller.text.trim();
    if (nextName.isEmpty) return false;
    setState(() {
      _locationProfiles = _locationProfiles
          .map((e) => e.id == profile.id ? e.copyWith(name: nextName) : e)
          .toList();
    });
    await _persistLocationProfiles();
    return true;
  }

  Future<bool> _removeLocationProfile(String id) async {
    setState(() {
      _locationProfiles = _locationProfiles.where((e) => e.id != id).toList();
    });
    await _persistLocationProfiles();
    return true;
  }

  void _useLocationProfile(_LocationProfile profile) {
    LocationController.instance.setManualLocation(
      LocationPoint(profile.latitude, profile.longitude),
    );
    final point = LatLng(profile.latitude, profile.longitude);
    _animatedMove(point, 15);
    setState(() {
      _areaSearchReference = null;
      _showSearchAreaCta = false;
    });
    CustomToast.show(
      context,
      message: 'Using location profile "${profile.name}".',
      type: ToastType.success,
    );
  }

  String _manualLocationPinLabel(LocationPoint manual) {
    final manualLatLng = LatLng(manual.latitude, manual.longitude);
    for (final profile in _locationProfiles) {
      final profileLatLng = LatLng(profile.latitude, profile.longitude);
      final meters = const Distance().as(
        LengthUnit.Meter,
        manualLatLng,
        profileLatLng,
      );
      if (meters <= 25) {
        final trimmed = profile.name.trim();
        if (trimmed.isNotEmpty) return trimmed;
      }
    }
    return 'Exact';
  }

  @override
  void dispose() {
    mapUserSkillsRevisionNotifier.removeListener(_onMapUserSkillsRevision);
    mapFocusRequestNotifier.removeListener(_onMapFocusRequested);
    activeHomeTabIndexNotifier.removeListener(_onActiveHomeTabChanged);
    final lc = LocationController.instance;
    lc.liveLocation.removeListener(_onLocationChanged);
    lc.manualLocation.removeListener(_onLocationChanged);
    lc.permission.removeListener(_onPermissionChanged);
    _mapLoadMoreDebounce?.cancel();
    _moveAnimController?.dispose();
    _exactProfileNameController.dispose();
    _searchController.dispose();
    _mapController.dispose();
    _mapClusterZoomNotifier.dispose();
    super.dispose();
  }

  /// Buckets must match zoom / radius tiers in [_clusterBusinesses] so the
  /// marker [ListenableBuilder] rebuilds when clustering strength changes.
  static int _clusteringModeBucket(double z) {
    if (z >= 13) return 4;
    if (z >= 11) return 3;
    if (z >= 9) return 2;
    if (z >= 7) return 1;
    return 0;
  }

  /// The user point currently being used for distance / ranking.
  LatLng _userLatLng() {
    final p = currentUserPoint();
    return LatLng(p.lat, p.lng);
  }

  /// Top 5 businesses sorted ascending by distance from [_userLatLng].
  /// If [source] is empty the result is also empty.
  List<Business> _nearestTop5(List<Business> source) {
    if (source.isEmpty) return const [];
    final reference = _activeDistanceReference();
    return _nearestTop5From(source, reference);
  }

  /// Active point used for ranking + displayed distance/travel metrics.
  /// When "Search this area" is applied, map center takes precedence.
  LatLng _activeDistanceReference() => _areaSearchReference ?? _userLatLng();

  List<Business> _nearestTop5From(List<Business> source, LatLng reference) {
    if (source.isEmpty) return const [];
    final list = [...source];
    list.sort((a, b) {
      final da = a.getDistanceFromUser(
          fromLat: reference.latitude, fromLng: reference.longitude);
      final db = b.getDistanceFromUser(
          fromLat: reference.latitude, fromLng: reference.longitude);
      return da.compareTo(db);
    });
    return list.take(5).toList(growable: false);
  }

  void _onMapFocusRequested() {
    final request = mapFocusRequestNotifier.value;
    if (request == null) return;
    mapFocusRequestNotifier.value = null;
    _pendingMapFocusRequest = request;
    _tryApplyPendingMapFocus();
  }

  void _tryApplyPendingMapFocus() {
    final request = _pendingMapFocusRequest;
    if (request == null || _allBusinesses.isEmpty) return;
    final business = _findBestBusinessForRequest(request);
    if (business == null) return;
    _pendingMapFocusRequest = null;
    _centerOnBusiness(business);
  }

  Business? _findBestBusinessForRequest(MapFocusRequest request) {
    String norm(String v) => v.toLowerCase().trim();
    final reqCompany = norm(request.companyName);
    final reqLocation = norm(request.locationText);

    for (final business in _allBusinesses) {
      if (norm(business.name) == reqCompany) return business;
    }

    for (final business in _allBusinesses) {
      if (norm(business.name).contains(reqCompany) ||
          reqCompany.contains(norm(business.name))) {
        return business;
      }
    }

    if (reqLocation.isNotEmpty) {
      for (final business in _allBusinesses) {
        if (norm(business.description).contains(reqLocation) ||
            reqLocation.contains(norm(business.description))) {
          return business;
        }
      }
    }

    if (request.latitude != null && request.longitude != null) {
      Business? nearest;
      var bestDistanceSquared = double.infinity;
      for (final business in _allBusinesses) {
        final dLat = business.latitude - request.latitude!;
        final dLng = business.longitude - request.longitude!;
        final distanceSquared = (dLat * dLat) + (dLng * dLng);
        if (distanceSquared < bestDistanceSquared) {
          bestDistanceSquared = distanceSquared;
          nearest = business;
        }
      }
      return nearest;
    }

    return null;
  }

  void _onSearch(String query) {
    final base = _applyBestMatchFilter(_allBusinesses);
    setState(() {
      if (query.isEmpty) {
        _filteredBusinesses = base;
      } else {
        _filteredBusinesses = base
            .where((b) => b.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
    _maybeLoadMoreBusinessesForSearch(query);
  }

  /// Smoothly animate the map camera from current position to [target] at
  /// [zoom]. Cancels any in-progress animation if a new one starts.
  void _animatedMove(LatLng target, double zoom, {int durationMs = 1100}) {
    _moveAnimController?.dispose();
    final controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: durationMs),
    );
    _moveAnimController = controller;

    final startCenter = _mapController.camera.center;
    final startZoom = _mapController.camera.zoom;

    // Fly-to effect:
    // 1) zoom out a bit from the current view (0.0–0.25)
    // 2) move the camera while staying zoomed out (0.25–0.75)
    // 3) zoom in to the target (0.75–1.0)
    final zoomOut = math.max(
      3.0,
      math.min(startZoom, zoom) - 1.6,
    );

    final latAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: ConstantTween<double>(startCenter.latitude),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: startCenter.latitude,
          end: target.latitude,
        ).chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(target.latitude),
        weight: 25,
      ),
    ]).animate(controller);

    final lngAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: ConstantTween<double>(startCenter.longitude),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: startCenter.longitude,
          end: target.longitude,
        ).chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(target.longitude),
        weight: 25,
      ),
    ]).animate(controller);

    final zoomAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: startZoom,
          end: zoomOut,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(zoomOut),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: zoomOut,
          end: zoom,
        ).chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 25,
      ),
    ]).animate(controller);

    controller.addListener(() {
      _mapController.move(
        LatLng(latAnim.value, lngAnim.value),
        zoomAnim.value,
      );
    });

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        controller.dispose();
        if (_moveAnimController == controller) {
          _moveAnimController = null;
        }
      }
    });

    controller.forward();
  }

  void _centerOnBusiness(Business business) {
    _animatedMove(
      LatLng(business.latitude, business.longitude),
      16,
    );
    setState(() {
      _selectedBusiness = business;
    });
  }

  void _centerOnUser() {
    final user = _userLatLng();
    _animatedMove(user, 15);
  }

  // ─── Exact-location override flow ─────────────────────────────────────────
  void _startPickingExactLocation() {
    setState(() {
      _isPickingExactLocation = true;
      _exactPickPreview = _userLatLng();
      _selectedBusiness = null;
      _saveExactAsProfile = false;
      _exactProfileNameController.clear();
    });
  }

  void _cancelPickingExactLocation() {
    setState(() {
      _isPickingExactLocation = false;
      _exactPickPreview = null;
      _saveExactAsProfile = false;
      _exactProfileNameController.clear();
    });
  }

  void _confirmPickingExactLocation() {
    final preview = _exactPickPreview;
    if (preview == null) return;
    final shouldSaveProfile = _saveExactAsProfile;
    final profileName = _exactProfileNameController.text.trim();
    LocationController.instance.setManualLocation(
      LocationPoint(preview.latitude, preview.longitude),
    );
    setState(() {
      _isPickingExactLocation = false;
      _exactPickPreview = null;
      _areaSearchReference = null;
      _showSearchAreaCta = false;
      _saveExactAsProfile = false;
      _exactProfileNameController.clear();
    });
    CustomToast.show(
      context,
      message: 'Exact location set. Showing closest jobs from here.',
      type: ToastType.success,
    );
    if (shouldSaveProfile) {
      if (profileName.isEmpty) {
        CustomToast.show(
          context,
          message: 'Exact location set. Enter a profile name to save it.',
          type: ToastType.info,
        );
      } else {
        unawaited(_saveLocationProfile(
          initialPoint: preview,
          name: profileName,
          showToast: true,
        ));
      }
    }
  }

  void _useLiveGps() {
    LocationController.instance.clearManualLocation();
    final live = LocationController.instance.liveLocation.value;
    if (live != null) {
      _animatedMove(LatLng(live.latitude, live.longitude), 15);
    } else {
      // Try to fetch a fresh position on demand.
      unawaited(_ensureLocationReady());
    }
    setState(() {
      _areaSearchReference = null;
      _showSearchAreaCta = false;
    });
  }

  Widget _buildLocationProfilesFab({bool withShowcase = false}) {
    Widget fab = FloatingActionButton.extended(
      heroTag: withShowcase ? 'map_tab_location_profiles' : 'map_tab_location_profiles_alt',
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF2563EB),
      elevation: 4,
      onPressed: _isPickingExactLocation ? _cancelPickingExactLocation : _showLocationProfilesSheet,
      icon: const Icon(Icons.layers_rounded, size: 18),
      label: const Text(
        'Location Profiles',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
    if (withShowcase) {
      fab = Showcase(
        key: _showcaseMapLocProfiles,
        title: 'Location Profiles',
        description: 'Pick an exact location, switch to live GPS, or save reusable places like Home.',
        tooltipActions: [
          TooltipActionButton(
            type: TooltipDefaultActionType.previous,
            textStyle: TextStyle(color: Colors.white),
          ),
          TooltipActionButton(
            type: TooltipDefaultActionType.next,
            name: 'Finish',
            textStyle: const TextStyle(color: Colors.white),
            onTap: () {
              ShowcaseView.get().dismiss();
            },
          ),
        ],
        onTargetClick: () {
          ShowcaseView.get().dismiss();
        },
        disposeOnTap: true,
        targetBorderRadius: BorderRadius.circular(28),
        tooltipBackgroundColor: const Color(0xFF1D4ED8),
        textColor: Colors.white,
        titleTextStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
        descTextStyle: const TextStyle(fontSize: 13.5, height: 1.4, color: Colors.white),
        child: fab,
      );
    }
    return fab;
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  /// Drive-time estimate from straight-line distance (see [_mapTravelTimeBucket]).
  Widget _travelTimeWithCarIcon(
    double meters, {
    required TextStyle style,
    double iconSize = 14,
  }) =>
      _mapTravelTimeWithCarIcon(meters, style: style, iconSize: iconSize);

  Set<String> _normalizedUserSkills() {
    return SkillMatchUtils.normalizedUserSkillsFromSession();
  }

  String _normalizedCompanyName(String name) {
    return SkillMatchUtils.normalizeCompanyName(name);
  }

  bool _businessHasSkillMatch(Business business, Set<String> userSkills) {
    if (_matchedCompanyNames.contains(_normalizedCompanyName(business.name))) {
      return true;
    }
    for (final job in business.availableJobs) {
      // Respect backend-calculated match when available.
      if (job.matchPercentage > 0) return true;
      if (SkillMatchUtils.anySkillMatch(
        normalizedUserSkills: userSkills,
        jobSkillsRaw: job.skills,
      )) return true;
    }
    return false;
  }

  List<Business> _applyBestMatchFilter(
    List<Business> source, {
    Set<String>? userSkills,
  }) {
    if (!_bestMatchOnly) return source;
    final skills = userSkills ?? _normalizedUserSkills();
    return source
        .where((b) => _businessHasSkillMatch(b, skills))
        .toList(growable: false);
  }

  void _onMapUserSkillsRevision() {
    if (!mounted) return;
    SkillMatchUtils.invalidateUserSkillsCache();
    unawaited(() async {
      await _loadMatchedCompanyNames();
      if (mounted) setState(() {});
    }());
  }

  /// Login payloads sometimes omit `skills`; profile has the canonical list.
  Future<void> _hydrateSessionSkillsIfNeededThenRefreshMatches() async {
    final token = UserSession().token;
    if (token != null &&
        token.isNotEmpty &&
        UserSession().skills.isEmpty) {
      try {
        final profile = await ApiService.getUser(token);
        if (mounted && profile['success'] == true) {
          final data = profile['data'];
          if (data is Map<String, dynamic>) {
            final user = (data['jobseeker'] as Map<String, dynamic>?) ??
                (data['user'] as Map<String, dynamic>?) ??
                data;
            UserSession().updateFromUser(user);
          }
        }
      } catch (_) {}
    }
    if (!mounted) return;
    SkillMatchUtils.invalidateUserSkillsCache();
    await _loadMatchedCompanyNames();
    if (mounted) setState(() {});
  }

  Future<void> _loadMatchedCompanyNames() async {
    final token = UserSession().token;
    final rawSkills = UserSession().skills
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList(growable: false);
    if (token == null || token.isEmpty || rawSkills.isEmpty) {
      if (!mounted) return;
      setState(() {
        _matchedCompanyNames = <String>{};
        final q = _searchController.text.trim().toLowerCase();
        final base = _applyBestMatchFilter(_allBusinesses);
        _filteredBusinesses = q.isEmpty
            ? base
            : base.where((b) => b.name.toLowerCase().contains(q)).toList();
      });
      return;
    }

    try {
      final res = await ApiService.getMatchedJobs(token, skills: rawSkills);
      if (!mounted || res['success'] != true) return;
      final data = res['data'] as List<dynamic>? ?? const <dynamic>[];
      final names = <String>{};
      for (final item in data) {
        if (item is! Map<String, dynamic>) continue;
        final employer = item['employer'] as Map<String, dynamic>?;
        final companyName = (item['company']?.toString() ??
                employer?['company_name']?.toString() ??
                '')
            .trim();
        if (companyName.isEmpty) continue;
        names.add(_normalizedCompanyName(companyName));
      }
      if (!mounted) return;
      setState(() {
        _matchedCompanyNames = names;
        final q = _searchController.text.trim().toLowerCase();
        final base = _applyBestMatchFilter(_allBusinesses);
        _filteredBusinesses = q.isEmpty
            ? base
            : base.where((b) => b.name.toLowerCase().contains(q)).toList();
      });
    } catch (_) {
      // Silently skip; map still works with direct skill checks.
    }
  }

  void _onMapPositionChanged(MapPosition position, bool hasGesture) {
    final center = position.center;
    final zoom = position.zoom;
    if (center == null || zoom == null) return;
    _mapCenterForAreaSearch = center;
    _currentMapZoom = zoom;
    final prevBucket = _clusteringModeBucket(_mapClusterZoomNotifier.value);
    final nextBucket = _clusteringModeBucket(zoom);
    if (prevBucket != nextBucket) {
      _mapClusterZoomNotifier.value = zoom;
    }
    if (_isApplyingAreaSearch || !hasGesture) return;
    if (_searchController.text.isNotEmpty) return;
    final currentReference = _areaSearchReference ?? _userLatLng();
    final moved = const Distance().as(
      LengthUnit.Meter,
      currentReference,
      center,
    );
    if (moved > 350) {
      if (!_showSearchAreaCta && mounted) {
        setState(() {
          _showSearchAreaCta = true;
        });
      }
    }
  }

  void _applySearchThisArea() {
    final center = _mapCenterForAreaSearch;
    if (center == null) return;
    setState(() {
      _isApplyingAreaSearch = true;
      _areaSearchReference = center;
      _showSearchAreaCta = false;
      _selectedBusiness = null;
    });
    Future<void>.delayed(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      setState(() {
        _isApplyingAreaSearch = false;
      });
    });
    CustomToast.show(
      context,
      message: 'Showing closest companies for this area.',
      type: ToastType.info,
    );
  }

  void _toggleCompareBusiness(Business business) {
    setState(() {
      if (_compareBusinessIds.contains(business.id)) {
        _compareBusinessIds.remove(business.id);
      } else {
        if (_compareBusinessIds.length >= 3) {
          _compareBusinessIds.remove(_compareBusinessIds.first);
        }
        _compareBusinessIds.add(business.id);
      }
    });
  }

  void _clearCompareSelection() {
    if (_compareBusinessIds.isEmpty) return;
    setState(() {
      _compareBusinessIds.clear();
    });
  }

  Future<void> _showCompanyCompareSheet() async {
    // Resolve selections from the full map data, not only the current card
    // source, so compare can reopen reliably even if the visible top list
    // changes after closing the modal.
    final selected = _allBusinesses
        .where((b) => _compareBusinessIds.contains(b.id))
        .take(3)
        .toList();
    if (selected.length < 2) {
      CustomToast.show(
        context,
        message: 'Select at least 2 companies to compare (long-press cards).',
        type: ToastType.info,
      );
      return;
    }
    final user = _activeDistanceReference();
    await showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.14),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.compare_arrows_rounded,
                      color: Color(0xFF1D4ED8),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Quick Compare',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                    ),
                  ),
                  Text(
                    '${selected.length} selected',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF475569),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Straight-line distance from your active map location. '
                'Drive time is a rough estimate (~20 km/h city traffic), not routing.',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),
              ...selected.asMap().entries.map((entry) {
                final idx = entry.key;
                final b = entry.value;
                final d = b.getDistanceFromUser(
                  fromLat: user.latitude,
                  fromLng: user.longitude,
                );
                final accent = switch (idx) {
                  0 => const Color(0xFF2563EB),
                  1 => const Color(0xFF0F766E),
                  _ => const Color(0xFF9333EA),
                };
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accent.withOpacity(0.12),
                        accent.withOpacity(0.03),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: accent.withOpacity(0.28)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: accent.withOpacity(0.16),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '#${idx + 1}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: accent,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              b.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                                height: 1.22,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.92),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              _formatDistance(d),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E3A8A),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.92),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: _travelTimeWithCarIcon(
                              d,
                              iconSize: 14,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.92),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${b.availableJobs.length} jobs',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 2),
              const Text(
                'Tip: long-press cards on the map list to add or remove companies.',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Whether to show the "enable location" banner at the top of the map.
  bool _shouldShowPermissionBanner() {
    final lc = LocationController.instance;
    final perm = lc.permission.value;
    final isDenied = perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever;
    final serviceOff = !lc.serviceEnabled.value;
    final hasNoFix = lc.liveLocation.value == null;
    return (isDenied || serviceOff) && hasNoFix;
  }

  /// Helper to render a small "person/pin" badge marker at [point].
  Marker _buildUserMarker(
    LatLng point, {
    required String label,
    required Color ringColor,
    IconData icon = Icons.person,
  }) {
    const labelStyle = TextStyle(
      color: Colors.white,
      fontSize: 8,
      fontWeight: FontWeight.bold,
      height: 1.2,
    );
    return Marker(
      point: point,
      width: 104,
      height: 58,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: ringColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: ringColor.withOpacity(0.4),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 14),
          ),
          const SizedBox(height: 2),
          Container(
            constraints: const BoxConstraints(maxWidth: 96),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: ringColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: labelStyle,
            ),
          ),
        ],
      ),
    );
  }

  List<_MapCluster> _clusterBusinesses(
    List<Business> businesses, {
    required double zoom,
  }) {
    if (businesses.isEmpty) return const [];
    if (zoom >= 13) {
      return businesses
          .map((b) => _MapCluster(
                center: LatLng(b.latitude, b.longitude),
                businesses: [b],
              ))
          .toList();
    }

    // Distance-based clustering is more stable than decimal-grid bucketing.
    // Radii grow quickly as the user zooms out: fixed ~km thresholds made pins
    // look stacked (same screen pixels) while still being unmerged >2.5 km apart.
    final radiusMeters = zoom < 7
        ? 50000.0
        : zoom < 9
            ? 15000.0
            : zoom < 11
                ? 5000.0
                : 900.0;

    final sorted = [...businesses]
      ..sort((a, b) {
        final byLat = a.latitude.compareTo(b.latitude);
        if (byLat != 0) return byLat;
        return a.longitude.compareTo(b.longitude);
      });

    final clusters = <List<Business>>[];
    final centers = <LatLng>[];

    for (final b in sorted) {
      final point = LatLng(b.latitude, b.longitude);
      int? nearestIdx;
      double nearestMeters = double.infinity;

      for (var i = 0; i < centers.length; i++) {
        final d = const Distance().as(
          LengthUnit.Meter,
          centers[i],
          point,
        );
        if (d <= radiusMeters && d < nearestMeters) {
          nearestMeters = d;
          nearestIdx = i;
        }
      }

      if (nearestIdx == null) {
        clusters.add([b]);
        centers.add(point);
        continue;
      }

      clusters[nearestIdx].add(b);
      final group = clusters[nearestIdx];
      final latAvg =
          group.map((e) => e.latitude).reduce((a, v) => a + v) / group.length;
      final lngAvg =
          group.map((e) => e.longitude).reduce((a, v) => a + v) / group.length;
      centers[nearestIdx] = LatLng(latAvg, lngAvg);
    }

    return List<_MapCluster>.generate(
      clusters.length,
      (i) => _MapCluster(center: centers[i], businesses: clusters[i]),
      growable: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Flutter Map with OpenStreetMap tiles (or Mapbox tiles)
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _userLatLng(),
              initialZoom: 15,
              onPositionChanged: _onMapPositionChanged,
              onTap: (_, point) {
                if (_isPickingExactLocation) {
                  setState(() {
                    _exactPickPreview = point;
                  });
                  return;
                }
                setState(() {
                  _selectedBusiness = null;
                });
              },
            ),
            children: [
              // Map tiles - Using OpenStreetMap (free, no token needed)
              // To use Mapbox, uncomment the line below and comment out the OpenStreetMap line
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.peso.app',
              ),
              // Mapbox tiles (uncomment to use with your token):
              // TileLayer(
              //   urlTemplate: 'https://api.mapbox.com/styles/v1/mapbox/streets-v11/tiles/{z}/{x}/{y}?access_token=$mapboxAccessToken',
              // ),
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: _areaSearchReference ?? _userLatLng(),
                    radius: 1000,
                    useRadiusInMeter: true,
                    color: const Color(0xFF10B981).withOpacity(0.04),
                    borderColor: const Color(0xFF10B981).withOpacity(0.32),
                    borderStrokeWidth: 1.2,
                  ),
                  CircleMarker(
                    point: _areaSearchReference ?? _userLatLng(),
                    radius: 3000,
                    useRadiusInMeter: true,
                    color: Colors.transparent,
                    borderColor: const Color(0xFF0EA5E9).withOpacity(0.26),
                    borderStrokeWidth: 1.1,
                  ),
                  CircleMarker(
                    point: _areaSearchReference ?? _userLatLng(),
                    radius: 5000,
                    useRadiusInMeter: true,
                    color: Colors.transparent,
                    borderColor: const Color(0xFFF59E0B).withOpacity(0.22),
                    borderStrokeWidth: 1.0,
                  ),
                ],
              ),

              // Markers Layer — bind to location notifiers so pins update even if
              // a parent misses a rebuild (e.g. IndexedStack / notifier edge cases).
              ListenableBuilder(
                listenable: Listenable.merge([
                  LocationController.instance.liveLocation,
                  LocationController.instance.manualLocation,
                  _mapClusterZoomNotifier,
                ]),
                builder: (context, _) {
                  final lc = LocationController.instance;
                  final live = lc.liveLocation.value;
                  final manual = lc.manualLocation.value;
                  final userSkills = _normalizedUserSkills();
                  final mapBusinesses = _applyBestMatchFilter(
                    _allBusinesses,
                    userSkills: userSkills,
                  );
                  final clusters = _clusterBusinesses(
                    mapBusinesses,
                    zoom: _mapClusterZoomNotifier.value,
                  );
                  return MarkerLayer(
                    markers: [
                      // Live GPS "You" — only when not using a manual exact pin and
                      // not in the pick flow (otherwise "Pick" is the sole user pin).
                      if (live != null && manual == null && !_isPickingExactLocation)
                        _buildUserMarker(
                          LatLng(live.latitude, live.longitude),
                          label: 'You',
                          ringColor: const Color(0xFF2563EB),
                        ),
                      if (manual != null)
                        _buildUserMarker(
                          LatLng(manual.latitude, manual.longitude),
                          label: _manualLocationPinLabel(manual),
                          ringColor: const Color(0xFFF59E0B),
                          icon: Icons.push_pin_rounded,
                        ),
                      if (_isPickingExactLocation && _exactPickPreview != null)
                        _buildUserMarker(
                          _exactPickPreview!,
                          label: 'Pick',
                          ringColor: const Color(0xFF10B981),
                          icon: Icons.add_location_alt_rounded,
                        ),
                      // Business markers (clustered on low zoom)
                      ...clusters.map((cluster) {
                        if (cluster.businesses.length > 1) {
                          final count = cluster.businesses.length;
                          final matchedCount = cluster.businesses
                              .where(
                                (b) =>
                                    _businessHasSkillMatch(b, userSkills),
                              )
                              .length;
                          const matchCol = Color(0xFF16A34A);
                          const nonMatchCol = Color(0xFF7C3AED);
                          final matchedFraction =
                              count > 0 ? matchedCount / count : 0.0;
                          final shadowTint = Color.lerp(
                            matchCol,
                            nonMatchCol,
                            1.0 - matchedFraction,
                          )!;
                          return Marker(
                            point: cluster.center,
                            width: 52,
                            height: 52,
                            child: GestureDetector(
                              onTap: () {
                                final nextZoom =
                                    (_currentMapZoom + 2).clamp(5, 17).toDouble();
                                _animatedMove(cluster.center, nextZoom);
                              },
                              child: Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: shadowTint.withOpacity(0.35),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: CustomPaint(
                                  painter: _MapClusterPiePainter(
                                    matchedFraction: matchedFraction,
                                    matchColor: matchCol,
                                    nonMatchColor: nonMatchCol,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$count',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: count > 99 ? 11 : 14,
                                        shadows: const [
                                          Shadow(
                                            color: Color(0x80000000),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }
                        final business = cluster.businesses.first;
                        final isSelected =
                            _selectedBusiness?.id == business.id;
                        final hasSkillMatch =
                            _businessHasSkillMatch(business, userSkills);
                        final color = hasSkillMatch
                            ? const Color(0xFF16A34A)
                            : business.id == 'sm_savemore'
                            ? const Color(0xFFE11D48)
                            : const Color(0xFF7C3AED);
                        final pinSize = isSelected ? 44.0 : 36.0;
                        return Marker(
                          point: LatLng(business.latitude, business.longitude),
                          width: 120,
                          height: 78,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedBusiness = business;
                              });
                            },
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedScale(
                                  scale: isSelected ? 1.1 : 1.0,
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOutBack,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: pinSize,
                                    height: pinSize,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: hasSkillMatch
                                            ? const Color(0xFF16A34A)
                                            : Colors.white,
                                        width: isSelected ? 4 : 3,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: color.withOpacity(0.4),
                                          blurRadius: isSelected ? 15 : 8,
                                          spreadRadius: isSelected ? 3 : 1,
                                        ),
                                      ],
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: ClipOval(
                                      child: business.imageUrl.isNotEmpty
                                          ? Image.network(
                                              business.imageUrl,
                                              width: pinSize,
                                              height: pinSize,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  Container(
                                                width: pinSize,
                                                height: pinSize,
                                                color: color,
                                                alignment: Alignment.center,
                                                child: Icon(
                                                  Icons.store_rounded,
                                                  color: Colors.white,
                                                  size: isSelected ? 22 : 18,
                                                ),
                                              ),
                                            )
                                          : Container(
                                              width: pinSize,
                                              height: pinSize,
                                              color: color,
                                              alignment: Alignment.center,
                                              child: Icon(
                                                Icons.store_rounded,
                                                color: Colors.white,
                                                size: isSelected ? 22 : 18,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: hasSkillMatch
                                        ? const Color(0xFFDCFCE7)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.15),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    business.name.split(' ').take(2).join(' '),
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: color,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            ],
          ),

          if (_isLoading)
            const Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),

          if (_errorMessage != null)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 72,
              left: 16,
              right: 16,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

          if (_showSearchAreaCta && !_isPickingExactLocation)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 80,
              left: 16,
              right: 16,
              child: Center(
                child: ElevatedButton.icon(
                  onPressed: _applySearchThisArea,
                  icon: const Icon(Icons.travel_explore_rounded, size: 16),
                  label: Text(
                    S.of(context)?.mapSearchThisArea ?? 'Search this area',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ),

          // Search Bar & Business List
          SafeArea(
            child: Column(
              children: [
                // Search Bar
                Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        onChanged: _onSearch,
                        decoration: InputDecoration(
                          hintText: S.of(context)?.searchBusinessesHint ??
                              'Search businesses...',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          prefixIcon: const Icon(Icons.search_rounded,
                              color: Color(0xFF2563EB)),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded,
                                      color: Colors.grey),
                                  onPressed: () {
                                    _searchController.clear();
                                    _onSearch('');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                        ),
                      ),
                      if (_searchController.text.isNotEmpty &&
                          _filteredBusinesses.isNotEmpty)
                        Container(
                          constraints: const BoxConstraints(maxHeight: 200),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(color: Colors.grey[200]!),
                            ),
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            itemCount: _filteredBusinesses.length,
                            itemBuilder: (context, index) {
                              final business = _filteredBusinesses[index];
                              final reference = _activeDistanceReference();
                              final distance = business.getDistanceFromUser(
                                fromLat: reference.latitude,
                                fromLng: reference.longitude,
                              );
                              return ListTile(
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: business.imageUrl.isNotEmpty
                                      ? Image.network(
                                          business.imageUrl,
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              Container(
                                            width: 40,
                                            height: 40,
                                            color: const Color(0xFF2563EB)
                                                .withOpacity(0.1),
                                            child: const Icon(
                                              Icons.store_rounded,
                                              color: Color(0xFF2563EB),
                                              size: 20,
                                            ),
                                          ),
                                        )
                                      : Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF2563EB)
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: const Icon(
                                            Icons.store_rounded,
                                            color: Color(0xFF2563EB),
                                            size: 20,
                                          ),
                                        ),
                                ),
                                title: Text(
                                  business.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                                subtitle: DefaultTextStyle.merge(
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          _formatDistance(distance),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        ' • ',
                                        style: TextStyle(
                                            color: Colors.grey[500]),
                                      ),
                                      _travelTimeWithCarIcon(
                                        distance,
                                        iconSize: 13,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                onTap: () {
                                  _searchController.clear();
                                  _onSearch('');
                                  _centerOnBusiness(business);
                                },
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Showcase(
                      key: _showcaseMapBestMatch,
                      title: 'Best Match Only',
                      description: 'Toggle to show only employers that match your saved skills.',
                      onBarrierClick: () {
                        ShowcaseView.get().next(force: true);
                      },
                      tooltipActions: const [
                        TooltipActionButton(
                          type: TooltipDefaultActionType.next,
                          textStyle: TextStyle(color: Colors.white),
                        ),
                      ],
                      targetBorderRadius: BorderRadius.circular(20),
                      tooltipBackgroundColor: const Color(0xFF15803D),
                      textColor: Colors.white,
                      titleTextStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                      descTextStyle: const TextStyle(fontSize: 13.5, height: 1.4, color: Colors.white),
                      child: FilterChip(
                        selected: _bestMatchOnly,
                        onSelected: (value) {
                          setState(() {
                            _bestMatchOnly = value;
                          });
                          _onSearch(_searchController.text);
                        },
                        showCheckmark: false,
                        label: Icon(
                          Icons.verified_rounded,
                          size: 21,
                          color: _bestMatchOnly
                              ? const Color(0xFF15803D)
                              : const Color(0xFF64748B),
                        ),
                        labelPadding: EdgeInsets.zero,
                        padding: const EdgeInsets.all(10),
                        selectedColor: const Color(0xFFDCFCE7),
                        backgroundColor: Colors.white,
                        side: BorderSide(
                          color: _bestMatchOnly
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // Business Cards List
                Padding(
                  padding: EdgeInsets.only(
                      bottom: MediaQuery.paddingOf(context).bottom + 80),
                  child: Builder(
                    builder: (context) {
                      // When the user is searching by name, keep their search
                      // results. Otherwise, surface the 5 closest businesses
                      // to the current effective user location.
                      final isSearching = _searchController.text.isNotEmpty;
                      final hasTrackedLocation =
                          LocationController.instance.liveLocation.value !=
                                  null ||
                              LocationController.instance.manualLocation.value !=
                                  null;
                      final visibleBusinesses = _applyBestMatchFilter(_allBusinesses);
                      final List<Business> cardSource = isSearching
                          ? _filteredBusinesses
                          : (hasTrackedLocation
                              ? _nearestTop5(visibleBusinesses)
                              : const <Business>[]);

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isSearching)
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 0, 20, 8),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: _buildLocationProfilesFab(withShowcase: true),
                              ),
                            ),
                          if (!isSearching && cardSource.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 20),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(10),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.08),
                                                blurRadius: 8,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.near_me_rounded,
                                                size: 16,
                                                color: Color(0xFF2563EB),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                _areaSearchReference == null
                                                    ? (S.of(context)
                                                            ?.mapClosestCompanyNearYou ??
                                                        'Closest company near you')
                                                    : (S.of(context)
                                                            ?.mapClosestCompanyInArea ??
                                                        'Closest company in this area'),
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.grey[800],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    top: 0,
                                    child: Align(
                                      alignment: Alignment.topCenter,
                                      child: AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 180),
                                        switchInCurve: Curves.easeOutCubic,
                                        switchOutCurve: Curves.easeInCubic,
                                        child: _compareBusinessIds.isNotEmpty
                                            ? Row(
                                                key: const ValueKey('compare_button_visible_overlay'),
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  FilledButton.icon(
                                                    onPressed: _showCompanyCompareSheet,
                                                    icon: const Icon(Icons.compare_arrows_rounded, size: 16),
                                                    label: Text('Compare (${_compareBusinessIds.length}/3)'),
                                                    style: FilledButton.styleFrom(
                                                      backgroundColor: const Color(0xFF2563EB),
                                                      foregroundColor: Colors.white,
                                                      padding: const EdgeInsets.symmetric(
                                                          horizontal: 14, vertical: 10),
                                                      textStyle: const TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w700,
                                                      ),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(999),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Material(
                                                    color: const Color(0xFF1D4ED8),
                                                    shape: const CircleBorder(),
                                                    child: InkWell(
                                                      customBorder: const CircleBorder(),
                                                      onTap: _clearCompareSelection,
                                                      child: const Padding(
                                                        padding: EdgeInsets.all(6),
                                                        child: Icon(
                                                          Icons.close_rounded,
                                                          size: 14,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : const SizedBox(
                                                key: ValueKey('compare_button_hidden_overlay'),
                                              ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          SizedBox(
                            height: 160,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: cardSource.length,
                              itemBuilder: (context, index) {
                                final business = cardSource[index];
                                final user = _activeDistanceReference();
                                final distance = business.getDistanceFromUser(
                                  fromLat: user.latitude,
                                  fromLng: user.longitude,
                                );
                                final isSelected =
                                    _selectedBusiness?.id == business.id;

                                return GestureDetector(
                                  onTap: () => _centerOnBusiness(business),
                                  onLongPress: () => _toggleCompareBusiness(business),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 280,
                                    margin: const EdgeInsets.only(
                                        right: 12, bottom: 16),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF2563EB)
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 15,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: Stack(
                              children: [
                                Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: business.imageUrl.isNotEmpty
                                          ? Image.network(
                                              business.imageUrl,
                                              width: 44,
                                              height: 44,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  Container(
                                                width: 44,
                                                height: 44,
                                                decoration: BoxDecoration(
                                                  color: (index % 2 == 0)
                                                      ? const Color(0xFFE11D48)
                                                          .withOpacity(0.1)
                                                      : const Color(0xFF7C3AED)
                                                          .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Icon(
                                                  Icons.store_rounded,
                                                  color: (index % 2 == 0)
                                                      ? const Color(0xFFE11D48)
                                                      : const Color(0xFF7C3AED),
                                                  size: 24,
                                                ),
                                              ),
                                            )
                                          : Container(
                                              width: 44,
                                              height: 44,
                                              decoration: BoxDecoration(
                                                color: (index % 2 == 0)
                                                    ? const Color(0xFFE11D48)
                                                        .withOpacity(0.1)
                                                    : const Color(0xFF7C3AED)
                                                        .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Icon(
                                                Icons.store_rounded,
                                                color: (index % 2 == 0)
                                                    ? const Color(0xFFE11D48)
                                                    : const Color(0xFF7C3AED),
                                                size: 24,
                                              ),
                                            ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            business.name,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF0F172A),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.location_on_rounded,
                                                size: 14,
                                                color: Color(0xFF2563EB),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                _formatDistance(distance),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF2563EB),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              _travelTimeWithCarIcon(
                                                distance,
                                                iconSize: 13,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF64748B),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981)
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.work_rounded,
                                            size: 14,
                                            color: Color(0xFF10B981),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${business.availableJobs.length} Jobs',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF10B981),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Spacer(),
                                    TextButton(
                                      onPressed: () =>
                                          _showBusinessDetails(business),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12),
                                        minimumSize: const Size(0, 32),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'View',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF2563EB),
                                            ),
                                          ),
                                          SizedBox(width: 4),
                                          Icon(
                                            Icons.arrow_forward_rounded,
                                            size: 16,
                                            color: Color(0xFF2563EB),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                                if (_compareBusinessIds.contains(business.id))
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF2563EB),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check_rounded,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // GPS controls (center on user + set exact location)
          Positioned(
            right: 16,
            bottom: MediaQuery.paddingOf(context).bottom + 260,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton(
                  // Unique tag — default FAB Hero tags collide with other
                  // routes' FABs (e.g. Notifications "Delete all") during pop
                  // transitions, causing morphs.
                  heroTag: 'map_tab_center_on_user',
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: _centerOnUser,
                  child: const Icon(Icons.my_location_rounded,
                      color: Color(0xFF2563EB)),
                ),
                // Exact-location control lives above "Closest company" when not
                // searching; keep it here while searching so it stays reachable.
                if (_searchController.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildLocationProfilesFab(),
                ],
              ],
            ),
          ),

          // Banner shown while the user is picking their exact location.
          if (_isPickingExactLocation)
            Positioned(
              left: 16,
              right: 16,
              bottom: MediaQuery.paddingOf(context).bottom + 250,
              child: _ExactLocationPickBanner(
                hasPreview: _exactPickPreview != null,
                saveAsProfile: _saveExactAsProfile,
                profileNameController: _exactProfileNameController,
                onSaveAsProfileChanged: (value) {
                  setState(() => _saveExactAsProfile = value);
                },
                onCancel: _cancelPickingExactLocation,
                onConfirm: _confirmPickingExactLocation,
              ),
            ),

          // Permission denied / location-off banner.
          if (!_isPickingExactLocation && _shouldShowPermissionBanner())
            Positioned(
              left: 16,
              right: 16,
              top: MediaQuery.paddingOf(context).top + 96,
              child: _LocationPermissionBanner(
                isServiceDisabled:
                    !LocationController.instance.serviceEnabled.value,
                permission: LocationController.instance.permission.value,
                onEnable: () async {
                  await _ensureLocationReady();
                },
                onOpenSettings: () =>
                    LocationController.instance.openAppSettings(),
                onOpenLocationSettings: () => LocationController.instance
                    .openLocationServiceSettings(),
              ),
            ),

          // Selected business popup
          if (_selectedBusiness != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: MediaQuery.paddingOf(context).bottom + 250,
              child: _BusinessPopupCard(
                business: _selectedBusiness!,
                distanceReference: _activeDistanceReference(),
                onClose: () => setState(() => _selectedBusiness = null),
                onViewJobs: () => _showBusinessDetails(_selectedBusiness!),
                formatDistance: _formatDistance,
              ),
            ),
        ],
      ),
    );
  }

  void _showBusinessDetails(Business business) {
    final userSkills = _normalizedUserSkills();
    final highlightAllJobs = _businessHasSkillMatch(business, userSkills);
    final distanceReference = _activeDistanceReference();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          behavior: HitTestBehavior.opaque,
          child: SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: GestureDetector(
                onTap: () {},
                child: _BusinessDetailSheet(
                  hostContext: this.context,
                  business: business,
                  distanceReference: distanceReference,
                  formatDistance: _formatDistance,
                  userSkills: userSkills,
                  highlightAllJobs: highlightAllJobs,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MapCluster {
  final LatLng center;
  final List<Business> businesses;

  const _MapCluster({
    required this.center,
    required this.businesses,
  });
}

/// Two-tone pie for cluster bubbles: green = skill-matched employers, purple = not.
class _MapClusterPiePainter extends CustomPainter {
  _MapClusterPiePainter({
    required this.matchedFraction,
    required this.matchColor,
    required this.nonMatchColor,
  });

  final double matchedFraction;
  final Color matchColor;
  final Color nonMatchColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    const strokeWidth = 3.0;
    final radius = (math.min(w, h) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final f = matchedFraction.clamp(0.0, 1.0);
    if (f <= 0) {
      canvas.drawCircle(center, radius, Paint()..color = nonMatchColor);
    } else if (f >= 1) {
      canvas.drawCircle(center, radius, Paint()..color = matchColor);
    } else {
      canvas.drawCircle(center, radius, Paint()..color = nonMatchColor);
      final start = -math.pi / 2;
      final matchedSweep = 2 * math.pi * f;
      canvas.drawArc(
        rect,
        start,
        matchedSweep,
        true,
        Paint()..color = matchColor,
      );
    }

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );
  }

  @override
  bool shouldRepaint(covariant _MapClusterPiePainter old) =>
      old.matchedFraction != matchedFraction ||
      old.matchColor != matchColor ||
      old.nonMatchColor != nonMatchColor;
}

class _LocationProfile {
  final String id;
  final String name;
  final double latitude;
  final double longitude;

  const _LocationProfile({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  _LocationProfile copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
  }) {
    return _LocationProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'lat': latitude,
        'lng': longitude,
      };

  factory _LocationProfile.fromJson(Map<String, dynamic> json) {
    return _LocationProfile(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      latitude: (json['lat'] as num?)?.toDouble() ?? 0,
      longitude: (json['lng'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Rough drive-time buckets from straight-line distance (~20 km/h mixed traffic).
String _mapTravelTimeBucket(double meters) {
  final minutes = ((meters / 1000) / 20) * 60;
  if (minutes <= 10) return '<10 min';
  if (minutes <= 20) return '10-20 min';
  if (minutes <= 35) return '20-35 min';
  return '35+ min';
}

Widget _mapTravelTimeWithCarIcon(
  double meters, {
  required TextStyle style,
  double iconSize = 14,
}) {
  final color = style.color ?? const Color(0xFF64748B);
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.directions_car_rounded, size: iconSize, color: color),
      SizedBox(width: iconSize >= 14 ? 4 : 3),
      Text(_mapTravelTimeBucket(meters), style: style),
    ],
  );
}

// ─── Business Popup Card ──────────────────────────────────────────────────────
class _BusinessPopupCard extends StatelessWidget {
  final Business business;
  /// Point km / drive-time estimates are measured from (map search area or user pin).
  final LatLng distanceReference;
  final VoidCallback onClose;
  final VoidCallback onViewJobs;
  final String Function(double) formatDistance;

  const _BusinessPopupCard({
    required this.business,
    required this.distanceReference,
    required this.onClose,
    required this.onViewJobs,
    required this.formatDistance,
  });

  double _distanceMeters() => business.getDistanceFromUser(
        fromLat: distanceReference.latitude,
        fromLng: distanceReference.longitude,
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: business.imageUrl.isNotEmpty
                    ? Image.network(
                        business.imageUrl,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 56,
                          height: 56,
                          color: const Color(0xFF2563EB).withOpacity(0.1),
                          child: const Icon(
                            Icons.store_rounded,
                            color: Color(0xFF2563EB),
                            size: 28,
                          ),
                        ),
                      )
                    : Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.store_rounded,
                          color: Color(0xFF2563EB),
                          size: 28,
                        ),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      business.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on_rounded,
                                size: 16, color: Color(0xFF2563EB)),
                            const SizedBox(width: 4),
                            Text(
                              '${formatDistance(_distanceMeters())} away',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          ],
                        ),
                        _mapTravelTimeWithCarIcon(
                          _distanceMeters(),
                          iconSize: 14,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onClose,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded,
                      size: 18, color: Colors.grey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            business.description,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.work_rounded,
                        size: 16, color: Color(0xFF10B981)),
                    const SizedBox(width: 6),
                    Text(
                      '${business.availableJobs.length} Jobs Available',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: onViewJobs,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('View Jobs',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Exact-location pick banner ───────────────────────────────────────────────
class _ExactLocationPickBanner extends StatelessWidget {
  final bool hasPreview;
  final bool saveAsProfile;
  final TextEditingController profileNameController;
  final ValueChanged<bool> onSaveAsProfileChanged;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const _ExactLocationPickBanner({
    required this.hasPreview,
    required this.saveAsProfile,
    required this.profileNameController,
    required this.onSaveAsProfileChanged,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.add_location_alt_rounded,
                    color: Color(0xFF10B981), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Set your exact location',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        hasPreview
                            ? 'Tap elsewhere to adjust, then confirm below.'
                            : 'Tap anywhere on the map to drop a pin.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Checkbox(
                  value: saveAsProfile,
                  visualDensity: VisualDensity.compact,
                  onChanged: (value) => onSaveAsProfileChanged(value ?? false),
                ),
                const SizedBox(width: 2),
                const Expanded(
                  child: Text(
                    'Save as location profile',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
            if (saveAsProfile) ...[
              const SizedBox(height: 6),
              TextField(
                controller: profileNameController,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: 'e.g. Home, Boarding House',
                  labelText: 'Profile name',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                const Spacer(),
                TextButton(
                  onPressed: onCancel,
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                ElevatedButton(
                  onPressed: hasPreview ? onConfirm : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Confirm',
                    style: TextStyle(fontWeight: FontWeight.w700),
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

// ─── Location permission banner ───────────────────────────────────────────────
class _LocationPermissionBanner extends StatelessWidget {
  final bool isServiceDisabled;
  final LocationPermission permission;
  final VoidCallback onEnable;
  final Future<bool> Function() onOpenSettings;
  final Future<bool> Function() onOpenLocationSettings;

  const _LocationPermissionBanner({
    required this.isServiceDisabled,
    required this.permission,
    required this.onEnable,
    required this.onOpenSettings,
    required this.onOpenLocationSettings,
  });

  @override
  Widget build(BuildContext context) {
    final permanentlyDenied = permission == LocationPermission.deniedForever;
    final title = isServiceDisabled
        ? 'Location services are off'
        : (permanentlyDenied
            ? 'Location permission blocked'
            : 'Enable location to see nearby jobs');
    final body = isServiceDisabled
        ? 'Turn on GPS in your device settings so we can find jobs closest to you.'
        : (permanentlyDenied
            ? 'Allow location for Kabsat Empoy in your phone settings.'
            : 'We use your location to rank the closest companies first.');

    final primaryLabel = isServiceDisabled
        ? 'Open Location Settings'
        : (permanentlyDenied ? 'Open App Settings' : 'Enable Location');

    Future<void> primaryAction() async {
      if (isServiceDisabled) {
        await onOpenLocationSettings();
        return;
      }
      if (permanentlyDenied) {
        await onOpenSettings();
        return;
      }
      onEnable();
    }

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.location_searching_rounded,
                  color: Color(0xFF2563EB), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    body,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[700],
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: primaryAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: Text(
                primaryLabel,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Business Detail Sheet ────────────────────────────────────────────────────
class _BusinessDetailSheet extends StatelessWidget {
  final BuildContext hostContext;
  final Business business;
  final LatLng distanceReference;
  final String Function(double) formatDistance;
  final Set<String> userSkills;
  final bool highlightAllJobs;

  const _BusinessDetailSheet({
    required this.hostContext,
    required this.business,
    required this.distanceReference,
    required this.formatDistance,
    required this.userSkills,
    required this.highlightAllJobs,
  });

  double _distanceMeters() => business.getDistanceFromUser(
        fromLat: distanceReference.latitude,
        fromLng: distanceReference.longitude,
      );

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
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Business Header
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: business.imageUrl.isNotEmpty
                                ? Image.network(
                                    business.imageUrl,
                                    width: 72,
                                    height: 72,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 72,
                                      height: 72,
                                      color: const Color(0xFF2563EB)
                                          .withOpacity(0.1),
                                      child: const Icon(
                                        Icons.store_rounded,
                                        color: Color(0xFF2563EB),
                                        size: 36,
                                      ),
                                    ),
                                  )
                                : Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2563EB)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: const Icon(
                                      Icons.store_rounded,
                                      color: Color(0xFF2563EB),
                                      size: 36,
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  business.name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2563EB)
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.location_on_rounded,
                                              size: 14,
                                              color: Color(0xFF2563EB)),
                                          const SizedBox(width: 4),
                                          Text(
                                            formatDistance(_distanceMeters()),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF2563EB),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF64748B)
                                            .withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: _mapTravelTimeWithCarIcon(
                                        _distanceMeters(),
                                        iconSize: 14,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF475569),
                                        ),
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

                      // Description
                      Text(
                        business.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF475569),
                          height: 1.6,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Available Jobs Section
                      Row(
                        children: [
                          const Icon(Icons.work_rounded,
                              size: 22, color: Color(0xFF2563EB)),
                          const SizedBox(width: 10),
                          Text(
                            S.of(context)?.companyJobs ?? 'Available Jobs',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${business.availableJobs.length}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Job List
                      ...business.availableJobs.map((job) => _JobListItem(
                            job: job,
                            userSkills: userSkills,
                            highlightOverride: highlightAllJobs,
                            onTap: () {
                              Navigator.pop(context);
                              Future.microtask(
                                  () => _showJobDetails(hostContext, job));
                            },
                          )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showJobDetails(BuildContext context, Job job) async {
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
            // Keep employer/location context from map result when missing.
            if ((listing['employer'] == null || listing['employer'] is! Map) &&
                job.company.isNotEmpty)
              'employer': {'company_name': job.company},
            if ((listing['location'] == null ||
                    listing['location'].toString().trim().isEmpty) &&
                job.location.isNotEmpty)
              'location': job.location,
            // Ensure match badge is present like Jobs page details.
            'match_percentage':
                (data['match_score'] as num?)?.toInt() ??
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
      isSaved: jobActionService.isSaved(detailJob.id),
      isApplied: jobActionService.isApplied(detailJob.id),
      onSave: () => jobActionService.toggleSave(detailJob.id),
      onApply: () =>
          _applyFromBusinessDetail(context, detailJob, jobActionService),
      onViewMap: null, // Redundant in map page
    );
  }

  Future<void> _applyFromBusinessDetail(
      BuildContext context, Job job, JobActionService jobActionService) async {
    final canApply = await _ensureResumeReadyForApply(context, jobActionService);
    if (!canApply || !context.mounted) return;

    final confirmed = await showAppDialog<bool>(
      context: context,
      type: AppDialogType.confirm,
      icon: Icons.send_rounded,
      title: Localizations.localeOf(context).languageCode == 'tl'
          ? 'Kumpirmahin ang Aplikasyon'
          : 'Confirm Application',
      message: Localizations.localeOf(context).languageCode == 'tl'
          ? 'Mag-apply para sa ${job.title} sa ${job.company}?'
          : 'Apply for ${job.title} at ${job.company}?',
      confirmLabel: S.of(context)?.apply ?? 'Apply',
      onConfirm: () => Navigator.pop(context, true),
      onCancel: () => Navigator.pop(context, false),
    );
    if (confirmed != true || !context.mounted) return;

    final error = await jobActionService.applyToJob(job.id, job.title);
    if (context.mounted) {
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
  }
}

// ─── Job List Item for Business Detail ────────────────────────────────────────
class _JobListItem extends StatelessWidget {
  final Job job;
  final Set<String> userSkills;
  final bool highlightOverride;
  final VoidCallback onTap;

  const _JobListItem({
    required this.job,
    required this.userSkills,
    this.highlightOverride = false,
    required this.onTap,
  });

  bool _looksMatched() {
    if (highlightOverride) return true;
    if (job.matchPercentage > 0) return true;
    return SkillMatchUtils.anySkillMatch(
      normalizedUserSkills: userSkills,
      jobSkillsRaw: job.skills,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasSkillMatch = _looksMatched();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasSkillMatch
              ? const Color(0xFF16A34A)
              : const Color(0xFFE2E8F0),
          width: hasSkillMatch ? 1.4 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CompanyLogoBox(
                  job: job,
                  size: 48,
                  borderRadius: 14,
                  boxShadow: const [],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              job.title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          if (job.isUrgent)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'URGENT',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${job.salaryDisplay} • ${job.employmentTypeLabel}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Notifications Tab ────────────────────────────────────────────────────────
class NotificationsTab extends StatefulWidget {
  final ValueChanged<MapFocusRequest>? onOpenMapRequested;

  const NotificationsTab({super.key, this.onOpenMapRequested});

  @override
  State<NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<NotificationsTab>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _notifications = [];
  final _jobActionService = JobActionService();
  Timer? _pollTimer;
  bool _isPolling = false;

  static const String _deleteFabLabel = 'Delete all';
  static const double _deleteFabCompact = 56;
  static const double _deleteFabExpanded = 146;
  /// Width + color use the full controller duration; this is only when width hits expanded.
  static const double _deleteFabExpandPhaseEnd = 0.42;
  /// Label animates only inside [start, end] so letters are fast while widen stays slow.
  static const double _deleteFabLetterPhaseStart = 0.42;
  static const double _deleteFabLettersEnd = 0.56;
  /// After delete-all slide finishes, wait this long before showing empty state.
  static const Duration _deleteAllToEmptyDelay = Duration(milliseconds: 400);

  late final AnimationController _deleteFabAnim;
  AnimationController? _deleteAllExitAnim;
  bool _fabAnimInitialized = false;
  bool? _fabAnimSyncedToCompact;
  int _fabSyncGen = 0;

  @override
  void initState() {
    super.initState();
    _deleteFabAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1320),
    );
    _loadNotifications();
    // Refresh the list if a new notification arrives while looking at it
    NotificationService.addListener(_onPushReceived);

    _jobActionService.addListener(_onJobActionsChanged);
  }

  void _onPushReceived() {
    if (mounted) _loadNotifications(showLoader: false);
  }

  @override
  void dispose() {
    _deleteAllExitAnim?.dispose();
    _deleteFabAnim.dispose();
    NotificationService.removeListener(_onPushReceived);
    _jobActionService.removeListener(_onJobActionsChanged);
    _pollTimer?.cancel();
    super.dispose();
  }

  void _onJobActionsChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadNotifications({bool showLoader = true}) async {
    if (_isPolling) return;
    _isPolling = true;
    try {
      final token = UserSession().token;
      if (token == null || token.isEmpty) {
        setState(() {
          _notifications = [];
          if (showLoader) _isLoading = false;
        });
        return;
      }

      if (showLoader) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      }

      final result =
          await ApiService.getJobseekerNotifications(token: token, page: 1);
      if (!mounted) return;

      if (result['success'] == true) {
        final data = result['data'];
        final list = data is Map<String, dynamic> ? data['data'] : null;
        _notifications =
            (list as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        if (showLoader) _isLoading = false;
        setState(() {});
      } else {
        if (showLoader) {
          setState(() {
            _errorMessage =
                result['message'] as String? ?? 'Failed to load notifications.';
            _isLoading = false;
          });
        }
      }
    } finally {
      _isPolling = false;
    }
  }

  Future<void> _markAllRead() async {
    final token = UserSession().token;
    if (token == null || token.isEmpty) return;
    try {
      await http.post(
        Uri.parse(
            '${ApiService.baseUrl}/jobseeker/notifications/mark-all-read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      setState(() {
        _notifications = _notifications
            .map((n) => {
                  ...n,
                  'read_at': n['read_at'] ?? DateTime.now().toIso8601String()
                })
            .toList();
      });
    } catch (_) {}
  }

  List<Map<String, dynamic>> get _sortedNotifications {
    final list = List<Map<String, dynamic>>.from(_notifications);
    list.sort((a, b) {
      final notifA = a['notification'] as Map<String, dynamic>? ?? {};
      final notifB = b['notification'] as Map<String, dynamic>? ?? {};
      final typeA = notifA['type'] as String?;
      final typeB = notifB['type'] as String?;

      if (typeA == 'satisfaction_survey' && typeB != 'satisfaction_survey') return -1;
      if (typeB == 'satisfaction_survey' && typeA != 'satisfaction_survey') return 1;

      // Otherwise maintain time order (newest first)
      final dateA = DateTime.tryParse(notifA['created_at'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      final dateB = DateTime.tryParse(notifB['created_at'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      return dateB.compareTo(dateA);
    });
    return list;
  }

  /// Pending experience-rating requests must not be dismissible or bulk-deleted.
  bool _isProtectedSatisfactionSurvey(Map<String, dynamic> item) {
    final notif = item['notification'] as Map<String, dynamic>? ?? {};
    return notif['type'] == 'satisfaction_survey';
  }

  /// Bulk delete is enabled only after every notification has been read.
  bool get _allNotificationsRead =>
      _notifications.isNotEmpty &&
      _notifications.every(_isReadNotification);

  /// Gray icon-only state while any notification is still unread.
  bool get _deleteFabIsCompact =>
      _notifications.isNotEmpty && !_allNotificationsRead;

  void _scheduleDeleteFabSync() {
    final gen = ++_fabSyncGen;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || gen != _fabSyncGen) return;
      _syncDeleteFabAnim();
    });
  }

  void _syncDeleteFabAnim() {
    if (!mounted) return;
    final compact = _deleteFabIsCompact;

    if (!_fabAnimInitialized) {
      _fabAnimInitialized = true;
      _fabAnimSyncedToCompact = compact;
      _deleteFabAnim.value = compact ? 0.0 : 1.0;
      return;
    }
    if (_fabAnimSyncedToCompact == compact) return;
    _fabAnimSyncedToCompact = compact;
    if (compact) {
      _deleteFabAnim.reverse();
    } else {
      _deleteFabAnim.forward();
    }
  }

  /// 0 → 1 while this item slides out; top item (index 0) goes first.
  double _deleteAllSlideProgressForIndex(int index, int total) {
    final c = _deleteAllExitAnim;
    if (c == null || total <= 0) return 0.0;
    final v = c.value;
    final start = index / total;
    final end = (index + 1) / total;
    if (v <= start) return 0.0;
    if (v >= end) return 1.0;
    return Curves.easeInCubic.transform((v - start) / (end - start));
  }

  Widget _buildAnimatedDeleteAllFab() {
    final disabled = !_allNotificationsRead;
    final label = _deleteFabLabel;

    return AnimatedBuilder(
      animation: _deleteFabAnim,
      builder: (context, child) {
        final v = _deleteFabAnim.value;
        final expandT = (v / _deleteFabExpandPhaseEnd).clamp(0.0, 1.0);
        final expandCurved = Curves.easeOutCubic.transform(expandT);
        final width = lerpDouble(
              _deleteFabCompact,
              _deleteFabExpanded,
              expandCurved,
            ) ??
            _deleteFabCompact;

        /// Tighter icon + label only when the FAB is actionable (red) and widened.
        final activeExpanded =
            !disabled && width > _deleteFabCompact + 0.5;

        final colorProgress = Curves.easeInOut.transform(v);
        final bg = Color.lerp(
          const Color(0xFFE2E8F0),
          const Color(0xFFEF4444),
          colorProgress,
        )!;
        final fg = Color.lerp(
          const Color(0xFF94A3B8),
          Colors.white,
          colorProgress,
        )!;
        final elevation = lerpDouble(0, 6, colorProgress) ?? 0;

        final letterPhaseStart = _deleteFabLetterPhaseStart;
        final letterPhaseLen =
            (_deleteFabLettersEnd - letterPhaseStart).clamp(0.02, 1.0);
        final n = label.length;
        final letterStyle = GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: fg,
          height: 1,
        );

        final letterWidgets = <Widget>[];
        for (var i = 0; i < n; i++) {
          final start = letterPhaseStart + (i / n) * letterPhaseLen;
          final end = letterPhaseStart + ((i + 1) / n) * letterPhaseLen;
          double op;
          if (v <= start) {
            op = 0;
          } else if (v >= end) {
            op = 1;
          } else {
            op = Curves.easeOut.transform((v - start) / (end - start));
          }
          letterWidgets.add(
            Opacity(
              opacity: op,
              child: Text(label[i], style: letterStyle),
            ),
          );
        }

        return Hero(
          tag: 'notifications_delete_all',
          child: Material(
            elevation: elevation,
            shadowColor: Colors.black.withOpacity(0.2),
            color: bg,
            borderRadius: BorderRadius.circular(_deleteFabCompact / 2),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: disabled
                  ? null
                  : () {
                      HapticFeedback.mediumImpact();
                      _confirmDeleteAllNotifications();
                    },
              borderRadius: BorderRadius.circular(_deleteFabCompact / 2),
              child: SizedBox(
                width: width,
                height: _deleteFabCompact,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: _deleteFabCompact,
                      height: _deleteFabCompact,
                      child: activeExpanded
                          ? Align(
                              alignment: Alignment.centerRight,
                              child: Icon(
                                Icons.delete_forever_rounded,
                                color: fg,
                                size: 24,
                              ),
                            )
                          : Center(
                              child: Icon(
                                Icons.delete_forever_rounded,
                                color: fg,
                                size: 24,
                              ),
                            ),
                    ),
                    SizedBox(
                      width: math.max(0, width - _deleteFabCompact),
                      height: _deleteFabCompact,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(width: activeExpanded ? 0 : 4),
                          Expanded(
                            child: ClipRect(
                              clipBehavior: Clip.hardEdge,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const NeverScrollableScrollPhysics(),
                                primary: false,
                                clipBehavior: Clip.hardEdge,
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    right: activeExpanded ? 6 : 10,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: letterWidgets,
                                  ),
                                ),
                              ),
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
      },
    );
  }

  Future<void> _applyToJob(Job job) async {
    final canApply = await _ensureResumeReadyForApply(context, _jobActionService);
    if (!canApply || !mounted) return;

    final confirmed = await showAppDialog<bool>(
      context: context,
      type: AppDialogType.confirm,
      icon: Icons.send_rounded,
      title: Localizations.localeOf(context).languageCode == 'tl'
          ? 'Kumpirmahin ang Aplikasyon'
          : 'Confirm Application',
      message: Localizations.localeOf(context).languageCode == 'tl'
          ? 'Mag-apply para sa ${job.title} sa ${job.company}?'
          : 'Apply for ${job.title} at ${job.company}?',
      confirmLabel: S.of(context)?.apply ?? 'Apply',
      onConfirm: () => Navigator.pop(context, true),
      onCancel: () => Navigator.pop(context, false),
    );
    if (confirmed != true || !mounted) return;

    final error = await _jobActionService.applyToJob(job.id, job.title);
    if (!mounted) return;

    if (error == null) {
      microInteractionSuccess();
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

  Future<void> _toggleSaveJob(Job job) async {
    final wasSaved = _jobActionService.isSaved(job.id);
    final error = await _jobActionService.toggleSave(job.id);
    if (!mounted) return;

    if (error == null) {
      microInteractionSuccess();
      CustomToast.show(
        context,
        message:
            wasSaved ? 'Job removed from saved.' : 'Job saved successfully.',
        type: wasSaved ? ToastType.info : ToastType.info,
      );
    } else {
      CustomToast.show(
        context,
        message: error,
        type: ToastType.error,
      );
    }
  }

  bool _isReadNotification(Map<String, dynamic> item) {
    final readAt = item['read_at'];
    if (readAt == null) return false;
    if (readAt is String) return readAt.trim().isNotEmpty;
    return true;
  }

  Future<void> _openNotification(Map<String, dynamic> notificationItem) async {
    HapticFeedback.selectionClick();
    final token = UserSession().token;
    if (token == null || token.isEmpty) return;
    final id = notificationItem['id'];
    if (id == null) return;

    final result = await ApiService.getJobseekerNotification(
      token: token,
      id: id is int ? id : int.tryParse(id.toString()) ?? 0,
    );
    if (!mounted) return;
    if (result['success'] == true) {
      final data = result['data'] as Map<String, dynamic>? ?? {};
      final readAt = data['read_at'] ?? DateTime.now().toIso8601String();
      setState(() {
        _notifications = _notifications
            .map((item) => item['id'] == id
                ? {
                    ...item,
                    'read_at': readAt,
                  }
                : item)
            .toList();
      });
    }
  }

  Future<void> _openInvitationJob(Map<String, dynamic> notification) async {
    final token = UserSession().token;
    if (token == null || token.isEmpty) return;

    final notif = notification['notification'] as Map<String, dynamic>? ?? {};
    // Try job listing data from eager-loaded relationship first
    final jobListing = notif['job_listing'] as Map<String, dynamic>?;
    final rawJobId = notif['job_listing_id'];
    final jobId =
        rawJobId is int ? rawJobId : int.tryParse(rawJobId?.toString() ?? '');

    if (jobId == null) return;

    // Prefer embedded listing data to avoid an extra round-trip
    Map<String, dynamic>? jobData;
    if (jobListing != null) {
      jobData = jobListing;
    } else {
      final result = await ApiService.getJobById(token, jobId);
      if (result['success'] == true) {
        final raw = result['data'];
        jobData = raw is Map<String, dynamic> ? raw : null;
      }
    }
    if (jobData == null || !mounted) return;
    final job = Job.fromJson(jobData);
    if (!mounted) return;
    showJobDetailSheet(
      context,
      job,
      isSaved: _jobActionService.isSaved(job.id),
      isApplied: _jobActionService.isApplied(job.id),
      onSave: () => _toggleSaveJob(job),
      onApply: () => _applyToJob(job),
      onViewMap: widget.onOpenMapRequested != null
          ? () {
              Navigator.of(context).pop();
              widget.onOpenMapRequested!(MapFocusRequest.fromJob(job));
            }
          : null,
    );
  }

  Future<int?> _resolveOfferApplicationId(Map<String, dynamic> notificationItem) async {
    final notif = notificationItem['notification'] as Map<String, dynamic>? ?? {};
    final meta = notif['meta'] as Map<String, dynamic>? ?? {};
    final direct = meta['application_id'];
    final parsedDirect =
        direct is int ? direct : int.tryParse(direct?.toString() ?? '');
    if (parsedDirect != null && parsedDirect > 0) return parsedDirect;

    final rawJobListingId = notif['job_listing_id'];
    final jobListingId = rawJobListingId is int
        ? rawJobListingId
        : int.tryParse(rawJobListingId?.toString() ?? '');
    if (jobListingId == null) return null;

    final token = UserSession().token;
    if (token == null || token.isEmpty) return null;
    final appsRes = await ApiService.getApplications(token);
    if (appsRes['success'] != true) return null;
    final apps = (appsRes['data'] as List<dynamic>? ?? []).cast<dynamic>();

    int? candidateId;
    for (final item in apps) {
      final app = item as Map<String, dynamic>;
      final appJob = app['job_listing'] as Map<String, dynamic>?;
      final appJobIdRaw = app['job_listing_id'] ?? appJob?['id'];
      final appJobId = appJobIdRaw is int
          ? appJobIdRaw
          : int.tryParse(appJobIdRaw?.toString() ?? '');
      if (appJobId != jobListingId) continue;

      final status = (app['status']?.toString() ?? '').toLowerCase();
      final appIdRaw = app['id'];
      final appId = appIdRaw is int ? appIdRaw : int.tryParse(appIdRaw?.toString() ?? '');
      if (appId == null) continue;
      if (status == 'for_job_offer') {
        candidateId = appId;
        break;
      }
      candidateId ??= appId;
    }
    return candidateId;
  }

  Future<({int? applicationId, String? offerResponse})> _resolveOfferState(
      Map<String, dynamic> notificationItem) async {
    final notif = notificationItem['notification'] as Map<String, dynamic>? ?? {};
    final meta = notif['meta'] as Map<String, dynamic>? ?? {};
    final directResponseRaw = meta['offer_response']?.toString().toLowerCase();
    final normalizedDirect = switch (directResponseRaw) {
      'accepted' => 'accepted',
      'declined' => 'declined',
      _ => null,
    };

    final appId = await _resolveOfferApplicationId(notificationItem);
    if (appId == null) {
      return (applicationId: null, offerResponse: normalizedDirect);
    }

    final token = UserSession().token;
    if (token == null || token.isEmpty) {
      return (applicationId: appId, offerResponse: normalizedDirect);
    }

    final appsRes = await ApiService.getApplications(token);
    if (appsRes['success'] != true) {
      return (applicationId: appId, offerResponse: normalizedDirect);
    }

    final apps = (appsRes['data'] as List<dynamic>? ?? []).cast<dynamic>();
    for (final item in apps) {
      final app = item as Map<String, dynamic>;
      final rawId = app['id'];
      final currentId =
          rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');
      if (currentId != appId) continue;
      final responseRaw = app['offer_response']?.toString().toLowerCase();
      final normalized = switch (responseRaw) {
        'accepted' => 'accepted',
        'declined' => 'declined',
        _ => null,
      };
      return (applicationId: appId, offerResponse: normalized ?? normalizedDirect);
    }

    return (applicationId: appId, offerResponse: normalizedDirect);
  }

  Future<bool> _submitOfferResponse({
    required int applicationId,
    required String response, // accepted | declined
  }) async {
    final token = UserSession().token;
    if (token == null || token.isEmpty) return false;
    final result = await ApiService.respondToJobOffer(
      token: token,
      applicationId: applicationId,
      response: response,
    );
    return result['success'] == true;
  }

  Future<void> _showOfferDecisionModal({
    required Map<String, dynamic> notificationItem,
    required String jobTitle,
    required String companyName,
    required String startDate,
    required String salary,
    required String employmentType,
    required bool hasKnownApplicationId,
  }) async {
    int? resolvedAppId;
    String? selectedResponse;
    bool isSubmitting = false;
    bool isHydratingOfferState = true;
    bool hasStartedHydration = false;
    bool isActionCooldown = true;
    bool hasStartedActionCooldown = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          if (!hasStartedHydration) {
            hasStartedHydration = true;
            unawaited(() async {
              ({int? applicationId, String? offerResponse}) initialState;
              try {
                initialState = await _resolveOfferState(notificationItem);
              } catch (_) {
                if (!mounted || !ctx.mounted) return;
                setModalState(() {
                  isHydratingOfferState = false;
                });
                return;
              }
              if (!mounted || !ctx.mounted) return;
              setModalState(() {
                resolvedAppId = initialState.applicationId;
                selectedResponse = initialState.offerResponse;
                isHydratingOfferState = false;
              });
            }());
          }
          if (!hasStartedActionCooldown) {
            hasStartedActionCooldown = true;
            unawaited(() async {
              await Future<void>.delayed(const Duration(milliseconds: 1500));
              if (!mounted || !ctx.mounted) return;
              setModalState(() {
                isActionCooldown = false;
              });
            }());
          }

          Future<void> handleResponse(String response) async {
            if (isSubmitting || selectedResponse != null || isActionCooldown) return;
            setModalState(() => isSubmitting = true);

            resolvedAppId ??= await _resolveOfferApplicationId(notificationItem);
            if (resolvedAppId == null) {
              if (!mounted) return;
              Navigator.of(ctx).pop();
              CustomToast.show(
                context,
                message:
                    'Unable to locate your application record for this offer. Please refresh notifications and try again.',
                type: ToastType.error,
              );
              return;
            }

            final ok = await _submitOfferResponse(
              applicationId: resolvedAppId!,
              response: response,
            );
            if (!mounted) return;
            if (ok) {
              setModalState(() {
                selectedResponse = response;
                isSubmitting = false;
              });
              CustomToast.show(
                context,
                message: response == 'accepted'
                    ? 'Offer accepted successfully.'
                    : 'Offer rejected successfully.',
                type: response == 'accepted' ? ToastType.success : ToastType.info,
              );
              await _loadNotifications(showLoader: false);
            } else {
              setModalState(() => isSubmitting = false);
              Navigator.of(ctx).pop();
              CustomToast.show(
                context,
                message:
                    'Failed to submit your offer response. Please try again.',
                type: ToastType.error,
              );
            }
          }

          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.84,
            minChildSize: 0.52,
            maxChildSize: 0.94,
            builder: (_, scrollCtrl) => Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: ListView(
                controller: scrollCtrl,
                padding: EdgeInsets.only(
                  bottom: MediaQuery.viewInsetsOf(ctx).bottom + 16,
                ),
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Icon(Icons.gavel_rounded, color: Colors.white, size: 28),
                        SizedBox(height: 10),
                        Text(
                          'Job Offer Received',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF475569),
                          height: 1.5,
                        ),
                        children: _parseMessageWithBold(
                          '**$companyName** offered you the **$jobTitle** role. Please review and choose one response below.',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Start Date: $startDate',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF334155))),
                          const SizedBox(height: 4),
                          Text('Salary: $salary',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF334155))),
                          const SizedBox(height: 4),
                          Text('Employment Type: $employmentType',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF334155))),
                        ],
                      ),
                    ),
                  ),
                  if (!hasKnownApplicationId)
                    const Padding(
                      padding: EdgeInsets.only(top: 8, left: 20, right: 20),
                      child: Text(
                        'Preparing offer reference...',
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ),
                  if (isHydratingOfferState)
                    const Padding(
                      padding: EdgeInsets.only(top: 6, left: 20, right: 20),
                      child: Text(
                        'Loading offer status...',
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ),
                  if (selectedResponse != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10, left: 20, right: 20),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: selectedResponse == 'accepted'
                              ? const Color(0xFFECFDF5)
                              : const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selectedResponse == 'accepted'
                                ? const Color(0xFFA7F3D0)
                                : const Color(0xFFFECACA),
                          ),
                        ),
                        child: Text(
                          selectedResponse == 'accepted'
                              ? 'You accepted this offer.'
                              : 'You rejected this offer.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: selectedResponse == 'accepted'
                                ? const Color(0xFF047857)
                                : const Color(0xFFB91C1C),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: (isSubmitting ||
                                    selectedResponse != null ||
                                    isActionCooldown)
                                ? null
                                : () => handleResponse('declined'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: isActionCooldown
                                  ? const Color(0xFF94A3B8)
                                  : selectedResponse == null
                                  ? const Color(0xFFB91C1C)
                                  : const Color(0xFF94A3B8),
                              side: BorderSide(
                                color: isActionCooldown
                                    ? const Color(0xFFE2E8F0)
                                    : selectedResponse == null
                                    ? const Color(0xFFFCA5A5)
                                    : const Color(0xFFE2E8F0),
                              ),
                              backgroundColor: isActionCooldown
                                  ? const Color(0xFFF1F5F9)
                                  : selectedResponse == 'declined'
                                  ? const Color(0xFFFEF2F2)
                                  : Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              isActionCooldown
                                  ? 'Reject Offer'
                                  : selectedResponse == 'declined'
                                  ? 'Rejected'
                                  : 'Reject Offer',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: (isSubmitting ||
                                    selectedResponse != null ||
                                    isActionCooldown)
                                ? null
                                : () => handleResponse('accepted'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isActionCooldown
                                  ? const Color(0xFFCBD5E1)
                                  : selectedResponse == 'accepted'
                                  ? const Color(0xFF047857)
                                  : (selectedResponse == null
                                      ? const Color(0xFF059669)
                                      : const Color(0xFFCBD5E1)),
                              foregroundColor: isActionCooldown
                                  ? const Color(0xFF475569)
                                  : selectedResponse == null
                                  ? Colors.white
                                  : const Color(0xFF475569),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                            child: isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    selectedResponse == 'accepted'
                                        ? 'Accepted'
                                        : 'Accept Offer',
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _deleteNotification(int idxInSortedList,
      {bool allowSatisfactionSurvey = false}) async {
    HapticFeedback.mediumImpact();
    // Use the sorted list to find the actual notification object
    final n = _sortedNotifications[idxInSortedList];
    final notifId = n['id'];
    
    final notifData = n['notification'] as Map<String, dynamic>? ?? {};
    if (notifData['type'] == 'satisfaction_survey' && !allowSatisfactionSurvey) {
      return;
    }

    // Immediately remove from the underlying source list by finding the matching ID
    // This fixed the "Dismissible widget still part of tree" and index-mismatch error.
    setState(() {
       _notifications.removeWhere((item) => item['id'] == notifId);
    });

    final token = UserSession().token;
    if (token == null || token.isEmpty || notifId == null) return;
    
    await ApiService.deleteJobseekerNotification(
      token: token,
      id: notifId is int ? notifId : int.tryParse(notifId.toString()) ?? 0,
    );
  }

  Future<void> _deleteNotificationByItem(Map<String, dynamic> n,
      {bool allowSatisfactionSurvey = false}) async {
    final notifId = n['id'];
    final notifData = n['notification'] as Map<String, dynamic>? ?? {};
    if (notifData['type'] == 'satisfaction_survey' && !allowSatisfactionSurvey) {
      return;
    }

    setState(() {
      _notifications.removeWhere((item) => item['id'] == notifId);
    });

    final token = UserSession().token;
    if (token == null || token.isEmpty || notifId == null) return;
    await ApiService.deleteJobseekerNotification(
      token: token,
      id: notifId is int ? notifId : int.tryParse(notifId.toString()) ?? 0,
    );
  }

  Future<void> _animateThenDeleteAllNotifications() async {
    final sorted = _sortedNotifications;
    final deletable =
        sorted.where((n) => !_isProtectedSatisfactionSurvey(n)).toList();
    final count = deletable.length;
    if (count == 0) return;

    final controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 160 + count * 68),
    );

    void tick() {
      if (mounted) setState(() {});
    }

    controller.addListener(tick);
    setState(() => _deleteAllExitAnim = controller);

    try {
      await controller.forward();
    } catch (_) {
      // e.g. route popped / ticker disposed
    }

    controller.removeListener(tick);

    if (!identical(_deleteAllExitAnim, controller)) {
      return;
    }
    if (!mounted) {
      controller.dispose();
      _deleteAllExitAnim = null;
      return;
    }

    // Keep last frame (items off-screen) so empty UI does not flash in early.
    await Future.delayed(_deleteAllToEmptyDelay);
    if (!mounted) return;
    if (!identical(_deleteAllExitAnim, controller)) {
      return;
    }

    controller.dispose();
    setState(() {
      _deleteAllExitAnim = null;
      _notifications.removeWhere(
          (item) => !_isProtectedSatisfactionSurvey(item));
    });

    if (!mounted) return;
    final token = UserSession().token;
    if (token == null || token.isEmpty) return;

    var allOk = true;
    for (final item in deletable) {
      final rawId = item['id'];
      final id = rawId is int ? rawId : int.tryParse(rawId.toString()) ?? 0;
      if (id == 0) continue;
      final ok = await ApiService.deleteJobseekerNotification(
        token: token,
        id: id,
      );
      if (!ok) allOk = false;
    }
    if (!mounted) return;
    if (!allOk) {
      await _loadNotifications(showLoader: false);
    }
  }

  Future<void> _confirmDeleteAllNotifications() async {
    if (_notifications.isEmpty) return;

    final hasProtected =
        _notifications.any(_isProtectedSatisfactionSurvey);
    final deletableCount = _notifications
        .where((n) => !_isProtectedSatisfactionSurvey(n))
        .length;

    if (deletableCount == 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Your experience rating is still pending. Submit your rating to clear it.',
          ),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final confirmed = await showAppDialog<bool>(
      context: context,
      type: AppDialogType.destructive,
      icon: Icons.delete_sweep_rounded,
      title: 'Delete All Notifications?',
      message: hasProtected
          ? 'This removes all notifications except your pending experience rating. That stays until you submit your feedback. This cannot be undone for the items removed.'
          : 'This will remove all notifications from your account. This cannot be undone.',
      confirmLabel: 'Delete all',
      onConfirm: () => Navigator.of(context).pop(true),
      onCancel: () => Navigator.of(context).pop(false),
    );

    if (confirmed == true && mounted) {
      await _animateThenDeleteAllNotifications();
    }
  }

  List<TextSpan> _parseMessageWithBold(String message) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'\*\*(.*?)\*\*');
    int lastIndex = 0;

    for (final match in regex.allMatches(message)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(text: message.substring(lastIndex, match.start)));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: Color(0xFF0F172A),
        ),
      ));
      lastIndex = match.end;
    }

    if (lastIndex < message.length) {
      spans.add(TextSpan(text: message.substring(lastIndex)));
    }

    return spans;
  }

  Future<void> _showRatingDialog(Map<String, dynamic> n) async {
    final token = UserSession().token;
    if (token == null || token.isEmpty) return;

    if (!_isReadNotification(n)) {
      _openNotification(n);
    }

    int selectedRating = 0;
    bool isSubmitting = false;

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) => Container(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curve = Curves.easeInOutBack.transform(anim1.value);
        return Transform.scale(
          scale: curve,
          child: Opacity(
            opacity: anim1.value,
            child: StatefulBuilder(
              builder: (ctx, setDialogState) {
                const double starBarWidth = 240;
                void applyStarFromDx(double dx) {
                  final x = dx.clamp(0.0, starBarWidth);
                  var next = ((x / starBarWidth) * 5).ceil();
                  if (next < 1) next = 1;
                  if (next > 5) next = 5;
                  if (next != selectedRating) {
                    HapticFeedback.selectionClick();
                    setDialogState(() => selectedRating = next);
                  }
                }

                return AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28)),
                  elevation: 24,
                  shadowColor: Colors.black26,
                  titlePadding: const EdgeInsets.fromLTRB(28, 28, 28, 12),
                  contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                  title: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.stars_rounded,
                            color: Color(0xFF10B981), size: 36),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'How did we do?',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Your feedback helps us improve the application process for everyone.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Emoji Feedback
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          selectedRating == 1
                              ? '😟'
                              : selectedRating == 2
                                  ? '😕'
                                  : selectedRating == 3
                                      ? '😐'
                                      : selectedRating == 4
                                          ? '🙂'
                                          : selectedRating == 5
                                              ? '🤩'
                                              : '✨',
                          key: ValueKey(selectedRating),
                          style: const TextStyle(fontSize: 48),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: SizedBox(
                          width: starBarWidth,
                          height: 52,
                          child: Listener(
                            behavior: HitTestBehavior.opaque,
                            onPointerDown: (e) =>
                                applyStarFromDx(e.localPosition.dx),
                            onPointerMove: (e) =>
                                applyStarFromDx(e.localPosition.dx),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(5, (i) {
                                final starIndex = i + 1;
                                final isSelected =
                                    starIndex <= selectedRating;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4),
                                  child: Icon(
                                    isSelected
                                        ? Icons.star_rounded
                                        : Icons.star_outline_rounded,
                                    color: isSelected
                                        ? const Color(0xFFF59E0B)
                                        : const Color(0xFFCBD5E1),
                                    size: 40,
                                  )
                                      .animate(
                                        target: isSelected ? 1 : 0,
                                      )
                                      .scale(
                                          begin: const Offset(1, 1),
                                          end: const Offset(1.2, 1.2),
                                          duration: 200.ms,
                                          curve: Curves.easeOutBack)
                                      .then()
                                      .scale(
                                          begin: const Offset(1.2, 1.2),
                                          end: const Offset(1, 1),
                                          duration: 150.ms),
                                );
                              }),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        selectedRating == 1
                            ? 'Very Dissatisfied'
                            : selectedRating == 2
                                ? 'Dissatisfied'
                                : selectedRating == 3
                                    ? 'Neutral'
                                    : selectedRating == 4
                                        ? 'Satisfied'
                                        : selectedRating == 5
                                            ? 'Excellent!'
                                            : 'Tap or slide to rate',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: selectedRating == 0
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  actions: [
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: isSubmitting
                                ? null
                                : () => Navigator.of(ctx).pop(),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text(
                              'Maybe Later',
                              style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: (selectedRating == 0 || isSubmitting)
                                ? null
                                : () async {
                                    setDialogState(() => isSubmitting = true);
                                    final result = await ApiService
                                        .submitSatisfactionRating(
                                            token, selectedRating);
                                    if (!mounted) return;
                                    setDialogState(() => isSubmitting = false);
                                    if (result['success'] == true) {
                                      Navigator.of(ctx).pop();
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: const Text(
                                              'Thank you! Your feedback was shared.'),
                                          backgroundColor:
                                              const Color(0xFF10B981),
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12)),
                                        ),
                                      );
                                      _deleteNotificationByItem(
                                        n,
                                        allowSatisfactionSurvey: true,
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(result['message'] ??
                                              'Failed to submit rating.'),
                                          backgroundColor:
                                              const Color(0xFFEF4444),
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12)),
                                        ),
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              disabledBackgroundColor: const Color(0xFFE2E8F0),
                            ),
                            child: isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : const Text('Submit',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: const Color(0xFF64748B)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_notifications.isNotEmpty || _fabAnimInitialized) {
      _scheduleDeleteFabSync();
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          S.of(context)?.notifications ?? 'Notifications',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF0F172A),
            letterSpacing: -0.4,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(),
              elevation: 4,
              shadowColor: Colors.black.withOpacity(0.12),
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded, size: 20),
                color: const Color(0xFF0F172A),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(8),
              ),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: InkWell(
                onTap: _notifications.isEmpty ? null : () {
                  HapticFeedback.selectionClick();
                  _markAllRead();
                },
                borderRadius: BorderRadius.circular(100),
                child: Opacity(
                  opacity: _notifications.isEmpty ? 0.5 : 1.0,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(100),
                      border:
                          Border.all(color: const Color(0xFFDBEAFE), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.done_all_rounded,
                          size: 14,
                          color: Color(0xFF2563EB),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Mark all read',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: const Color(0xFFF1F5F9),
            height: 1,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2563EB)),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            size: 40, color: Color(0xFFEF4444)),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _loadNotifications,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : AnimatedSwitcher(
                  duration: const Duration(milliseconds: 420),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, anim) {
                    return FadeTransition(opacity: anim, child: child);
                  },
                  child: _notifications.isEmpty
                      ? KeyedSubtree(
                          key: const ValueKey('notifications-empty'),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2563EB)
                                        .withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.notifications_outlined,
                                    size: 50,
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'No notifications yet',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 40),
                                  child: Text(
                                    'You\'ll receive updates about jobs, applications, and more',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : KeyedSubtree(
                          key: const ValueKey('notifications-list'),
                          child: RefreshIndicator(
                      color: const Color(0xFF2563EB),
                      onRefresh: _loadNotifications,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        clipBehavior: Clip.hardEdge,
                        itemCount: _sortedNotifications.length,
                        itemBuilder: (context, index) {
                          final sortedList = _sortedNotifications;
                          final n = sortedList[index];
                          final notif =
                              n['notification'] as Map<String, dynamic>? ?? {};
                          final type = notif['type'] as String?;
                          final subject =
                              notif['subject'] as String? ?? 'Notification';
                          final message = notif['message'] as String? ?? '';
                          final createdAt = DateTime.tryParse(
                                (notif['created_at'] as String? ?? ''),
                              ) ??
                              DateTime.now();
                          final isRead = _isReadNotification(n);
                          final id = n['id'] ?? index;

                          // Shared time/date formatting
                          final nowPh = nowInPhilippines();
                          final createdAtPh = createdAt.isUtc
                              ? createdAt.add(const Duration(hours: 8))
                              : createdAt;
                          final diff = nowPh.difference(createdAtPh);
                          final timeAgo = diff.inDays > 0
                              ? '${diff.inDays}d ago'
                              : diff.inHours > 0
                                  ? '${diff.inHours}h ago'
                                  : diff.inMinutes > 0
                                      ? '${diff.inMinutes}m ago'
                                      : 'just now';

                          const monthNames = [
                            'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                            'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                          ];
                          final dateFormatted =
                              '${monthNames[createdAtPh.month - 1]}/${createdAtPh.day.toString().padLeft(2, '0')}/${createdAtPh.year}';

                          // Header detection
                          Widget? header;
                          if (index == 0 && type == 'satisfaction_survey') {
                            header = Padding(
                              padding: const EdgeInsets.fromLTRB(4, 8, 0, 16),
                              child: Row(
                                children: [
                                  const Icon(Icons.stars_rounded, size: 18, color: Color(0xFF2563EB)),
                                  const SizedBox(width: 8),
                                  Text(
                                    'ACTION REQUIRED',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF2563EB),
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          } else if (type != 'satisfaction_survey') {
                            final prevType = index > 0 
                                ? (sortedList[index - 1]['notification'] as Map<String, dynamic>? ?? {})['type'] as String?
                                : null;
                            if (index == 0 || prevType == 'satisfaction_survey') {
                              header = Padding(
                                padding: EdgeInsets.fromLTRB(4, index == 0 ? 8 : 12, 0, 16),
                                child: Text(
                                  'LATEST UPDATES',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF64748B),
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              );
                            }
                          }

                          Widget card;
                          if (type == 'invitation') {
                            final jobListing = notif['job_listing'] as Map<String, dynamic>?;
                            final jobTitle = jobListing?['title'] as String? ?? subject;
                            final jobType = jobListing?['type'] as String? ?? '';
                            final jobLocation = jobListing?['location'] as String? ?? '';
                            final companyName = (jobListing?['employer'] as Map<String, dynamic>?)?['company_name'] as String? ?? 'An employer';

                            card = Dismissible(
                              key: ValueKey('notif_$id'),
                              direction: DismissDirection.endToStart,
                              background: _buildDismissBackground(),
                              onDismissed: (_) => _deleteNotification(index),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: _buildCardDecoration(isRead, const Color(0xFF2563EB)),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Material(
                                    color: Colors.white,
                                    child: InkWell(
                                      onTap: () {
                                        _openNotification(n);
                                        _openInvitationJob(n);
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            _buildInvitationHeader(subject, timeAgo, dateFormatted, isRead),
                                            const SizedBox(height: 12),
                                            _buildJobBriefBox(companyName, jobTitle, jobLocation, jobType, jobListing),
                                            const SizedBox(height: 16),
                                            _buildViewInvitationChip(),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          } else if (type == 'satisfaction_survey') {
                            card = Dismissible(
                              key: ValueKey('notif_$id'),
                              direction: DismissDirection.none,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 24),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0F7FF),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF2563EB).withOpacity(0.06),
                                      blurRadius: 15,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Stack(
                                    children: [
                                      // Main Content
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(25, 20, 20, 20),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            _buildSurveyHeader(timeAgo, dateFormatted, isRead),
                                            const SizedBox(height: 18),
                                            _buildSurveyMessageBox(message),
                                            const SizedBox(height: 18),
                                            _buildRateButton(() => _showRatingDialog(n)),
                                          ],
                                        ),
                                      ),
                                      // Vertical Accent Bar
                                      Positioned(
                                        left: 0,
                                        top: 0,
                                        bottom: 0,
                                        width: 5,
                                        child: Container(color: const Color(0xFF2563EB)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          } else if (type == 'status_interview') {
                            // ── Interview Scheduled notification ────────────
                            final meta = notif['meta'] as Map<String, dynamic>?;
                            final jobListing = notif['job_listing'] as Map<String, dynamic>?;
                            final interviewJobTitle = jobListing?['title'] as String? ?? subject;
                            final interviewCompany = (jobListing?['employer'] as Map<String, dynamic>?)?['company_name'] as String? ?? 'The employer';
                            const Color interviewColor = Color(0xFF8B5CF6);

                            card = Dismissible(
                              key: ValueKey('notif_$id'),
                              direction: DismissDirection.endToStart,
                              background: _buildDismissBackground(),
                              onDismissed: (_) => _deleteNotification(index),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: _buildCardDecoration(isRead, interviewColor),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Material(
                                    color: Colors.white,
                                    child: InkWell(
                                      onTap: () {
                                        _openNotification(n);
                                        _showInterviewScheduleModal(
                                          context,
                                          companyName: interviewCompany,
                                          jobTitle: interviewJobTitle,
                                          meta: meta,
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            _buildStatusLeading(interviewColor, 'assets/empoy_notif_interview.png'),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          subject,
                                                          style: TextStyle(
                                                            fontSize: 15,
                                                            fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                                                            color: const Color(0xFF0F172A),
                                                          ),
                                                        ),
                                                      ),
                                                      if (!isRead) _buildUnreadDot(interviewColor),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  RichText(
                                                    text: TextSpan(
                                                      style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
                                                      children: _parseMessageWithBold(
                                                        'Interview for **$interviewJobTitle** at **$interviewCompany**.',
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text('$timeAgo • $dateFormatted', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                                                  const SizedBox(height: 10),
                                                  // "View Schedule" chip
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFF5F3FF),
                                                      borderRadius: BorderRadius.circular(999),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: const [
                                                        Icon(Icons.calendar_month_rounded, size: 14, color: Color(0xFF7C3AED)),
                                                        SizedBox(width: 5),
                                                        Text(
                                                          'View Schedule',
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.w600,
                                                            color: Color(0xFF6D28D9),
                                                          ),
                                                        ),
                                                      ],
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
                                ),
                              ),
                            );
                          } else if (type == 'status_for_job_offer_sent') {
                            // ── Job Offer notification (requires accept/reject) ──
                            final meta = notif['meta'] as Map<String, dynamic>?;
                            final jobListing = notif['job_listing'] as Map<String, dynamic>?;
                            final offerJobTitle = meta?['job_title'] as String? ??
                                jobListing?['title'] as String? ??
                                subject;
                            final offerCompany = meta?['company_name'] as String? ??
                                (jobListing?['employer'] as Map<String, dynamic>?)?['company_name'] as String? ??
                                'The employer';
                            final startDate = meta?['start_date'] as String? ?? 'To be discussed';
                            final salary = meta?['salary'] as String? ??
                                jobListing?['salary_range'] as String? ??
                                'Negotiable';
                            final empTypeRaw = meta?['employment_type'] as String? ??
                                jobListing?['type'] as String? ??
                                'Full-time';
                            final applicationIdRaw = meta?['application_id'];
                            final hasKnownAppId = applicationIdRaw is int ||
                                int.tryParse(applicationIdRaw?.toString() ?? '') != null;
                            const Color offerColor = Color(0xFF0EA5E9);

                            card = Dismissible(
                              key: ValueKey('notif_$id'),
                              direction: DismissDirection.endToStart,
                              background: _buildDismissBackground(),
                              onDismissed: (_) => _deleteNotification(index),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: _buildCardDecoration(isRead, offerColor),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Material(
                                    color: Colors.white,
                                    child: InkWell(
                                      onTap: () {
                                        _openNotification(n);
                                        _showOfferDecisionModal(
                                          notificationItem: n,
                                          jobTitle: offerJobTitle,
                                          companyName: offerCompany,
                                          startDate: startDate,
                                          salary: salary,
                                          employmentType:
                                              formatEmploymentTypeLabel(empTypeRaw),
                                          hasKnownApplicationId: hasKnownAppId,
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            _buildStatusLeading(
                                                offerColor, 'assets/empoy_notif_hired.png'),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          subject,
                                                          style: TextStyle(
                                                            fontSize: 15,
                                                            fontWeight: isRead
                                                                ? FontWeight.w500
                                                                : FontWeight.w700,
                                                            color: const Color(0xFF0F172A),
                                                          ),
                                                        ),
                                                      ),
                                                      if (!isRead) _buildUnreadDot(offerColor),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  RichText(
                                                    text: TextSpan(
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        color: Color(0xFF64748B),
                                                        height: 1.4,
                                                      ),
                                                      children: _parseMessageWithBold(
                                                        '**$offerCompany** has offered you the **$offerJobTitle** role. Please choose to accept or reject this offer.',
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    '$timeAgo • $dateFormatted',
                                                    style: const TextStyle(
                                                        fontSize: 11,
                                                        color: Color(0xFF94A3B8)),
                                                  ),
                                                  const SizedBox(height: 10),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                        horizontal: 10, vertical: 5),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFE0F2FE),
                                                      borderRadius:
                                                          BorderRadius.circular(999),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: const [
                                                        Icon(Icons.gavel_rounded,
                                                            size: 14,
                                                            color: Color(0xFF0369A1)),
                                                        SizedBox(width: 5),
                                                        Text(
                                                          'Respond to Offer',
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.w600,
                                                            color: Color(0xFF075985),
                                                          ),
                                                        ),
                                                      ],
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
                                ),
                              ),
                            );
                          } else if (type == 'status_hired') {
                            // ── Hired notification ──────────────────────────
                            final meta = notif['meta'] as Map<String, dynamic>?;
                            final jobListing = notif['job_listing'] as Map<String, dynamic>?;
                            final hiredJobTitle  = meta?['job_title']       as String? ?? jobListing?['title'] as String? ?? subject;
                            final hiredCompany   = meta?['company_name']    as String? ?? (jobListing?['employer'] as Map<String, dynamic>?)?['company_name'] as String? ?? 'The employer';
                            final hiredStartDate = meta?['start_date']      as String? ?? 'To be discussed';
                            final hiredSalary    = meta?['salary']          as String? ?? jobListing?['salary_range'] as String? ?? 'Negotiable';
                            final hiredEmpType   = meta?['employment_type'] as String? ?? jobListing?['type'] as String? ?? 'Full-time';
                            const Color hiredColor = Color(0xFF10B981);

                            card = Dismissible(
                              key: ValueKey('notif_$id'),
                              direction: DismissDirection.endToStart,
                              background: _buildDismissBackground(),
                              onDismissed: (_) => _deleteNotification(index),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: _buildCardDecoration(isRead, hiredColor),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Material(
                                    color: Colors.white,
                                    child: InkWell(
                                      onTap: () {
                                        _openNotification(n);
                                        _showHiredOfferModal(
                                          context,
                                          jobTitle: hiredJobTitle,
                                          companyName: hiredCompany,
                                          startDate: hiredStartDate,
                                          salary: hiredSalary,
                                          employmentType:
                                              formatEmploymentTypeLabel(hiredEmpType),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            _buildStatusLeading(hiredColor, 'assets/empoy_notif_hired.png'),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          subject,
                                                          style: TextStyle(
                                                            fontSize: 15,
                                                            fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                                                            color: const Color(0xFF0F172A),
                                                          ),
                                                        ),
                                                      ),
                                                      if (!isRead) _buildUnreadDot(hiredColor),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  RichText(
                                                    text: TextSpan(
                                                      style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
                                                      children: _parseMessageWithBold(
                                                        'Offer extended for **$hiredJobTitle** at **$hiredCompany**.',
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text('$timeAgo • $dateFormatted', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                                                  const SizedBox(height: 10),
                                                  // "View Offer" chip
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFF0FDF4),
                                                      borderRadius: BorderRadius.circular(999),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: const [
                                                        Icon(Icons.workspace_premium_rounded, size: 14, color: Color(0xFF059669)),
                                                        SizedBox(width: 5),
                                                        Text(
                                                          'View Offer',
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.w600,
                                                            color: Color(0xFF047857),
                                                          ),
                                                        ),
                                                      ],
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
                                ),
                              ),
                            );
                          } else if (type == 'status_rejected') {
                            // ── Rejected notification ────────────────────────
                            final meta = notif['meta'] as Map<String, dynamic>?;
                            final jobListing = notif['job_listing'] as Map<String, dynamic>?;
                            final rejJobTitle  = meta?['job_title']    as String? ?? jobListing?['title'] as String? ?? subject;
                            final rejCompany   = meta?['company_name'] as String? ?? (jobListing?['employer'] as Map<String, dynamic>?)?['company_name'] as String? ?? 'The employer';
                            final rejUpdateDate = meta?['update_date'] as String? ?? dateFormatted;
                            const Color rejColor = Color(0xFFEF4444);

                            card = Dismissible(
                              key: ValueKey('notif_$id'),
                              direction: DismissDirection.endToStart,
                              background: _buildDismissBackground(),
                              onDismissed: (_) => _deleteNotification(index),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: _buildCardDecoration(isRead, rejColor),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Material(
                                    color: Colors.white,
                                    child: InkWell(
                                      onTap: () {
                                        _openNotification(n);
                                        _showRejectedModal(
                                          context,
                                          jobTitle: rejJobTitle,
                                          companyName: rejCompany,
                                          updateDate: rejUpdateDate,
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            _buildStatusLeading(rejColor, 'assets/empoy_notif_rejected.png'),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          subject,
                                                          style: TextStyle(
                                                            fontSize: 15,
                                                            fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                                                            color: const Color(0xFF0F172A),
                                                          ),
                                                        ),
                                                      ),
                                                      if (!isRead) _buildUnreadDot(rejColor),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  RichText(
                                                    text: TextSpan(
                                                      style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
                                                      children: _parseMessageWithBold(
                                                        'Application for **$rejJobTitle** at **$rejCompany**.',
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text('$timeAgo • $dateFormatted', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                                                  const SizedBox(height: 10),
                                                  // "View Details" chip
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFFEF2F2),
                                                      borderRadius: BorderRadius.circular(999),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFFDC2626)),
                                                        SizedBox(width: 5),
                                                        Text(
                                                          S.of(context)
                                                                  ?.viewDetails ??
                                                              'View Details',
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.w600,
                                                            color: Color(0xFFB91C1C),
                                                          ),
                                                        ),
                                                      ],
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
                                ),
                              ),
                            );
                          } else {
                            // Generic notification card
                            Color statusColor = _getStatusColor(type, subject, message);
                            String? statusAsset = _getStatusAsset(type, subject, message);

                            card = Dismissible(
                              key: ValueKey('notif_$id'),
                              direction: DismissDirection.endToStart,
                              background: _buildDismissBackground(),
                              onDismissed: (_) => _deleteNotification(index),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: _buildCardDecoration(isRead, statusColor),
                                child: ListTile(
                                  onTap: () => _openNotification(n),
                                  leading: _buildStatusLeading(statusColor, statusAsset),
                                  title: Text(
                                    subject,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                  subtitle: _buildGenericSubtitle(message, timeAgo, dateFormatted),
                                  trailing: !isRead ? _buildUnreadDot(statusColor) : null,
                                ),
                              ),
                            );
                          }

                          final deletableCount = sortedList
                              .where((x) => !_isProtectedSatisfactionSurvey(x))
                              .length;
                          final deletableIndexBefore = sortedList
                              .take(index)
                              .where((x) => !_isProtectedSatisfactionSurvey(x))
                              .length;
                          final slideOut = _isProtectedSatisfactionSurvey(n)
                              ? 0.0
                              : _deleteAllSlideProgressForIndex(
                                  deletableIndexBefore,
                                  deletableCount,
                                );
                          final slideW = MediaQuery.sizeOf(context).width;
                          // Nearly full-width cards need ~full viewport shift to clear the screen
                          // (0.5 * width left the right portion stuck visible).
                          final offscreenLeft = slideW + 56;
                          final column = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (header != null) header,
                              card,
                            ],
                          );
                          if (slideOut <= 0) return column;
                          return Opacity(
                            opacity: (1.0 - 0.92 * slideOut).clamp(0.0, 1.0),
                            child: Transform.translate(
                              offset:
                                  Offset(-offscreenLeft * slideOut, 0),
                              child: column,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
      floatingActionButton:
          _notifications.isEmpty ? null : _buildAnimatedDeleteAllFab(),
    );
  }

  // ── Helper Builders ─────────────────────────────────────────────────────────

  Widget _buildDismissBackground() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444),
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: const Icon(Icons.delete_rounded, color: Colors.white),
    );
  }

  BoxDecoration _buildCardDecoration(bool isRead, Color statusColor) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: isRead ? const Color(0xFFE2E8F0) : statusColor.withOpacity(0.5),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _buildInvitationHeader(String subject, String timeAgo, String dateFormatted, bool isRead) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: const Color(0xFF2563EB).withOpacity(0.1), shape: BoxShape.circle),
          child: const Icon(Icons.event_seat_rounded, color: Color(0xFF2563EB), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subject,
                style: TextStyle(
                  fontSize: 15, fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text('$timeAgo • $dateFormatted', style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
            ],
          ),
        ),
        if (!isRead) _buildUnreadDot(const Color(0xFF2563EB)),
      ],
    );
  }

  Widget _buildJobBriefBox(String companyName, String jobTitle, String jobLocation, String jobType, dynamic jobListing) {
    final jobTypeLabel = formatEmploymentTypeLabel(jobType);
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF), borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(companyName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2563EB))),
          const SizedBox(height: 4),
          Text(jobTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 6,
            children: [
              if (jobLocation.isNotEmpty) _buildChip(Icons.location_on_outlined, jobLocation),
              if (jobTypeLabel != 'Not specified') _buildChip(Icons.work_outline_rounded, jobTypeLabel),
              if ((jobListing?['salary_range'] as String? ?? '').isNotEmpty)
                _buildChip(Icons.payments_outlined, jobListing!['salary_range']),
            ],
          ),
        ],
      ),
    );
  }

  /// Small capsule hint shown on invitation notifications to indicate
  /// that tapping the card will open the full invitation details.
  Widget _buildViewInvitationChip() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.visibility_rounded, size: 16, color: Color(0xFF4F46E5)),
            SizedBox(width: 6),
            Text(
              'View Invitation',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3730A3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInterviewScheduleModal(
    BuildContext context, {
    required String companyName,
    required String jobTitle,
    Map<String, dynamic>? meta,
  }) {
    final date       = meta?['interview_date']     as String? ?? 'TBA';
    final time       = meta?['interview_time']     as String? ?? 'TBA';
    final format     = meta?['interview_format']   as String? ?? 'In-person';
    final location   = meta?['interview_location'] as String? ?? 'TBA';
    final interviewer= meta?['interviewer_name']   as String? ?? 'Hiring Manager';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.88,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollCtrl,
            padding: EdgeInsets.zero,
            children: [
              // Drag handle
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    width: 36, height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Purple header
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 28),
                    const SizedBox(height: 10),
                    Text(
                      '$companyName would like to invite you for a job interview for the',
                      style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.5),
                    ),
                    Text(
                      '$jobTitle position.',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white, height: 1.5),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Application Status chip
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFDDD6FE)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event_available_rounded, size: 20, color: Color(0xFF7C3AED)),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Application Status: For Interview',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF6D28D9))),
                          Text('Updated: $jobTitle',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF8B5CF6))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Interview Details section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'INTERVIEW DETAILS',
                      style: GoogleFonts.poppins(
                        fontSize: 11, fontWeight: FontWeight.w900,
                        letterSpacing: 1.1, color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          _buildInterviewDetailRow(Icons.calendar_today_rounded, 'Date', date, const Color(0xFF8B5CF6), isFirst: true),
                          _buildInterviewDetailDivider(),
                          _buildInterviewDetailRow(Icons.access_time_rounded, 'Time', time, const Color(0xFF8B5CF6)),
                          _buildInterviewDetailDivider(),
                          _buildInterviewDetailRow(Icons.chat_bubble_outline_rounded, 'Format', format, const Color(0xFF8B5CF6)),
                          _buildInterviewDetailDivider(),
                          _buildInterviewDetailRow(Icons.location_on_outlined, 'Location', location, const Color(0xFF8B5CF6)),
                          _buildInterviewDetailDivider(),
                          _buildInterviewDetailRow(Icons.person_outline_rounded, 'Interviewer', interviewer, const Color(0xFF8B5CF6), isLast: true),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // What to prepare
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What to prepare:',
                      style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildPrepItem(1, 'Updated Resume', 'Bring 2 printed copies or have it ready digitally on your device'),
                    _buildPrepItem(2, 'Valid Government ID', 'Passport, Driver\'s License, SSS, PhilHealth, or any government-issued ID'),
                    _buildPrepItem(3, 'Portfolio or Work Samples', 'Relevant projects, certifications, or links to your work if applicable'),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInterviewDetailRow(
    IconData icon, String label, String value, Color iconColor, {
    bool isFirst = false, bool isLast = false,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInterviewDetailDivider() =>
      const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFE2E8F0));

  Widget _buildPrepItem(int num, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28, height: 28,
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$num',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showHiredOfferModal(
    BuildContext context, {
    required String jobTitle,
    required String companyName,
    required String startDate,
    required String salary,
    required String employmentType,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.78,
        minChildSize: 0.5,
        maxChildSize: 0.92,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollCtrl,
            padding: EdgeInsets.zero,
            children: [
              // Drag handle
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    width: 36, height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Green header
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF059669), Color(0xFF047857)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 28),
                    const SizedBox(height: 10),
                    const Text(
                      'Application Status: Hired',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Offer extended on $startDate',
                      style: const TextStyle(fontSize: 13, color: Colors.white70),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Offer Details section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'OFFER DETAILS',
                      style: GoogleFonts.poppins(
                        fontSize: 11, fontWeight: FontWeight.w900,
                        letterSpacing: 1.1, color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          _buildOfferDetailRow('Position', jobTitle, isFirst: true),
                          _buildInterviewDetailDivider(),
                          _buildOfferDetailRow('Employer', companyName),
                          _buildInterviewDetailDivider(),
                          _buildOfferDetailRow('Start Date', startDate, valueColor: const Color(0xFF059669)),
                          _buildInterviewDetailDivider(),
                          _buildOfferDetailRow('Salary', salary),
                          _buildInterviewDetailDivider(),
                          _buildOfferDetailRow('Employment Type', employmentType, isLast: true),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOfferDetailRow(
    String label,
    String value, {
    bool isFirst = false,
    bool isLast = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: valueColor ?? const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRejectedModal(
    BuildContext context, {
    required String jobTitle,
    required String companyName,
    required String updateDate,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.82,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollCtrl,
            padding: EdgeInsets.zero,
            children: [
              // Drag handle
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    width: 36, height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Body text
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hi, ${UserSession().firstName ?? 'there'}',
                      style: GoogleFonts.poppins(
                        fontSize: 17, fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.65),
                        children: [
                          const TextSpan(text: 'Thank you for applying to '),
                          TextSpan(text: companyName, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                          const TextSpan(text: ' for the '),
                          TextSpan(text: jobTitle, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                          const TextSpan(text: ' position, and for the time and effort you invested throughout the application process. We sincerely appreciate your interest.'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'After careful review, the employer has decided to move forward with another candidate whose experience more closely aligns with their current needs. This was a highly competitive process, and this decision does not reflect your overall qualifications or potential.',
                      style: TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.65),
                    ),
                    const SizedBox(height: 20),

                    // Status chip
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.cancel_outlined, size: 20, color: Color(0xFFDC2626)),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Application Status: Not Selected',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFDC2626)),
                              ),
                              Text(
                                'Updated $updateDate',
                                style: const TextStyle(fontSize: 11, color: Color(0xFFEF4444)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    Text(
                      'Do not stop here — keep moving forward:',
                      style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildPrepItem(1, 'Update your profile',
                        'Add new skills, certifications, or accomplishments to strengthen your profile and stand out in future applications.'),
                    _buildPrepItem(2, 'Explore more job listings',
                        'There are many more active vacancies on PESO right now — a new opportunity is waiting for you.'),
                    _buildPrepItem(3, 'Attend PESO Job Fair events',
                        'Meet employers in person and make a lasting impression at our upcoming events this month.'),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSurveyHeader(String timeAgo, String dateFormatted, bool isRead) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.12), shape: BoxShape.circle),
          child: const Icon(Icons.rate_review_rounded, color: Color(0xFF059669), size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rate Your Experience',
                style: TextStyle(
                  fontSize: 16, fontWeight: isRead ? FontWeight.w700 : FontWeight.w900,
                  color: const Color(0xFF0F172A), letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 3),
              Text('$timeAgo • $dateFormatted', style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
            ],
          ),
        ),
        if (!isRead) _buildUnreadDot(const Color(0xFF10B981)),
      ],
    );
  }

  Widget _buildSurveyMessageBox(String message) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.15)),
      ),
      child: Text(message, style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B), height: 1.5)),
    );
  }

  Widget _buildRateButton(VoidCallback onTap) {
    return SizedBox(
      width: double.infinity, height: 48,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.stars_rounded, size: 20),
        label: const Text('Rate Application Process'),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _buildStatusLeading(Color statusColor, String? asset) {
    return Container(
      width: 48, height: 48,
      decoration: BoxDecoration(color: statusColor.withOpacity(0.12), shape: BoxShape.circle),
      padding: const EdgeInsets.all(4),
      child: asset != null
          ? Image.asset(asset, fit: BoxFit.contain)
          : Icon(Icons.notifications_rounded, color: statusColor, size: 24),
    );
  }

  Widget _buildUnreadDot(Color color) {
    return Container(
      margin: const EdgeInsets.only(top: 8, right: 4),
      width: 10, height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildGenericSubtitle(String message, String timeAgo, String dateFormatted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            children: _parseMessageWithBold(message),
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
          ),
        ),
        const SizedBox(height: 6),
        Text('$timeAgo • $dateFormatted', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
      ],
    );
  }

  Color _getStatusColor(String? type, String subject, String message) {
    final t = (type ?? '').toLowerCase();
    final s = subject.toLowerCase();
    final m = message.toLowerCase();
    if (t.contains('shortlisted') || s.contains('shortlisted') || m.contains('shortlisted')) return const Color(0xFFF59E0B);
    if (t.contains('interview') || s.contains('interview') || m.contains('interview')) return const Color(0xFF8B5CF6);
    if (t.contains('hired') || s.contains('hired') || m.contains('hired')) return const Color(0xFF10B981);
    if (t.contains('rejected') || s.contains('rejected') || m.contains('rejected') || s.contains('not selected')) return const Color(0xFFEF4444);
    return const Color(0xFF2563EB);
  }

  String? _getStatusAsset(String? type, String subject, String message) {
    final t = (type ?? '').toLowerCase();
    final s = subject.toLowerCase();
    final m = message.toLowerCase();
    if (t.contains('shortlisted') || s.contains('shortlisted') || m.contains('shortlisted')) return 'assets/empoy_notif_shortlisted.png';
    if (t.contains('interview') || s.contains('interview') || m.contains('interview')) return 'assets/empoy_notif_interview.png';
    if (t.contains('hired') || s.contains('hired') || m.contains('hired')) return 'assets/empoy_notif_hired.png';
    if (t.contains('rejected') || s.contains('rejected') || m.contains('rejected') || s.contains('not selected')) return 'assets/empoy_notif_rejected.png';
    if (t.contains('reviewing') || s.contains('received') || m.contains('received')) return 'assets/empoy_notif_application_received.png';
    return null;
  }
}
