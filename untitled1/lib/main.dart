import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'api_service.dart';
import 'home_pages.dart';
import 'user_session.dart';
import 'job_action_service.dart';
import 'onboarding_intro_slides.dart';
import 'onboarding_post_auth.dart';
import 'onboarding_prefs.dart';
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
  // Light/app-wide
  static const blueAccent = Color(0xFF2563EB);
  static const blueLight = Color(0xFF3B82F6);
  static const textPrimary = Color(0xFF0F172A);
  static const textMuted = Color(0xFF64748B);
  static const divider = Color(0xFFE2E8F0);
  static const pageBackground = Color(0xFFF4F7FB);
  static const navyMid = Color(0xFF112240);
  static const navyLight = Color(0xFF1D3461);

  // Welcome page gradient — white (top) → PESO blue (bottom)
  static const darkBg1 = Color(0xFFFFFFFF);   // top: pure white
  static const darkBg2 = Color(0xFFCFE5F7);   // mid: soft sky blue
  static const darkBg3 = Color(0xFF1565C0);   // bottom: PESO royal blue
  static const glassWhite = Color(0x99FFFFFF); // frosted white card (light bg)
  static const glassBorder = Color(0x331565C0);// PESO blue card border
  static const pesoBlue = Color(0xFF1565C0);  // PESO official royal blue
  static const pesoRed = Color(0xFFCC2229);   // PESO official red
  static const pesoGold = Color(0xFFF59E0B);  // PESO official gold/yellow
}

