import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'api_service.dart';
import 'home_pages.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const PESOApp());
}

// ─── Color Palette ───────────────────────────────────────────────────────────
class AppColors {
  static const blueAccent = Color(0xFF2563EB);
  static const blueLight = Color(0xFF3B82F6);
  static const textPrimary = Color(0xFF0F172A);
  static const textMuted = Color(0xFF64748B);
  static const divider = Color(0xFFE2E8F0);
  static const pageBackground = Color(0xFFF4F7FB);
  static const navyMid = Color(0xFF112240);
  static const navyLight = Color(0xFF1D3461);
}

// ─── App ─────────────────────────────────────────────────────────────────────
class PESOApp extends StatelessWidget {
  const PESOApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PESO Santiago City',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.blueAccent,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const WelcomePage(),
    );
  }
}

// ─── Welcome Page ─────────────────────────────────────────────────────────────
class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));

    _fadeIn = CurvedAnimation(
        parent: _ctrl, curve: const Interval(0.0, 0.7, curve: Curves.easeOut));

    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic)));

    _logoFade = CurvedAnimation(
        parent: _ctrl, curve: const Interval(0.1, 0.6, curve: Curves.easeOut));

    _logoScale = Tween<double>(begin: 0.88, end: 1.0).animate(CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.1, 0.65, curve: Curves.easeOutBack)));

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return Stack(
            children: [
              Positioned(
                top: -size.width * 0.35,
                right: -size.width * 0.2,
                child: Container(
                  width: size.width * 0.85,
                  height: size.width * 0.85,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFDDE8F5),
                  ),
                ),
              ),
              Positioned(
                bottom: -size.width * 0.15,
                left: -size.width * 0.1,
                child: Container(
                  width: size.width * 0.5,
                  height: size.width * 0.5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.blueAccent.withOpacity(0.06),
                  ),
                ),
              ),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            FadeTransition(
                              opacity: _logoFade,
                              child: SlideTransition(
                                position: _slideUp,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 7),
                                      decoration: BoxDecoration(
                                        color: AppColors.blueAccent.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      child: const Text(
                                        'PUBLIC EMPLOYMENT SERVICE OFFICE',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.blueAccent,
                                          letterSpacing: 1.5,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        ScaleTransition(
                                          scale: _logoScale,
                                          child: Container(
                                            width: size.width * 0.24,
                                            height: size.width * 0.24,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.white,
                                              border: Border.all(
                                                color: AppColors.divider,
                                                width: 1.5,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.07),
                                                  blurRadius: 16,
                                                  offset: const Offset(0, 5),
                                                ),
                                              ],
                                            ),
                                            child: ClipOval(
                                              child: Image.asset(
                                                'assets/PESOLOGO.jpg',
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          margin: const EdgeInsets.symmetric(horizontal: 20),
                                          width: 1.5,
                                          height: size.width * 0.16,
                                          decoration: BoxDecoration(
                                            color: AppColors.blueAccent.withOpacity(0.25),
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        ),
                                        Text(
                                          'PESO',
                                          style: TextStyle(
                                            fontSize: size.width * 0.15,
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.textPrimary,
                                            letterSpacing: size.width * 0.018,
                                            height: 1.0,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            FadeTransition(
                              opacity: _fadeIn,
                              child: const Text(
                                'SERBISYONG TAPAT  ·  SERBISYONG KABSAT',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textMuted,
                                  letterSpacing: 2.2,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            FadeTransition(
                              opacity: _fadeIn,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 13),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(50),
                                  border: Border.all(color: AppColors.divider, width: 1.2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.location_on_outlined,
                                        color: AppColors.blueAccent, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      'City of Santiago, Isabela',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary.withOpacity(0.8),
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            FadeTransition(
                              opacity: _fadeIn,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildFeaturePill(Icons.work_outline_rounded, 'Find Jobs'),
                                  const SizedBox(width: 10),
                                  _buildFeaturePill(Icons.people_outline_rounded, 'Connect'),
                                  const SizedBox(width: 10),
                                  _buildFeaturePill(Icons.trending_up_rounded, 'Grow'),
                                ],
                              ),
                            ),
                            SlideTransition(
                              position: _slideUp,
                              child: FadeTransition(
                                opacity: _fadeIn,
                                child: _GetStartedButton(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const AboutPage()),
                                    );
                                  },
                                ),
                              ),
                            ),
                            FadeTransition(
                              opacity: _fadeIn,
                              child: Column(
                                children: [
                                  Text(
                                    'POWERED BY DOLE  ·  EST. 1999',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textMuted.withOpacity(0.5),
                                      letterSpacing: 1.8,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'v1.0.0',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: AppColors.textMuted.withOpacity(0.35),
                                      letterSpacing: 1.2,
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
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFeaturePill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.divider, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.blueAccent, size: 15),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Get Started Button ───────────────────────────────────────────────────────
class _GetStartedButton extends StatefulWidget {
  final VoidCallback onTap;
  const _GetStartedButton({required this.onTap});

  @override
  State<_GetStartedButton> createState() => _GetStartedButtonState();
}

class _GetStartedButtonState extends State<_GetStartedButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          height: 58,
          decoration: BoxDecoration(
            color: AppColors.blueAccent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.blueAccent.withOpacity(_pressed ? 0.15 : 0.28),
                blurRadius: _pressed ? 8 : 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'GET STARTED',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 2.5,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_forward_rounded,
                    color: Colors.white, size: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── About Page ───────────────────────────────────────────────────────────────
class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  final ScrollController _scrollController = ScrollController();
  bool _hasShownLoginModal = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 50 &&
        !_hasShownLoginModal) {
      _hasShownLoginModal = true;
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _showLoginModal(context);
      });
    }
  }

  void _showLoginModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const LoginModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF5F7FA), Color(0xFFE8F0F8), Colors.white],
            stops: [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.navyMid.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back_rounded,
                            color: AppColors.navyMid, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'About PESO',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navyMid,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showLoginModal(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.navyMid, AppColors.navyLight],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.navyMid.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.login_rounded, color: Colors.white, size: 18),
                            SizedBox(width: 6),
                            Text('Login',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      _buildSectionCard(
                        title: 'What is PESO?',
                        icon: Icons.info_outline_rounded,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoItem('A non-fee charging employment service facility', Icons.check_circle_outline_rounded),
                            const SizedBox(height: 12),
                            _buildInfoItem('Established under Republic Act No. 8759 (PESO Act of 1999)', Icons.gavel_rounded),
                            const SizedBox(height: 12),
                            _buildInfoItem('Operates at the local government level', Icons.location_city_rounded),
                            const SizedBox(height: 12),
                            _buildInfoItem('Managed by the Department of Labor and Employment (DOLE)', Icons.business_center_rounded),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildSectionCard(
                        title: 'Core Services',
                        icon: Icons.work_outline_rounded,
                        child: Column(
                          children: [
                            _buildServiceCard(icon: Icons.search_rounded, title: 'Job Referral & Placement', description: 'Matches job seekers with employers locally and abroad.'),
                            const SizedBox(height: 16),
                            _buildServiceCard(icon: Icons.school_outlined, title: 'Career Guidance', description: 'Provides counseling, career planning, and job search strategies.'),
                            const SizedBox(height: 16),
                            _buildServiceCard(icon: Icons.trending_up_rounded, title: 'Skills Training', description: 'Offers training programs to enhance employability.'),
                            const SizedBox(height: 16),
                            _buildServiceCard(icon: Icons.event_rounded, title: 'Job Fairs', description: 'Organizes events to connect job seekers with hiring companies.'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildSectionCard(
                        title: 'Target Beneficiaries',
                        icon: Icons.groups_rounded,
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _buildBeneficiaryChip('Fresh Graduates'),
                            _buildBeneficiaryChip('Skilled Workers'),
                            _buildBeneficiaryChip('Professionals'),
                            _buildBeneficiaryChip('Displaced Workers'),
                            _buildBeneficiaryChip('Students & Youth'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: AppColors.navyMid.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: AppColors.navyMid, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navyMid,
                        letterSpacing: 0.5)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoItem(String text, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.navyLight, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2C3E50),
                  height: 1.5)),
        ),
      ],
    );
  }

  Widget _buildServiceCard({required IconData icon, required String title, required String description}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.navyMid.withOpacity(0.1), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: AppColors.navyLight.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: AppColors.navyLight, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.navyMid)),
                const SizedBox(height: 6),
                Text(description, style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBeneficiaryChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.navyLight.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.navyLight.withOpacity(0.25)),
      ),
      child: Text(text,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.navyMid)),
    );
  }
}

