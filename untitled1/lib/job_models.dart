import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api_service.dart';
import 'job_action_service.dart';
import 'skill_match_utils.dart';
import 'l10n/app_localizations.dart';
import 'micro_interactions.dart';
import 'app_haptics.dart';
import 'main.dart';

// ─── Job Model ────────────────────────────────────────────────────────────────
class Job {
  final String id;
  final String title;
  final String company;
  final String companyInitial;
  final Color companyColor;

  /// Relative storage path from employer profile (`employers.photo`), if any.
  final String? companyPhotoPath;
  final String? employerId;
  final String? program;
  final bool isPesoPosted;
  final String? employerEmail;
  final String? employerPhone;
  final String location;
  final double? latitude;
  final double? longitude;
  final String description;
  final List<String> requirements;
  final List<String> skills;
  final String experienceLevel;
  final String? educationLevel;
  final String salaryMin;
  final String salaryMax;
  final String employmentType;
  final String? category;
  final DateTime postedDate;
  final int? slots;
  final DateTime? deadline;
  final int matchPercentage;
  final bool isUrgent;
  final bool isOverseas;

  const Job({
    required this.id,
    required this.title,
    required this.company,
    required this.companyInitial,
    required this.companyColor,
    this.companyPhotoPath,
    this.employerId,
    this.program,
    this.isPesoPosted = false,
    this.employerEmail,
    this.employerPhone,
    required this.location,
    this.latitude,
    this.longitude,
    required this.description,
    required this.requirements,
    required this.skills,
    required this.experienceLevel,
    this.educationLevel,
    required this.salaryMin,
    required this.salaryMax,
    required this.employmentType,
    this.category,
    required this.postedDate,
    this.slots,
    this.deadline,
    this.matchPercentage = 0,
    this.isUrgent = false,
    this.isOverseas = false,
  });

  /// Whether this job has valid GPS map coordinates available.
  bool get hasCoordinates =>
      latitude != null &&
      longitude != null &&
      latitude != 0.0 &&
      longitude != 0.0;

  bool get isDoleProgram {
    if (program != null &&
        program!.trim().isNotEmpty &&
        program!.trim().toLowerCase() != 'none' &&
        program!.trim().toLowerCase() != 'null') {
      return true;
    }
    final compLower = company.trim().toLowerCase();
    return compLower.contains('dole') ||
        compLower.contains('department of labor');
  }

  /// Compact name used for tight 2x2 grid views ('DOLE' instead of full name).
  String get compactCompanyName {
    if (isDoleProgram) return 'DOLE';
    return company;
  }

  bool get isPesoOffice {
    if (isDoleProgram) return false;
    if (isPesoPosted) return true;
    final compLower = company.trim().toLowerCase();
    return compLower == 'peso' ||
        compLower == 'peso santiago' ||
        compLower.contains('peso santiago') ||
        compLower == 'employer';
  }

  /// Local asset image path for PESO Santiago or DOLE postings, if applicable.
  String? get assetLogoPath {
    if (isDoleProgram) {
      return 'assets/Department_of_Labor_and_Employment_(DOLE).png';
    }
    if (isPesoOffice) {
      return 'assets/PESOLOGO.jpg';
    }
    return null;
  }

  String get salaryDisplay {
    final min = salaryMin.trim();
    final max = salaryMax.trim();
    if (min.isEmpty && max.isEmpty) return 'Not specified';
    if (min.isEmpty) return max;
    if (max.isEmpty || min == max) return min;
    return '$min - $max';
  }

  /// Formatted experience level string for user display.
  String get experienceDisplay {
    final raw = experienceLevel.trim().toLowerCase();
    if (raw.isEmpty) return 'Not specified';
    switch (raw) {
      case 'fresh_grad':
      case 'fresh_graduate':
      case 'entry_level':
        return 'Fresh Grad / None';
      case 'less_than_1':
      case 'less_than_1_year':
        return '< 1 year exp';
      case '1_year':
      case '1':
        return 'At least 1 year';
      case '2_years':
      case '2':
        return 'At least 2 years';
      case '3_years':
      case '3':
        return 'At least 3 years';
      case '5_years':
      case '5':
        return 'At least 5 years';
      case '10_years':
      case '10':
        return '10+ years exp';
      default:
        return experienceLevel.trim();
    }
  }

