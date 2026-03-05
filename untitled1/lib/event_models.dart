// ─── Event Model ───────────────────────────────────────────────────────────────
class PesoEvent {
  final int id;
  final String title;
  final String description;
  final String location;
  final DateTime eventDate;
  final String? eventTime;
  final String eventType; // job_fair, seminar, career_event
  final String? organizer;
  final String? imageUrl;

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
  });

  factory PesoEvent.fromJson(Map<String, dynamic> json) {
    return PesoEvent(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      location: json['location'] as String,
      eventDate: DateTime.tryParse(json['event_date'] as String? ?? '') ?? DateTime.now(),
      eventTime: json['event_time'] as String?,
      eventType: json['event_type'] as String? ?? 'job_fair',
      organizer: json['organizer'] as String?,
      imageUrl: json['image_url'] as String?,
    );
  }

  String get typeLabel {
    switch (eventType) {
      case 'job_fair':
        return 'Job Fair';
      case 'seminar':
        return 'Seminar';
      case 'career_event':
        return 'Career Event';
      default:
        return eventType;
    }
  }

  String get formattedDate {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[eventDate.month - 1]} ${eventDate.day}, ${eventDate.year}';
  }
}
