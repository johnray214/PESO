import 'package:flutter/material.dart';
import 'dart:math' as math;

void main() {
  runApp(const PESOApp());
}

class PESOApp extends StatelessWidget {
  const PESOApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PESO of Santiago City',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E5C8A),
          primary: const Color(0xFF2E5C8A),
          secondary: const Color(0xFF1E88E5),
          surface: Colors.white,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const WelcomePage(),
    );
  }
}

// ─── Subtle geometric background painter ───────────────────────────────────
class GeometricBackgroundPainter extends CustomPainter {
  final double opacity;
  GeometricBackgroundPainter({this.opacity = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2E5C8A).withOpacity(0.035 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Diagonal lines
    for (double i = -size.height; i < size.width + size.height; i += 48) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }

    // Dot grid
    final dotPaint = Paint()
      ..color = const Color(0xFF1E88E5).withOpacity(0.07 * opacity)
      ..style = PaintingStyle.fill;

    for (double x = 0; x < size.width; x += 36) {
      for (double y = 0; y < size.height; y += 36) {
        canvas.drawCircle(Offset(x, y), 1.5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(GeometricBackgroundPainter oldDelegate) =>
      oldDelegate.opacity != opacity;
}

// ─── Animated glow ring around the logo ────────────────────────────────────
class GlowRingPainter extends CustomPainter {
  final double animationValue;
  GlowRingPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Rotating gradient arc
    final paint = Paint()
      ..shader = SweepGradient(
        startAngle: animationValue * 2 * math.pi,
        endAngle: animationValue * 2 * math.pi + math.pi,
        colors: [
          const Color(0xFF1E88E5).withOpacity(0.0),
          const Color(0xFF1E88E5).withOpacity(0.6),
          const Color(0xFF2E5C8A).withOpacity(0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawCircle(center, radius - 2, paint);

    // Soft pulse ring
    final pulsePaint = Paint()
      ..color = const Color(0xFF1E88E5)
          .withOpacity(0.15 * (1 - (animationValue % 1)))
      ..style = PaintingStyle.stroke
      ..strokeWidth = (1 - (animationValue % 1)) * 12
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawCircle(center, radius + (animationValue % 1) * 20, pulsePaint);
  }

  @override
  bool shouldRepaint(GlowRingPainter old) => true;
}

// ─── Welcome Page ───────────────────────────────────────────────────────────
class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with TickerProviderStateMixin {
  // Staggered entrance animations
  late AnimationController _entranceController;
  late AnimationController _glowController;
  late AnimationController _buttonBounceController;
  late AnimationController _bgController;

  late Animation<double> _bgFade;

  // Individual element animations
  late Animation<double> _logoFade;
  late Animation<Offset> _logoSlide;

  late Animation<double> _titleFade;
  late Animation<Offset> _titleSlide;

  late Animation<double> _taglineFade;
  late Animation<Offset> _taglineSlide;

  late Animation<double> _locationFade;
  late Animation<Offset> _locationSlide;

  late Animation<double> _iconsFade;
  late Animation<Offset> _iconsSlide;

  late Animation<double> _buttonFade;
  late Animation<Offset> _buttonSlide;

  late Animation<double> _footerFade;

  late Animation<double> _glowAnim;
  late Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();

    // Background fade
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _bgFade = CurvedAnimation(parent: _bgController, curve: Curves.easeIn);
    _bgController.forward();

    // Staggered entrance (total 1400ms)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _logoFade = _buildFade(0.0, 0.25);
    _logoSlide = _buildSlide(0.0, 0.25);

    _titleFade = _buildFade(0.18, 0.42);
    _titleSlide = _buildSlide(0.18, 0.42);

    _taglineFade = _buildFade(0.32, 0.55);
    _taglineSlide = _buildSlide(0.32, 0.55);

    _locationFade = _buildFade(0.44, 0.66);
    _locationSlide = _buildSlide(0.44, 0.66);

    _iconsFade = _buildFade(0.56, 0.78);
    _iconsSlide = _buildSlide(0.56, 0.78);

    _buttonFade = _buildFade(0.68, 0.88);
    _buttonSlide = _buildSlide(0.68, 0.88);

    _footerFade = _buildFade(0.80, 1.0);

    _entranceController.forward();

    // Glow ring rotation (loop)
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _glowAnim = Tween<double>(begin: 0, end: 1).animate(_glowController);

    // Button bounce hint (delay, then subtle pulse)
    _buttonBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _bounceAnim = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(
          parent: _buttonBounceController, curve: Curves.easeInOut),
    );

    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) {
        _buttonBounceController.repeat(reverse: true);
      }
    });
  }

  Animation<double> _buildFade(double start, double end) {
    return CurvedAnimation(
      parent: _entranceController,
      curve: Interval(start, end, curve: Curves.easeOut),
    );
  }

  Animation<Offset> _buildSlide(double start, double end) {
    return Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    ));
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _glowController.dispose();
    _buttonBounceController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: FadeTransition(
        opacity: _bgFade,
        child: Stack(
          children: [
            // ── Gradient background ──
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFECF3FB),
                    Color(0xFFDCEAF8),
                    Color(0xFFF0F6FF),
                    Colors.white,
                  ],
                  stops: [0.0, 0.3, 0.65, 1.0],
                ),
              ),
            ),

            // ── Geometric texture overlay ──
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _bgFade,
                builder: (context, _) => CustomPaint(
                  painter: GeometricBackgroundPainter(opacity: _bgFade.value),
                ),
              ),
            ),

            // ── Main content ──
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0),
                  child: Column(
                    children: [
                      SizedBox(height: size.height * 0.08),

                      // ── Logo with animated glow ring ──
                      FadeTransition(
                        opacity: _logoFade,
                        child: SlideTransition(
                          position: _logoSlide,
                          child: SizedBox(
                            width: 190,
                            height: 190,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Animated glow ring
                                AnimatedBuilder(
                                  animation: _glowAnim,
                                  builder: (context, _) => CustomPaint(
                                    size: const Size(190, 190),
                                    painter: GlowRingPainter(_glowAnim.value),
                                  ),
                                ),
                                // Logo circle
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF2E5C8A)
                                            .withOpacity(0.12),
                                        blurRadius: 30,
                                        offset: const Offset(0, 15),
                                      ),
                                      BoxShadow(
                                        color: const Color(0xFF1E88E5)
                                            .withOpacity(0.08),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(
                                      'assets/PESOLOGO.jpg',
                                      width: 130,
                                      height: 130,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 44),

                      // ── Title section ──
                      FadeTransition(
                        opacity: _titleFade,
                        child: SlideTransition(
                          position: _titleSlide,
                          child: Column(
                            children: [
                              // "Public Employment Service Office" ABOVE as label
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E88E5).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color:
                                        const Color(0xFF1E88E5).withOpacity(0.25),
                                  ),
                                ),
                                child: const Text(
                                  'Public Employment Service Office',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1E88E5),
                                    letterSpacing: 1.2,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // "PESO" gradient title
                              ShaderMask(
                                shaderCallback: (bounds) =>
                                    const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF2E5C8A),
                                    Color(0xFF1E88E5)
                                  ],
                                ).createShader(bounds),
                                child: const Text(
                                  'PESO',
                                  style: TextStyle(
                                    fontSize: 52,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 4.0,
                                    height: 1.1,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),

                              const SizedBox(height: 10),
                              // Divider accent
                              Container(
                                width: 80,
                                height: 3,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF2E5C8A),
                                      Color(0xFF1E88E5)
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Tagline ──
                      FadeTransition(
                        opacity: _taglineFade,
                        child: SlideTransition(
                          position: _taglineSlide,
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: const TextSpan(
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2E5C8A),
                                letterSpacing: 2.5,
                              ),
                              children: [
                                TextSpan(text: 'SERBISYONG '),
                                TextSpan(
                                  text: 'TAPAT',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF64B5F6),
                                    letterSpacing: 2.5,
                                  ),
                                ),
                                TextSpan(text: ', SERBISYONG '),
                                TextSpan(
                                  text: 'KABSAT',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF64B5F6),
                                    letterSpacing: 2.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── Location Badge ──
                      FadeTransition(
                        opacity: _locationFade,
                        child: SlideTransition(
                          position: _locationSlide,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color:
                                    const Color(0xFF2E5C8A).withOpacity(0.15),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.location_on_rounded,
                                  color: Color(0xFF2E5C8A),
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'City of Santiago, Isabela',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2E5C8A),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: size.height * 0.06),

                      // ── Feature Icons with labels ──
                      FadeTransition(
                        opacity: _iconsFade,
                        child: SlideTransition(
                          position: _iconsSlide,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildFeatureIcon(
                                icon: Icons.work_outline_rounded,
                                color: const Color(0xFF1E88E5),
                                label: 'Find Jobs',
                              ),
                              _buildFeatureIcon(
                                icon: Icons.people_outline_rounded,
                                color: const Color(0xFF2E5C8A),
                                label: 'Connect',
                              ),
                              _buildFeatureIcon(
                                icon: Icons.handshake_outlined,
                                color: const Color(0xFF1E88E5),
                                label: 'Grow',
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: size.height * 0.05),

                      // ── Get Started Button (with bounce hint) ──
                      FadeTransition(
                        opacity: _buttonFade,
                        child: SlideTransition(
                          position: _buttonSlide,
                          child: AnimatedBuilder(
                            animation: _bounceAnim,
                            builder: (context, child) => Transform.scale(
                              scale: _bounceAnim.value,
                              child: child,
                            ),
                            child: Container(
                              width: double.infinity,
                              height: 60,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF2E5C8A),
                                    Color(0xFF1E88E5)
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF2E5C8A)
                                        .withOpacity(0.35),
                                    blurRadius: 22,
                                    offset: const Offset(0, 10),
                                  ),
                                  BoxShadow(
                                    color: const Color(0xFF1E88E5)
                                        .withOpacity(0.2),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    _buttonBounceController.stop();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const AboutPage(),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(18),
                                  splashColor:
                                      Colors.white.withOpacity(0.15),
                                  highlightColor:
                                      Colors.white.withOpacity(0.08),
                                  child: Container(
                                    alignment: Alignment.center,
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Get Started',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            letterSpacing: 1.0,
                                          ),
                                        ),
                                        SizedBox(width: 10),
                                        Icon(
                                          Icons.arrow_forward_rounded,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── Footer attribution ──
                      FadeTransition(
                        opacity: _footerFade,
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 40,
                                  height: 1,
                                  color: const Color(0xFF2E5C8A)
                                      .withOpacity(0.2),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Powered by DOLE  •  Serving since 1999',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF2E5C8A)
                                        .withOpacity(0.5),
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  width: 40,
                                  height: 1,
                                  color: const Color(0xFF2E5C8A)
                                      .withOpacity(0.2),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'v1.0.0',
                              style: TextStyle(
                                fontSize: 10,
                                color: const Color(0xFF2E5C8A)
                                    .withOpacity(0.3),
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),
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

  Widget _buildFeatureIcon({
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.25), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: color, size: 32),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2E5C8A).withOpacity(0.75),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

// ─── About Page (unchanged) ─────────────────────────────────────────────────
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
        if (mounted) {
          _showLoginModal(context);
        }
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFF5F7FA),
              const Color(0xFFE8F0F8),
              Colors.white,
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: const Color(0xFF2E5C8A),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'About PESO',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2E5C8A),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF2E5C8A), Color(0xFF1E88E5)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2E5C8A).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _showLoginModal(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.login_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Login',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
                            _buildInfoItem(
                              'A non-fee charging employment service facility',
                              Icons.check_circle_outline_rounded,
                            ),
                            const SizedBox(height: 12),
                            _buildInfoItem(
                              'Established under Republic Act No. 8759 (PESO Act of 1999)',
                              Icons.gavel_rounded,
                            ),
                            const SizedBox(height: 12),
                            _buildInfoItem(
                              'Operates at the local government level (provinces, cities, municipalities, and barangays)',
                              Icons.location_city_rounded,
                            ),
                            const SizedBox(height: 12),
                            _buildInfoItem(
                              'Managed by the Department of Labor and Employment (DOLE)',
                              Icons.business_center_rounded,
                            ),
                            const SizedBox(height: 12),
                            _buildInfoItem(
                              'Goal: Facilitate full employment and equal opportunities for Filipino workers',
                              Icons.flag_rounded,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildSectionCard(
                        title: 'Core Services',
                        icon: Icons.work_outline_rounded,
                        child: Column(
                          children: [
                            _buildServiceCard(
                              icon: Icons.search_rounded,
                              title: 'Job Referral & Placement',
                              description:
                                  'Matches job seekers with employers locally and abroad.',
                            ),
                            const SizedBox(height: 16),
                            _buildServiceCard(
                              icon: Icons.school_outlined,
                              title: 'Career Guidance & Coaching',
                              description:
                                  'Provides counseling, career planning, and job search strategies.',
                            ),
                            const SizedBox(height: 16),
                            _buildServiceCard(
                              icon: Icons.trending_up_rounded,
                              title: 'Skills Training & Development',
                              description:
                                  'Offers training programs to enhance employability, often in partnership with TESDA and other agencies.',
                            ),
                            const SizedBox(height: 16),
                            _buildServiceCard(
                              icon: Icons.analytics_outlined,
                              title: 'Labor Market Information (LMI)',
                              description:
                                  'Supplies data on job vacancies, skills demand, and employment trends.',
                            ),
                            const SizedBox(height: 16),
                            _buildServiceCard(
                              icon: Icons.support_agent_rounded,
                              title: 'Special Programs for Displaced Workers',
                              description:
                                  'Assists retrenched or displaced workers in finding new employment.',
                            ),
                            const SizedBox(height: 16),
                            _buildServiceCard(
                              icon: Icons.business_rounded,
                              title: 'Technical Assistance to LGUs & Employers',
                              description:
                                  'Helps local governments and businesses with employment-related programs.',
                            ),
                            const SizedBox(height: 16),
                            _buildServiceCard(
                              icon: Icons.event_rounded,
                              title: 'Job Fairs & Recruitment Events',
                              description:
                                  'Organizes events to connect job seekers directly with hiring companies.',
                            ),
                            const SizedBox(height: 16),
                            _buildServiceCard(
                              icon: Icons.flight_takeoff_rounded,
                              title: 'Overseas Employment Assistance',
                              description:
                                  'Coordinates with POEA/OWWA for overseas job opportunities.',
                            ),
                            const SizedBox(height: 16),
                            _buildServiceCard(
                              icon: Icons.people_outline_rounded,
                              title: 'Youth & Student Programs',
                              description:
                                  'Includes career guidance, job internships, and summer job programs.',
                            ),
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
                      const SizedBox(height: 24),
                      _buildSectionCard(
                        title: 'Why PESO Matters',
                        icon: Icons.favorite_outline_rounded,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color:
                                    const Color(0xFF2E5C8A).withOpacity(0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color:
                                      const Color(0xFF2E5C8A).withOpacity(0.1),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.link_rounded,
                                        color: const Color(0xFF2E5C8A),
                                        size: 24,
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Bridge Role',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF2E5C8A),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  _buildMatterItem(
                                    'Fair hiring practices (local hiring encouraged, fair wages promoted)',
                                  ),
                                  const SizedBox(height: 12),
                                  _buildMatterItem(
                                    'Accessible employment services at the community level',
                                  ),
                                  const SizedBox(height: 12),
                                  _buildMatterItem(
                                    'Economic growth by reducing unemployment and underemployment',
                                  ),
                                ],
                              ),
                            ),
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

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E5C8A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    Icon(icon, color: const Color(0xFF2E5C8A), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2E5C8A),
                    letterSpacing: 0.5,
                  ),
                ),
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
        Icon(icon, color: const Color(0xFF1E88E5), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2C3E50),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServiceCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF2E5C8A).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E88E5).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF1E88E5), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2E5C8A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
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
        color: const Color(0xFF1E88E5).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: const Color(0xFF1E88E5).withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2E5C8A),
        ),
      ),
    );
  }

  Widget _buildMatterItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 6),
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: Color(0xFF1E88E5),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Login Modal (unchanged) ────────────────────────────────────────────────
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
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSignUpMode = false;

  @override
  void initState() {
    super.initState();
    _isSignUpMode = widget.isSignUp;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _switchMode() {
    setState(() {
      _isSignUpMode = !_isSignUpMode;
      _formKey.currentState?.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.vertical(bottom: Radius.circular(30)),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E5C8A).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _isSignUpMode
                          ? Icons.person_add_rounded
                          : Icons.login_rounded,
                      color: const Color(0xFF2E5C8A),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _isSignUpMode ? 'Create Account' : 'Login to PESO',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2E5C8A),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    color: Colors.grey[600],
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _isSignUpMode
                    ? 'Join PESO and discover employment opportunities'
                    : 'Access your account to explore job opportunities',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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
                        keyboardType: TextInputType.name,
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          labelStyle: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                          prefixIcon: const Icon(
                            Icons.person_outline_rounded,
                            color: Color(0xFF2E5C8A),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8F9FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFF2E5C8A),
                              width: 2,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your full name';
                          }
                          if (value.length < 3) {
                            return 'Name must be at least 3 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: _isSignUpMode
                            ? 'Email'
                            : 'Email or Username',
                        labelStyle: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                        prefixIcon: Icon(
                          _isSignUpMode
                              ? Icons.email_outlined
                              : Icons.person_outline_rounded,
                          color: const Color(0xFF2E5C8A),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8F9FA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide:
                              BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide:
                              BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFF2E5C8A),
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return _isSignUpMode
                              ? 'Please enter your email'
                              : 'Please enter your email or username';
                        }
                        if (_isSignUpMode) {
                          if (!value.contains('@') ||
                              !value.contains('.')) {
                            return 'Please enter a valid email address';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                        prefixIcon: const Icon(
                          Icons.lock_outline_rounded,
                          color: Color(0xFF2E5C8A),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: Colors.grey[600],
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8F9FA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide:
                              BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide:
                              BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFF2E5C8A),
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    if (_isSignUpMode) ...[
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          labelStyle: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                          prefixIcon: const Icon(
                            Icons.lock_outline_rounded,
                            color: Color(0xFF2E5C8A),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: Colors.grey[600],
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8F9FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFF2E5C8A),
                              width: 2,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (!_isSignUpMode) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'Forgot password feature coming soon',
                                ),
                                backgroundColor:
                                    const Color(0xFF2E5C8A),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: Color(0xFF1E88E5),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF2E5C8A), Color(0xFF1E88E5)],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2E5C8A)
                                .withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            if (_formKey.currentState!.validate()) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    _isSignUpMode
                                        ? 'Account created successfully!'
                                        : 'Login successful!',
                                  ),
                                  backgroundColor:
                                      const Color(0xFF2E5C8A),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            }
                          },
                          borderRadius: BorderRadius.circular(18),
                          splashColor: Colors.white.withOpacity(0.15),
                          highlightColor: Colors.white.withOpacity(0.08),
                          child: Container(
                            alignment: Alignment.center,
                            child: Text(
                              _isSignUpMode ? 'Sign Up' : 'Login',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
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
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        TextButton(
                          onPressed: _switchMode,
                          child: Text(
                            _isSignUpMode ? 'Login' : 'Sign Up',
                            style: const TextStyle(
                              color: Color(0xFF1E88E5),
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}