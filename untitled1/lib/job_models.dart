import 'package:flutter/material.dart';
import 'api_service.dart';
import 'job_action_service.dart';
import 'user_session.dart';

// ─── Job Model ────────────────────────────────────────────────────────────────
class Job {
  final String id;
  final String title;
  final String company;
  final String companyInitial;
  final Color companyColor;
  /// Relative storage path from employer profile (`employers.photo`), if any.
  final String? companyPhotoPath;
  final String location;
  final double? latitude;
  final double? longitude;
  final String description;
  final List<String> requirements;
  final List<String> skills;
  final String experienceLevel;
  final String salaryMin;
  final String salaryMax;
  final String employmentType;
  final String? category;
  final DateTime postedDate;
  final int? slots;
  final DateTime? deadline;
  final int matchPercentage;
  final bool isUrgent;

  const Job({
    required this.id,
    required this.title,
    required this.company,
    required this.companyInitial,
    required this.companyColor,
    this.companyPhotoPath,
    required this.location,
    this.latitude,
    this.longitude,
    required this.description,
    required this.requirements,
    required this.skills,
    required this.experienceLevel,
    required this.salaryMin,
    required this.salaryMax,
    required this.employmentType,
    this.category,
    required this.postedDate,
    this.slots,
    this.deadline,
    this.matchPercentage = 0,
    this.isUrgent = false,
  });

  String get salaryDisplay {
    final min = salaryMin.trim();
    final max = salaryMax.trim();
    if (min.isEmpty && max.isEmpty) return 'Not specified';
    if (min.isEmpty) return max;
    if (max.isEmpty || min == max) return min;
    return '$min - $max';
  }

