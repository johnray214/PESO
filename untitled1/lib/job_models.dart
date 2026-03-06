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
    this.matchPercentage = 0,
    this.isUrgent = false,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    // Backend stores color as hex without '#', e.g. '3B82F6'
    final colorHex = json['company_color'] as String? ?? '3B82F6';
    final color = Color(int.parse('0xFF$colorHex'));

    final latValue = json['latitude'];
    final lonValue = json['longitude'];
    final double? latitude = latValue is num ? latValue.toDouble() : null;
    final double? longitude = lonValue is num ? lonValue.toDouble() : null;

    return Job(
      id: json['id'].toString(),
      title: json['title'] as String,
      company: json['company'] as String,
      companyInitial: json['company_initial'] as String? ?? '?',
      companyColor: color,
      location: json['location'] as String,
      latitude: latitude,
      longitude: longitude,
      description: json['description'] as String,
      requirements: (json['requirements'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      skills: (json['skills'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      experienceLevel: json['experience_level'] as String? ?? '',
      salaryMin: json['salary_min'] as String? ?? '',
      salaryMax: json['salary_max'] as String? ?? '',
      employmentType: json['employment_type'] as String? ?? 'Full-time',
      category: json['category'] as String?,
      postedDate: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
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

  const JobDetailSheet({
    super.key,
    required this.job,
    this.headerBanner,
    this.isApplied = false,
    this.onApply,
    this.isSaved = false,
    this.onSave,
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
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
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
                      if (widget.headerBanner != null) ...[
                        widget.headerBanner!,
                        const SizedBox(height: 20),
                      ],

                      // Header
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: job.companyColor,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Center(
                              child: Text(
                                job.companyInitial,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (job.isUrgent)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 6),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEF4444),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      'URGENT HIRING',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                Text(
                                  job.title,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  job.company,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Color(0xFF2563EB),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (job.matchPercentage > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  const Icon(Icons.star_rounded,
                                      size: 18, color: Colors.white),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${job.matchPercentage}%',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Info chips
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _buildInfoChip(
                              Icons.location_on_outlined, job.location),
                          _buildInfoChip(
                              Icons.work_outline_rounded, job.employmentType),
                          _buildInfoChip(Icons.payments_outlined,
                              '${job.salaryMin} – ${job.salaryMax}'),
                        ],
                      ),

                      const SizedBox(height: 24),

                      _buildSection(
                        title: 'Job Description',
                        icon: Icons.description_outlined,
                        child: Text(
                          job.description,
                          style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF475569),
                              height: 1.6),
                        ),
                      ),

                      const SizedBox(height: 20),

                      _buildSection(
                        title: 'Experience Required',
                        icon: Icons.timeline_outlined,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.badge_outlined,
                                  color: Color(0xFF2563EB), size: 22),
                              const SizedBox(width: 12),
                              Text(
                                job.experienceLevel,
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      _buildSection(
                        title: 'Requirements',
                        icon: Icons.checklist_rounded,
                        child: Column(
                          children: job.requirements.map((req) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(top: 6),
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                        color: Color(0xFF2563EB),
                                        shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(req,
                                        style: const TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF475569),
                                            height: 1.5)),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      const SizedBox(height: 20),

                      _buildSection(
                        title: 'Skills',
                        icon: Icons.psychology_outlined,
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: job.skills.map((skill) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color:
                                    const Color(0xFF2563EB).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                skill,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2563EB)),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Action buttons
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              widget.onSave?.call();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: _jobActionService.isSaved(job.id)
                                      ? const Color(0xFF2563EB)
                                      : const Color(0xFFE2E8F0),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                color: _jobActionService.isSaved(job.id)
                                    ? const Color(0xFF2563EB).withOpacity(0.08)
                                    : Colors.transparent,
                              ),
                              child: Icon(
                                _jobActionService.isSaved(job.id)
                                    ? Icons.bookmark_rounded
                                    : Icons.bookmark_outline_rounded,
                                color: _jobActionService.isSaved(job.id)
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFF64748B),
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: SizedBox(
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _jobActionService.isApplied(job.id)
                                    ? null
                                    : () {
                                        widget.onApply?.call();
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _jobActionService.isApplied(job.id)
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFF2563EB),
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor:
                                      const Color(0xFF10B981),
                                  disabledForegroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                  elevation: 0,
                                ),
                                child: _jobActionService.isApplied(job.id)
                                    ? const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                              Icons
                                                  .check_circle_outline_rounded,
                                              size: 20),
                                          SizedBox(width: 8),
                                          Text('Applied',
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight:
                                                      FontWeight.w700)),
                                        ],
                                      )
                                    : const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text('Apply Now',
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight:
                                                      FontWeight.w700)),
                                          SizedBox(width: 8),
                                          Icon(Icons.arrow_forward_rounded,
                                              size: 20),
                                        ],
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
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF64748B)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF475569)),
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
        Row(
          children: [
            Icon(icon, size: 22, color: const Color(0xFF2563EB)),
            const SizedBox(width: 10),
            Text(title,
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A))),
          ],
        ),
        const SizedBox(height: 14),
        child,
      ],
    );
  }
}