// ─── App ─────────────────────────────────────────────────────────────────────
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class PESOApp extends StatelessWidget {
  const PESOApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PESO Santiago City',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: scaffoldMessengerKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.blueAccent,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          elevation: 6,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// ─── Splash Screen ────────────────────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _mascotCtrl;
  late AnimationController _floatCtrl;
  late AnimationController _shimmerCtrl;

  late Animation<double> _mascotScale;
  late Animation<double> _mascotY;
  late Animation<double> _float;
  late Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();

    _mascotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _mascotScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mascotCtrl, curve: Curves.elasticOut),
    );
    _mascotY = Tween<double>(begin: 60.0, end: 0.0).animate(
      CurvedAnimation(parent: _mascotCtrl, curve: Curves.easeOutCubic),
    );
    _float = Tween<double>(begin: -7.0, end: 7.0).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );
    _shimmer = Tween<double>(begin: -2.0, end: 3.0).animate(
      CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut),
    );

    _mascotCtrl.forward();

    // Auto-navigate: intro slides (first launch) → auth entry
    Future.delayed(const Duration(milliseconds: 3400), () async {
      if (!mounted) return;
      final introDone = await OnboardingPrefs.isIntroDone();
      if (!mounted) return;
      if (!introDone) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 700),
            pageBuilder: (_, __, ___) => IntroOnboardingPage(
              onComplete: (introContext) {
                Navigator.of(introContext).pushReplacement(
                  PageRouteBuilder(
                    transitionDuration: const Duration(milliseconds: 500),
                    pageBuilder: (_, __, ___) => const AuthEntryPage(),
                    transitionsBuilder: (_, animation, __, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                  ),
                );
              },
            ),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 700),
            pageBuilder: (_, __, ___) => const AuthEntryPage(),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _mascotCtrl.dispose();
    _floatCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
      ),
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFFFFF),
                  Color(0xFFE8F4FD),
                  Color(0xFFB3D4FC),
                  Color(0xFF5B9BD5),
                ],
                stops: [0.0, 0.35, 0.7, 1.0],
              ),
            ),
            child: Stack(
              children: [
                // ── Decorative orbs ──────────────────────────────────────────
                Positioned(
                  top: -size.width * 0.3,
                  left: -size.width * 0.25,
                  child: Container(
                    width: size.width * 0.80,
                    height: size.width * 0.80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF1565C0).withOpacity(0.08),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -size.width * 0.22,
                  right: -size.width * 0.18,
                  child: Container(
                    width: size.width * 0.65,
                    height: size.width * 0.65,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF5B9BD5).withOpacity(0.12),
                    ),
                  ),
                ),
                Positioned(
                  top: size.height * 0.08,
                  right: size.width * 0.06,
                  child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFB3D4FC).withOpacity(0.5),
                  ),
                ),
                ),
                Positioned(
                  bottom: size.height * 0.18,
                  left: size.width * 0.04,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF5B9BD5).withOpacity(0.15),
                    ),
                  ),
                ),

                // ── Horizontal accent line ────────────────────────────────────
                Positioned(
                  bottom: size.height * 0.32,
                  left: 0,
                  right: 0,
                  child: Center(
                  child: Container(
                    width: size.width * 0.55,
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          const Color(0xFF1565C0).withOpacity(0.15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                ),

                // ── Main content ─────────────────────────────────────────────
                Positioned.fill(
                  child: SafeArea(
                    child: SizedBox(
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                    // Top spacer (positions mascot + text block toward vertical center)
                    SizedBox(height: size.height * 0.16),

                    // ── Mascot + shadow ──────────────────────────────────────
                    AnimatedBuilder(
                      animation: Listenable.merge([_mascotCtrl, _floatCtrl]),
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _mascotY.value + _float.value),
                          child: Transform.scale(
                            scale: _mascotScale.value,
                            child: child,
                          ),
                        );
                      },
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          // Shadow ellipse under mascot
                          Container(
                            width: size.width * 0.28,
                            height: 14,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.35),
                                  blurRadius: 28,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: size.width * 0.30,
                            height: size.width * 0.30,
                            child: Image.asset(
                              'assets/EMPOY 3.png',
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.person,
                                size: size.width * 0.22,
                                color: const Color(0xFF1565C0).withOpacity(0.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: size.height * 0.035),

                    // ── PESO + city text ─────────────────────────────────────
                    Column(
                      children: [
                        // PESO text with shimmer
                        AnimatedBuilder(
                          animation: _shimmerCtrl,
                          builder: (context, child) {
                            return ShaderMask(
                              blendMode: BlendMode.srcIn,
                              shaderCallback: (bounds) {
                                final shimmerX = _shimmer.value * bounds.width;
                                return LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: const [
                                    Color(0xFF0F2250),
                                    Color(0xFF0F2250),
                                    Color(0xFF3B82F6),
                                    Color(0xFF0F2250),
                                    Color(0xFF0F2250),
                                  ],
                                  stops: [
                                    0.0,
                                    math.max(0.0, (shimmerX / bounds.width) - 0.18),
                                    (shimmerX / bounds.width).clamp(0.0, 1.0),
                                    math.min(1.0, (shimmerX / bounds.width) + 0.18),
                                    1.0,
                                  ],
                                ).createShader(bounds);
                              },
                              child: child!,
                            );
                          },
                              child: Text(
                            'PESO',
                            style: GoogleFonts.poppins(
                              fontSize: 60,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF0F2250),
                              letterSpacing: 12,
                              height: 1.0,
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 500.ms, duration: 600.ms)
                            .slideY(begin: 0.2, curve: Curves.easeOutCubic),

                        const SizedBox(height: 4),

                        Text(
                          'Santiago City',
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF1565C0),
                            letterSpacing: 5,
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 700.ms, duration: 600.ms)
                            .slideY(begin: 0.2, curve: Curves.easeOutCubic),

                        const SizedBox(height: 10),

                        // Gold accent label
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: const Color(0xFF1565C0).withOpacity(0.4),
                            ),
                            color: const Color(0xFF1565C0).withOpacity(0.08),
                          ),
                            child: Text(
                              'PUBLIC EMPLOYMENT SERVICE OFFICE',
                              style: GoogleFonts.poppins(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1565C0),
                                letterSpacing: 2.2,
                              ),
                            ),
                        )
                            .animate()
                            .fadeIn(delay: 900.ms, duration: 600.ms),
                      ],
                    ),

                    const Spacer(),

                    // ── Loading indicator ────────────────────────────────────
                    Column(
                      children: [
                        const _SplashDots()
                            .animate()
                            .fadeIn(delay: 1200.ms, duration: 500.ms),
                        const SizedBox(height: 10),
                        Text(
                          'Connecting you to opportunities...',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: const Color(0xFF1565C0).withOpacity(0.6),
                            letterSpacing: 0.5,
                          ),
                        ).animate().fadeIn(delay: 1400.ms, duration: 500.ms),
                        const SizedBox(height: 28),
                      ],
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
    );
  }
}

