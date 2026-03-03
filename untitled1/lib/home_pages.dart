import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;
import 'profile_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final String mapboxToken = dotenv.env['MAPBOX_TOKEN'] ?? '';

final String mapboxAccessToken = mapboxToken.isNotEmpty ? mapboxToken : '';

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

// ─── Job Model ────────────────────────────────────────────────────────────────
class Job {
  final String id;
  final String title;
  final String company;
  final String companyInitial;
  final Color companyColor;
  final String location;
  final String description;
  final List<String> requirements;
  final List<String> skills;
  final String experienceLevel;
  final String salaryMin;
  final String salaryMax;
  final String employmentType;
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
    required this.description,
    required this.requirements,
    required this.skills,
    required this.experienceLevel,
    required this.salaryMin,
    required this.salaryMax,
    required this.employmentType,
    required this.postedDate,
    this.matchPercentage = 0,
    this.isUrgent = false,
  });
}

// Sample job data
final List<Job> sampleJobs = [
  Job(
    id: '1',
    title: 'Software Developer',
    company: 'Tech Solutions Inc.',
    companyInitial: 'T',
    companyColor: const Color(0xFF3B82F6),
    location: 'Santiago City, Isabela',
    description: 'Looking for a skilled software developer with experience in mobile and web development. You will be working on cutting-edge projects and collaborating with a talented team.',
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
    postedDate: DateTime.now().subtract(const Duration(days: 2)),
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
    description: 'The City Government is seeking a reliable Administrative Assistant to provide support to our department. Duties include managing schedules, handling correspondence, and maintaining office records.',
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
    postedDate: DateTime.now().subtract(const Duration(days: 3)),
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
    description: 'Join our dynamic sales team! We are looking for motivated individuals to promote and sell our products. Commission-based incentives available for top performers.',
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
    postedDate: DateTime.now().subtract(const Duration(days: 1)),
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
    description: 'We are hiring compassionate and skilled Registered Nurses to provide quality patient care. Must be willing to work in shifts and handle emergency situations.',
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
    postedDate: DateTime.now().subtract(const Duration(days: 5)),
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
    description: 'Looking for hardworking warehouse staff to handle inventory management, packing, and shipping operations. Physical fitness required.',
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
    postedDate: DateTime.now(),
    matchPercentage: 70,
    isUrgent: true,
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

  final List<Widget> _pages = [
    const HomeTab(),
    const MapTab(),
    const NotificationsTab(),
    const ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, 'Home'),
                _buildNavItem(1, Icons.map_rounded, Icons.map_outlined, 'Map'),
                _buildNavItem(2, Icons.notifications_rounded, Icons.notifications_outlined, 'Notifications'),
                _buildNavItem(3, Icons.person_rounded, Icons.person_outline_rounded, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 20 : 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB).withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
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
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    if (difference == 0) return 'Today';
    if (difference == 1) return '1d ago';
    if (difference < 7) return '${difference}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  _getGreeting(),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text('👋', style: TextStyle(fontSize: 14)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Find Your Dream Job',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: Text(
                            'JD',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Search bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search_rounded, color: Colors.grey[500], size: 22),
                        const SizedBox(width: 12),
                        Text(
                          'Search jobs, companies...',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 15,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.tune_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Job count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    '${sampleJobs.length} Jobs Found',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Latest',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Colors.grey[600]),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Job listings
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: sampleJobs.length,
                itemBuilder: (context, index) {
                  final job = sampleJobs[index];
                  return _JobCard(
                    job: job,
                    formattedDate: _formatDate(job.postedDate),
                    onTap: () => _showJobDetails(context, job),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _JobDetailSheet(job: job),
    );
  }
}

// ─── Job Card Widget ──────────────────────────────────────────────────────────
class _JobCard extends StatelessWidget {
  final Job job;
  final String formattedDate;
  final VoidCallback onTap;

  const _JobCard({
    required this.job,
    required this.formattedDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Company icon
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: job.companyColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          job.companyInitial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
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
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
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
                    // Match percentage
                    if (job.matchPercentage > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, size: 14, color: Colors.white),
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

                const SizedBox(height: 16),

                // Location and type chips
                Row(
                  children: [
                    _buildChip(Icons.location_on_outlined, job.location),
                    const SizedBox(width: 10),
                    _buildChip(Icons.work_outline_rounded, job.employmentType),
                  ],
                ),

                const SizedBox(height: 12),

                // Salary and date
                Row(
                  children: [
                    Icon(Icons.payments_outlined, size: 16, color: Colors.grey[500]),
                    const SizedBox(width: 6),
                    Text(
                      '${job.salaryMin} - ${job.salaryMax}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Description
                Text(
                  job.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 14),

                // Skills tags
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: job.skills.map((skill) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        skill,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF475569),
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bookmark_outline_rounded, size: 18, color: Colors.grey[700]),
                          const SizedBox(width: 6),
                          Text(
                            'Save',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Apply button
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Apply Now',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 6),
                            Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                          ],
                        ),
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

  Widget _buildChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF64748B)),
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

// ─── Job Detail Sheet ─────────────────────────────────────────────────────────
class _JobDetailSheet extends StatelessWidget {
  final Job job;

  const _JobDetailSheet({required this.job});

  @override
  Widget build(BuildContext context) {
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
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  const Icon(Icons.star_rounded, size: 18, color: Colors.white),
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
                          _buildInfoChip(Icons.location_on_outlined, job.location),
                          _buildInfoChip(Icons.work_outline_rounded, job.employmentType),
                          _buildInfoChip(Icons.payments_outlined, '${job.salaryMin} - ${job.salaryMax}'),
                        ],
                      ),

                      const SizedBox(height: 24),

                      _buildSection(
                        title: 'Job Description',
                        icon: Icons.description_outlined,
                        child: Text(
                          job.description,
                          style: const TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.6),
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
                              const Icon(Icons.badge_outlined, color: Color(0xFF2563EB), size: 22),
                              const SizedBox(width: 12),
                              Text(
                                job.experienceLevel,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
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
                                    decoration: const BoxDecoration(color: Color(0xFF2563EB), shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(req, style: const TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.5)),
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
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                skill,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2563EB)),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      const SizedBox(height: 30),

                      Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.bookmark_outline_rounded, color: Color(0xFF64748B), size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: SizedBox(
                              height: 56,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Application submitted!'),
                                      backgroundColor: const Color(0xFF10B981),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 0,
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('Apply Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                    SizedBox(width: 8),
                                    Icon(Icons.arrow_forward_rounded, size: 20),
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
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF475569)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required IconData icon, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 22, color: const Color(0xFF2563EB)),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
          ],
        ),
        const SizedBox(height: 14),
        child,
      ],
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
  List<Business> _filteredBusinesses = demoBusinesses;

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredBusinesses = demoBusinesses;
      } else {
        _filteredBusinesses = demoBusinesses
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
                  ...demoBusinesses.map((business) {
                    final isSelected = _selectedBusiness?.id == business.id;
                    final color = business.id == 'sm_savemore'
                        ? const Color(0xFFE11D48)
                        : const Color(0xFF7C3AED);
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
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: isSelected ? 44 : 36,
                              height: isSelected ? 44 : 36,
                              decoration: BoxDecoration(
                                color: color,
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
                              child: Icon(
                                Icons.store_rounded,
                                color: Colors.white,
                                size: isSelected ? 22 : 18,
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
                                leading: Container(
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
                SizedBox(
                  height: 160,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: demoBusinesses.length,
                    itemBuilder: (context, index) {
                      final business = demoBusinesses[index];
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
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: index == 0
                                          ? const Color(0xFFE11D48).withOpacity(0.1)
                                          : const Color(0xFF7C3AED).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.store_rounded,
                                      color: index == 0
                                          ? const Color(0xFFE11D48)
                                          : const Color(0xFF7C3AED),
                                      size: 24,
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
              ],
            ),
          ),

          // Center on user button
          Positioned(
            right: 16,
            bottom: 190,
            child: FloatingActionButton(
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
              bottom: 180,
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
      builder: (context) => _BusinessDetailSheet(
        business: business,
        formatDistance: _formatDistance,
      ),
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
              Container(
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
  final Business business;
  final String Function(double) formatDistance;

  const _BusinessDetailSheet({
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
                          Container(
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
                          _showJobDetails(context, job);
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

  void _showJobDetails(BuildContext context, Job job) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _JobDetailSheet(job: job),
    );
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
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: job.companyColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      job.companyInitial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
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
class NotificationsTab extends StatelessWidget {
  const NotificationsTab({super.key});

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
            onPressed: () {},
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
      body: Center(
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
      ),
    );
  }
}