  /// Formatted education level string for user display.
  String get educationDisplay {
    final raw = (educationLevel ?? '').trim().toLowerCase();
    if (raw.isEmpty || raw == 'none') return 'Any education';
    switch (raw) {
      case 'elementary':
        return 'Elementary Grad';
      case 'highschool':
      case 'high_school':
      case 'high school':
      case 'secondary':
        return 'High School / SHS';
      case 'vocational':
      case 'technical':
        return 'Vocational / Tech';
      case 'associate':
      case 'college_level':
      case 'college_undergrad':
        return 'College Level';
      case 'bachelors':
      case 'college_graduate':
      case 'college':
      case 'tertiary':
        return "Bachelor's Degree";
      case 'masters':
      case 'postgraduate':
        return "Master's Degree";
      case 'doctorate':
      case 'phd':
        return 'Doctorate / PhD';
      default:
        return educationLevel!.trim();
    }
  }

  /// Display form of [employmentType] for modals, chips, and lists.
  String get employmentTypeLabel => formatEmploymentTypeLabel(employmentType);

  /// Relative time for feed cards: e.g. "Just now", "2h ago", "Yesterday", "3d ago", "2w ago"
  String get postedTimeAgo {
    final now = DateTime.now();
    final diff = now.difference(postedDate);

    if (diff.isNegative || diff.inMinutes < 1) {
      return 'Just now';
    }
    if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    }
    if (diff.inDays == 1) {
      return 'Yesterday';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    }
    if (diff.inDays < 30) {
      final weeks = (diff.inDays / 7).floor();
      return '${weeks}w ago';
    }
    if (diff.inDays < 365) {
      final months = (diff.inDays / 30).floor();
      return '${months}mo ago';
    }
    return formatJobDeadlineDate(postedDate);
  }

  /// Exact full date for Job Details modal / sheet: e.g. "Aug 18, 2026"
  String get postedDateFormatted => formatJobDeadlineDate(postedDate);

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

    final rawProgram = (json['program'] as String?)?.trim();
    final bool hasProgram = rawProgram != null &&
        rawProgram.isNotEmpty &&
        rawProgram.toLowerCase() != 'none' &&
        rawProgram.toLowerCase() != 'null';

    final rawEmployer = json['employer'];
    Map<String, dynamic>? employerMap;
    if (rawEmployer is Map) {
      employerMap = Map<String, dynamic>.from(rawEmployer);
    }
    final employerIdStr =
        json['employer_id']?.toString() ?? employerMap?['id']?.toString();

    final isPeso = employerIdStr == null ||
        employerIdStr.isEmpty ||
        employerIdStr == '0' ||
        json['is_peso_posted'] == true;

    String companyName;
    if (hasProgram) {
      companyName = 'Department of Labor and Employment';
    } else if (isPeso) {
      final rawName = (json['company'] as String?) ??
          (json['employer_name'] as String?) ??
          (employerMap?['company_name'] as String?);
      if (rawName == null ||
          rawName.trim().isEmpty ||
          rawName.trim().toLowerCase() == 'employer') {
        companyName = 'PESO Santiago';
      } else if (rawName.trim().toLowerCase() == 'dole' ||
          rawName.trim().toLowerCase().contains('department of labor')) {
        companyName = 'Department of Labor and Employment';
      } else {
        companyName = rawName.trim();
      }
    } else {
      final rawName = (json['company'] as String?) ??
          (employerMap?['company_name'] as String?) ??
          (json['employer_name'] as String?);
      if (rawName == null ||
          rawName.trim().isEmpty ||
          rawName.trim().toLowerCase() == 'employer') {
        companyName = 'PESO Santiago';
      } else if (rawName.trim().toLowerCase() == 'dole' ||
          rawName.trim().toLowerCase().contains('department of labor')) {
        companyName = 'Department of Labor and Employment';
      } else {
        companyName = rawName.trim();
      }
    }

    // Prefer API-computed absolute URL; then nested employer.photo / photo_url.
    String? companyPhotoPath;
    final topPhoto = json['employer_photo_url'] ?? json['employerPhotoUrl'];
    if (topPhoto != null && topPhoto.toString().trim().isNotEmpty) {
      companyPhotoPath = topPhoto.toString().trim();
    } else if (employerMap != null) {
      final p = employerMap['photo'] ?? employerMap['photo_url'];
      if (p != null && p.toString().trim().isNotEmpty) {
        companyPhotoPath = p.toString().trim();
      }
    }

    final companyInitial = (json['company_initial'] as String?) ??
        (companyName.trim().isNotEmpty
            ? companyName.trim()[0].toUpperCase()
            : (hasProgram ? 'D' : 'P'));

    String? cleanContactValue(dynamic value) {
      final text = value?.toString().trim();
      return text == null || text.isEmpty ? null : text;
    }

    final employerEmail = cleanContactValue(
      json['employer_email'] ??
          json['email'] ??
          employerMap?['email'] ??
          (isPeso || hasProgram ? 'admin@peso.gov.ph' : null),
    );
    final employerPhone = cleanContactValue(
      json['employer_phone'] ??
          json['phone'] ??
          json['contact'] ??
          employerMap?['phone'] ??
          (isPeso || hasProgram ? '09001234567' : null),
    );

    final salaryRange = (json['salary_range'] as String?)?.trim();
    String salaryMin = (json['salary_min'] as String?) ?? '';
    String salaryMax = (json['salary_max'] as String?) ?? '';
    if ((salaryMin.isEmpty || salaryMax.isEmpty) &&
        salaryRange != null &&
        salaryRange.isNotEmpty) {
      final parts = salaryRange.split(RegExp(r'\s*-\s*'));
      if (parts.length >= 2) {
        salaryMin = parts[0].trim();
        salaryMax = parts[1].trim();
      } else {
        salaryMin = salaryRange;
        salaryMax = salaryRange;
      }
    }

    final latValue = json['latitude'] ?? employerMap?['latitude'];
    final lonValue = json['longitude'] ?? employerMap?['longitude'];
    double? latitude = switch (latValue) {
      final num v => v.toDouble(),
      final String v => double.tryParse(v),
      _ => null,
    };
    double? longitude = switch (lonValue) {
      final num v => v.toDouble(),
      final String v => double.tryParse(v),
      _ => null,
    };

    if ((latitude == null ||
            longitude == null ||
            latitude == 0 ||
            longitude == 0) &&
        (isPeso || hasProgram)) {
      latitude = 16.68930015164032;
      longitude = 121.55596296008191;
    }

    final rawSkills = json['skills'];
    final skills = (rawSkills is List ? rawSkills : const <dynamic>[])
        .map((e) {
          if (e is Map<String, dynamic>) return e['skill']?.toString() ?? '';
          return e.toString();
        })
        .where((s) => s.trim().isNotEmpty)
        .toList();

    final postedRaw = (json['posted_date'] as String?) ??
        (json['created_at'] as String?) ??
        '';
    final postedDate = DateTime.tryParse(postedRaw) ?? DateTime.now();
    final deadlineRaw = json['deadline'] as String?;
    final deadline =
        deadlineRaw != null ? DateTime.tryParse(deadlineRaw) : null;

    final isUrgent = json['is_urgent'] == true ||
        json['is_urgent'] == 1 ||
        json['urgent'] == true ||
        (json['is_urgent'] is String &&
            (json['is_urgent'] == '1' ||
                json['is_urgent'].toString().toLowerCase() == 'true'));

    final isOverseas = json['is_overseas'] == true ||
        json['is_overseas'] == 1 ||
        json['overseas'] == true ||
        (json['is_overseas'] is String &&
            (json['is_overseas'] == '1' ||
                json['is_overseas'].toString().toLowerCase() == 'true')) ||
        (employerMap?['employer_type'] == 'overseas');

    return Job(
      id: json['id'].toString(),
      title: (json['title'] as String?) ?? '',
      company: companyName,
      companyInitial: companyInitial,
      companyColor: color,
      companyPhotoPath: companyPhotoPath,
      employerId: employerIdStr,
      program: rawProgram,
      isPesoPosted: isPeso,
      employerEmail: employerEmail,
      employerPhone: employerPhone,
      location: (json['location'] as String?) ?? '',
      latitude: latitude,
      longitude: longitude,
      description: (json['description'] as String?) ?? '',
      requirements: (json['requirements'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      skills: skills,
      experienceLevel: (json['experience_required'] as String?) ??
          (json['experience_level'] as String?) ??
          (json['experience'] as String?) ??
          (json['work_experience'] as String?) ??
          '',
      educationLevel: (json['education_level'] as String?) ??
          (json['educational_attainment'] as String?) ??
          (json['education'] as String?),
      salaryMin: salaryMin,
      salaryMax: salaryMax,
      employmentType: (json['employment_type'] as String?) ??
          (json['type'] as String?) ??
          'full-time',
      category: json['category'] as String?,
      postedDate: postedDate,
      slots: (json['slots'] as num?)?.toInt() ??
          (json['number_of_slots'] as num?)?.toInt(),
      deadline: deadline,
      matchPercentage: (json['match_percentage'] as num?)?.toInt() ?? 0,
      isUrgent: isUrgent,
      isOverseas: isOverseas,
    );
  }
}

