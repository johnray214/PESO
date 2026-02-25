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
  late AnimationController _logoRollController;
  late AnimationController _entranceController;
  late AnimationController _glowController;
  late AnimationController _buttonBounceController;
  late AnimationController _bgController;

  late Animation<double> _bgFade;

  // Individual element animations
  late Animation<double> _logoFade;
  late Animation<Offset> _logoSlide;
  late Animation<double> _logoRotation;

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

    // Logo roll‑down + rotation entrance
    _logoRollController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoFade = CurvedAnimation(
      parent: _logoRollController,
      curve: Curves.easeOut,
    );
    _logoSlide = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _logoRollController,
        curve: Curves.easeOutCubic,
      ),
    );
    _logoRotation = Tween<double>(
      begin: -1.0, // one full turn backwards
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _logoRollController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Staggered entrance for remaining content (runs after logo completes)
    // Staggered entrance (total 1400ms)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

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

    // Chain: once logo animation finishes, bring in the rest
    _logoRollController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _entranceController.forward();
      }
    });
    _logoRollController.forward();

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
    _logoRollController.dispose();
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
                          child: RotationTransition(
                            turns: _logoRotation,
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
  static const String _demoEmail = 'jobseeker@peso.app';
  static const String _demoPassword = 'peso1234';

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
                            color: const Color(0xFF2E5C8A).withOpacity(0.3),
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
                              final email = _emailController.text.trim();
                              final password = _passwordController.text.trim();

                              if (_isSignUpMode) {
                                Navigator.pop(context);
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const JobListingsPage(),
                                  ),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Welcome, ${_nameController.text.isEmpty ? 'PESO Jobseeker' : _nameController.text}! (Demo signup)',
                                    ),
                                    backgroundColor: const Color(0xFF2E5C8A),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                              } else {
                                if (email == _demoEmail &&
                                    password == _demoPassword) {
                                  Navigator.pop(context);
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const JobListingsPage(),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                        'Invalid demo credentials. Use jobseeker@peso.app / peso1234',
                                      ),
                                      backgroundColor: const Color(0xFFEF5350),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                    ),
                                  );
                                }
                              }
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

// ─── Job Model ──────────────────────────────────────────────────────────────
class Job {
  final String id;
  final String title;
  final String company;
  final String location;
  final String jobType;
  final String salaryRange;
  final List<String> skills;
  final String description;
  final int matchPercentage;
  final DateTime postedDate;
  final String category;

  Job({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.jobType,
    required this.salaryRange,
    required this.skills,
    required this.description,
    required this.matchPercentage,
    required this.postedDate,
    required this.category,
  });
}

// ─── Job Listings Page ──────────────────────────────────────────────────────
class JobListingsPage extends StatefulWidget {
  const JobListingsPage({super.key});

  @override
  State<JobListingsPage> createState() => _JobListingsPageState();
}