// ─── Login Modal ──────────────────────────────────────────────────────────────
class LoginModal extends StatefulWidget {
  final bool isSignUp;
  const LoginModal({super.key, this.isSignUp = false});

  @override
  State<LoginModal> createState() => _LoginModalState();
}

class _LoginModalState extends State<LoginModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _ageController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSignUpMode = false;
  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    _isSignUpMode = widget.isSignUp;
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _animationController, curve: Curves.easeOutCubic));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _switchMode() {
    setState(() {
      _isSignUpMode = !_isSignUpMode;
      _formKey.currentState?.reset();
    });
  }

  Future<void> _handleRegistration() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _RegistrationLoadingDialog(),
    );

    final result = await ApiService.register(
      name: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      passwordConfirmation: _confirmPasswordController.text,
      age: int.tryParse(_ageController.text),
      gender: _selectedGender,
    );

    Navigator.pop(context);

    if (result['success'] == true) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const _RegistrationResultDialog(
          isSuccess: true,
          message: 'Account created successfully!',
        ),
      );

      _nameController.clear();
      _emailController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
      _ageController.clear();
      setState(() {
        _selectedGender = null;
        _isSignUpMode = false;
      });
    } else {
      String errorMessage = 'Registration failed';
      if (result['message'] != null) {
        errorMessage = result['message'];
      } else if (result['errors'] != null) {
        final errors = result['errors'] as Map<String, dynamic>;
        final errorList = <String>[];
        errors.forEach((key, value) {
          if (value is List && value.isNotEmpty) {
            errorList.add(value.first.toString());
          }
        });
        if (errorList.isNotEmpty) {
          errorMessage = errorList.join('\n');
        }
      }

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _RegistrationResultDialog(
          isSuccess: false,
          message: errorMessage,
        ),
      );
    }
  }

  InputDecoration _fieldDec(String label, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
      prefixIcon: Icon(icon, color: const Color(0xFF2563EB)),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF8F9FA),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[300]!)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[300]!)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              left: 24,
              right: 24,
              top: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12)),
                      child: Icon(
                          _isSignUpMode
                              ? Icons.person_add_rounded
                              : Icons.login_rounded,
                          color: const Color(0xFF2563EB),
                          size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        _isSignUpMode ? 'Create Account' : 'Welcome Back',
                        style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            letterSpacing: 0.5),
                      ),
                    ),
                    IconButton(
                        icon: const Icon(Icons.close_rounded),
                        color: Colors.grey[600],
                        onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _isSignUpMode
                        ? 'Join PESO and discover employment opportunities'
                        : 'Sign in to access your account',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ),
                const SizedBox(height: 32),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_isSignUpMode) ...[
                        TextFormField(
                          controller: _nameController,
                          decoration: _fieldDec('Full Name', Icons.person_outline_rounded),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Please enter your full name';
                            if (v.length < 3) return 'Name must be at least 3 characters';
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                      ],
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _fieldDec(
                            _isSignUpMode ? 'Email' : 'Email or Username',
                            Icons.email_outlined),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return _isSignUpMode ? 'Please enter your email' : 'Please enter your email or username';
                          }
                          if (_isSignUpMode && (!v.contains('@') || !v.contains('.'))) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: _fieldDec(
                          'Password',
                          Icons.lock_outline_rounded,
                          suffix: IconButton(
                            icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: Colors.grey[600]),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Please enter your password';
                          if (v.length < 6) return 'Password must be at least 6 characters';
                          return null;
                        },
                      ),
                      if (_isSignUpMode) ...[
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          decoration: _fieldDec(
                            'Confirm Password',
                            Icons.lock_outline_rounded,
                            suffix: IconButton(
                              icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: Colors.grey[600]),
                              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Please confirm your password';
                            if (v != _passwordController.text) return 'Passwords do not match';
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _ageController,
                                keyboardType: TextInputType.number,
                                decoration: _fieldDec('Age', Icons.cake_outlined),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Enter age';
                                  final age = int.tryParse(v);
                                  if (age == null || age < 15 || age > 120) return 'Invalid';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<String>(
                                value: _selectedGender,
                                decoration: _fieldDec('Sex', Icons.person_outline),
                                items: ['Male', 'Female', 'Other'].map((gender) {
                                  return DropdownMenuItem(value: gender, child: Text(gender));
                                }).toList(),
                                onChanged: (value) => setState(() => _selectedGender = value),
                                validator: (v) => v == null ? 'Select' : null,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              if (_isSignUpMode) {
                                await _handleRegistration();
                              } else {
                                final result = await ApiService.login(
                                  email: _emailController.text,
                                  password: _passwordController.text,
                                );

                                if (result['success'] == true) {
                                  Navigator.pop(context);
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (context) => const HomePage()),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(result['message'] ?? 'Login failed'),
                                      backgroundColor: Colors.red,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  );
                                }
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: Text(
                            _isSignUpMode ? 'Sign Up' : 'Sign In',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                              _isSignUpMode
                                  ? 'Already have an account? '
                                  : "Don't have an account? ",
                              style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                          TextButton(
                            onPressed: _switchMode,
                            child: Text(_isSignUpMode ? 'Sign In' : 'Sign Up',
                                style: const TextStyle(
                                    color: Color(0xFF2563EB),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14)),
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
      ),
    );
  }
}