/// e.g. Jan 15, 2026 (for job detail / cards)
String formatJobDeadlineDate(DateTime? d) {
  if (d == null) return 'Not specified';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
  return '${months[d.month - 1]} ${d.day}, ${d.year}';
}

/// Maps API slugs (`full-time`, `contract`, …) to UI labels (`Full-time`, `Contract`).
String formatEmploymentTypeLabel(String? raw) {
  if (raw == null) return 'Not specified';
  final t = raw.trim();
  if (t.isEmpty) return 'Not specified';

  final key =
      t.toLowerCase().replaceAll('_', '-').replaceAll(RegExp(r'\s+'), '');
  switch (key) {
    case 'full-time':
    case 'fulltime':
      return 'Full-time';
    case 'part-time':
    case 'parttime':
      return 'Part-time';
    case 'contract':
      return 'Contract';
    case 'internship':
      return 'Internship';
    case 'temporary':
      return 'Temporary';
    case 'freelance':
      return 'Freelance';
    case 'seasonal':
      return 'Seasonal';
  }

  return _humanizeEmploymentTypeSegments(t);
}

String _humanizeEmploymentTypeSegments(String raw) {
  final normalized = raw.replaceAll('_', '-');
  final buffer = StringBuffer();
  var capitalizeNext = true;
  for (var i = 0; i < normalized.length; i++) {
    final c = normalized[i];
    if (c == '-' || c == ' ') {
      buffer.write(c == ' ' ? ' ' : '-');
      capitalizeNext = true;
      continue;
    }
    if (capitalizeNext) {
      buffer.write(c.toUpperCase());
      capitalizeNext = false;
    } else {
      buffer.write(c.toLowerCase());
    }
  }
  return buffer.toString();
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
    final assetLogo = job.assetLogoPath;
    final path = job.companyPhotoPath;
    final url = ApiService.storageOrAbsoluteUrl(path) ?? '';
    final radius = borderRadius ?? size / 2;
    final hasLogo = url.isNotEmpty;

    if (assetLogo != null) {
      final isDole = job.isDoleProgram;
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: isDole
                ? const Color(0xFF1E3A8A).withOpacity(0.18)
                : AppColors.pesoBlue.withOpacity(0.22),
            width: 1.5,
          ),
          boxShadow: boxShadow ??
              [
                BoxShadow(
                  color: (isDole ? const Color(0xFF1E3A8A) : AppColors.pesoBlue)
                      .withOpacity(0.14),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: EdgeInsets.all(isDole ? size * 0.08 : 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Image.asset(
              assetLogo,
              fit: isDole ? BoxFit.contain : BoxFit.cover,
            ),
          ),
        ),
      );
    }

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
                    child: const CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
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
  String? customActionLabel,
  dynamic customActionIcon,
  List<Color>? customActionGradientColors,
  VoidCallback? onCustomActionTap,
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
                customActionLabel: customActionLabel,
                customActionIcon: customActionIcon,
                customActionGradientColors: customActionGradientColors,
                onCustomActionTap: onCustomActionTap,
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
  final String? customActionLabel;
  final dynamic customActionIcon;
  final List<Color>? customActionGradientColors;
  final VoidCallback? onCustomActionTap;

  const JobDetailSheet({
    super.key,
    required this.job,
    this.headerBanner,
    this.isApplied = false,
    this.onApply,
    this.isSaved = false,
    this.onSave,
    this.onViewMap,
    this.customActionLabel,
    this.customActionIcon,
    this.customActionGradientColors,
    this.onCustomActionTap,
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
    final userSkillsNormalized =
        SkillMatchUtils.normalizedUserSkillsFromSession();

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
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: widget.headerBanner!,
                              ),
                              const SizedBox(height: 16),
                            ],
                            _buildMainContentCard(
                              job: job,
                              slotsText: slotsText,
                              deadlineText: deadlineText,
                              userSkillsNormalized: userSkillsNormalized,
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
        // Badges (DOLE / PESO / Overseas / Urgent)
        if (job.isDoleProgram ||
            job.isPesoOffice ||
            job.isOverseas ||
            job.isUrgent) ...[
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              if (job.isDoleProgram)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                    ),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1D4ED8).withOpacity(0.30),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const HugeIcon(
                        icon: HugeIcons.strokeRoundedBerlin,
                        size: 13,
                        color: Colors.white,
                        strokeWidth: 2.0,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        job.program != null &&
                                job.program!.trim().isNotEmpty &&
                                job.program!.toLowerCase() != 'none'
                            ? 'DOLE • ${job.program!.toUpperCase()}'
                            : 'DOLE PROGRAM',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                )
              else if (job.isPesoOffice)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                    ),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0284C7).withOpacity(0.30),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedCheckmarkCircle01,
                        size: 13,
                        color: Colors.white,
                        strokeWidth: 2.0,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'PESO SANTIAGO',
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
              if (job.isOverseas)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4F46E5), Color(0xFF3730A3)],
                    ),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4F46E5).withOpacity(0.30),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedGlobe02,
                        size: 13,
                        color: Colors.white,
                        strokeWidth: 2.0,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'OVERSEAS JOB',
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
              if (job.isUrgent)
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
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedFire,
                        size: 13,
                        color: Colors.white,
                        strokeWidth: 2.0,
                      ),
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
            ],
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
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
                      const HugeIcon(
                        icon: HugeIcons.strokeRoundedLocation01,
                        size: 14,
                        color: Color(0xFF94A3B8),
                        strokeWidth: 2.0,
                      ),
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
              if (widget.onViewMap != null && job.hasCoordinates) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: widget.onViewMap,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFF93C5FD)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedMapsLocation01,
                          size: 14,
                          color: Color(0xFF1D4ED8),
                          strokeWidth: 2.0,
                        ),
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
              ] else ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    CustomToast.show(
                      context,
                      message:
                          'Exact map pin is being verified by PESO Santiago staff',
                      type: ToastType.info,
                      duration: const Duration(seconds: 3),
                    );
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedLocation01,
                          size: 13,
                          color: Color(0xFF94A3B8),
                          strokeWidth: 2.0,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Pin Pending',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
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
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const HugeIcon(
              icon: HugeIcons.strokeRoundedClock01,
              size: 13,
              color: Color(0xFF64748B),
              strokeWidth: 2.0,
            ),
            const SizedBox(width: 4),
            Text(
              'Posted ${job.postedDateFormatted} (${job.postedTimeAgo})',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        // Match badge
        if (job.matchPercentage > 0) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
              ),
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withOpacity(0.30),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const HugeIcon(
                  icon: HugeIcons.strokeRoundedStar,
                  size: 14,
                  color: Colors.white,
                  strokeWidth: 2.0,
                ),
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
    required Set<String> userSkillsNormalized,
  }) {
    final l10n = S.of(context);
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
                        l10n?.aboutThisRoleTitle ?? 'About This Role',
                        HugeIcons.strokeRoundedFile01),
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
                child: _buildSkillsContent(job, userSkillsNormalized),
              ),
            ],

            if (job.requirements.isNotEmpty) ...[
              const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
              Padding(
                padding: const EdgeInsets.all(22),
                child: _buildRequirementsContent(job),
              ),
            ],

            if (job.employerPhone != null || job.employerEmail != null) ...[
              const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
              Padding(
                padding: const EdgeInsets.all(22),
                child: _buildContactContent(job),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContactContent(Job job) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          'Contact Information',
          HugeIcons.strokeRoundedCall,
          iconColor: const Color(0xFF0EA5E9),
        ),
        const SizedBox(height: 16),
        if (job.employerPhone != null)
          _buildContactRow(
            icon: HugeIcons.strokeRoundedCall,
            label: 'Phone Number',
            value: job.employerPhone!,
            actionIcon: HugeIcons.strokeRoundedCall,
            actionLabel: 'Call',
            onAction: () => _launchPhone(job.employerPhone!),
          ),
        if (job.employerPhone != null && job.employerEmail != null)
          const SizedBox(height: 10),
        if (job.employerEmail != null)
          _buildContactRow(
            icon: HugeIcons.strokeRoundedMail01,
            label: 'Email Address',
            value: job.employerEmail!,
            actionIcon: HugeIcons.strokeRoundedMail01,
            actionLabel: 'Email',
            onAction: () => _launchEmail(job),
          ),
      ],
    );
  }

  Future<void> _launchPhone(String phone) async {
    final normalized = phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri(scheme: 'tel', path: normalized);
    await _launchContactUri(uri);
  }

  Future<void> _launchEmail(Job job) async {
    final email = job.employerEmail?.trim();
    if (email == null || email.isEmpty) return;
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': 'Job inquiry: ${job.title}',
      },
    );
    await _launchContactUri(uri);
  }

  Future<void> _launchContactUri(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
    if (!mounted) return;
    CustomToast.show(
      context,
      message: 'No app found to handle this contact action.',
      type: ToastType.info,
    );
  }

  Widget _buildContactRow({
    required dynamic icon,
    required String label,
    required String value,
    required dynamic actionIcon,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF0EA5E9).withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: HugeIcon(
              icon: icon as List<List<dynamic>>,
              size: 17,
              color: const Color(0xFF0284C7),
              strokeWidth: 2.0,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 3),
                SelectableText(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 40,
            child: FilledButton.icon(
              onPressed: onAction,
              icon: HugeIcon(
                icon: actionIcon as List<List<dynamic>>,
                size: 16,
                color: Colors.white,
                strokeWidth: 2.0,
              ),
              label: Text(actionLabel),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
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
                icon: HugeIcons.strokeRoundedBriefcase01,
                label: 'Type',
                value: job.employmentTypeLabel,
                color: const Color(0xFF2563EB),
              ),
            ),
            Container(width: 1, height: 60, color: const Color(0xFFF1F5F9)),
            Expanded(
              child: _buildDetailCell(
                icon: HugeIcons.strokeRoundedMoney01,
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
                icon: HugeIcons.strokeRoundedCertificate01,
                label: 'Experience',
                value: job.experienceDisplay,
                color: const Color(0xFF6366F1),
              ),
            ),
            Container(width: 1, height: 60, color: const Color(0xFFF1F5F9)),
            Expanded(
              child: _buildDetailCell(
                icon: HugeIcons.strokeRoundedGraduateMale,
                label: 'Education',
                value: job.educationDisplay,
                color: const Color(0xFF0D9488),
              ),
            ),
          ],
        ),
        Container(height: 1, color: const Color(0xFFF1F5F9)),
        Row(
          children: [
            Expanded(
              child: _buildDetailCell(
                icon: HugeIcons.strokeRoundedUserGroup,
                label: 'Slots',
                value: slotsText,
                color: const Color(0xFF8B5CF6),
              ),
            ),
            Container(width: 1, height: 60, color: const Color(0xFFF1F5F9)),
            Expanded(
              child: _buildDetailCell(
                icon: HugeIcons.strokeRoundedCalendar03,
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
    required dynamic icon,
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
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: HugeIcon(
              icon: icon as List<List<dynamic>>,
              size: 18,
              color: color,
              strokeWidth: 2.0,
            ),
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

  Widget _buildSectionTitle(String title, dynamic icon, {Color? iconColor}) {
    final color = iconColor ?? const Color(0xFF2563EB);
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(9),
          ),
          child: HugeIcon(
            icon: icon as List<List<dynamic>>,
            size: 16,
            color: color,
            strokeWidth: 2.0,
          ),
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
  Widget _buildSkillsContent(Job job, Set<String> userSkillsNormalized) {
    final l10n = S.of(context);
    final matchedCount = job.skills
        .where((s) => SkillMatchUtils.matchesSingleSkillLabel(
              normalizedUserSkills: userSkillsNormalized,
              jobSkill: s,
            ))
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(l10n?.skillsRequiredTitle ?? 'Skills Required',
            HugeIcons.strokeRoundedBrain01,
            iconColor: const Color(0xFF8B5CF6)),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: job.skills.map((skill) {
            final isMatch = SkillMatchUtils.matchesSingleSkillLabel(
              normalizedUserSkills: userSkillsNormalized,
              jobSkill: skill,
            );
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
                    const HugeIcon(
                      icon: HugeIcons.strokeRoundedCheckmarkCircle01,
                      size: 14,
                      color: Color(0xFF10B981),
                      strokeWidth: 2.0,
                    ),
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
        if (userSkillsNormalized.isNotEmpty && matchedCount > 0) ...[
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
                const HugeIcon(
                  icon: HugeIcons.strokeRoundedCheckmarkBadge01,
                  size: 14,
                  color: Color(0xFF10B981),
                  strokeWidth: 2.0,
                ),
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
        _buildSectionTitle('Requirements', HugeIcons.strokeRoundedTask01,
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
            const SizedBox(width: 40),
            Expanded(
              child: ValueListenableBuilder<double>(
                valueListenable: _scrollOffset,
                builder: (context, offset, _) {
                  final opacity = (1.0 - (offset / 40.0)).clamp(0.0, 1.0);
                  final translateY = (offset * -0.4).clamp(-15.0, 0.0);

                  return Opacity(
                    opacity: opacity,
                    child: Transform.translate(
                      offset: Offset(0, translateY),
                      child: Text(
                        S.of(context)?.jobDetailsTitle ?? 'Job Details',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
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
              onTap: () {
                AppHaptics.lightImpact();
                Navigator.of(context).pop();
              },
              child: Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const HugeIcon(
                  icon: HugeIcons.strokeRoundedCancel01,
                  size: 18,
                  color: Color(0xFF0F172A),
                  strokeWidth: 2.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Fixed Bottom Action Bar ────────────────────────────────────────────────
  Widget _buildBottomBar(bool isSaved, bool isApplied, double bottomPad) {
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
        padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPad + 16),
        child: Row(
          children: [
            AnimatedBookmarkBounce(
              isSaved: isSaved,
              onTap: () => widget.onSave?.call(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 54,
                height: 54,
                alignment: Alignment.center,
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
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedBookmark01,
                  size: 20,
                  color: isSaved
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF64748B),
                  strokeWidth: 2.0,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Builder(
                builder: (context) {
                  final hasCustomAction = widget.onCustomActionTap != null;
                  final isEnabled = !isApplied || hasCustomAction;
                  final onTap = hasCustomAction
                      ? widget.onCustomActionTap
                      : (isApplied ? null : () => widget.onApply?.call());

                  final defaultGradient = isApplied
                      ? [
                          const Color(0xFF10B981),
                          const Color(0xFF059669),
                        ]
                      : [
                          const Color(0xFF2563EB),
                          const Color(0xFF1D4ED8),
                        ];

                  final gradientColors = widget.customActionGradientColors ??
                      (hasCustomAction
                          ? [
                              const Color(0xFF0EA5E9),
                              const Color(0xFF0284C7),
                            ]
                          : defaultGradient);

                  final label = widget.customActionLabel ??
                      (isApplied ? 'Applied' : 'Apply Now');

                  final dynamic customIcon = widget.customActionIcon;

                  Widget iconWidget;
                  if (customIcon != null) {
                    if (customIcon is IconData) {
                      iconWidget = Icon(
                        customIcon,
                        size: 18,
                        color: Colors.white,
                      );
                    } else {
                      iconWidget = HugeIcon(
                        icon: customIcon as List<List<dynamic>>,
                        size: 18,
                        color: Colors.white,
                        strokeWidth: 2.0,
                      );
                    }
                  } else {
                    iconWidget = HugeIcon(
                      icon: isApplied
                          ? HugeIcons.strokeRoundedCheckmarkCircle01
                          : HugeIcons.strokeRoundedSent,
                      size: 18,
                      color: Colors.white,
                      strokeWidth: 2.0,
                    );
                  }

                  return GestureDetector(
                    onTap: isEnabled ? onTap : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: gradientColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: gradientColors.first.withOpacity(0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          iconWidget,
                          const SizedBox(width: 10),
                          Text(
                            label,
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
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
