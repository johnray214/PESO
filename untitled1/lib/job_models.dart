import 'package:flutter/material.dart';
import 'job_action_service.dart';

// ─── Job Model ────────────────────────────────────────────────────────────────
class Job {
  final String id;
  final String title;
  final String company;
  final String companyInitial;
  final Color companyColor;
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

    final employer = json['employer'];
    final companyName = (json['company'] as String?) ??
        (employer is Map<String, dynamic> ? employer['company_name'] as String? : null) ??
        'Employer';

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

    return Job(
      id: json['id'].toString(),
      title: (json['title'] as String?) ?? '',
      company: companyName,
      companyInitial: companyInitial,
      companyColor: color,
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
      slots: (json['slots'] as num?)?.toInt(),
      deadline: deadline,
      matchPercentage: (json['match_percentage'] as num?)?.toInt() ?? 0,
      isUrgent: (json['is_urgent'] as dynamic) == true ||
          json['is_urgent'] == 1,
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final isSaved = _jobActionService.isSaved(job.id);
    final isApplied = _jobActionService.isApplied(job.id);
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final deadlineText = job.deadline != null
        ? '${job.deadline!.month}/${job.deadline!.day}/${job.deadline!.year}'
        : 'Not specified';
    final slotsText = (job.slots ?? 0) > 0 ? '${job.slots} slot(s)' : 'Not specified';

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // ── Drag handle ──────────────────────────────────────────────────
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // ── Main body: hero + scroll + floating pills all in a Stack ─────
              Expanded(
                child: Stack(
                  children: [
                    // ── Scrollable content ─────────────────────────────────────
                    SingleChildScrollView(
                      controller: scrollController,
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 70),

                          // Logo + white card stacked so logo sits behind top edge
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                // White info card with shadow (content starts below logo overlap)
                                Container(
                                  margin: const EdgeInsets.only(top: 40),
                                  padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.06),
                                        blurRadius: 16,
                                        spreadRadius: 0,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                  // Urgent badge
                                  if (job.isUrgent) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEF4444),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: const Text(
                                        'URGENT HIRING',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                  ],

                                  // Job title
                                  Text(
                                    job.title,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 4),

                                  // Company name
                                  Text(
                                    job.company,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF2563EB),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  // Centered location + map CTA
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Flexible(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF8FAFC),
                                            borderRadius:
                                                BorderRadius.circular(999),
                                            border: Border.all(
                                              color: const Color(0xFFE2E8F0),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.location_on_outlined,
                                                size: 13,
                                                color: Color(0xFF94A3B8),
                                              ),
                                              const SizedBox(width: 4),
                                              Flexible(
                                                child: Text(
                                                  job.location,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Color(0xFF64748B),
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
                                                horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEFF6FF),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                              border: Border.all(
                                                color: const Color(0xFF93C5FD),
                                              ),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.my_location_rounded,
                                                  size: 13,
                                                  color: Color(0xFF1D4ED8),
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  'View on Map',
                                                  style: TextStyle(
                                                    fontSize: 11,
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
                                  const SizedBox(height: 12),

                                  // Match badge
                                  if (job.matchPercentage > 0) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 6),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF10B981),
                                            Color(0xFF059669)
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(999),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF10B981)
                                                .withOpacity(0.30),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.star_rounded,
                                              size: 13, color: Colors.white),
                                          const SizedBox(width: 5),
                                          Text(
                                            '${job.matchPercentage}% Match',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                  ],

                                  // Quick facts (2x2 grid)
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildInfoChip(
                                            Icons.work_outline_rounded,
                                            job.employmentType),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _buildInfoChip(
                                            Icons.payments_outlined,
                                            '${job.salaryMin} – ${job.salaryMax}'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildInfoChip(
                                            Icons.groups_2_outlined, slotsText),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _buildInfoChip(
                                            Icons.event_outlined, deadlineText),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                                // Company logo (on top, overlapping card but not content)
                                Positioned(
                                  top: 0,
                                  left: 0,
                                  right: 0,
                                  child: Center(
                                    child: Container(
                                      width: 72,
                                      height: 72,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            job.companyColor,
                                            job.companyColor.withOpacity(0.75),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(18),
                                        boxShadow: [
                                          BoxShadow(
                                            color: job.companyColor.withOpacity(0.45),
                                            blurRadius: 18,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          job.companyInitial,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 30,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Application status banner (if provided from My Applications)
                          if (widget.headerBanner != null) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: widget.headerBanner!,
                            ),
                            const SizedBox(height: 16),
                          ],

                          // ── Sections ────────────────────────────────────────
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                    height: 1,
                                    color: const Color(0xFFF1F5F9)),
                                const SizedBox(height: 22),

                                _buildSection(
                                  title: 'Job Description',
                                  icon: Icons.description_outlined,
                                  child: Text(
                                    job.description,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF475569),
                                      height: 1.7,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                _buildSection(
                                  title: 'Skills',
                                  icon: Icons.psychology_outlined,
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: job.skills.map((skill) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF2563EB)
                                              .withOpacity(0.08),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          skill,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF2563EB),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _buildSection(
                                  title: 'Job Information',
                                  icon: Icons.info_outline_rounded,
                                  child: Column(
                                    children: [
                                      _buildDetailRow(
                                          'Employment Type', job.employmentType),
                                      _buildDetailRow('Salary Range',
                                          '${job.salaryMin} - ${job.salaryMax}'),
                                      _buildDetailRow('Location', job.location),
                                      _buildDetailRow('Number of Slots', slotsText),
                                      _buildDetailRow('Deadline', deadlineText),
                                    ],
                                  ),
                                ),

                                // Space for floating buttons
                                SizedBox(height: bottomPad + 110),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── App bar (fixed at top, respects rounded corners) ───────
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                        child: Container(
                          color: Colors.white,
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.of(context).pop(),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: const Icon(
                                      Icons.arrow_back_ios_new_rounded,
                                      size: 17,
                                      color: Color(0xFF0F172A)),
                                ),
                              ),
                              const Expanded(
                                child: Text(
                                  'Job Details',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => widget.onSave?.call(),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: isSaved
                                        ? const Color(0xFF2563EB)
                                        : const Color(0xFFF8FAFC),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSaved
                                          ? const Color(0xFF2563EB)
                                          : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Icon(
                                    isSaved
                                        ? Icons.bookmark_rounded
                                        : Icons.bookmark_outline_rounded,
                                    size: 20,
                                    color: isSaved
                                        ? Colors.white
                                        : const Color(0xFF475569),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ── Gradient fade + floating pill buttons ──────────────────
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withOpacity(0.0),
                              Colors.white.withOpacity(0.85),
                              Colors.white,
                            ],
                            stops: const [0.0, 0.35, 0.6],
                          ),
                        ),
                        padding: EdgeInsets.fromLTRB(
                            20, 32, 20, bottomPad + 16),
                        child: Row(
                          children: [
                            // Save pill (outlined)
                            Expanded(
                              child: GestureDetector(
                                onTap: () => widget.onSave?.call(),
                                child: AnimatedContainer(
                                  duration:
                                      const Duration(milliseconds: 200),
                                  height: 54,
                                  decoration: BoxDecoration(
                                    color: isSaved
                                        ? const Color(0xFF2563EB)
                                            .withOpacity(0.07)
                                        : Colors.white,
                                    borderRadius:
                                        BorderRadius.circular(999),
                                    border: Border.all(
                                      color: isSaved
                                          ? const Color(0xFF2563EB)
                                          : const Color(0xFFCBD5E1),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Colors.black.withOpacity(0.06),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        isSaved
                                            ? Icons.bookmark_rounded
                                            : Icons.bookmark_outline_rounded,
                                        size: 19,
                                        color: isSaved
                                            ? const Color(0xFF2563EB)
                                            : const Color(0xFF475569),
                                      ),
                                      const SizedBox(width: 7),
                                      Text(
                                        isSaved ? 'Saved' : 'Save',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: isSaved
                                              ? const Color(0xFF2563EB)
                                              : const Color(0xFF475569),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Apply pill (gradient filled)
                            Expanded(
                              flex: 2,
                              child: GestureDetector(
                                onTap: isApplied
                                    ? null
                                    : () => widget.onApply?.call(),
                                child: AnimatedContainer(
                                  duration:
                                      const Duration(milliseconds: 200),
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
                                    borderRadius:
                                        BorderRadius.circular(999),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (isApplied
                                                ? const Color(0xFF10B981)
                                                : const Color(0xFF2563EB))
                                            .withOpacity(0.40),
                                        blurRadius: 14,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        isApplied
                                            ? Icons
                                                .check_circle_outline_rounded
                                            : Icons.send_rounded,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        isApplied ? 'Applied' : 'Apply Now',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
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
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF2563EB)),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF0F172A),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
      {required String title, required IconData icon, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withOpacity(0.10),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 17, color: const Color(0xFF2563EB)),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        child,
      ],
    );
  }
}
