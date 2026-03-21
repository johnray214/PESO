// ─── Event Model (API: /public/events, admin events) ─────────────────────────
class PesoEvent {
  final int id;
  final String title;
  final String description;
  final String location;
  final DateTime eventDate;
  final String? eventTime;
  final String eventType; // job_fair, seminar, career_event (mapped from API type)
  final String? organizer;
  final String? imageUrl;
  final int participantsCount;
  final int? maxParticipants;
  final bool isRegistered;

  const PesoEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.eventDate,
    this.eventTime,
    this.eventType = 'job_fair',
    this.organizer,
    this.imageUrl,
    this.participantsCount = 0,
    this.maxParticipants,
    this.isRegistered = false,
  });

  PesoEvent copyWith({
    int? id,
    String? title,
    String? description,
    String? location,
    DateTime? eventDate,
    String? eventTime,
    String? eventType,
    String? organizer,
    String? imageUrl,
    int? participantsCount,
    int? maxParticipants,
    bool? isRegistered,
  }) {
    return PesoEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      eventDate: eventDate ?? this.eventDate,
      eventTime: eventTime ?? this.eventTime,
      eventType: eventType ?? this.eventType,
      organizer: organizer ?? this.organizer,
      imageUrl: imageUrl ?? this.imageUrl,
      participantsCount: participantsCount ?? this.participantsCount,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      isRegistered: isRegistered ?? this.isRegistered,
    );
  }

  factory PesoEvent.fromJson(Map<String, dynamic> json, {bool isRegistered = false}) {
    final id = (json['id'] as num).toInt();
    final title = (json['title'] as String?)?.trim() ?? 'Event';
    final description = (json['description'] as String?)?.trim() ?? '';
    final location = (json['location'] as String?)?.trim() ?? '';

    final rawDate = json['event_date'];
    DateTime eventDate = DateTime.now();
    if (rawDate is String) {
      eventDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    }

    final typeRaw = (json['type'] as String?)?.trim() ?? 'Job Fair';
    final eventType = _slugifyEventType(typeRaw);

    String? eventTime = _formatTimeRange(json['start_time'], json['end_time']);
    if (eventTime == null && json['event_time'] != null) {
      eventTime = json['event_time'] as String?;
    }

    final organizer = json['organizer'] as String?;
    final participantsCount = (json['participants_count'] as num?)?.toInt() ?? 0;
    final maxParticipants = (json['max_participants'] as num?)?.toInt();

    return PesoEvent(
      id: id,
      title: title,
      description: description,
      location: location,
      eventDate: eventDate,
      eventTime: eventTime,
      eventType: eventType,
      organizer: organizer,
      imageUrl: json['image_url'] as String?,
      participantsCount: participantsCount,
      maxParticipants: maxParticipants,
      isRegistered: isRegistered,
    );
  }

  static String _slugifyEventType(String t) {
    final lower = t.toLowerCase();
    if (lower.contains('seminar')) return 'seminar';
    if (lower.contains('training')) return 'training'; // distinct label in typeLabel
    if (lower.contains('workshop')) return 'career_event';
    if (lower.contains('livelihood')) return 'career_event';
    return 'job_fair';
  }

  static String? _formatTimeRange(dynamic start, dynamic end) {
    if (start == null) return null;
    var s = start.toString();
    if (s.length >= 8) s = s.substring(0, 5);
    if (end == null || end.toString().isEmpty) return s;
    var e = end.toString();
    if (e.length >= 8) e = e.substring(0, 5);
    return '$s – $e';
  }

  String get typeLabel {
    switch (eventType) {
      case 'seminar':
        return 'Seminar';
      case 'training':
        return 'Training';
      case 'career_event':
        return 'Workshop / Program';
      case 'job_fair':
        return 'Job Fair';
      default:
        return eventType;
    }
  }

  String get formattedDate {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[eventDate.month - 1]} ${eventDate.day}, ${eventDate.year}';
  }

  /// Stacked date badge (day / MON / year) — same month abbrev as formattedDate.
  String get dateBadgeDay => eventDate.day.toString().padLeft(2, '0');

  String get dateBadgeMonthUpper {
    final months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return months[eventDate.month - 1];
  }

  String get dateBadgeYear => '${eventDate.year}';

  String get slotsLabel {
    if (maxParticipants == null) {
      return '$participantsCount registered';
    }
    return '$participantsCount / $maxParticipants registered';
  }

  bool get isFull =>
      maxParticipants != null && participantsCount >= maxParticipants!;
}