  factory Job.fromJson(Map<String, dynamic> json) {
    // Supports both old app JSON and current Laravel JobListing shape.
    // Laravel returns `employer: { company_name }`, `skills: [{skill}]`,
    // and `salary_range` rather than `salary_min/max`.
    Color color;
    final colorHex = json['company_color'] as String?;
    if (colorHex != null && colorHex.isNotEmpty) {
      try {
        color = Color(int.parse('0xFF$colorHex'));
      } catch (_) {
        color = const Color(0xFF3B82F6);
      }
    } else {
      color = const Color(0xFF3B82F6);
    }

    final rawEmployer = json['employer'];
    Map<String, dynamic>? employerMap;
    if (rawEmployer is Map) {
      employerMap = Map<String, dynamic>.from(rawEmployer);
    }
    final companyName = (json['company'] as String?) ??
        (employerMap?['company_name'] as String?) ??
        'Employer';

    // Prefer API-computed absolute URL; then nested employer.photo / photo_url.
    String? companyPhotoPath;
    final topPhoto =
        json['employer_photo_url'] ?? json['employerPhotoUrl'];
    if (topPhoto != null && topPhoto.toString().trim().isNotEmpty) {
      companyPhotoPath = topPhoto.toString().trim();
    } else if (employerMap != null) {
      final p = employerMap['photo'] ?? employerMap['photo_url'];
      if (p != null && p.toString().trim().isNotEmpty) {
        companyPhotoPath = p.toString().trim();
      }
    }

    final companyInitial = (json['company_initial'] as String?) ??
        (companyName.trim().isNotEmpty ? companyName.trim()[0].toUpperCase() : '?');

    final salaryRange = (json['salary_range'] as String?)?.trim();
    String salaryMin = (json['salary_min'] as String?) ?? '';
    String salaryMax = (json['salary_max'] as String?) ?? '';
    if ((salaryMin.isEmpty || salaryMax.isEmpty) && salaryRange != null && salaryRange.isNotEmpty) {
      final parts = salaryRange.split(RegExp(r'\s*-\s*'));
      if (parts.length >= 2) {
        salaryMin = parts[0].trim();
        salaryMax = parts[1].trim();
      } else {
        salaryMin = salaryRange;
        salaryMax = salaryRange;
      }
    }

    final latValue = json['latitude'];
    final lonValue = json['longitude'];
    final double? latitude = switch (latValue) {
      final num v => v.toDouble(),
      final String v => double.tryParse(v),
      _ => null,
    };
    final double? longitude = switch (lonValue) {
      final num v => v.toDouble(),
      final String v => double.tryParse(v),
      _ => null,
    };

    final rawSkills = json['skills'];
    final skills = (rawSkills is List ? rawSkills : const <dynamic>[])
        .map((e) {
          if (e is Map<String, dynamic>) return e['skill']?.toString() ?? '';
          return e.toString();
        })
        .where((s) => s.trim().isNotEmpty)
        .toList();

    final postedRaw = (json['posted_date'] as String?) ?? (json['created_at'] as String?) ?? '';
    final postedDate = DateTime.tryParse(postedRaw) ?? DateTime.now();
    final deadlineRaw = json['deadline'] as String?;
    final deadline = deadlineRaw != null ? DateTime.tryParse(deadlineRaw) : null;

    final isUrgent = json['is_urgent'] == true ||
        json['is_urgent'] == 1 ||
        json['urgent'] == true ||
        (json['is_urgent'] is String && (json['is_urgent'] == '1' || json['is_urgent'].toString().toLowerCase() == 'true'));

    return Job(
      id: json['id'].toString(),
      title: (json['title'] as String?) ?? '',
      company: companyName,
      companyInitial: companyInitial,
      companyColor: color,
      companyPhotoPath: companyPhotoPath,
      location: (json['location'] as String?) ?? '',
      latitude: latitude,
      longitude: longitude,
      description: (json['description'] as String?) ?? '',
      requirements: (json['requirements'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      skills: skills,
      experienceLevel: (json['experience_level'] as String?) ?? '',
      salaryMin: salaryMin,
      salaryMax: salaryMax,
      employmentType: (json['employment_type'] as String?) ??
          (json['type'] as String?) ??
          'full-time',
      category: json['category'] as String?,
      postedDate: postedDate,
      slots: (json['slots'] as num?)?.toInt() ?? (json['number_of_slots'] as num?)?.toInt(),
      deadline: deadline,
      matchPercentage: (json['match_percentage'] as num?)?.toInt() ?? 0,
      isUrgent: isUrgent,
    );
  }
}

/// e.g. Jan 15, 2026 (for job detail / cards)
String formatJobDeadlineDate(DateTime? d) {
  if (d == null) return 'Not specified';
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${months[d.month - 1]} ${d.day}, ${d.year}';
}

/// Company avatar: employer photo from API or initial on brand color.
class CompanyLogoBox extends StatelessWidget {
  final Job job;
  final double size;
  /// When null, uses a full circle ([size] / 2).
  final double? borderRadius;
  final List<BoxShadow>? boxShadow;

  const CompanyLogoBox({
    super.key,
    required this.job,
    this.size = 52,
    this.borderRadius,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final path = job.companyPhotoPath;
    final url = ApiService.storageOrAbsoluteUrl(path) ?? '';
    final radius = borderRadius ?? size / 2;
    final hasLogo = url.isNotEmpty;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        // When we have an employer logo, use a solid background so that
        // transparent PNGs don't show the placeholder gradient behind them.
        color: hasLogo ? Colors.white : null,
        gradient: hasLogo
            ? null
            : LinearGradient(
                colors: [job.companyColor, job.companyColor.withOpacity(0.75)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: job.companyColor.withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
      ),
      clipBehavior: Clip.antiAlias,
      child: hasLogo
          ? Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Center(
                child: Text(
                  job.companyInitial,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size * 0.42,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: SizedBox(
                    width: size * 0.35,
                    height: size * 0.35,
                    child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
                );
              },
            )
          : Center(
              child: Text(
                job.companyInitial,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.42,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
    );
  }
}

// ─── Sample Job Data ──────────────────────────────────────────────────────────
final List<Job> sampleJobs = [
  Job(
    id: '1',
    title: 'Software Developer',
    company: 'Tech Solutions Inc.',
    companyInitial: 'T',
    companyColor: const Color(0xFF3B82F6),
    location: 'Santiago City, Isabela',
    description:
        'Looking for a skilled software developer with experience in mobile and web development. You will be working on cutting-edge projects and collaborating with a talented team.',
    requirements: [
      'Bachelor\'s degree in Computer Science or related field',
      'Proficiency in JavaScript, Python, or Java',
      'Experience with web frameworks (React, Angular, or Vue)',
      'Strong problem-solving skills',
      'Good communication skills',
    ],
    skills: ['Flutter', 'Laravel', 'MySQL'],
    experienceLevel: '2-3 years experience',
    salaryMin: '₱25,000',
    salaryMax: '₱35,000',
    employmentType: 'Full-time',
    postedDate: DateTime(2026, 3, 1),
    matchPercentage: 95,
    isUrgent: true,
  ),
  Job(
    id: '2',
    title: 'Administrative Assistant',
    company: 'City Government',
    companyInitial: 'C',
    companyColor: const Color(0xFF10B981),
    location: 'Santiago City, Isabela',
    description:
        'The City Government is seeking a reliable Administrative Assistant to provide support to our department. Duties include managing schedules, handling correspondence, and maintaining office records.',
    requirements: [
      'Bachelor\'s degree in any field',
      'Proficient in MS Office applications',
      'Excellent organizational skills',
      'Strong written and verbal communication',
      'Attention to detail',
    ],
    skills: ['MS Office', 'Communication', 'Filing'],
    experienceLevel: '1-2 years experience',
    salaryMin: '₱18,000',
    salaryMax: '₱22,000',
    employmentType: 'Full-time',
    postedDate: DateTime(2026, 2, 28),
    matchPercentage: 82,
    isUrgent: false,
  ),
  Job(
    id: '3',
    title: 'Sales Representative',
    company: 'PhilMart Trading',
    companyInitial: 'P',
    companyColor: const Color(0xFFF59E0B),
    location: 'Santiago City, Isabela',
    description:
        'Join our dynamic sales team! We are looking for motivated individuals to promote and sell our products. Commission-based incentives available for top performers.',
    requirements: [
      'High school diploma or equivalent',
      'Excellent communication and interpersonal skills',
      'Self-motivated and goal-oriented',
      'Willing to do field work',
      'With valid driver\'s license (preferred)',
    ],
    skills: ['Sales', 'Negotiation', 'Customer Service'],
    experienceLevel: 'Entry level',
    salaryMin: '₱15,000',
    salaryMax: '₱20,000',
    employmentType: 'Full-time',
    postedDate: DateTime(2026, 3, 2),
    matchPercentage: 78,
    isUrgent: true,
  ),
  Job(
    id: '4',
    title: 'Registered Nurse',
    company: 'Santiago Medical Center',
    companyInitial: 'S',
    companyColor: const Color(0xFFEF4444),
    location: 'Santiago City, Isabela',
    description:
        'We are hiring compassionate and skilled Registered Nurses to provide quality patient care. Must be willing to work in shifts and handle emergency situations.',
    requirements: [
      'Bachelor\'s degree in Nursing',
      'Valid PRC License',
      'BLS/ACLS certification',
      'Good interpersonal skills',
      'Willing to work on shifting schedule',
    ],
    skills: ['Patient Care', 'BLS', 'Medical Records'],
    experienceLevel: '1 year hospital experience',
    salaryMin: '₱20,000',
    salaryMax: '₱28,000',
    employmentType: 'Full-time',
    postedDate: DateTime(2026, 2, 26),
    matchPercentage: 88,
    isUrgent: false,
  ),
  Job(
    id: '5',
    title: 'Warehouse Staff',
    company: 'Logistics Hub Corp.',
    companyInitial: 'L',
    companyColor: const Color(0xFF8B5CF6),
    location: 'Santiago City, Isabela',
    description:
        'Looking for hardworking warehouse staff to handle inventory management, packing, and shipping operations. Physical fitness required.',
    requirements: [
      'High school diploma',
      'Physically fit',
      'Can lift heavy objects',
      'Basic computer literacy',
      'Team player',
    ],
    skills: ['Inventory', 'Logistics', 'Forklift'],
    experienceLevel: 'No experience required',
    salaryMin: '₱12,000',
    salaryMax: '₱15,000',
    employmentType: 'Full-time',
    postedDate: DateTime(2026, 3, 3),
    matchPercentage: 70,
    isUrgent: true,
  ),
  Job(
    id: '6',
    title: 'Cashier',
    company: 'SM SaveMore Market',
    companyInitial: 'S',
    companyColor: const Color(0xFF0EA5E9),
    location: 'Santiago City, Isabela',
    description:
        'We are looking for a friendly and efficient Cashier to join our team. You will handle customer transactions, maintain accurate cash counts, and provide excellent service.',
    requirements: [
      'High school diploma or equivalent',
      'Basic math proficiency',
      'Customer service skills',
      'Honest and trustworthy',
      'Can work in shifting schedule',
    ],
    skills: ['Cashiering', 'Customer Service', 'POS System'],
    experienceLevel: 'No experience required',
    salaryMin: '₱12,000',
    salaryMax: '₱15,000',
    employmentType: 'Full-time',
    postedDate: DateTime(2026, 2, 25),
    matchPercentage: 74,
    isUrgent: false,
  ),
  Job(
    id: '7',
    title: 'Sales Associate',
    company: 'Robinsons Department Store',
    companyInitial: 'R',
    companyColor: const Color(0xFFEC4899),
    location: 'Santiago City, Isabela',
    description:
        'Join our retail team as a Sales Associate! You will assist customers in finding products, manage merchandise displays, and process transactions with a smile.',
    requirements: [
      'High school diploma or equivalent',
      'Good communication skills',
      'Presentable and customer-oriented',
      'Willing to work on weekends and holidays',
      'Energetic and team player',
    ],
    skills: ['Retail Sales', 'Customer Service', 'Merchandising'],
    experienceLevel: 'Entry level',
    salaryMin: '₱13,000',
    salaryMax: '₱16,000',
    employmentType: 'Full-time',
    postedDate: DateTime(2026, 2, 20),
    matchPercentage: 68,
    isUrgent: false,
  ),
];

// ─── Show Job Detail Sheet Helper ─────────────────────────────────────────────
void showJobDetailSheet(
  BuildContext context,
  Job job, {
  Widget? headerBanner,
  bool isApplied = false,
  VoidCallback? onApply,
  bool isSaved = false,
  VoidCallback? onSave,
  VoidCallback? onViewMap,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return GestureDetector(
        onTap: () => Navigator.of(ctx).pop(),
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTap: () {},
              child: JobDetailSheet(
                job: job,
                headerBanner: headerBanner,
                isApplied: isApplied,
                onApply: onApply,
                isSaved: isSaved,
                onSave: onSave,
                onViewMap: onViewMap,
              ),
            ),
          ),
        ),
      );
    },
  );
}

// ─── Job Detail Sheet ─────────────────────────────────────────────────────────
class JobDetailSheet extends StatefulWidget {
  final Job job;
  final Widget? headerBanner;
  final bool isApplied;
  final VoidCallback? onApply;
  final bool isSaved;
  final VoidCallback? onSave;
  final VoidCallback? onViewMap;