// ─── Animated loading dots ────────────────────────────────────────────────────────
class _SplashDots extends StatefulWidget {
  const _SplashDots();
  @override
  State<_SplashDots> createState() => _SplashDotsState();
}

class _SplashDotsState extends State<_SplashDots> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            // Each dot's brightness peaks one-third of the cycle apart
            final phase = (_ctrl.value * 3 - i) % 3;
            final brightness = math.sin(phase * math.pi / 1.5).clamp(0.0, 1.0).toDouble();
            final scale = 0.55 + 0.45 * brightness;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8 * scale,
              height: 8 * scale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1565C0).withOpacity(0.35 + 0.55 * brightness),
              ),
            );
          }),
        );
      },
    );
  }
}

// ─── Auth Entry Page ──────────────────────────────────────────────────────────
class AuthEntryPage extends StatefulWidget {
  const AuthEntryPage({super.key});

  @override
  State<AuthEntryPage> createState() => _AuthEntryPageState();
}

class _AuthEntryPageState extends State<AuthEntryPage>
    with TickerProviderStateMixin {
  bool _isSignUpMode = false;

  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      // Longer staged timeline:
      // 1) welcome fades in
      // 2) stays highlighted (~3s)
      // 3) then header moves and auth panel enters
      duration: const Duration(milliseconds: 3500),
    );
    _ctrl.forward();
  }   

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;

    final headerFade = CurvedAnimation(
      parent: _ctrl,
      // Quick fade in at start.
      curve: const Interval(0.0, 0.12, curve: Curves.easeOut),
    );
    final headerMove = CurvedAnimation(
      parent: _ctrl,
      // Hold for ~3s first, then move up.
      curve: const Interval(0.68, 0.90, curve: Curves.easeInOutCubic),
    );
    final authPop = CurvedAnimation(
      parent: _ctrl,
      // Enter right after the header starts moving.
      curve: const Interval(0.82, 1.0, curve: Curves.easeOutBack),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final maxH = constraints.maxHeight.isFinite
                    ? constraints.maxHeight
                    : h;
                final headerTranslateY = lerpDouble(
                  0,
                  -maxH * 0.33,
                  headerMove.value,
                );
                final headerOpacity = headerFade.value;

                final authTranslateY = lerpDouble(
                  // Start off-screen.
                  maxH * 0.60,
                  0,
                  authPop.value,
                );
                // `easeOutBack` can overshoot >1.0; Opacity requires 0..1.
                final authOpacity = authPop.value.clamp(0.0, 1.0).toDouble();

                final iconScale = lerpDouble(1.18, 1.0, headerMove.value)!;
                final titleColor = Color.lerp(
                  const Color(0xFF2563EB),
                  const Color(0xFF0F172A),
                  headerMove.value,
                )!;
                final subtitleColor = Color.lerp(
                  const Color(0xFF2563EB),
                  const Color(0xFF64748B),
                  headerMove.value,
                )!;
                // Hide subtitle during the highlighted intro, then reveal smoothly
                // as the header settles near the top.
                final subtitleReveal = CurvedAnimation(
                  parent: _ctrl,
                  curve: const Interval(0.78, 0.96, curve: Curves.easeOutCubic),
                ).value;
                final subtitleOpacity =
                    subtitleReveal.clamp(0.0, 1.0).toDouble();
                final subtitleYOffset =
                    lerpDouble(8, 0, subtitleReveal) ?? 0;

                return Stack(
                  children: [
                    // Header + welcome copy
                    Align(
                      alignment: Alignment.center,
                      child: Transform.translate(
                        offset: Offset(0, headerTranslateY ?? 0),
                        child: Opacity(
                          opacity: headerOpacity,
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Transform.scale(
                                  scale: iconScale,
                                  child: Icon(
                                    Icons.verified_user_rounded,
                                    size: 64,
                                    color:
                                        const Color(0xFF2563EB).withOpacity(0.9),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  'Welcome to PESO',
                                  style: GoogleFonts.poppins(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: titleColor,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Transform.translate(
                                  offset: Offset(0, subtitleYOffset),
                                  child: Opacity(
                                    opacity: subtitleOpacity,
                                    child: Text(
                                      'Sign in to continue, or create an account to start applying for jobs and events.',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        height: 1.4,
                                        color: subtitleColor,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Buttons + on-screen auth form
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Transform.translate(
                        offset: Offset(0, authTranslateY ?? 0),
                        child: Opacity(
                          opacity: authOpacity,
                          child: Padding(
                            padding:
                                const EdgeInsets.fromLTRB(24, 0, 24, 10),
                            child: SizedBox(
                              width: double.infinity,
                              height: h * 0.70,
                              child: Material(
                                color: Colors.transparent,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [Colors.white, Color(0xFFF8FBFF)],
                                    ),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: const Color(0xFFE6ECF5),
                                      width: 1.0,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF0F172A)
                                            .withOpacity(0.09),
                                        blurRadius: 30,
                                        offset: const Offset(0, 14),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(14, 14, 14, 12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Expanded(
                                          child: SingleChildScrollView(
                                            physics:
                                                const BouncingScrollPhysics(),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                      4, 6, 4, 20),
                                              child: LoginModal(
                                                key: ValueKey<bool>(
                                                    _isSignUpMode),
                                                isSignUp: _isSignUpMode,
                                                renderAsModal: false,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        SizedBox(
                                          width: double.infinity,
                                          height: 52,
                                          child: FilledButton(
                                            onPressed: () {
                                              setState(
                                                  () => _isSignUpMode = false);
                                            },
                                            style: FilledButton.styleFrom(
                                              backgroundColor:
                                                  !_isSignUpMode
                                                      ? const Color(0xFF2563EB)
                                                      : Colors.transparent,
                                              foregroundColor:
                                                  !_isSignUpMode
                                                      ? Colors.white
                                                      : const Color(0xFF2563EB),
                                              side: BorderSide(
                                                color: const Color(0xFF2563EB)
                                                    .withOpacity(
                                                  _isSignUpMode ? 1 : 0,
                                                ),
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                            ),
                                            child: const Text(
                                              'Sign in',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        SizedBox(
                                          width: double.infinity,
                                          height: 52,
                                          child: FilledButton(
                                            onPressed: () {
                                              setState(
                                                  () => _isSignUpMode = true);
                                            },
                                            style: FilledButton.styleFrom(
                                              backgroundColor:
                                                  _isSignUpMode
                                                      ? const Color(0xFF2563EB)
                                                      : Colors.transparent,
                                              foregroundColor:
                                                  _isSignUpMode
                                                      ? Colors.white
                                                      : const Color(0xFF2563EB),
                                              side: BorderSide(
                                                color: const Color(0xFF2563EB)
                                                    .withOpacity(
                                                  !_isSignUpMode ? 1 : 0,
                                                ),
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                            ),
                                            child: const Text(
                                              'Create account',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
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
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
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
    with TickerProviderStateMixin {
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _glowAnim = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.darkBg1,
        body: Stack(
          children: [
            // ── White → PESO blue gradient (top to bottom) ──
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.darkBg1, AppColors.darkBg2, AppColors.darkBg3],
                    stops: [0.0, 0.60, 1.0],
                  ),
                ),
              ),
            ),

            // ── Floating orbs — trigger last with a late start ──
            _FloatingOrb(
              size: size.width * 0.72,
              color: AppColors.pesoBlue.withOpacity(0.07),
              top: -size.width * 0.28,
              right: -size.width * 0.22,
              moveY: -28,
              duration: const Duration(seconds: 5),
              delay: const Duration(milliseconds: 1200),
            ),
            _FloatingOrb(
              size: size.width * 0.55,
              color: AppColors.pesoBlue.withOpacity(0.09),
              bottom: size.height * 0.22,
              left: -size.width * 0.18,
              moveY: 24,
              duration: const Duration(seconds: 6),
              delay: const Duration(milliseconds: 1350),
            ),
            _FloatingOrb(
              size: size.width * 0.40,
              color: Colors.white.withOpacity(0.18),
              bottom: -size.width * 0.10,
              right: size.width * 0.08,
              moveY: -18,
              duration: const Duration(seconds: 4),
              delay: const Duration(milliseconds: 1500),
            ),
            _FloatingOrb(
              size: size.width * 0.26,
              color: Colors.white.withOpacity(0.14),
              bottom: size.height * 0.10,
              left: size.width * 0.05,
              moveY: 20,
              duration: const Duration(milliseconds: 3500),
              delay: const Duration(milliseconds: 1650),
            ),

            // ── Content ──
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Badge (same visual position as before)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.glassWhite,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: AppColors.glassBorder, width: 1),
                          ),
                          child: Text(
                            'PUBLIC EMPLOYMENT SERVICE OFFICE',
                            style: GoogleFonts.poppins(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.pesoBlue,
                              letterSpacing: 1.8,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    )
                        // Visually on top, but animates slightly *after* the logo
                        .animate()
                        .fadeIn(delay: 150.ms, duration: 600.ms)
                        .slideY(begin: 0.10, curve: Curves.easeOutCubic),

                    // Logo row (same layout position as before, animates first)
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Glow ring + logo (slides in from the left)
                            AnimatedBuilder(
                              animation: _glowAnim,
                              builder: (context, child) {
                                return Container(
                                  width: size.width * 0.27,
                                  height: size.width * 0.27,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.pesoBlue.withOpacity(0.60 * _glowAnim.value),
                                        blurRadius: 28 + 14 * _glowAnim.value,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: child,
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.pesoBlue.withOpacity(0.30),
                                    width: 2.5,
                                  ),
                                  color: AppColors.pesoBlue.withOpacity(0.05),
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/PESOLOGO.jpg',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),

                            // Divider
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 22),
                              width: 1.5,
                              height: size.width * 0.18,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    AppColors.pesoBlue.withOpacity(0.0),
                                    AppColors.pesoBlue.withOpacity(0.35),
                                    AppColors.pesoBlue.withOpacity(0.0),
                                  ],
                                ),
                              ),
                            ),

                            // PESO text
                            Text(
                              'PESO',
                              style: GoogleFonts.poppins(
                                fontSize: size.width * 0.145,
                                fontWeight: FontWeight.w900,
                                color: AppColors.navyMid,
                                letterSpacing: size.width * 0.012,
                                height: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                        .animate()
                        .fadeIn(delay: 0.ms, duration: 700.ms)
                        .slideY(begin: 0.10, curve: Curves.easeOutCubic)
                        .slideX(begin: -0.22, curve: Curves.easeOutCubic),

                    // Tagline
                    Text(
                      'SERBISYONG TAPAT  ·  SERBISYONG KABSAT',
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.pesoBlue.withOpacity(0.70),
                        letterSpacing: 2.4,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 450.ms, duration: 600.ms).slideY(begin: 0.12, curve: Curves.easeOutCubic),

                    // Location pill
                    ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                          decoration: BoxDecoration(
                            color: AppColors.glassWhite,
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(color: AppColors.glassBorder, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.location_on_rounded,
                                  color: AppColors.pesoRed, size: 17),
                              const SizedBox(width: 8),
                              Text(
                                'City of Santiago, Isabela',
                                style: GoogleFonts.poppins(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.navyMid,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 600.ms, duration: 600.ms).slideY(begin: 0.12, curve: Curves.easeOutCubic),

                    // Feature chips
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildFeatureChip(Icons.work_outline_rounded, 'Find Jobs',
                            const [Color(0xFF1565C0), Color(0xFF0D47A1)]),
                        const SizedBox(width: 10),
                        _buildFeatureChip(Icons.people_outline_rounded, 'Connect',
                            const [Color(0xFFCC2229), Color(0xFF991B1B)]),
                        const SizedBox(width: 10),
                        _buildFeatureChip(Icons.trending_up_rounded, 'Grow',
                            const [Color(0xFFF59E0B), Color(0xFFD97706)]),
                      ],
                    ).animate().fadeIn(delay: 750.ms, duration: 600.ms).slideY(begin: 0.12, curve: Curves.easeOutCubic),

                    // CTA button
                    _GetStartedButton(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AboutPage()),
                        );
                      },
                    ).animate().fadeIn(delay: 900.ms, duration: 600.ms).slideY(begin: 0.15, curve: Curves.easeOutCubic),

                    // Footer
                    Column(
                      children: [
                        Text(
                          'POWERED BY DOLE  ·  EST. 1999',
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.28),
                            letterSpacing: 1.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'v1.0.0',
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            color: Colors.white.withOpacity(0.18),
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 1050.ms, duration: 600.ms),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureChip(IconData icon, String label, List<Color> gradientColors) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.glassWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.glassBorder, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradientColors,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: gradientColors[0].withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(height: 7),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navyMid,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Floating Orb ────────────────────────────────────────────────────────────
class _FloatingOrb extends StatelessWidget {
  final double size;
  final Color color;
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final double moveY;
  final Duration duration;
  final Duration delay;

  const _FloatingOrb({
    required this.size,
    required this.color,
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.moveY,
    required this.duration,
    this.delay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .fadeIn(duration: 600.ms, delay: delay)
          .moveY(
            begin: 0,
            end: moveY,
            duration: duration,
            curve: Curves.easeInOut,
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

class _GetStartedButtonState extends State<_GetStartedButton>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late AnimationController _shimmerCtrl;
  late Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _shimmerAnim = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

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
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1565C0).withOpacity(_pressed ? 0.20 : 0.55),
                blurRadius: _pressed ? 10 : 28,
                spreadRadius: _pressed ? 0 : 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AnimatedBuilder(
              animation: _shimmerAnim,
              builder: (context, child) {
                return ShaderMask(
                  blendMode: BlendMode.srcATop,
                  shaderCallback: (bounds) {
                    final shimmerX = _shimmerAnim.value * bounds.width;
                    return LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: const [
                        Colors.transparent,
                        Colors.transparent,
                        Color(0x33FFFFFF),
                        Colors.transparent,
                        Colors.transparent,
                      ],
                      stops: [
                        0.0,
                        math.max(0.0, (shimmerX / bounds.width) - 0.15),
                        (shimmerX / bounds.width).clamp(0.0, 1.0),
                        math.min(1.0, (shimmerX / bounds.width) + 0.15),
                        1.0,
                      ],
                    ).createShader(bounds);
                  },
                  child: child!,
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'GET STARTED',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 2.8,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.20),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 16),
                  ),
                ],
              ),
            ),
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
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AuthEntryPage()),
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
            colors: [AppColors.darkBg1, AppColors.darkBg2, AppColors.darkBg3],
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
                          color: AppColors.pesoBlue.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back_rounded,
                            color: AppColors.pesoBlue, size: 20),
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
                            colors: [AppColors.pesoBlue, AppColors.navyLight],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.pesoBlue.withOpacity(0.3),
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
        color: AppColors.glassWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.glassBorder, width: 1),
        boxShadow: [
          BoxShadow(color: AppColors.pesoBlue.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 5))
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
                    color: AppColors.pesoBlue.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: AppColors.pesoBlue, size: 24),
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
        Icon(icon, color: AppColors.pesoBlue, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.navyMid,
                  height: 1.5)),
        ),
      ],
    );
  }

  Widget _buildServiceCard({required IconData icon, required String title, required String description}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.darkBg2.withOpacity(0.25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: AppColors.pesoBlue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: AppColors.pesoBlue, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.pesoBlue)),
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
        color: AppColors.pesoBlue.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.pesoBlue.withOpacity(0.35)),
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
  /// When false, this widget renders as a plain embedded form (no bottom-sheet,
  /// no slide animation, no close button).
  final bool renderAsModal;

  const LoginModal({super.key, this.isSignUp = false, this.renderAsModal = true});

  @override
  State<LoginModal> createState() => _LoginModalState();
}

class _LoginModalState extends State<LoginModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _dobController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSignUpMode = false;
  String? _selectedSex; // 'male' | 'female' — required on sign-up
  DateTime? _selectedDob;
  bool _isSubmitting = false;
  String? _authError;

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
    if (widget.renderAsModal) {
      _animationController.forward();
    } else {
      // When embedding in the auth page, we don't want the bottom-sheet slide.
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _switchMode() {
    setState(() {
      _isSignUpMode = !_isSignUpMode;
      _formKey.currentState?.reset();
      _authError = null;
    });
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final initial = _selectedDob ?? DateTime(now.year - 21, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900, 1, 1),
      lastDate: now,
    );
    if (picked == null) return;
    setState(() {
      _selectedDob = picked;
      _dobController.text =
          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    });
  }

  Future<void> _handleRegistration() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _RegistrationLoadingDialog(),
    );

    final result = await ApiService.register(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      passwordConfirmation: _confirmPasswordController.text,
      contact: _phoneController.text.trim(),
      sex: _selectedSex!,
      dateOfBirth: _dobController.text.isEmpty ? null : _dobController.text,
    );

    Navigator.pop(context);

    if (result['success'] == true) {
      // Store session — backend returns token + user on register too
      UserSession().setFromApiData(result['data'] as Map<String, dynamic>);

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const _RegistrationResultDialog(
          isSuccess: true,
          message: 'Account created! Welcome aboard.',
        ),
      );

      if (!mounted) return;
      // Load job action state after login
      await JobActionService().loadFromBackend();
      if (!mounted) return;
      await OnboardingPrefs.setPostAuthPending();
      if (!mounted) return;
      // Close modal, then post-auth onboarding → Home
      if (widget.renderAsModal) Navigator.pop(context);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PostAuthOnboardingScreen()),
      );
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
    final fill = widget.renderAsModal
        ? const Color(0xFFF8F9FA)
        : Colors.white;
    final enabledBorderColor = widget.renderAsModal
        ? Colors.grey[300]!
        : const Color(0xFFD8E1EC);
    return InputDecoration(
      labelText: label,
      labelStyle:
          TextStyle(color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
      prefixIcon: Icon(icon, color: const Color(0xFF2563EB)),
      suffixIcon: suffix,
      filled: true,
      fillColor: fill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: enabledBorderColor)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: enabledBorderColor)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.6)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 24,
          right: 24,
          top: widget.renderAsModal ? 16 : 4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
                if (widget.renderAsModal)
                  Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2))),
                SizedBox(height: widget.renderAsModal ? 24 : 8),
                if (widget.renderAsModal) ...[
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
                          _isSignUpMode
                              ? 'Create Account'
                              : 'Welcome Back',
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
                      style: TextStyle(
                          fontSize: 14, color: Colors.grey[600]),
                    ),
                  ),
                ],

                SizedBox(height: widget.renderAsModal ? 32 : 16),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_isSignUpMode) ...[
                        TextFormField(
                          controller: _firstNameController,
                          decoration: _fieldDec('First Name', Icons.person_outline_rounded),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Please enter your first name';
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _lastNameController,
                          decoration: _fieldDec('Last Name', Icons.person_outline_rounded),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Please enter your last name';
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: _fieldDec(
                            'Phone number (11 digits)',
                            Icons.phone_outlined,
                          ),
                          validator: (v) {
                            final value = v?.trim() ?? '';
                            if (value.isEmpty) {
                              return 'Please enter your mobile number';
                            }
                            final phPattern = RegExp(r'^0\d{10}$');
                            if (!phPattern.hasMatch(value)) {
                              return 'Enter 11-digit PH number (e.g. 09XXXXXXXXX)';
                            }
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
                          if (v.length < 8) return 'Password must be at least 8 characters';
                          return null;
                        },
                      ),
                      if (!_isSignUpMode) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Forgot password is not yet available.',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 0,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Forgot password?',
                              style: TextStyle(
                                color: Color(0xFF2563EB),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                      if (!_isSignUpMode && _authError != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _authError!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _dobController,
                                readOnly: true,
                                decoration: _fieldDec('Birthdate (YYYY-MM-DD)', Icons.cake_outlined),
                                onTap: _pickDob,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<String>(
                                value: _selectedSex,
                                decoration: _fieldDec('Sex', Icons.person_outline),
                                items: const [
                                  DropdownMenuItem(value: 'male', child: Text('Male')),
                                  DropdownMenuItem(value: 'female', child: Text('Female')),
                                ],
                                onChanged: (value) => setState(() => _selectedSex = value),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isSubmitting
                              ? null
                              : () async {
                            if (_formKey.currentState!.validate()) {
                                setState(() {
                                  _authError = null;
                                  _isSubmitting = true;
                                });
                              if (_isSignUpMode) {
                                  await _handleRegistration();
                                  if (mounted) {
                                    setState(() => _isSubmitting = false);
                                  }
                              } else {
                                final result = await ApiService.login(
                                  email: _emailController.text,
                                  password: _passwordController.text,
                                );

                                if (result['success'] == true) {
                                  UserSession().setFromApiData(
                                    result['data'] as Map<String, dynamic>,
                                  );
                                  if (!mounted) return;
                                  // Load job action state after login
                                  await JobActionService().loadFromBackend();
                                  if (!mounted) return;
                                  if (widget.renderAsModal) Navigator.pop(context);
                                  final needsOnboarding =
                                      await OnboardingPrefs.needsPostAuth();
                                  if (!mounted) return;
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => needsOnboarding
                                          ? const PostAuthOnboardingScreen()
                                          : const HomePage(),
                                    ),
                                  );
                                } else {
                                    final msg = result['message'] as String? ??
                                        'Login failed. Check your email and password.';
                                    if (!mounted) return;
                                    setState(() {
                                      _authError = msg;
                                      _isSubmitting = false;
                                    });
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
                          child: !widget.renderAsModal
                              ? (_isSubmitting
                                  ? const Text(
                                      'Please wait...',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    )
                                  : const Text(
                                      'Continue',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ))
                              : _isSubmitting && !_isSignUpMode
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 22,
                                          height: 22,
                                          child:
                                              CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Text(
                                          'Signing in...',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Text(
                                      _isSignUpMode ? 'Sign Up' : 'Sign In',
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700),
                                    ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (widget.renderAsModal)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                                _isSignUpMode
                                    ? 'Already have an account? '
                                    : "Don't have an account? ",
                                style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14)),
                            TextButton(
                              onPressed: _switchMode,
                              child: Text(
                                  _isSignUpMode ? 'Sign In' : 'Sign Up',
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
    );

    if (!widget.renderAsModal) return content;

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: content,
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
