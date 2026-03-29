import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'profile_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'job_models.dart';
import 'event_models.dart';
import 'user_session.dart';
import 'api_service.dart';
import 'job_action_service.dart';
import 'micro_interactions.dart';
import 'package:http/http.dart' as http;
import 'main.dart';

final String mapboxToken = dotenv.env['MAPBOX_TOKEN'] ?? '';

final String mapboxAccessToken = mapboxToken.isNotEmpty ? mapboxToken : '';

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
final ValueNotifier<MapFocusRequest?> mapFocusRequestNotifier =
    ValueNotifier<MapFocusRequest?>(null);

Widget _pesoEventDetailRow(IconData icon, String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF2563EB)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 15, color: Colors.grey[800], height: 1.4),
          ),
        ),
      ],
    ),
  );
}

/// Reliable live updates after register/unregister (StatefulBuilder can miss rebuilds on web).
class _EventDetailDialog extends StatefulWidget {
  final PesoEvent initialEvent;
  final VoidCallback onRegistrationChanged;
  /// Host context (e.g. Home) for SnackBars after the dialog closes.
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
      final data = res['data'];
      final pc = data is Map<String, dynamic> ? (data['participants_count'] as num?)?.toInt() : null;
      final nextRegistered = !_event.isRegistered;
      setState(() {
        _event = _event.copyWith(
          isRegistered: nextRegistered,
          participantsCount: pc ??
              (nextRegistered
                  ? _event.participantsCount + 1
                  : (_event.participantsCount > 0 ? _event.participantsCount - 1 : 0)),
        );
      });
      microInteractionSuccess();
      widget.onRegistrationChanged();
      CustomToast.show(
        widget.hostContext,
        message: _event.isRegistered ? 'Registered for ${_event.title}' : 'Cancelled registration',
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _event.typeLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _event.isRegistered
                          ? const Color(0xFF10B981).withOpacity(0.15)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _event.isRegistered
                            ? const Color(0xFF10B981).withOpacity(0.35)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Text(
                      _event.isRegistered ? 'Registered' : 'Not registered',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _event.isRegistered ? const Color(0xFF059669) : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                _event.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 16),
              _pesoEventDetailRow(Icons.calendar_today_rounded, _event.formattedDate),
              if (_event.eventTime != null) _pesoEventDetailRow(Icons.access_time_rounded, _event.eventTime!),
              _pesoEventDetailRow(Icons.location_on_rounded, _event.location),
              _pesoEventDetailRow(Icons.people_outline_rounded, _event.slotsLabel),
              if (_event.organizer != null) _pesoEventDetailRow(Icons.business_rounded, _event.organizer!),
              const SizedBox(height: 16),
              Text(
                'Description',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _event.description,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busy ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF64748B),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: primaryDisabled ? null : () => _onPrimaryAction(context),
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            _event.isRegistered ? const Color(0xFFEF4444) : const Color(0xFF2563EB),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _busy
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _event.isRegistered ? 'Cancel registration' : 'Register',
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Events bottom sheet keeps its own [Future] so register/cancel updates the list
/// immediately (parent [_reloadEventsFuture] alone does not rebuild an open sheet).
class _EventsBottomSheet extends StatefulWidget {
  final BuildContext homeContext;
  final VoidCallback onParentReloadEvents;
  final List<PesoEvent> Function(Map<String, dynamic>) parseEventsPayload;

  const _EventsBottomSheet({
    required this.homeContext,
    required this.onParentReloadEvents,
    required this.parseEventsPayload,
  });

  @override
  State<_EventsBottomSheet> createState() => _EventsBottomSheetState();
}

class _EventsBottomSheetState extends State<_EventsBottomSheet> {
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
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.event_rounded,
                    color: Color(0xFF2563EB),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Events',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Job fairs, seminars, and career events',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(color: Color(0xFF2563EB)),
                    ),
                  );
                }
                final data = snapshot.data;
                if (data == null || data['success'] != true) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline_rounded, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            data?['message'] ?? 'Failed to load events',
                            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final events = widget.parseEventsPayload(data);
                if (events.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.event_available_rounded, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            'No upcoming events',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Check back soon for job fairs and career events.',
                            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final e = events[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _openEventDetail(e),
                          borderRadius: BorderRadius.circular(16),
                          child: IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  width: 82,
                                  color: const Color(0xFF2563EB),
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 10,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          e.dateBadgeDay,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w800,
                                            height: 1.05,
                                            color: Color(0xFF2563EB),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          e.dateBadgeMonthUpper,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.5,
                                            color: Color(0xFF2563EB),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          e.dateBadgeYear,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    color: const Color(0xFFF8FAFC),
                                    padding: const EdgeInsets.fromLTRB(12, 14, 14, 14),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF2563EB).withOpacity(0.12),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    e.typeLabel,
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                      color: Color(0xFF2563EB),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            AnimatedSwitcher(
                                              duration: const Duration(milliseconds: 240),
                                              switchInCurve: Curves.easeOutCubic,
                                              switchOutCurve: Curves.easeInCubic,
                                              transitionBuilder: (child, anim) => FadeTransition(
                                                opacity: anim,
                                                child: ScaleTransition(scale: anim, child: child),
                                              ),
                                              child: Container(
                                                key: ValueKey<bool>(e.isRegistered),
                                                constraints: const BoxConstraints(maxWidth: 118),
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 5,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: e.isRegistered
                                                      ? const Color(0xFFE8F5E9)
                                                      : Colors.white,
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: e.isRegistered
                                                        ? const Color(0xFF81C784).withOpacity(0.6)
                                                        : const Color(0xFFE2E8F0),
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      e.isRegistered
                                                          ? Icons.check_circle_rounded
                                                          : Icons.circle_outlined,
                                                      size: 14,
                                                      color: e.isRegistered
                                                          ? const Color(0xFF2E7D32)
                                                          : const Color(0xFF757575),
                                                    ),
                                                    const SizedBox(width: 5),
                                                    Flexible(
                                                      child: Text(
                                                        e.isRegistered
                                                            ? 'Registered'
                                                            : 'Not registered',
                                                        maxLines: 2,
                                                        textAlign: TextAlign.right,
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.w700,
                                                          height: 1.2,
                                                          color: e.isRegistered
                                                              ? const Color(0xFF2E7D32)
                                                              : const Color(0xFF757575),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          e.title,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                        if (e.eventTime != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            e.eventTime!,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Icon(Icons.location_on_outlined,
                                                size: 14, color: Colors.grey[600]),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                e.location,
                                                style: TextStyle(
                                                    fontSize: 13, color: Colors.grey[600]),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (e.organizer != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            'by ${e.organizer}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[500],
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 4),
                                        Text(
                                          e.slotsLabel,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w500,
                                          ),
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
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── User Location (Demo) ─────────────────────────────────────────────────────
const double userLatitude = 16.689315116453432;
const double userLongitude = 121.55584211537534;

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

  double getDistanceFromUser() {
    return _calculateDistance(
      userLatitude,
      userLongitude,
      latitude,
      longitude,
    );
  }

  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
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
    description: 'SM SaveMore Market is a supermarket chain in the Philippines. We offer various career opportunities in retail, customer service, and management.',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6d/SM_Savemore_logo.svg/1200px-SM_Savemore_logo.svg.png',
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
        description: 'We are looking for friendly and efficient cashiers to provide excellent customer service and handle transactions accurately.',
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
        description: 'Responsible for organizing and stocking merchandise, maintaining inventory levels, and ensuring products are properly displayed.',
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
    description: 'Robinsons Place Santiago is a shopping mall offering retail, dining, and entertainment options. Join our team and be part of a dynamic work environment.',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/en/thumb/c/cc/Robinsons_Malls_logo.svg/1200px-Robinsons_Malls_logo.svg.png',
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
        description: 'Be part of our sales team! Assist customers in finding products, provide product information, and ensure excellent shopping experience.',
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
        description: 'Maintain safety and security of the mall premises. Monitor CCTV, conduct patrols, and respond to emergencies.',
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
        description: 'Handle customer inquiries, complaints, and requests. Provide information about mall services and promotions.',
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
    return raw.map((item) {
      final e = item as Map<String, dynamic>;
      final id = (e['id'] as num).toInt();
      return PesoEvent.fromJson(e, isRegistered: regIds.contains(id));
    }).where((event) => event.status != 'completed').toList();
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
    homeNavRequestNotifier.addListener(_onHomeNavRequested);
  }

  @override
  void dispose() {
    homeNavRequestNotifier.removeListener(_onHomeNavRequested);
    super.dispose();
  }

  void _onHomeNavRequested() {
    final requestedIndex = homeNavRequestNotifier.value;
    if (requestedIndex == null) return;
    homeNavRequestNotifier.value = null;
    if (!mounted) return;
    setState(() => _selectedIndex = requestedIndex.clamp(0, 2));
  }

  void _openMapForJob(MapFocusRequest request) {
    if (!mounted) return;
    setState(() => _selectedIndex = 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      mapFocusRequestNotifier.value = request;
    });
  }

  void _showEventsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _EventsBottomSheet(
          homeContext: context,
          onParentReloadEvents: _reloadEventsFuture,
          parseEventsPayload: _parseEventsPayload,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Scaffold(
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
            child: _buildFloatingNavBar(context),
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
                      ? (snapshot.data!['data'] as List).length
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
                  return AnimatedScale(
                    scale: _fabPulseScale,
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutBack,
                    child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _showEventsSheet,
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF2563EB).withOpacity(0.4),
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
                                constraints: const BoxConstraints(minWidth: 24),
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
          final pillLeft = itemWidth * _selectedIndex + (itemWidth - pillWidth) / 2;

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
                Row(
                  children: [
                    Expanded(
                      child: Center(
                        child: _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, 'Home'),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: _buildNavItem(1, Icons.map_rounded, Icons.map_outlined, 'Map'),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: _buildNavItem(2, Icons.person_rounded, Icons.person_outline_rounded, 'Profile'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isSelected = _selectedIndex == index;
    final iconColor = isSelected ? const Color(0xFF2563EB) : Colors.white.withOpacity(0.7);
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedScale(
        scale: isSelected ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.elasticOut,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (index == 2)
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? const Color(0xFF2563EB).withOpacity(0.14)
                      : Colors.white.withOpacity(0.22),
                ),
                alignment: Alignment.center,
                child: Icon(
                  isSelected ? activeIcon : inactiveIcon,
                  color: iconColor,
                  size: 18,
                ),
              )
            else
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
  final FocusNode _searchFocus = FocusNode();
  bool _searchFocused = false;
  String _searchText = '';
  String _sortOption = 'Latest';
  final Set<String> _selectedEmploymentTypes = <String>{};
  final Set<String> _selectedSkillFilters = <String>{};
  String _skillFilterQuery = '';

  List<Job> _jobs = [];
  bool _isLoading = true;
  String? _errorMessage;
  final _jobActionService = JobActionService();
  List<int>? _avatarBytes;
  int _unreadNotificationCount = 0;
  /// -1 before first successful read; ring when count increases vs previous.
  int _previousUnreadForBell = -1;
  late AnimationController _bellRingController;
  late Animation<double> _bellAngle;
  int _jobListSerial = 0;
  String _greetingText = '';
  Timer? _notificationPollTimer;
  Timer? _greetingTimer;
  bool _isUnreadLoading = false;

  static const List<String> _sortOptions = [
    'Latest',
    'Oldest',
    'Highest Salary',
    'Lowest Salary',
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
      final f = _searchFocus.hasFocus;
      if (f != _searchFocused) setState(() => _searchFocused = f);
    });
    final preferredType = _preferredEmploymentTypeFromSession();
    if (preferredType != null) {
      _selectedEmploymentTypes.add(preferredType);
    }
    _greetingText = '${getPhilippinesGreeting()},';
    _fetchJobs();
    _loadAvatar();
    _jobActionService.addListener(_onJobActionsChanged);
    _loadUnreadNotifications();
    _startLiveUpdates();
  }

  void _ringBell() {
    HapticFeedback.lightImpact();
    _bellRingController.forward(from: 0);
  }

  Future<void> _loadAvatar() async {
    final token = UserSession().token;
    if (token == null || UserSession().avatarPath == null) return;
    final bytes = await ApiService.getAvatarBytes(token);
    if (mounted) setState(() => _avatarBytes = bytes);
  }

  void _onJobActionsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _notificationPollTimer?.cancel();
    _greetingTimer?.cancel();
    _jobActionService.removeListener(_onJobActionsChanged);
    _bellRingController.dispose();
    _searchFocus.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _startLiveUpdates() {
    _notificationPollTimer?.cancel();
    _notificationPollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _loadUnreadNotifications();
    });

    _greetingTimer?.cancel();
    _greetingTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      final next = '${getPhilippinesGreeting()},';
      if (!mounted) return;
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
      final count =
          await ApiService.getJobseekerUnreadNotificationCount(token);
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

  Future<void> _fetchJobs({bool showPageLoader = true}) async {
    if (showPageLoader) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    final token = UserSession().token;
    final result = (token != null && token.isNotEmpty)
        ? await ApiService.getMatchedJobs(token)
        : await ApiService.getJobListings();
    if (!mounted) return;
    if (result['success'] == true) {
      final rawList = result['data'] as List<dynamic>? ?? [];
      setState(() {
        _jobs = rawList
            .map((e) => Job.fromJson(e as Map<String, dynamic>))
            .toList();
        if (showPageLoader) _isLoading = false;
        _jobListSerial++;
      });
    } else {
      if (showPageLoader) {
        setState(() {
          _errorMessage = result['message'] as String? ?? 'Failed to load jobs.';
          _isLoading = false;
        });
      } else {
        CustomToast.show(
          context,
          message: result['message'] as String? ?? 'Failed to refresh jobs.',
          type: ToastType.error,
        );
      }
    }
  }

  Future<void> _applyToJob(Job job) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Application'),
        content: Text(
          'Apply for ${job.title} at ${job.company}?',
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
        message: wasSaved ? 'Job removed from saved.' : 'Job saved successfully.',
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

  List<Job> get _filteredJobs {
    List<Job> jobs = _jobs.where((job) {
      final q = _searchText.toLowerCase();
      final matchesSearch = q.isEmpty ||
          job.title.toLowerCase().contains(q) ||
          job.company.toLowerCase().contains(q) ||
          job.skills.any((s) => s.toLowerCase().contains(q));

      String normType(String s) => s.toLowerCase().replaceAll(' ', '').trim();
      final matchesType = _selectedEmploymentTypes.isEmpty ||
          _selectedEmploymentTypes
              .map(normType)
              .contains(normType(job.employmentType));

      final matchesSkill = _selectedSkillFilters.isEmpty ||
          _selectedSkillFilters.any((selected) =>
              job.skills.any((s) => s.toLowerCase() == selected.toLowerCase()));

      return matchesSearch && matchesType && matchesSkill;
    }).toList();

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
    }
    return jobs;
  }

  bool get _hasActiveFilters =>
      _selectedEmploymentTypes.isNotEmpty || _selectedSkillFilters.isNotEmpty;

  List<String> get _availableSkillFilters {
    final unique = <String>{};
    for (final job in _jobs) {
      for (final skill in job.skills) {
        final s = skill.trim();
        if (s.isNotEmpty) unique.add(s);
      }
    }
    final list = unique.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list.take(30).toList(); // keep filter sheet compact
  }

  List<String> get _visibleSkillFilters {
    final q = _skillFilterQuery.trim().toLowerCase();
    if (q.isEmpty) return _availableSkillFilters;
    return _availableSkillFilters
        .where((s) => s.toLowerCase().contains(q))
        .toList();
  }

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
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
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
            final sheetHeight = (MediaQuery.of(ctx).size.height * 0.78)
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
                      const Text(
                        'Filter Jobs',
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
                    children: _visibleSkillFilters.map((skill) {
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
                              skill,
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
                        onTap: () => Navigator.pop(ctx),
                        child: const Center(
                          child: Text(
                            'Apply Filters',
                            style: TextStyle(
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
                Icon(Icons.cloud_off_rounded, size: 72, color: Colors.grey[300]),
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
                  style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
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
    if (UserSession().avatarPath != null && _avatarBytes == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadAvatar();
      });
    }

    final jobs = _filteredJobs;
    final topPadding = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        top: false,
        left: false,
        right: false,
        child: Column(
          children: [
            // Greeting banner: full-width blue card with mascot peeking from left
          Container(
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
                // Robot mascot – adjust position via left, bottom, width, height
                Positioned(
                  left: -30,
                  bottom: -62.4,
                  child: Image.asset(
                    'assets/empoy_homescreen.png',
                    width: 150,
                    height: 160,
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
                    Stack(
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
                  ],
                  ),
                ),
              ],
            ),
          ),
            // Search section: punchy white card
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Find a job',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Search bar
                  Row(
                    children: [
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _searchFocused
                                  ? const Color(0xFF2563EB)
                                  : Colors.transparent,
                              width: _searchFocused ? 2 : 0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (_searchFocused
                                        ? const Color(0xFF2563EB)
                                        : Colors.black)
                                    .withOpacity(_searchFocused ? 0.12 : 0.04),
                                blurRadius: _searchFocused ? 14 : 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            focusNode: _searchFocus,
                            controller: _searchController,
                            onChanged: (v) => setState(() => _searchText = v),
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF0F172A),
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              icon: Icon(
                                Icons.search_rounded,
                                color: Colors.grey[500],
                                size: 22,
                              ),
                              hintText: 'Search jobs, companies...',
                              hintStyle: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 15,
                              ),
                              suffixIcon: _searchText.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(
                                        Icons.clear_rounded,
                                        color: Colors.grey[500],
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchText = '');
                                      },
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Filter button
                      GestureDetector(
                        onTap: _showFilterSheet,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2563EB).withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              const Icon(
                                Icons.tune_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              if (_hasActiveFilters)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFBBF24),
                                      shape: BoxShape.circle,
                                    ),
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

            const SizedBox(height: 16),

            // Job count + sort
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    '${jobs.length} Jobs Found',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _showSortSheet,
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

            // Job listings
            Expanded(
              child: Stack(
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
                            height: MediaQuery.of(context).size.height * 0.35,
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
                                    'No jobs found',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Try adjusting your search or filters',
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
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: EdgeInsets.only(
                          left: 20,
                          right: 20,
                          bottom: MediaQuery.of(context).padding.bottom + 96,
                        ),
                        itemCount: jobs.length,
                        itemBuilder: (context, index) {
                          final job = jobs[index];
                          final isSaved = _jobActionService.isSaved(job.id);
                          final isApplied = _jobActionService.isApplied(job.id);
                          return _JobCard(
                            key: ValueKey('${job.id}_$_jobListSerial'),
                            job: job,
                            formattedDate: _formatDate(job.postedDate),
                            isSaved: isSaved,
                            isApplied: isApplied,
                            onTap: () => _showJobDetails(context, job),
                            onSave: () => _toggleSaveJob(job),
                            onApply: () => _showJobDetails(context, job),
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
                              );
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
    final formattedDate = widget.formattedDate;
    final isSaved = widget.isSaved;
    final isApplied = widget.isApplied;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top accent bar
              Container(
                height: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      job.companyColor,
                      job.companyColor.withOpacity(0.4),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Hero(
                          tag: 'job_logo_${job.id}',
                          child: Material(
                            color: Colors.transparent,
                            child: CompanyLogoBox(
                              job: job,
                              size: 52,
                              borderRadius: 18,
                              boxShadow: [
                                BoxShadow(
                                  color: job.companyColor.withOpacity(0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Job title and company
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                job.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                job.company,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Match percentage badge (always visible, including 0%)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: job.matchPercentage > 0
                                ? const LinearGradient(
                                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : const LinearGradient(
                                    colors: [Color(0xFF94A3B8), Color(0xFF64748B)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: (job.matchPercentage > 0
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFF64748B))
                                    .withOpacity(0.30),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, size: 13, color: Colors.white),
                              const SizedBox(width: 3),
                              Text(
                                '${job.matchPercentage}%',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Location and type chips
                    Row(
                      children: [
                        _buildChip(Icons.location_on_outlined, job.location),
                        const SizedBox(width: 8),
                        _buildChip(Icons.work_outline_rounded, job.employmentType),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Salary and date row
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB).withOpacity(0.10),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.payments_outlined,
                              size: 15,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${job.salaryMin} - ${job.salaryMax}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            formattedDate,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF94A3B8),
                              fontWeight: FontWeight.w500,
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
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        height: 1.55,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 12),

                    // Skills tags
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: job.skills.map((skill) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withOpacity(0.07),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            skill,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 16),

                    // Action buttons
                    Row(
                      children: [
                        // Save button
                        GestureDetector(
                          onTap: widget.onSave,
                          child: AnimatedScale(
                            scale: _savePulse,
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.elasticOut,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSaved
                                    ? const Color(0xFF2563EB).withOpacity(0.08)
                                    : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSaved
                                      ? const Color(0xFF2563EB)
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isSaved
                                        ? Icons.bookmark_rounded
                                        : Icons.bookmark_outline_rounded,
                                    size: 18,
                                    color: isSaved
                                        ? const Color(0xFF2563EB)
                                        : const Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isSaved ? 'Saved' : 'Save',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isSaved
                                          ? const Color(0xFF2563EB)
                                          : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Apply button
                        Expanded(
                          child: GestureDetector(
                            onTap: isApplied ? null : widget.onApply,
                            child: AnimatedScale(
                              scale: _applyPulse,
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.elasticOut,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isApplied
                                        ? [const Color(0xFF10B981), const Color(0xFF059669)]
                                        : [const Color(0xFF2563EB), const Color(0xFF1D4ED8)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (isApplied
                                              ? const Color(0xFF10B981)
                                              : const Color(0xFF2563EB))
                                          .withOpacity(0.35),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      isApplied ? 'Applied' : 'Apply Now',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(
                                      isApplied
                                          ? Icons.check_circle_outline_rounded
                                          : Icons.arrow_forward_rounded,
                                      size: 17,
                                      color: Colors.white,
                                    ),
                                  ],
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
            ],
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF2563EB)),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
        ],
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

class _MapTabState extends State<MapTab> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  Business? _selectedBusiness;
  List<Business> _allBusinesses = [];
  List<Business> _filteredBusinesses = [];
  bool _isLoading = true;
  String? _errorMessage;
  MapFocusRequest? _pendingMapFocusRequest;

  @override
  void initState() {
    super.initState();
    _loadBusinessesFromApi();
    mapFocusRequestNotifier.addListener(_onMapFocusRequested);
    _onMapFocusRequested();
  }

  Future<void> _loadBusinessesFromApi() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.getMapEmployers();
      if (!mounted) return;
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
              description: locationText.isNotEmpty ? locationText : (emp['tagline']?.toString() ?? ''),
              imageUrl: imageUrl,
              latitude: lat,
              longitude: lng,
              availableJobs: jobs,
            ),
          );
        }

        if (!mounted) return;
        setState(() {
          _allBusinesses = businesses;
          _filteredBusinesses = businesses;
          _isLoading = false;
        });
        _tryApplyPendingMapFocus();
      } else {
        if (!mounted) return;
        setState(() {
          _errorMessage =
              response['message'] as String? ?? 'Failed to load map data.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load map data.';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    mapFocusRequestNotifier.removeListener(_onMapFocusRequested);
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
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
    setState(() {
      if (query.isEmpty) {
        _filteredBusinesses = _allBusinesses;
      } else {
        _filteredBusinesses = _allBusinesses
            .where((b) => b.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _centerOnBusiness(Business business) {
    _mapController.move(
      LatLng(business.latitude, business.longitude),
      16,
    );
    setState(() {
      _selectedBusiness = business;
    });
  }

  void _centerOnUser() {
    _mapController.move(
      const LatLng(userLatitude, userLongitude),
      15,
    );
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Flutter Map with OpenStreetMap tiles (or Mapbox tiles)
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(userLatitude, userLongitude),
              initialZoom: 15,
              onTap: (_, __) {
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

              // Markers Layer
              MarkerLayer(
                markers: [
                  // User location marker
                  Marker(
                    point: const LatLng(userLatitude, userLongitude),
                    width: 50,
                    height: 50,
                    child: Column(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2563EB).withOpacity(0.4),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.person, color: Colors.white, size: 14),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'You',
                            style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Business markers
                  ..._allBusinesses.map((business) {
                    final isSelected = _selectedBusiness?.id == business.id;
                    final color = business.id == 'sm_savemore'
                        ? const Color(0xFFE11D48)
                        : const Color(0xFF7C3AED);
                    final pinSize = isSelected ? 44.0 : 36.0;
                    return Marker(
                      point: LatLng(business.latitude, business.longitude),
                      width: 120,
                      height: 70,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedBusiness = business;
                          });
                        },
                        child: Column(
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
                                    color: Colors.white,
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
                                          errorBuilder: (_, __, ___) => Container(
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
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
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
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
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
              top: MediaQuery.of(context).padding.top + 72,
              left: 16,
              right: 16,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                          hintText: 'Search businesses...',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF2563EB)),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, color: Colors.grey),
                                  onPressed: () {
                                    _searchController.clear();
                                    _onSearch('');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        ),
                      ),
                      if (_searchController.text.isNotEmpty && _filteredBusinesses.isNotEmpty)
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
                              return ListTile(
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: business.imageUrl.isNotEmpty
                                      ? Image.network(
                                          business.imageUrl,
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
                                            width: 40,
                                            height: 40,
                                            color: const Color(0xFF2563EB).withOpacity(0.1),
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
                                            color: const Color(0xFF2563EB).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(10),
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
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(
                                  '${_formatDistance(business.getDistanceFromUser())} away',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
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

                const Spacer(),

                // Business Cards List
                Padding(
                  padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 80),
                  child: SizedBox(
                    height: 160,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredBusinesses.isNotEmpty
                          ? _filteredBusinesses.length
                          : _allBusinesses.length,
                    itemBuilder: (context, index) {
                      final source = _filteredBusinesses.isNotEmpty ? _filteredBusinesses : _allBusinesses;
                      final business = source[index];
                      final distance = business.getDistanceFromUser();
                      final isSelected = _selectedBusiness?.id == business.id;
                      
                      return GestureDetector(
                        onTap: () => _centerOnBusiness(business),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 280,
                          margin: const EdgeInsets.only(right: 12, bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
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
                          child: Column(
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
                                            errorBuilder: (_, __, ___) => Container(
                                              width: 44,
                                              height: 44,
                                              decoration: BoxDecoration(
                                                color: (index % 2 == 0)
                                                    ? const Color(0xFFE11D48).withOpacity(0.1)
                                                    : const Color(0xFF7C3AED).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(12),
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
                                                  ? const Color(0xFFE11D48).withOpacity(0.1)
                                                  : const Color(0xFF7C3AED).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
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
                                      crossAxisAlignment: CrossAxisAlignment.start,
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
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withOpacity(0.1),
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
                                    onPressed: () => _showBusinessDetails(business),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
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
                        ),
                      );
                    },
                  ),
                ),
                ),
              ],
            ),
          ),

          // Center on user button
          Positioned(
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 260,
            child: FloatingActionButton(
              // Unique tag — default FAB Hero tags collide with other routes' FABs
              // (e.g. Notifications "Delete all") during pop transitions, causing morphs.
              heroTag: 'map_tab_center_on_user',
              mini: true,
              backgroundColor: Colors.white,
              onPressed: _centerOnUser,
              child: const Icon(Icons.my_location_rounded, color: Color(0xFF2563EB)),
            ),
          ),

          // Selected business popup
          if (_selectedBusiness != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).padding.bottom + 250,
              child: _BusinessPopupCard(
                business: _selectedBusiness!,
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
                  formatDistance: _formatDistance,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Business Popup Card ──────────────────────────────────────────────────────
class _BusinessPopupCard extends StatelessWidget {
  final Business business;
  final VoidCallback onClose;
  final VoidCallback onViewJobs;
  final String Function(double) formatDistance;

  const _BusinessPopupCard({
    required this.business,
    required this.onClose,
    required this.onViewJobs,
    required this.formatDistance,
  });

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
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFF2563EB)),
                        const SizedBox(width: 4),
                        Text(
                          '${formatDistance(business.getDistanceFromUser())} away',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2563EB),
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
                  child: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.work_rounded, size: 16, color: Color(0xFF10B981)),
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('View Jobs', style: TextStyle(fontWeight: FontWeight.w600)),
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

// ─── Business Detail Sheet ────────────────────────────────────────────────────
class _BusinessDetailSheet extends StatelessWidget {
  final BuildContext hostContext;
  final Business business;
  final String Function(double) formatDistance;

  const _BusinessDetailSheet({
    required this.hostContext,
    required this.business,
    required this.formatDistance,
  });

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
                                      color: const Color(0xFF2563EB).withOpacity(0.1),
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
                                      color: const Color(0xFF2563EB).withOpacity(0.1),
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
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2563EB).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF2563EB)),
                                          const SizedBox(width: 4),
                                          Text(
                                            formatDistance(business.getDistanceFromUser()),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF2563EB),
                                            ),
                                          ),
                                        ],
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
                          const Icon(Icons.work_rounded, size: 22, color: Color(0xFF2563EB)),
                          const SizedBox(width: 10),
                          const Text(
                            'Available Jobs',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                        onTap: () {
                          Navigator.pop(context);
                          Future.microtask(() => _showJobDetails(hostContext, job));
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
                (data['match_score'] as num?)?.toInt() ?? job.matchPercentage,
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Application'),
        content: Text(
          'Apply for ${job.title} at ${job.company}?',
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
  final VoidCallback onTap;

  const _JobListItem({required this.job, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                        '${job.salaryMin} - ${job.salaryMax} • ${job.employmentType}',
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

class _NotificationsTabState extends State<NotificationsTab> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _notifications = [];
  final _jobActionService = JobActionService();
  Timer? _pollTimer;
  bool _isPolling = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _loadNotifications(showLoader: false);
    });
    _jobActionService.addListener(_onJobActionsChanged);
  }

  void _onJobActionsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _jobActionService.removeListener(_onJobActionsChanged);
    super.dispose();
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
        Uri.parse('${ApiService.baseUrl}/jobseeker/notifications/mark-all-read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      setState(() {
        _notifications = _notifications
            .map((n) => {...n, 'read_at': n['read_at'] ?? DateTime.now().toIso8601String()})
            .toList();
      });
    } catch (_) {}
  }

  bool get _allRead =>
      _notifications.isNotEmpty &&
      _notifications.every((n) => n['read_at'] != null);

  Future<void> _applyToJob(Job job) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Application'),
        content: Text(
          'Apply for ${job.title} at ${job.company}?',
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
        message: wasSaved ? 'Job removed from saved.' : 'Job saved successfully.',
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

  Future<void> _openNotification(int index) async {
    final token = UserSession().token;
    if (token == null || token.isEmpty) return;
    final n = _notifications[index];
    final id = n['id'];
    if (id == null) return;

    final result = await ApiService.getJobseekerNotification(
      token: token,
      id: id is int ? id : int.tryParse(id.toString()) ?? 0,
    );
    if (!mounted) return;
    if (result['success'] == true) {
      final data = result['data'] as Map<String, dynamic>? ?? {};
      setState(() {
        _notifications[index] = {
          ..._notifications[index],
          'read_at': data['read_at'] ?? DateTime.now().toIso8601String(),
        };
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
    final jobId = rawJobId is int ? rawJobId : int.tryParse(rawJobId?.toString() ?? '');

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
      onViewMap: widget.onOpenMapRequested != null ? () {
        Navigator.of(context).pop();
        widget.onOpenMapRequested!(MapFocusRequest.fromJob(job));
      } : null,
    );
  }

  Future<void> _deleteNotification(int index) async {
    final n = _notifications[index];
    final notif = n['notification'] as Map<String, dynamic>? ?? {};
    if (notif['type'] == 'satisfaction_survey') {
      // Prevents deletion via manual swipe if UI somehow allows it
      return;
    }

    final token = UserSession().token;
    if (token == null || token.isEmpty) {
      setState(() => _notifications.removeAt(index));
      return;
    }
    final notifId = n['id'];
    setState(() => _notifications.removeAt(index));
    if (notifId == null) return;
    await ApiService.deleteJobseekerNotification(
      token: token,
      id: notifId is int ? notifId : int.tryParse(notifId.toString()) ?? 0,
    );
  }

  Future<void> _deleteAllRead() async {
    final token = UserSession().token;
    if (token == null || token.isEmpty) return;
    
    // Filter to show only read notifications that are NOT surveys
    final toDelete = _notifications.where((n) {
      final notif = n['notification'] as Map<String, dynamic>? ?? {};
      return n['read_at'] != null && notif['type'] != 'satisfaction_survey';
    }).toList();

    if (toDelete.isEmpty) return;

    final ok = await ApiService.deleteAllJobseekerNotifications(token);
    if (!mounted) return;
    if (ok) {
      setState(() {
        _notifications.clear();
      });
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

  Future<void> _showRatingDialog(int index, Map<String, dynamic> n) async {
    final token = UserSession().token;
    if (token == null || token.isEmpty) return;
    
    // Mark as read first if not read
    if (n['read_at'] == null) {
      _openNotification(index);
    }

    int selectedRating = 0;
    bool isSubmitting = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Rate Application Process'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'How was the processing of your application? Rate your experience from 1 to 5.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      return IconButton(
                        icon: Icon(
                          i < selectedRating ? Icons.star_rounded : Icons.star_border_rounded,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            selectedRating = i + 1;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    selectedRating == 1 ? 'Very Dissatisfied' :
                    selectedRating == 2 ? 'Dissatisfied' :
                    selectedRating == 3 ? 'Neutral' :
                    selectedRating == 4 ? 'Satisfied' :
                    selectedRating == 5 ? 'Very Satisfied' : 'Select a rating',
                    style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: (selectedRating == 0 || isSubmitting) ? null : () async {
                    setDialogState(() => isSubmitting = true);
                    final result = await ApiService.submitSatisfactionRating(token, selectedRating);
                    if (!mounted) return;
                    setDialogState(() => isSubmitting = false);
                    if (result['success'] == true) {
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Thank you for your rating!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      _deleteNotification(index); // Remove after rating
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(result['message'] ?? 'Failed to submit rating.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Submit'),
                ),
              ],
            );
          },
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _notifications.isEmpty ? null : _markAllRead,
            child: const Text(
              'Mark all read',
              style: TextStyle(
                color: Color(0xFF2563EB),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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
              : _notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB).withOpacity(0.1),
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
                            padding: const EdgeInsets.symmetric(horizontal: 40),
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
                    )
                  : RefreshIndicator(
                      color: const Color(0xFF2563EB),
                      onRefresh: _loadNotifications,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        itemCount: _notifications.length,
                          itemBuilder: (context, index) {
                            final n = _notifications[index];
                            final notif = n['notification'] as Map<String, dynamic>? ?? {};
                            final type = notif['type'] as String?;
                            final subject = notif['subject'] as String? ?? 'Notification';
                            final message = notif['message'] as String? ?? '';
                            final createdAt = DateTime.tryParse(
                                  (notif['created_at'] as String? ?? ''),
                                ) ??
                                DateTime.now();
                            final isRead = n['read_at'] != null;
                            final id = n['id'] ?? index;

                            // Shared time/date formatting (using PH time cluster)
                            final nowPh = nowInPhilippines();
                            // If backend sends UTC, parse and convert to PH
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

                            const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                            final dateFormatted = '${monthNames[createdAtPh.month - 1]}/${createdAtPh.day.toString().padLeft(2, '0')}/${createdAtPh.year}';

                            // ── Invitation card ───────────────────────────
                            if (type == 'invitation') {
                              final jobListing = notif['job_listing'] as Map<String, dynamic>?;
                              final jobTitle = jobListing?['title'] as String? ?? subject;
                              final jobType = jobListing?['type'] as String? ?? '';
                              final jobLocation = jobListing?['location'] as String? ?? '';
                              final companyName = (jobListing?['employer'] as Map<String, dynamic>?)?['company_name'] as String? ?? 'An employer';

                              return Dismissible(
                                key: ValueKey('notif_$id'),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: const Icon(Icons.delete_rounded, color: Colors.white),
                                ),
                                onDismissed: (_) => _deleteNotification(index),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Material(
                                      color: Colors.white,
                                      child: InkWell(
                                        onTap: () => _openNotification(index),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            border: Border(
                                              left: BorderSide(
                                                color: isRead ? Colors.transparent : const Color(0xFF2563EB),
                                                width: 4,
                                              ),
                                              top: BorderSide(color: isRead ? const Color(0xFFE2E8F0) : const Color(0xFF2563EB).withOpacity(0.3)),
                                              right: BorderSide(color: isRead ? const Color(0xFFE2E8F0) : const Color(0xFF2563EB).withOpacity(0.3)),
                                              bottom: BorderSide(color: isRead ? const Color(0xFFE2E8F0) : const Color(0xFF2563EB).withOpacity(0.3)),
                                            ),
                                          ),
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              // Header row
                                              Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Container(
                                                    width: 40,
                                                    height: 40,
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFF2563EB).withOpacity(0.1),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(
                                                      Icons.event_seat_rounded,
                                                      color: Color(0xFF2563EB),
                                                      size: 20,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          subject,
                                                          style: TextStyle(
                                                            fontSize: 15,
                                                            fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                                                            color: const Color(0xFF0F172A),
                                                          ),
                                                        ),
                                                        const SizedBox(height: 2),
                                                        Text(
                                                          '$timeAgo • $dateFormatted',
                                                          style: const TextStyle(
                                                            fontSize: 12,
                                                            color: Color(0xFF94A3B8),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  if (!isRead)
                                                    Container(
                                                      margin: const EdgeInsets.only(top: 8, right: 4),
                                                      width: 10,
                                                      height: 10,
                                                      decoration: const BoxDecoration(
                                                        color: Color(0xFF2563EB),
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 16),

                                              // Company + job title box
                                              Container(
                                                width: double.infinity,
                                                padding: const EdgeInsets.all(14),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFF8FAFF),
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      companyName,
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w600,
                                                        color: Color(0xFF2563EB),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      jobTitle,
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w700,
                                                        color: Color(0xFF0F172A),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 10),
                                                    Wrap(
                                                      spacing: 8,
                                                      runSpacing: 6,
                                                      children: [
                                                        if (jobLocation.isNotEmpty)
                                                          _buildChip(Icons.location_on_outlined, jobLocation),
                                                        if (jobType.isNotEmpty)
                                                          _buildChip(Icons.work_outline_rounded, jobType),
                                                        if ((jobListing?['salary_range'] as String? ?? '').isNotEmpty)
                                                          _buildChip(Icons.payments_outlined, jobListing!['salary_range']),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 16),

                                              // View Job Details button
                                              SizedBox(
                                                width: double.infinity,
                                                height: 44,
                                                child: OutlinedButton.icon(
                                                  onPressed: () => _openInvitationJob(n),
                                                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                                                  label: const Text('View Job Details'),
                                                  style: OutlinedButton.styleFrom(
                                                    foregroundColor: const Color(0xFF2563EB),
                                                    side: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    textStyle: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w700,
                                                      letterSpacing: 0.3,
                                                    ),
                                                  ),
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
                            } else if (type == 'satisfaction_survey') {
                              return Dismissible(
                                key: ValueKey('notif_$id'),
                                direction: DismissDirection.none,
                                background: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: const Icon(Icons.delete_rounded, color: Colors.white),
                                ),
                                onDismissed: (_) => _deleteNotification(index),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Material(
                                      color: Colors.white,
                                      child: InkWell(
                                        onTap: () => _openNotification(index),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            border: Border(
                                              left: BorderSide(
                                                color: isRead ? Colors.transparent : const Color(0xFF10B981), // Emerald
                                                width: 4,
                                              ),
                                              top: BorderSide(color: isRead ? const Color(0xFFE2E8F0) : const Color(0xFF10B981).withOpacity(0.3)),
                                              right: BorderSide(color: isRead ? const Color(0xFFE2E8F0) : const Color(0xFF10B981).withOpacity(0.3)),
                                              bottom: BorderSide(color: isRead ? const Color(0xFFE2E8F0) : const Color(0xFF10B981).withOpacity(0.3)),
                                            ),
                                          ),
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Container(
                                                    width: 40,
                                                    height: 40,
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFF10B981).withOpacity(0.1),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(
                                                      Icons.rate_review_rounded,
                                                      color: Color(0xFF10B981),
                                                      size: 20,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          subject,
                                                          style: TextStyle(
                                                            fontSize: 15,
                                                            fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                                                            color: const Color(0xFF0F172A),
                                                          ),
                                                        ),
                                                        const SizedBox(height: 2),
                                                        Text(
                                                          '$timeAgo • $dateFormatted',
                                                          style: const TextStyle(
                                                            fontSize: 12,
                                                            color: Color(0xFF94A3B8),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  if (!isRead)
                                                    Container(
                                                      margin: const EdgeInsets.only(top: 8, right: 4),
                                                      width: 10,
                                                      height: 10,
                                                      decoration: const BoxDecoration(
                                                        color: Color(0xFF10B981),
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 16),
                                              Container(
                                                width: double.infinity,
                                                padding: const EdgeInsets.all(14),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFF0FDF4),
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                                                ),
                                                child: Text(
                                                  message,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Color(0xFF334155),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              SizedBox(
                                                width: double.infinity,
                                                height: 44,
                                                child: FilledButton.icon(
                                                  onPressed: () => _showRatingDialog(index, n),
                                                  icon: const Icon(Icons.star_half_rounded, size: 18),
                                                  label: const Text('Rate Application Process'),
                                                  style: FilledButton.styleFrom(
                                                    backgroundColor: const Color(0xFF10B981),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    textStyle: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
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
                            }

                            // Determine asset and color for generic card based on status/type
                            String? statusAsset;
                            Color statusColor = const Color(0xFF2563EB);

                            if (type != null) {
                              final t = type.toLowerCase();
                              final s = subject.toLowerCase();
                              final m = message.toLowerCase();

                              if (t.contains('shortlisted') || s.contains('shortlisted') || m.contains('shortlisted')) {
                                statusAsset = 'assets/empoy_notif_shortlisted.png';
                                statusColor = const Color(0xFFF59E0B); // Amber
                              } else if (t.contains('interview') || s.contains('interview') || m.contains('interview')) {
                                statusAsset = 'assets/empoy_notif_interview.png';
                                statusColor = const Color(0xFF8B5CF6); // Violet
                              } else if (t.contains('hired') || s.contains('hired') || m.contains('hired')) {
                                statusAsset = 'assets/empoy_notif_hired.png';
                                statusColor = const Color(0xFF10B981); // Emerald
                              } else if (t.contains('rejected') || s.contains('rejected') || m.contains('rejected') || s.contains('not selected')) {
                                statusAsset = 'assets/empoy_notif_rejected.png';
                                statusColor = const Color(0xFFEF4444); // Red
                              } else if (t.contains('reviewing') || s.contains('received') || m.contains('received')) {
                                statusAsset = 'assets/empoy_notif_application_received.png';
                                statusColor = const Color(0xFF2563EB); // Blue
                              }
                            } else {
                              // Fallback for null type based on text
                              final s = subject.toLowerCase();
                              final m = message.toLowerCase();
                              if (s.contains('shortlisted') || m.contains('shortlisted')) {
                                statusAsset = 'assets/empoy_notif_shortlisted.png';
                                statusColor = const Color(0xFFF59E0B);
                              } else if (s.contains('interview') || m.contains('interview')) {
                                statusAsset = 'assets/empoy_notif_interview.png';
                                statusColor = const Color(0xFF8B5CF6);
                              } else if (s.contains('hired') || m.contains('hired')) {
                                statusAsset = 'assets/empoy_notif_hired.png';
                                statusColor = const Color(0xFF10B981);
                              } else if (s.contains('rejected') || m.contains('rejected') || s.contains('not selected')) {
                                statusAsset = 'assets/empoy_notif_rejected.png';
                                statusColor = const Color(0xFFEF4444);
                              } else if (s.contains('received') || m.contains('received')) {
                                statusAsset = 'assets/empoy_notif_application_received.png';
                                statusColor = const Color(0xFF2563EB);
                              }
                            }

                            // ── Generic notification card ─────────────────
                            return Dismissible(
                              key: ValueKey('notif_$id'),
                              direction: type == 'satisfaction_survey' ? DismissDirection.none : DismissDirection.endToStart,
                              background: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: const Icon(Icons.delete_rounded, color: Colors.white),
                              ),
                              onDismissed: (_) => _deleteNotification(index),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isRead
                                        ? const Color(0xFFE2E8F0)
                                        : statusColor.withOpacity(0.5),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  onTap: () => _openNotification(index),
                                  leading: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(4),
                                    child: statusAsset != null
                                        ? Image.asset(
                                            statusAsset,
                                            fit: BoxFit.contain,
                                          )
                                        : Icon(
                                            Icons.notifications_rounded,
                                            color: statusColor,
                                            size: 24,
                                          ),
                                  ),
                                  title: Text(
                                    subject,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      RichText(
                                        text: TextSpan(
                                          children: _parseMessageWithBold(message),
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF64748B),
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '$timeAgo • $dateFormatted',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: !isRead
                                      ? Container(
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            color: statusColor,
                                            shape: BoxShape.circle,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                            );
                          },
                      ),
                    ),
      floatingActionButton: _notifications.isEmpty
          ? null
          : FloatingActionButton.extended(
              // Unique tag — avoids Hero flight to Map tab's locate FAB (IndexedStack keeps Map mounted).
              heroTag: 'notifications_delete_all',
              onPressed: _allRead ? _deleteAllRead : null,
              backgroundColor: _allRead
                  ? const Color(0xFFEF4444)
                  : const Color(0xFFCBD5E1),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.delete_forever_rounded),
              label: const Text('Delete all'),
            ),
    );
  }
}