class _JobListingsPageState extends State<JobListingsPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  int _currentTabIndex = 1; // 0 = Saved, 1 = Jobs, 2 = Applications
  String _selectedSortOption = 'Best Match';
  final Set<String> _selectedJobTypes = {};
  final Set<String> _selectedCategories = {};
  final Set<String> _savedJobIds = {};
  final Set<String> _appliedJobIds = {};
  bool _showFilters = false;

  final List<String> _sortOptions = [
    'Best Match',
    'Newest First',
    'Highest Salary',
    'Lowest Salary',
  ];

  final List<String> _jobTypes = [
    'Full-time',
    'Part-time',
    'Contract',
    'Freelance',
  ];

  final List<String> _categories = [
    'IT & Software',
    'Healthcare',
    'Education',
    'Construction',
    'Sales & Marketing',
    'Manufacturing',
  ];

  List<Job> _allJobs = [];
  List<Job> _filteredJobs = [];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();
    _loadJobs();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadJobs() {
    _allJobs = [
      Job(
        id: '1',
        title: 'Software Developer',
        company: 'Tech Solutions Inc.',
        location: 'Santiago City, Isabela',
        jobType: 'Full-time',
        salaryRange: '₱25,000 - ₱35,000',
        skills: ['Flutter', 'Laravel', 'MySQL'],
        description:
            'Looking for a skilled software developer with experience in mobile and web development.',
        matchPercentage: 95,
        postedDate: DateTime.now().subtract(const Duration(days: 2)),
        category: 'IT & Software',
      ),
      Job(
        id: '2',
        title: 'Registered Nurse',
        company: 'Santiago City Hospital',
        location: 'Santiago City, Isabela',
        jobType: 'Full-time',
        salaryRange: '₱20,000 - ₱28,000',
        skills: ['Patient Care', 'Medical Knowledge', 'Communication'],
        description:
            'Seeking a compassionate registered nurse to join our healthcare team.',
        matchPercentage: 78,
        postedDate: DateTime.now().subtract(const Duration(days: 1)),
        category: 'Healthcare',
      ),
      Job(
        id: '3',
        title: 'Elementary Teacher',
        company: 'Santiago Central School',
        location: 'Santiago City, Isabela',
        jobType: 'Full-time',
        salaryRange: '₱18,000 - ₱24,000',
        skills: ['Teaching', 'Classroom Management', 'Curriculum Planning'],
        description:
            'Dedicated teacher needed for elementary education with strong communication skills.',
        matchPercentage: 82,
        postedDate: DateTime.now().subtract(const Duration(days: 3)),
        category: 'Education',
      ),
      Job(
        id: '4',
        title: 'Marketing Specialist',
        company: 'Isabela Marketing Group',
        location: 'Santiago City, Isabela',
        jobType: 'Full-time',
        salaryRange: '₱22,000 - ₱30,000',
        skills: ['Digital Marketing', 'Social Media', 'Content Creation'],
        description:
            'Creative marketing specialist to develop and execute marketing campaigns.',
        matchPercentage: 88,
        postedDate: DateTime.now().subtract(const Duration(hours: 12)),
        category: 'Sales & Marketing',
      ),
      Job(
        id: '5',
        title: 'Construction Worker',
        company: 'BuildRight Construction',
        location: 'Santiago City, Isabela',
        jobType: 'Contract',
        salaryRange: '₱15,000 - ₱20,000',
        skills: ['Construction', 'Safety Protocols', 'Physical Stamina'],
        description:
            'Experienced construction worker for ongoing building projects.',
        matchPercentage: 65,
        postedDate: DateTime.now().subtract(const Duration(days: 5)),
        category: 'Construction',
      ),
      Job(
        id: '6',
        title: 'Graphic Designer',
        company: 'Creative Studio PH',
        location: 'Santiago City, Isabela',
        jobType: 'Part-time',
        salaryRange: '₱12,000 - ₱18,000',
        skills: ['Adobe Photoshop', 'Illustrator', 'Creativity'],
        description:
            'Talented graphic designer for part-time creative projects.',
        matchPercentage: 72,
        postedDate: DateTime.now().subtract(const Duration(days: 4)),
        category: 'IT & Software',
      ),
      Job(
        id: '7',
        title: 'Production Operator',
        company: 'Isabela Manufacturing Corp.',
        location: 'Santiago City, Isabela',
        jobType: 'Full-time',
        salaryRange: '₱16,000 - ₱22,000',
        skills: ['Machine Operation', 'Quality Control', 'Teamwork'],
        description:
            'Production operator needed for manufacturing facility.',
        matchPercentage: 70,
        postedDate: DateTime.now().subtract(const Duration(days: 6)),
        category: 'Manufacturing',
      ),
      Job(
        id: '8',
        title: 'Web Developer',
        company: 'Digital Innovations',
        location: 'Santiago City, Isabela',
        jobType: 'Freelance',
        salaryRange: '₱30,000 - ₱45,000',
        skills: ['React', 'Node.js', 'MongoDB'],
        description:
            'Freelance web developer for multiple client projects.',
        matchPercentage: 91,
        postedDate: DateTime.now().subtract(const Duration(hours: 8)),
        category: 'IT & Software',
      ),
    ];
    _applyFilters();
  }

  void _applyFilters() {
    setState(() {
      _filteredJobs = _allJobs.where((job) {
        bool matchesSearch = _searchController.text.isEmpty ||
            job.title
                .toLowerCase()
                .contains(_searchController.text.toLowerCase()) ||
            job.company
                .toLowerCase()
                .contains(_searchController.text.toLowerCase()) ||
            job.skills.any((skill) => skill
                .toLowerCase()
                .contains(_searchController.text.toLowerCase()));

        bool matchesJobType = _selectedJobTypes.isEmpty ||
            _selectedJobTypes.contains(job.jobType);

        bool matchesCategory = _selectedCategories.isEmpty ||
            _selectedCategories.contains(job.category);

        return matchesSearch && matchesJobType && matchesCategory;
      }).toList();

      switch (_selectedSortOption) {
        case 'Best Match':
          _filteredJobs.sort((a, b) => b.matchPercentage.compareTo(a.matchPercentage));
          break;
        case 'Newest First':
          _filteredJobs.sort((a, b) => b.postedDate.compareTo(a.postedDate));
          break;
        case 'Highest Salary':
          _filteredJobs.sort((a, b) => b.salaryRange.compareTo(a.salaryRange));
          break;
        case 'Lowest Salary':
          _filteredJobs.sort((a, b) => a.salaryRange.compareTo(b.salaryRange));
          break;
      }
    });
  }

  String _getTimeAgo(DateTime date) {
    final difference = DateTime.now().difference(date);
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: _buildBottomNavBar(),
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
              _buildAppBar(),
              if (_currentTabIndex != 2) _buildSearchBar(),
              if (_currentTabIndex == 1 && _showFilters) _buildFiltersSection(),
              _buildSortBar(),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildTabContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2E5C8A).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfilePage(),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF2E5C8A), Color(0xFF1E88E5)],
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'J',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My Profile',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2E5C8A),
                            ),
                          ),
                          Text(
                            'Skills & Settings',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1E88E5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Job Opportunities',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2E5C8A),
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'Find your perfect match',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1E88E5),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsPage(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E88E5).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  color: Color(0xFF1E88E5),
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => _applyFilters(),
                decoration: InputDecoration(
                  hintText: 'Search jobs, companies, skills...',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF2E5C8A),
                    size: 24,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear_rounded, color: Colors.grey[400]),
                          onPressed: () {
                            _searchController.clear();
                            _applyFilters();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _showFilters
                    ? [const Color(0xFF1E88E5), const Color(0xFF2E5C8A)]
                    : [const Color(0xFF2E5C8A), const Color(0xFF1E88E5)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2E5C8A).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _showFilters = !_showFilters;
                  });
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Icon(
                    _showFilters
                        ? Icons.filter_alt_rounded
                        : Icons.filter_alt_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filters',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2E5C8A),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedJobTypes.clear();
                      _selectedCategories.clear();
                      _applyFilters();
                    });
                  },
                  child: const Text(
                    'Clear All',
                    style: TextStyle(
                      color: Color(0xFF1E88E5),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Job Type',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2E5C8A),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _jobTypes.map((type) {
                final isSelected = _selectedJobTypes.contains(type);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedJobTypes.remove(type);
                      } else {
                        _selectedJobTypes.add(type);
                      }
                      _applyFilters();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF1E88E5)
                          : const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF1E88E5)
                            : Colors.grey[300]!,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      type,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : const Color(0xFF2E5C8A),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            const Text(
              'Category',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2E5C8A),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((category) {
                final isSelected = _selectedCategories.contains(category);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedCategories.remove(category);
                      } else {
                        _selectedCategories.add(category);
                      }
                      _applyFilters();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF2E5C8A)
                          : const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF2E5C8A)
                            : Colors.grey[300]!,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : const Color(0xFF2E5C8A),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildSortBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Builder(
            builder: (context) {
              String label;
              if (_currentTabIndex == 0) {
                final savedCount =
                    _allJobs.where((job) => _savedJobIds.contains(job.id)).length;
                label = '$savedCount Saved Jobs';
              } else if (_currentTabIndex == 1) {
                label = '${_filteredJobs.length} Jobs Found';
              } else {
                final appliedCount = _allJobs
                    .where((job) => _appliedJobIds.contains(job.id))
                    .length;
                label = '$appliedCount Applications';
              }
              return Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2E5C8A),
                ),
              );
            },
          ),
          const Spacer(),
          if (_currentTabIndex == 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF2E5C8A).withOpacity(0.2),
                ),
              ),
              child: DropdownButton<String>(
                value: _selectedSortOption,
                underline: const SizedBox(),
                icon: const Icon(
                  Icons.arrow_drop_down_rounded,
                  color: Color(0xFF2E5C8A),
                ),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2E5C8A),
                ),
                items: _sortOptions.map((option) {
                  return DropdownMenuItem(
                    value: option,
                    child: Text(option),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedSortOption = value;
                      _applyFilters();
                    });
                  }
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildJobList(List<Job> jobs) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemCount: jobs.length,
      itemBuilder: (context, index) {
        final job = jobs[index];
        return _buildJobCard(job, index);
      },
    );
  }

  Widget _buildJobCard(Job job, int index) {
    final bool isSaved = _savedJobIds.contains(job.id);
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF2E5C8A).withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => JobDetailsPage(
                    job: job,
                    initialIsSaved: isSaved,
                    initialIsApplied: _appliedJobIds.contains(job.id),
                    onSavedChanged: (saved) {
                      setState(() {
                        if (saved) {
                          _savedJobIds.add(job.id);
                        } else {
                          _savedJobIds.remove(job.id);
                        }
                      });
                    },
                    onAppliedChanged: (applied) {
                      setState(() {
                        if (applied) {
                          _appliedJobIds.add(job.id);
                        } else {
                          _appliedJobIds.remove(job.id);
                        }
                      });
                    },
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF2E5C8A), Color(0xFF1E88E5)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            job.company[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              job.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2E5C8A),
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              job.company,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _getMatchColor(job.matchPercentage),
                              _getMatchColor(job.matchPercentage)
                                  .withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${job.matchPercentage}%',
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
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildInfoChip(
                        Icons.location_on_outlined,
                        job.location,
                      ),
                      const SizedBox(width: 12),
                      _buildInfoChip(
                        Icons.work_outline_rounded,
                        job.jobType,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.payments_outlined,
                        size: 18,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        job.salaryRange,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.access_time_rounded,
                        size: 16,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getTimeAgo(job.postedDate),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    job.description,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: job.skills.take(3).map((skill) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E88E5).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF1E88E5).withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          skill,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E88E5),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSaved
                                  ? const Color(0xFF1E88E5)
                                  : const Color(0xFF2E5C8A),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  if (isSaved) {
                                    _savedJobIds.remove(job.id);
                                  } else {
                                    _savedJobIds.add(job.id);
                                  }
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isSaved
                                          ? 'Removed from saved jobs'
                                          : 'Saved to your jobs',
                                    ),
                                    backgroundColor: const Color(0xFF2E5C8A),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      isSaved
                                          ? Icons.bookmark_rounded
                                          : Icons.bookmark_outline_rounded,
                                      color: isSaved
                                          ? const Color(0xFF1E88E5)
                                          : const Color(0xFF2E5C8A),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isSaved ? 'Saved' : 'Save',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: isSaved
                                            ? const Color(0xFF1E88E5)
                                            : const Color(0xFF2E5C8A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF2E5C8A), Color(0xFF1E88E5)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    const Color(0xFF2E5C8A).withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                final alreadyApplied =
                                    _appliedJobIds.contains(job.id);
                                setState(() {
                                  _appliedJobIds.add(job.id);
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      alreadyApplied
                                          ? 'You already applied to ${job.company} (demo)'
                                          : 'Application submitted to ${job.company} (demo)',
                                    ),
                                    backgroundColor: const Color(0xFF2E5C8A),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: const Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Apply Now',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 6),
                                    Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
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
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.grey[300]!,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: const Color(0xFF1E88E5),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Color _getMatchColor(int percentage) {
    if (percentage >= 90) {
      return const Color(0xFF4CAF50);
    } else if (percentage >= 75) {
      return const Color(0xFF1E88E5);
    } else if (percentage >= 60) {
      return const Color(0xFFFFA726);
    } else {
      return const Color(0xFFEF5350);
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF2E5C8A).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 64,
              color: Color(0xFF2E5C8A),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Jobs Found',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2E5C8A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or search terms',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    if (_currentTabIndex == 0) {
      final savedJobs = _filteredJobs
          .where((job) => _savedJobIds.contains(job.id))
          .toList();
      if (savedJobs.isEmpty) {
        return _buildSavedEmptyState();
      }
      return _buildJobList(savedJobs);
    } else if (_currentTabIndex == 1) {
      if (_filteredJobs.isEmpty) {
        return _buildEmptyState();
      }
      return _buildJobList(_filteredJobs);
    } else {
      final appliedJobs = _allJobs
          .where((job) => _appliedJobIds.contains(job.id))
          .toList();
      if (appliedJobs.isEmpty) {
        return _buildApplicationsEmptyState();
      }
      return _buildJobList(appliedJobs);
    }
  }

  Widget _buildSavedEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF2E5C8A).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.bookmark_border_rounded,
              size: 64,
              color: Color(0xFF2E5C8A),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Saved Jobs Yet',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2E5C8A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the Save button on jobs you like',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationsEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E88E5).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.description_outlined,
              size: 64,
              color: Color(0xFF1E88E5),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Applications Yet',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2E5C8A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Apply to jobs to track them here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentTabIndex,
        onTap: (index) {
          setState(() {
            _currentTabIndex = index;
            if (_currentTabIndex != 1) {
              _showFilters = false;
            }
          });
        },
        selectedItemColor: const Color(0xFF2E5C8A),
        unselectedItemColor: Colors.grey[500],
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_border_rounded),
            activeIcon: Icon(Icons.bookmark_rounded),
            label: 'Saved',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work_outline_rounded),
            activeIcon: Icon(Icons.work_rounded),
            label: 'Jobs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description_outlined),
            activeIcon: Icon(Icons.description_rounded),
            label: 'Applications',
          ),
        ],
      ),
    );
  }
}