// ─── Registration Loading Dialog ─────────────────────────────────────────────
class _RegistrationLoadingDialog extends StatefulWidget {
  const _RegistrationLoadingDialog();

  @override
  State<_RegistrationLoadingDialog> createState() => _RegistrationLoadingDialogState();
}

class _RegistrationLoadingDialogState extends State<_RegistrationLoadingDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 30, offset: const Offset(0, 10))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _controller.value * 2 * 3.14159,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE2E8F0), width: 4),
                        ),
                        child: CustomPaint(
                          painter: _LoadingArcPainter(color: const Color(0xFF2563EB), strokeWidth: 4),
                        ),
                      ),
                    );
                  },
                ),
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                  ),
                  child: ClipOval(child: Image.asset('assets/PESOLOGO.jpg', fit: BoxFit.cover)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Creating your account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
            const SizedBox(height: 8),
            Text('Please wait...', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}

class _LoadingArcPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _LoadingArcPainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawArc(rect, 0, 1.5, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Registration Result Dialog ──────────────────────────────────────────────
class _RegistrationResultDialog extends StatefulWidget {
  final bool isSuccess;
  final String message;

  const _RegistrationResultDialog({required this.isSuccess, required this.message});

  @override
  State<_RegistrationResultDialog> createState() => _RegistrationResultDialogState();
}

class _RegistrationResultDialogState extends State<_RegistrationResultDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeOut)),
    );
    _controller.forward();

    if (widget.isSuccess) {
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) Navigator.pop(context);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 30, offset: const Offset(0, 10))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
                    ),
                    child: ClipOval(child: Image.asset('assets/PESOLOGO.jpg', fit: BoxFit.cover)),
                  ),
                  const SizedBox(height: 20),
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.isSuccess
                            ? const Color(0xFF10B981).withOpacity(0.1)
                            : const Color(0xFFEF4444).withOpacity(0.1),
                      ),
                      child: Icon(
                        widget.isSuccess ? Icons.check_circle_rounded : Icons.cancel_rounded,
                        size: 50,
                        color: widget.isSuccess ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.isSuccess ? 'Success!' : 'Registration Failed',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: widget.isSuccess ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5),
                  ),
                  if (!widget.isSuccess) ...[
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text('Try Again', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
