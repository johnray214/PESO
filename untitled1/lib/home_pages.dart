import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'profile_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'job_models.dart';
import 'event_models.dart';
import 'user_session.dart';
import 'api_service.dart';
import 'job_action_service.dart';

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


// ─── Home Page with Bottom Navigation ────────────────────────────────────────
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final Future<Map<String, dynamic>> _eventsFuture = ApiService.getEvents();

  final List<Widget> _pages = [
    const HomeTab(),
    const MapTab(),
    const ProfileTab(),
  ];

  void _showEventDetailModal(BuildContext context, PesoEvent e) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
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
                        e.typeLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(ctx).pop(),
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
                  e.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 16),
                _detailRow(Icons.calendar_today_rounded, e.formattedDate),
                if (e.eventTime != null) _detailRow(Icons.access_time_rounded, e.eventTime!),
                _detailRow(Icons.location_on_rounded, e.location),
                if (e.organizer != null) _detailRow(Icons.business_rounded, e.organizer!),
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
                  e.description,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) {
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

  void _showEventsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.75,
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
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
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
                  future: _eventsFuture,
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
                    final raw = data['data'] as List<dynamic>? ?? [];
                    final events = raw
                        .map((e) => PesoEvent.fromJson(e as Map<String, dynamic>))
                        .toList();
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
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _showEventDetailModal(context, e),
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
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
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF2563EB),
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          e.formattedDate,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
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
                                        Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            e.location,
                                            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          _pages[_selectedIndex],
          // Floating Events button on homepage (bottom right, above nav bar)
          if (_selectedIndex == 0)
            Positioned(
              right: 20,
              bottom: bottomPadding + 92,
              child: FutureBuilder<Map<String, dynamic>>(
                future: _eventsFuture,
                builder: (context, snapshot) {
                  final count = snapshot.hasData &&
                          snapshot.data!['success'] == true &&
                          snapshot.data!['data'] != null
                      ? (snapshot.data!['data'] as List).length
                      : 0;
                  return Material(
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
                  );
                },
              ),
            ),
          // Floating pill navigation bar
          Positioned(
            left: 20,
            right: 20,
            bottom: bottomPadding + 12,
            child: _buildFloatingNavBar(context),
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
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedScale(
        scale: isSelected ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.elasticOut,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected ? const Color(0xFF2563EB) : Colors.white.withOpacity(0.7),
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
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';
  String _sortOption = 'Latest';
  final Set<String> _selectedEmploymentTypes = {};
  final Set<String> _selectedCategories = {};

  List<Job> _jobs = [];
  bool _isLoading = true;
  String? _errorMessage;
  final _jobActionService = JobActionService();
  List<int>? _avatarBytes;

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
  static const List<String> _categories = [
    'IT & Software',
    'Healthcare',
    'Education',
    'Construction',
    'Sales & Marketing',
    'Manufacturing',
  ];

  @override
  void initState() {
    super.initState();
    _fetchJobs();
    _loadAvatar();
    _jobActionService.addListener(_onJobActionsChanged);
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
    _jobActionService.removeListener(_onJobActionsChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationsTab()),
    );
  }

  String _getPhilippinesGreeting() => '${getPhilippinesGreeting()},';

  Future<void> _fetchJobs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final result = await ApiService.getJobListings();
    if (!mounted) return;
    if (result['success'] == true) {
      final rawList = result['data'] as List<dynamic>? ?? [];
      setState(() {
        _jobs = rawList
            .map((e) => Job.fromJson(e as Map<String, dynamic>))
            .toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = result['message'] as String? ?? 'Failed to load jobs.';
        _isLoading = false;
      });
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('Applied to ${job.title}!'),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<void> _toggleSaveJob(Job job) async {
    final wasSaved = _jobActionService.isSaved(job.id);
    final error = await _jobActionService.toggleSave(job.id);
    if (!mounted) return;

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(wasSaved
              ? 'Job removed from saved.'
              : 'Job saved successfully.'),
          backgroundColor: wasSaved
              ? const Color(0xFF64748B)
              : const Color(0xFF2563EB),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
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

      final matchesType = _selectedEmploymentTypes.isEmpty ||
          _selectedEmploymentTypes.contains(job.employmentType);

      final matchesCategory = _selectedCategories.isEmpty ||
          (job.category != null && _selectedCategories.contains(job.category));

      return matchesSearch && matchesType && matchesCategory;
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
      _selectedEmploymentTypes.isNotEmpty || _selectedCategories.isNotEmpty;

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
                            _selectedCategories.clear();
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
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF2563EB)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Text(
                            type,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Category',
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
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategories.contains(cat);
                      return GestureDetector(
                        onTap: () {
                          setSheetState(() {
                            if (isSelected) {
                              _selectedCategories.remove(cat);
                            } else {
                              _selectedCategories.add(cat);
                            }
                          });
                          setState(() {});
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF0F172A)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 28),
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
        backgroundColor: Color(0xFFF8FAFC),
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
        backgroundColor: const Color(0xFFF8FAFC),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Header: avatar + greeting + name + notifications bell
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Avatar
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: _avatarBytes != null && _avatarBytes!.isNotEmpty
                              ? Image.memory(
                                  Uint8List.fromList(_avatarBytes!),
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                )
                              : Center(
                                  child: Text(
                                    UserSession().initials,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Greeting + name
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getPhilippinesGreeting(),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF94A3B8),
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              UserSession().displayName,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Notifications bell
                      IconButton(
                        onPressed: _openNotifications,
                        icon: const Icon(
                          Icons.notifications_none_rounded,
                          color: Color(0xFF0F172A),
                          size: 26,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  // Big title above search bar
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Find a job',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Search bar
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: TextField(
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
                            color: _hasActiveFilters
                                ? const Color(0xFF2563EB)
                                : const Color(0xFF2563EB),
                            borderRadius: BorderRadius.circular(14),
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
                        border: Border.all(color: const Color(0xFFE2E8F0)),
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
                onRefresh: _fetchJobs,
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
                            job: job,
                            formattedDate: _formatDate(job.postedDate),
                            isSaved: isSaved,
                            isApplied: isApplied,
                            onTap: () => _showJobDetails(context, job),
                            onSave: () => _toggleSaveJob(job),
                            onApply: () => _applyToJob(job),
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
    );
  }
}

// ─── Job Card Widget ──────────────────────────────────────────────────────────
class _JobCard extends StatelessWidget {
  final Job job;
  final String formattedDate;
  final VoidCallback onTap;
  final VoidCallback onSave;
  final VoidCallback onApply;
  final bool isSaved;
  final bool isApplied;

  const _JobCard({
    required this.job,
    required this.formattedDate,
    required this.onTap,
    required this.onSave,
    required this.onApply,
    required this.isSaved,
    required this.isApplied,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          // ambient shadow
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
          // key light shadow
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.06),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
          // top highlight
          const BoxShadow(
            color: Colors.white,
            blurRadius: 0,
            spreadRadius: 0,
            offset: Offset(0, -1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
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
                        // Company icon with glow
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                job.companyColor,
                                job.companyColor.withOpacity(0.75),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: job.companyColor.withOpacity(0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 5),
                              ),
                            ],
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
                        // Match percentage badge
                        if (job.matchPercentage > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF10B981), Color(0xFF059669)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF10B981).withOpacity(0.35),
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
                          onTap: onSave,
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
                        const SizedBox(width: 10),
                        // Apply button
                        Expanded(
                          child: GestureDetector(
                            onTap: isApplied ? null : onApply,
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

  @override
  void initState() {
    super.initState();
    _loadBusinessesFromApi();
  }

  Future<void> _loadBusinessesFromApi() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.getJobListings();
      if (response['success'] == true) {
        final raw = response['data'] as List<dynamic>? ?? [];
        final jobs = raw
            .map((e) => Job.fromJson(e as Map<String, dynamic>))
            .where((job) => job.latitude != null && job.longitude != null)
            .toList();

        // For now, treat each job as a "business" marker
        final businesses = jobs
            .map(
              (job) => Business(
                id: 'job_${job.id}',
                name: job.company,
                description: job.title,
                imageUrl: '',
                latitude: job.latitude!,
                longitude: job.longitude!,
                availableJobs: [job],
              ),
            )
            .toList();

        setState(() {
          _allBusinesses = businesses;
          _filteredBusinesses = businesses;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              response['message'] as String? ?? 'Failed to load jobs.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load jobs.';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
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
                Padding(
                  padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 80),
                  child: SizedBox(
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
                ),
              ],
            ),
          ),

          // Center on user button
          Positioned(
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 260,
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
    final jobActionService = JobActionService();
    showJobDetailSheet(
      context,
      job,
      isSaved: jobActionService.isSaved(job.id),
      isApplied: jobActionService.isApplied(job.id),
      onSave: () => jobActionService.toggleSave(job.id),
      onApply: () => _applyFromBusinessDetail(context, job, jobActionService),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text('Applied to ${job.title}!'),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
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