// ─── Job Details Page ─────────────────────────────────────────────────────────

class JobDetailsPage extends StatefulWidget {
  final Job job;
  final bool initialIsSaved;
  final bool initialIsApplied;
  final ValueChanged<bool> onSavedChanged;
  final ValueChanged<bool> onAppliedChanged;

  const JobDetailsPage({
    super.key,
    required this.job,
    required this.initialIsSaved,
    required this.initialIsApplied,
    required this.onSavedChanged,
    required this.onAppliedChanged,
  });

  @override
  State<JobDetailsPage> createState() => _JobDetailsPageState();
}

class _JobDetailsPageState extends State<JobDetailsPage> {
  late bool _isSaved;
  late bool _isApplied;

  @override
  void initState() {
    super.initState();
    _isSaved = widget.initialIsSaved;
    _isApplied = widget.initialIsApplied;
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
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
              _buildHeader(job),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMatchSection(job),
                      const SizedBox(height: 20),
                      _buildInfoRow(job),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Job Description'),
                      const SizedBox(height: 8),
                      Text(
                        job.description,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Key Skills'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: job.skills.map((skill) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E88E5).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color:
                                    const Color(0xFF1E88E5).withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              skill,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E88E5),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Category'),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E5C8A).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          job.category,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2E5C8A),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Posted'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            size: 18,
                            color: Color(0xFF1E88E5),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${DateTime.now().difference(job.postedDate).inDays} days ago',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomActions(job),
    );
  }

  Widget _buildHeader(Job job) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            color: const Color(0xFF2E5C8A),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2E5C8A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  job.company,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchSection(Job job) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  _getMatchColor(job.matchPercentage),
                  _getMatchColor(job.matchPercentage).withOpacity(0.8),
                ],
              ),
            ),
            child: Center(
              child: Text(
                '${job.matchPercentage}%',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Match with your profile',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2E5C8A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  job.matchPercentage >= 90
                      ? 'Excellent match based on your skills.'
                      : job.matchPercentage >= 75
                          ? 'Good match. You meet most of the requirements.'
                          : job.matchPercentage >= 60
                              ? 'Decent match. Some skills may need improvement.'
                              : 'Low match. Consider training or other roles.',
                  style: TextStyle(
                    fontSize: 12,
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

  Widget _buildInfoRow(Job job) {
    return Row(
      children: [
        _buildDetailsInfoChip(Icons.location_on_outlined, job.location),
        const SizedBox(width: 10),
        _buildDetailsInfoChip(Icons.work_outline_rounded, job.jobType),
        const SizedBox(width: 10),
        _buildDetailsInfoChip(Icons.payments_outlined, job.salaryRange),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Color(0xFF2E5C8A),
      ),
    );
  }

  Widget _buildBottomActions(Job job) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x29000000),
            blurRadius: 12,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _isSaved
                      ? const Color(0xFF1E88E5)
                      : const Color(0xFF2E5C8A),
                  width: 2,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    setState(() {
                      _isSaved = !_isSaved;
                    });
                    widget.onSavedChanged(_isSaved);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _isSaved
                              ? 'Saved to your jobs'
                              : 'Removed from saved jobs',
                        ),
                        backgroundColor: const Color(0xFF2E5C8A),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  },
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isSaved
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_outline_rounded,
                          color: _isSaved
                              ? const Color(0xFF1E88E5)
                              : const Color(0xFF2E5C8A),
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isSaved ? 'Saved' : 'Save',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _isSaved
                                ? const Color(0xFF1E88E5)
                                : const Color(0xFF2E5C8A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2E5C8A), Color(0xFF1E88E5)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2E5C8A).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    final wasApplied = _isApplied;
                    setState(() {
                      _isApplied = true;
                    });
                    widget.onAppliedChanged(true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          wasApplied
                              ? 'You already applied to ${job.company} (demo)'
                              : 'Application submitted to ${job.company} (demo)',
                        ),
                        backgroundColor: const Color(0xFF2E5C8A),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  },
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isApplied ? 'Applied' : 'Apply Now',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getMatchColor(int percentage) {
    if (percentage >= 90) {
      return const Color(0xFF4CAF50);
    } else if (percentage >= 75) {
      return const Color(0xFF1E88E5);
    } else if (percentage >= 60) {
      return const Color(0xFFFFA726);
    } else {
      return const Color(0xFFEF5350);
    }
  }

  Widget _buildDetailsInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.grey[300]!,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: const Color(0xFF1E88E5),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Profile & Skills Page ────────────────────────────────────────────────────

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2E5C8A)),
        title: const Text(
          'My Profile & Skills',
          style: TextStyle(
            color: Color(0xFF2E5C8A),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
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
          top: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF2E5C8A), Color(0xFF1E88E5)],
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'J',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 26,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PESO Jobseeker (Demo)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2E5C8A),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'jobseeker@peso.app',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF607D8B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'My Skills (Demo)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2E5C8A),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildSkillChip('Flutter'),
                    _buildSkillChip('Laravel'),
                    _buildSkillChip('Customer Service'),
                    _buildSkillChip('Communication'),
                    _buildSkillChip('Basic Computer Skills'),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Note',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2E5C8A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This is a demo profile for UI testing. Later, this screen can be '
                  'connected to your Laravel backend so that PESO staff and job seekers '
                  'can manage real profiles and skills for more accurate job matching.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkillChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E88E5).withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF1E88E5).withOpacity(0.3),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1E88E5),
        ),
      ),
    );
  }
}

// ─── Notifications Page ───────────────────────────────────────────────────────

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = [
      'New job matches available in IT & Software.',
      'Your application to Tech Solutions Inc. was received.',
      'PESO Santiago: Upcoming job fair next week.',
      'New training program available for Construction workers.',
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2E5C8A)),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Color(0xFF2E5C8A),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
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
        child: ListView.separated(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          itemBuilder: (context, index) {
            final text = notifications[index];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E88E5).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_rounded,
                      color: Color(0xFF1E88E5),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      text,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF2C3E50),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemCount: notifications.length,
        ),
      ),
    );
  }
}