  const JobDetailSheet({
    super.key,
    required this.job,
    this.headerBanner,
    this.isApplied = false,
    this.onApply,
    this.isSaved = false,
    this.onSave,
    this.onViewMap,
  });

  @override
  State<JobDetailSheet> createState() => _JobDetailSheetState();
}

class _JobDetailSheetState extends State<JobDetailSheet> {
  final _jobActionService = JobActionService();
  final ValueNotifier<double> _scrollOffset = ValueNotifier<double>(0.0);

  @override
  void initState() {
    super.initState();
    _jobActionService.addListener(_onJobActionsChanged);
  }

  void _onJobActionsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _jobActionService.removeListener(_onJobActionsChanged);
    _scrollOffset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final isSaved = _jobActionService.isSaved(job.id);
    final isApplied = _jobActionService.isApplied(job.id);
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final deadlineText = formatJobDeadlineDate(job.deadline);
    final slotsText = (job.slots ?? 0) > 0 ? '${job.slots}' : '—';
    final userSkillsLower =
        UserSession().skills.map((s) => s.toLowerCase()).toSet();

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                child: Stack(
                  children: [
                    NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification is ScrollUpdateNotification) {
                          _scrollOffset.value = notification.metrics.pixels;
                        }
                        return false;
                      },
                      child: SingleChildScrollView(
                        controller: scrollController,
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 68),
                            _buildHeroSection(job),
                            const SizedBox(height: 24),
                            if (widget.headerBanner != null) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20),
                                child: widget.headerBanner!,
                              ),
                              const SizedBox(height: 16),
                            ],
                            _buildMainContentCard(
                              job: job,
                              slotsText: slotsText,
                              deadlineText: deadlineText,
                              userSkillsLower: userSkillsLower,
                            ),
                            SizedBox(height: bottomPad + 100),
                          ],
                        ),
                      ),
                    ),
                    _buildTopBar(context, isSaved),
                    _buildBottomBar(isSaved, isApplied, bottomPad),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Hero Section ───────────────────────────────────────────────────────────
  Widget _buildHeroSection(Job job) {
    return Column(
      children: [
        // Gradient header band with logo
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              width: double.infinity,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    job.companyColor.withOpacity(0.12),
                    job.companyColor.withOpacity(0.04),
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Positioned(
              bottom: -38,
              child: Hero(
                tag: 'job_logo_${job.id}',
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: job.companyColor.withOpacity(0.30),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: CompanyLogoBox(
                      job: job,
                      size: 76,
                      borderRadius: 22,
                      boxShadow: const [],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 48),
        // Urgent badge
        if (job.isUrgent) ...[
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
              ),
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEF4444).withOpacity(0.30),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.local_fire_department_rounded,
                    size: 13, color: Colors.white),
                SizedBox(width: 4),
                Text(
                  'URGENT HIRING',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        // Job title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            job.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 6),
        // Company name
        Text(
          job.company,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: job.companyColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        // Location + View on Map
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border:
                        Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on_rounded,
                          size: 14, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          job.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF475569),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (widget.onViewMap != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: widget.onViewMap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(999),
                      border:
                          Border.all(color: const Color(0xFF93C5FD)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.map_rounded,
                            size: 14, color: Color(0xFF1D4ED8)),
                        SizedBox(width: 5),
                        Text(
                          'Locate',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1D4ED8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        // Match badge
        if (job.matchPercentage > 0) ...[
          const SizedBox(height: 14),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
              ),
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color:
                      const Color(0xFF10B981).withOpacity(0.30),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded,
                    size: 14, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  '${job.matchPercentage}% Match',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }



  // ── Main Content Card (Consolidated) ──────────────────────────────────────
  Widget _buildMainContentCard({
    required Job job,
    required String slotsText,
    required String deadlineText,
    required Set<String> userSkillsLower,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // 1. Key Details Grid
            _buildKeyDetailsGridContent(job, slotsText, deadlineText),

            if (job.description.isNotEmpty) ...[
              const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(
                        'About This Role', Icons.description_outlined),
                    const SizedBox(height: 16),
                    Text(
                      job.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF475569),
                        height: 1.7,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (job.skills.isNotEmpty) ...[
              const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
              Padding(
                padding: const EdgeInsets.all(22),
                child: _buildSkillsContent(job, userSkillsLower),
              ),
            ],

            if (job.requirements.isNotEmpty) ...[
              const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
              Padding(
                padding: const EdgeInsets.all(22),
                child: _buildRequirementsContent(job),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Key Details Content ──────────────────────────────────────────────────────
  Widget _buildKeyDetailsGridContent(
      Job job, String slotsText, String deadlineText) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDetailCell(
                icon: Icons.work_outline_rounded,
                label: 'Type',
                value: job.employmentType,
                color: const Color(0xFF2563EB),
              ),
            ),
            Container(width: 1, height: 60, color: const Color(0xFFF1F5F9)),
            Expanded(
              child: _buildDetailCell(
                icon: Icons.payments_outlined,
                label: 'Salary Range',
                value: job.salaryDisplay,
                color: const Color(0xFF10B981),
              ),
            ),
          ],
        ),
        Container(height: 1, color: const Color(0xFFF1F5F9)),
        Row(
          children: [
            Expanded(
              child: _buildDetailCell(
                icon: Icons.groups_2_outlined,
                label: 'Slots',
                value: slotsText,
                color: const Color(0xFF8B5CF6),
              ),
            ),
            Container(width: 1, height: 60, color: const Color(0xFFF1F5F9)),
            Expanded(
              child: _buildDetailCell(
                icon: Icons.event_outlined,
                label: 'Deadline',
                value: deadlineText,
                color: const Color(0xFFF59E0B),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailCell({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, {Color? iconColor}) {
    final color = iconColor ?? const Color(0xFF2563EB);
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.4,
          ),
        ),
      ],
    );
  }

  // ── Skills Content ─────────────────────────────────────────────────────────
  Widget _buildSkillsContent(Job job, Set<String> userSkillsLower) {
    final matchedCount = job.skills
        .where((s) => userSkillsLower.contains(s.toLowerCase()))
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Skills Required', Icons.psychology_outlined,
            iconColor: const Color(0xFF8B5CF6)),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: job.skills.map((skill) {
            final isMatch = userSkillsLower.contains(skill.toLowerCase());
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isMatch
                    ? const Color(0xFF10B981).withOpacity(0.08)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isMatch
                      ? const Color(0xFF10B981).withOpacity(0.25)
                      : Colors.transparent,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isMatch) ...[
                    const Icon(Icons.check_circle_rounded,
                        size: 14, color: Color(0xFF10B981)),
                    const SizedBox(width: 5),
                  ],
                  Text(
                    skill,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isMatch
                          ? const Color(0xFF059669)
                          : const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        if (userSkillsLower.isNotEmpty && matchedCount > 0) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF10B981)),
                const SizedBox(width: 8),
                Text(
                  '$matchedCount of ${job.skills.length} skills match your profile',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF059669),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ── Requirements Content ───────────────────────────────────────────────────
  Widget _buildRequirementsContent(Job job) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Requirements', Icons.checklist_rounded,
            iconColor: const Color(0xFFF59E0B)),
        const SizedBox(height: 18),
        ...job.requirements.asMap().entries.map((entry) {
          return Padding(
            padding: EdgeInsets.only(
                bottom: entry.key < job.requirements.length - 1 ? 12 : 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF94A3B8),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    entry.value,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF475569),
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ── Fixed Top Bar ──────────────────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context, bool isSaved) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 17,
                    color: Color(0xFF0F172A)),
              ),
            ),
            Expanded(
              child: ValueListenableBuilder<double>(
                valueListenable: _scrollOffset,
                builder: (context, offset, _) {
                  // Fade out between 0 and 40 pixels of scroll
                  final opacity = (1.0 - (offset / 40.0)).clamp(0.0, 1.0);
                  // Float up by 15px as it fades
                  final translateY = (offset * -0.4).clamp(-15.0, 0.0);
                  
                  return Opacity(
                    opacity: opacity,
                    child: Transform.translate(
                      offset: Offset(0, translateY),
                      child: const Text(
                        'Job Details',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            GestureDetector(
              onTap: () => widget.onSave?.call(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSaved ? const Color(0xFF2563EB) : Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSaved ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  isSaved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                  size: 20,
                  color: isSaved ? Colors.white : const Color(0xFF475569),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Fixed Bottom Action Bar ────────────────────────────────────────────────
  Widget _buildBottomBar(
      bool isSaved, bool isApplied, double bottomPad) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        padding:
            EdgeInsets.fromLTRB(20, 16, 20, bottomPad + 16),
        child: Row(
          children: [
            // Save icon button
            GestureDetector(
              onTap: () => widget.onSave?.call(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: isSaved
                      ? const Color(0xFF2563EB).withOpacity(0.08)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSaved
                        ? const Color(0xFF2563EB)
                        : const Color(0xFFE2E8F0),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  isSaved
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_outline_rounded,
                  size: 22,
                  color: isSaved
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF64748B),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Apply button
            Expanded(
              child: GestureDetector(
                onTap: isApplied
                    ? null
                    : () => widget.onApply?.call(),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isApplied
                          ? [
                              const Color(0xFF10B981),
                              const Color(0xFF059669),
                            ]
                          : [
                              const Color(0xFF2563EB),
                              const Color(0xFF1D4ED8),
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: (isApplied
                                ? const Color(0xFF10B981)
                                : const Color(0xFF2563EB))
                            .withOpacity(0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isApplied
                            ? Icons.check_circle_rounded
                            : Icons.send_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isApplied ? 'Applied' : 'Apply Now',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
