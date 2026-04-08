import 'dart:math' as math;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
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
import 'session_prefs.dart';
import 'password_rules.dart';
import 'app_nav.dart';
import 'connectivity_wrapper.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_core/firebase_core.dart';
import 'notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp();
  NotificationService().initialize();

  FlutterError.onError = (FlutterErrorDetails details) {
    final message = details.exceptionAsString();
    if (kIsWeb && message.contains('_viewInsets.isNonNegative')) {
      debugPrint('Ignored web insets assertion: $message');
      return;
    }
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (Object error, StackTrace stackTrace) {
    final message = error.toString();
    if (kIsWeb && message.contains('_viewInsets.isNonNegative')) {
      debugPrint('Ignored web insets assertion: $message');
      return true;
    }
    return false;
  };

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
  static const darkBg1 = Color(0xFFFFFFFF); // top: pure white
  static const darkBg2 = Color(0xFFCFE5F7); // mid: soft sky blue
  static const darkBg3 = Color(0xFF1565C0); // bottom: PESO royal blue
  static const glassWhite = Color(0x99FFFFFF); // frosted white card (light bg)
  static const glassBorder = Color(0x331565C0); // PESO blue card border
  static const pesoBlue = Color(0xFF1565C0); // PESO official royal blue
  static const pesoRed = Color(0xFFCC2229); // PESO official red
  static const pesoGold = Color(0xFFF59E0B); // PESO official gold/yellow
}

// ─── App ─────────────────────────────────────────────────────────────────────
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

class PESOApp extends StatelessWidget {
  const PESOApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      title: 'PESO Connect',
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
      routes: {
        '/splash': (context) => const SplashScreen(),
      },
      builder: (context, child) {
        return ValueListenableBuilder<bool>(
          valueListenable: disableConnectivityModalNotifier,
          builder: (context, isDisabled, _) {
            if (isDisabled) return child!;
            return ConnectivityWrapper(child: child!);
          },
        );
      },
    );
  }
}

// ─── Splash Screen ────────────────────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mascotCtrl;
  late AnimationController _floatCtrl;
  late AnimationController _shimmerCtrl;
  late AnimationController _orbCtrl;
  late AnimationController _exitCtrl;

  late Animation<double> _mascotScale;
  late Animation<double> _mascotY;
  late Animation<double> _float;
  late Animation<double> _shimmer;
  late Animation<double> _orbMovement;
  late Animation<double> _exitScale;
  late Animation<double> _exitOpacity;

  bool _isOffline = false;
  bool _isRetrying = false;
  int _shakeKey = 0;

  @override
  void initState() {
    super.initState();

    registerJobseekerSignOut(() {
      rootNavigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const AuthEntryPage()),
        (route) => false,
      );
    });

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
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _orbCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 10000),
    )..repeat(reverse: true);
    _exitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

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
    _orbMovement = Tween<double>(begin: -20.0, end: 20.0).animate(
      CurvedAnimation(parent: _orbCtrl, curve: Curves.easeInOut),
    );
    _exitScale = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _exitCtrl, curve: Curves.easeInOutCubic),
    );
    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitCtrl, curve: Curves.easeIn),
    );

    // 1. Start Mascot Animation
    _mascotCtrl.forward();

    // 2. Parallel Background Initialization
    _initializeInternalState();
  }

  Future<void> _initializeInternalState() async {
    // Wait for 3 seconds for branding, giving the mascot + shimmer time to shine
    await Future.delayed(const Duration(milliseconds: 3000));
    if (!mounted) return;

    // ── CONNECTIVITY GATE ────────────────────────────────────────────────────
    await _proceedIfOnline();
  }

  Future<bool> _hasRealInternet() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.isEmpty || connectivityResult.contains(ConnectivityResult.none)) {
        return false;
      }
      
      // Perform a gold-standard Captive Portal HTTP check.
      // E.g., filters out fake Wi-Fis or dead cellular data by expecting a literal '204 No Content'
      // from Google's reliable network endpoint. If a network intercepts this (e.g. no load), 
      // it will return a 200 with an HTML login page or throw an exception.
      final response = await http.get(Uri.parse('https://clients3.google.com/generate_204'))
          .timeout(const Duration(seconds: 4));
          
      return response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  Future<void> _proceedIfOnline() async {
    final isOnline = await _hasRealInternet();

    if (!mounted) return;

    if (!isOnline) {
      HapticFeedback.lightImpact();
      setState(() {
        _isOffline = true;
        _shakeKey++;
        _isRetrying = false;
      });
      return; // Stay on splash — user must retry
    }

    // We have true internet — hide offline UI if it was showing
    if (_isOffline) {
      setState(() {
        _isOffline = false;
        _isRetrying = false;
      });
    }

    try {
      // Restore session from server (now safe — we have internet)
      final hasSession = await SessionPrefs.restoreSession();
      if (!mounted) return;

      // ── EXIT SEQUENCE ──────────────────────────────────────────────────────
      await _exitCtrl.forward();
      if (!mounted) return;

      if (hasSession) {
        // Load saved/applied jobs + sync FCM token before entering home
        await JobActionService().loadFromBackend();
        await NotificationService().syncTokenNow();
        if (!mounted) return;

        final needsPostAuth = await OnboardingPrefs.needsPostAuth(ignoreDebug: true);
        _navigate(
          needsPostAuth ? const PostAuthOnboardingScreen() : const HomePage(),
        );
      } else {
        final introDone = await OnboardingPrefs.isIntroDone(ignoreDebug: true);
        if (!mounted) return;

        if (!introDone) {
          _navigate(IntroOnboardingPage(
            onComplete: (introCtx) => _navigateFromIntro(introCtx),
          ));
        } else {
          _navigate(const AuthEntryPage());
        }
      }
    } catch (e) {
      debugPrint('Splash Init Error: $e');
      if (mounted) _navigate(const AuthEntryPage());
    }
  }

  Future<void> _retry() async {
    if (_isRetrying) return;
    setState(() => _isRetrying = true);

    // Small delay for UX so the button doesn't flicker
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    await _proceedIfOnline();
  }

  // ── Loading Pill (default state) ───────────────────────────────────────────
  Widget _buildLoadingPill() {
    return Container(
      key: const ValueKey('loading'),
      margin: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withOpacity(0.12),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            child: Column(
              children: [
                const _SplashDots()
                    .animate()
                    .fadeIn(delay: 1200.ms, duration: 500.ms),
                const SizedBox(height: 12),
                Text(
                  'Connecting you to opportunities...',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A).withOpacity(0.6),
                    letterSpacing: 0.3,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 1400.ms, duration: 500.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Offline Pill (no internet state) ───────────────────────────────────────
  Widget _buildOfflinePill() {
    return Container(
      key: const ValueKey('offline'),
      margin: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withOpacity(0.25),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            child: Column(
              children: [
                Icon(
                  Icons.wifi_off_rounded,
                  size: 28,
                  color: const Color(0xFF0F172A).withOpacity(0.5),
                ),
                const SizedBox(height: 10),
                Text(
                  'No internet connection',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A).withOpacity(0.7),
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: _retry,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _isRetrying
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Retry',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate(key: const ValueKey('offline_main'))
     .fadeIn(duration: 400.ms)
     .slideY(begin: 0.1, curve: Curves.easeOut)
     .animate(key: ValueKey('shake_$_shakeKey'))
     .shake(hz: 8, curve: Curves.easeInOutCubic, duration: 400.ms);
  }


  void _navigate(Widget page) {
    if (!mounted) return;
    
    // Re-enable global modal before leaving
    disableConnectivityModalNotifier.value = false;
    
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _navigateFromIntro(BuildContext introContext) {
    // Re-enable global modal before leaving
    disableConnectivityModalNotifier.value = false;
    
    Navigator.of(introContext).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) => const AuthEntryPage(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _mascotCtrl.dispose();
    _floatCtrl.dispose();
    _shimmerCtrl.dispose();
    _orbCtrl.dispose();
    _exitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

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
          child: AnimatedBuilder(
            animation: Listenable.merge([_orbCtrl, _exitCtrl]),
            builder: (context, child) {
              return Opacity(
                opacity: _exitOpacity.value,
                child: Transform.scale(
                  scale: _exitScale.value,
                  child: child,
                ),
              );
            },
            child: Stack(
              children: [
                // ── Decorative orbs (with wandering motion) ──────────────────
                AnimatedBuilder(
                  animation: _orbCtrl,
                  builder: (context, _) => Positioned(
                    top: (-size.width * 0.3) + _orbMovement.value,
                    left: (-size.width * 0.25) + (_orbMovement.value * 1.5),
                    child: Container(
                      width: size.width * 0.80,
                      height: size.width * 0.80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF1565C0).withOpacity(0.08),
                      ),
                    ),
                  ),
                ),
                AnimatedBuilder(
                  animation: _orbCtrl,
                  builder: (context, _) => Positioned(
                    bottom: (-size.width * 0.22) - (_orbMovement.value * 0.8),
                    right: (-size.width * 0.18) + _orbMovement.value,
                    child: Container(
                      width: size.width * 0.65,
                      height: size.width * 0.65,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF5B9BD5).withOpacity(0.12),
                      ),
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
                        SizedBox(height: size.height * 0.25),

                        // ── Mascot + shadow ──────────────────────────────────────
                        AnimatedBuilder(
                          animation:
                              Listenable.merge([_mascotCtrl, _floatCtrl]),
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
                                  'assets/empoy_app_icon.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => Icon(
                                    Icons.person,
                                    size: size.width * 0.22,
                                    color: const Color(0xFF1565C0)
                                        .withOpacity(0.5),
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
                                    final shimmerX =
                                        _shimmer.value * bounds.width;
                                    return LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: const [
                                        Color(0xFF0F172A), // Deep Navy
                                        Color(0xFF0F172A),
                                        Color(0xFF2563EB), // Vibrant Brand Blue
                                        Color(0xFF60A5FA), // Sky Highlight
                                        Color(0xFF0F172A),
                                        Color(0xFF0F172A),
                                      ],
                                      stops: [
                                        0.0,
                                        math.max(0.0,
                                            (shimmerX / bounds.width) - 0.25),
                                        (shimmerX / bounds.width)
                                            .clamp(0.0, 1.0),
                                        math.min(1.0,
                                            (shimmerX / bounds.width) + 0.15),
                                        math.min(1.0,
                                            (shimmerX / bounds.width) + 0.35),
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
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 5),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color:
                                      const Color(0xFF1565C0).withOpacity(0.4),
                                ),
                                color:
                                    const Color(0xFF1565C0).withOpacity(0.08),
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
                            ).animate().fadeIn(delay: 900.ms, duration: 600.ms),
                          ],
                        ),

                        const Spacer(),

                        // ── Status Pill (Loading / Offline) ──────────────────────────────────
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          child: _isOffline
                              ? _buildOfflinePill()
                              : _buildLoadingPill(),
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

class _SplashDotsState extends State<_SplashDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
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
            final brightness =
                math.sin(phase * math.pi / 1.5).clamp(0.0, 1.0).toDouble();
            final scale = 0.55 + 0.45 * brightness;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8 * scale,
              height: 8 * scale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1565C0)
                    .withOpacity(0.35 + 0.55 * brightness),
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
    final h = MediaQuery.sizeOf(context).height;
    // Keep Sign in / Create account pinned to the physical bottom; do not resize
    // the scaffold when the keyboard opens (avoids those buttons riding up).

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
      // Keep auth hero/header and form shell fixed while keyboard animates.
      // The form itself is scrollable, so fields remain usable without full-page jump.
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final maxH =
                    constraints.maxHeight.isFinite ? constraints.maxHeight : h;
                final headerOpacity = headerFade.value;

                // Staged intro: welcome starts centered (highlight, subtext hidden), eases
                // toward the top; form [authPop] starts with a low top edge then rises to
                // sit just under the header — avoids Column pinning everything at top t=0.
                final headerAlignment = Alignment.lerp(
                  Alignment.center,
                  const Alignment(0, -0.80),
                  headerMove.value,
                )!;

                // Top edge of the white card: mid-screen → below icon/title/subtext with a
                // clear gap (previous end ~158–178px let the sheet overlap the subtitle).
                final formTopEnd = maxH < 640 ? 228.0 : 252.0;
                final formTop = lerpDouble(
                  maxH * 0.48,
                  formTopEnd,
                  authPop.value,
                )!;
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
                final subtitleYOffset = lerpDouble(8, 0, subtitleReveal) ?? 0;

                // Tighter header on short viewports so title + wrapped subtitle fit.
                final compact = maxH < 640;
                final iconSz = compact ? 52.0 : 64.0;
                final titleSz = compact ? 21.0 : 24.0;
                final subSize = compact ? 12.5 : 13.0;

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Align(
                      alignment: headerAlignment,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          24,
                          compact ? 4 : 8,
                          24,
                          compact ? 14 : 18,
                        ),
                        child: Opacity(
                          opacity: headerOpacity,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Transform.scale(
                                scale: iconScale,
                                child: Icon(
                                  Icons.verified_user_rounded,
                                  size: iconSz,
                                  color:
                                      const Color(0xFF2563EB).withOpacity(0.9),
                                ),
                              ),
                              SizedBox(height: compact ? 10 : 14),
                              Text(
                                'Welcome to PESO Connect',
                                style: GoogleFonts.poppins(
                                  fontSize: titleSz,
                                  fontWeight: FontWeight.w800,
                                  color: titleColor,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: compact ? 6 : 8),
                              Transform.translate(
                                offset: Offset(0, subtitleYOffset),
                                child: Opacity(
                                  opacity: subtitleOpacity,
                                  child: Text(
                                    'Sign in to continue, or create an account to start applying for jobs and events.',
                                    style: GoogleFonts.poppins(
                                      fontSize: subSize,
                                      height: 1.4,
                                      color: subtitleColor,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              // Air below subtext so the sheet cannot ride up over it.
                              SizedBox(height: compact ? 10 : 12),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 24,
                      right: 24,
                      top: formTop,
                      bottom: 10,
                      child: Opacity(
                        opacity: authOpacity,
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
                                  color:
                                      const Color(0xFF0F172A).withOpacity(0.09),
                                  blurRadius: 30,
                                  offset: const Offset(0, 14),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(14, 14, 14, 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: SingleChildScrollView(
                                      physics: const BouncingScrollPhysics(),
                                      keyboardDismissBehavior:
                                          ScrollViewKeyboardDismissBehavior
                                              .onDrag,
                                      child: Padding(
                                        padding: EdgeInsets.fromLTRB(
                                          4,
                                          6,
                                          4,
                                          20,
                                        ),
                                        child: LoginModal(
                                          key: ValueKey<bool>(_isSignUpMode),
                                          isSignUp: _isSignUpMode,
                                          renderAsModal: false,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],
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
    final size = MediaQuery.sizeOf(context);

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
                    colors: [
                      AppColors.darkBg1,
                      AppColors.darkBg2,
                      AppColors.darkBg3
                    ],
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.glassWhite,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                                color: AppColors.glassBorder, width: 1),
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
                                        color: AppColors.pesoBlue.withOpacity(
                                            0.60 * _glowAnim.value),
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
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 22),
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
                    )
                        .animate()
                        .fadeIn(delay: 450.ms, duration: 600.ms)
                        .slideY(begin: 0.12, curve: Curves.easeOutCubic),

                    // Location pill
                    ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 13),
                          decoration: BoxDecoration(
                            color: AppColors.glassWhite,
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(
                                color: AppColors.glassBorder, width: 1),
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
                    )
                        .animate()
                        .fadeIn(delay: 600.ms, duration: 600.ms)
                        .slideY(begin: 0.12, curve: Curves.easeOutCubic),

                    // Feature chips
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildFeatureChip(
                            Icons.work_outline_rounded,
                            'Find Jobs',
                            const [Color(0xFF1565C0), Color(0xFF0D47A1)]),
                        const SizedBox(width: 10),
                        _buildFeatureChip(
                            Icons.people_outline_rounded,
                            'Connect',
                            const [Color(0xFFCC2229), Color(0xFF991B1B)]),
                        const SizedBox(width: 10),
                        _buildFeatureChip(Icons.trending_up_rounded, 'Grow',
                            const [Color(0xFFF59E0B), Color(0xFFD97706)]),
                      ],
                    )
                        .animate()
                        .fadeIn(delay: 750.ms, duration: 600.ms)
                        .slideY(begin: 0.12, curve: Curves.easeOutCubic),

                    // CTA button
                    _GetStartedButton(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AboutPage()),
                        );
                      },
                    )
                        .animate()
                        .fadeIn(delay: 900.ms, duration: 600.ms)
                        .slideY(begin: 0.15, curve: Curves.easeOutCubic),

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

  Widget _buildFeatureChip(
      IconData icon, String label, List<Color> gradientColors) {
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
                color:
                    const Color(0xFF1565C0).withOpacity(_pressed ? 0.20 : 0.55),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                            Icon(Icons.login_rounded,
                                color: Colors.white, size: 18),
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
                            _buildInfoItem(
                                'A non-fee charging employment service facility',
                                Icons.check_circle_outline_rounded),
                            const SizedBox(height: 12),
                            _buildInfoItem(
                                'Established under Republic Act No. 8759 (PESO Act of 1999)',
                                Icons.gavel_rounded),
                            const SizedBox(height: 12),
                            _buildInfoItem(
                                'Operates at the local government level',
                                Icons.location_city_rounded),
                            const SizedBox(height: 12),
                            _buildInfoItem(
                                'Managed by the Department of Labor and Employment (DOLE)',
                                Icons.business_center_rounded),
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
                                    'Matches job seekers with employers locally and abroad.'),
                            const SizedBox(height: 16),
                            _buildServiceCard(
                                icon: Icons.school_outlined,
                                title: 'Career Guidance',
                                description:
                                    'Provides counseling, career planning, and job search strategies.'),
                            const SizedBox(height: 16),
                            _buildServiceCard(
                                icon: Icons.trending_up_rounded,
                                title: 'Skills Training',
                                description:
                                    'Offers training programs to enhance employability.'),
                            const SizedBox(height: 16),
                            _buildServiceCard(
                                icon: Icons.event_rounded,
                                title: 'Job Fairs',
                                description:
                                    'Organizes events to connect job seekers with hiring companies.'),
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

  Widget _buildSectionCard(
      {required String title, required IconData icon, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.glassWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.glassBorder, width: 1),
        boxShadow: [
          BoxShadow(
              color: AppColors.pesoBlue.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5))
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

  Widget _buildServiceCard(
      {required IconData icon,
      required String title,
      required String description}) {
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
                Text(title,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.pesoBlue)),
                const SizedBox(height: 6),
                Text(description,
                    style: TextStyle(
                        fontSize: 14, color: Colors.grey[700], height: 1.4)),
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

  const LoginModal(
      {super.key, this.isSignUp = false, this.renderAsModal = true});

  @override
  State<LoginModal> createState() => _LoginModalState();
}

class _LoginModalState extends State<LoginModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _middleInitialController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _dobController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSignUpMode = false;
  String? _selectedSex;
  DateTime? _selectedDob;
  bool _isSubmitting = false;
  String? _authError;
  bool _rememberMe = true;
  Timer? _otpReopenCooldownTimer;
  int _otpReopenCooldownSeconds = 0;
  String? _serverEmailError;
  Timer? _emailDebounce;

  @override
  void initState() {
    super.initState();
    _isSignUpMode = widget.isSignUp;
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _animationController, curve: Curves.easeOutCubic));
    if (widget.renderAsModal) {
      _animationController.forward();
    } else {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _otpReopenCooldownTimer?.cancel();
    _emailDebounce?.cancel();
    _firstNameController.dispose();
    _middleInitialController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _setMode(bool isSignUp) {
    if (_isSignUpMode == isSignUp) return;
    setState(() {
      _isSignUpMode = isSignUp;
      _formKey.currentState?.reset();
      _authError = null;
      _serverEmailError = null;
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
      _selectedDob = DateTime(picked.year, picked.month, picked.day);
      _dobController.text =
          '${_selectedDob!.year.toString().padLeft(4, '0')}-${_selectedDob!.month.toString().padLeft(2, '0')}-${_selectedDob!.day.toString().padLeft(2, '0')}';
    });
  }

  Future<void> _handleRegistration() async {
    Map<String, dynamic> result;
    result = await ApiService.register(
      firstName: _firstNameController.text.trim(),
      middleInitial: _middleInitialController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      passwordConfirmation: _confirmPasswordController.text,
      contact: _phoneController.text.trim(),
      sex: _selectedSex!,
      dateOfBirth: _dobController.text.isEmpty ? null : _dobController.text,
    );

    if (result['success'] == true) {
      final data = result['data'] as Map<String, dynamic>? ?? {};
      final initialRemainingDailySends =
          _initialRemainingDailySendsFromAuthResponse(result);
      final otpResult = await showDialog<Map<String, dynamic>>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _OtpVerificationDialog(
          email: _emailController.text.trim(),
          initialRemainingDailySends: initialRemainingDailySends,
        ),
      );
      if (otpResult == null || otpResult['success'] != true) {
        _handleOtpCancelCooldown();
        return;
      }
      final otpData = otpResult['data'] as Map<String, dynamic>? ?? data;
      UserSession().setFromApiData(otpData);
      final token = UserSession().token;
      if (token != null && token.isNotEmpty) {
        await SessionPrefs.saveToken(token);
      }
      if (!mounted) return;
      await JobActionService().loadFromBackend();
      if (!mounted) return;
      await OnboardingPrefs.setPostAuthPending();
      if (!mounted) return;
      if (widget.renderAsModal) Navigator.pop(context);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => const PostAuthOnboardingScreen()),
      );
    } else {
      if (result['requires_verification'] == true) {
        if (!mounted) return;
        setState(() {
          _isSignUpMode = false;
          _passwordController.clear();
          _confirmPasswordController.clear();
          _authError =
              'This email is already registered but not verified. Sign in to continue verification.';
          _isSubmitting = false;
        });
        return;
      }

      String errorMessage = 'Registration failed';
      String? emailError;
      if (result['message'] != null) {
        errorMessage = result['message'];
        if (errorMessage.toLowerCase().contains('email') &&
            (errorMessage.toLowerCase().contains('registered') ||
                errorMessage.toLowerCase().contains('taken'))) {
          emailError = 'Email is already registered.';
        }
      } else if (result['errors'] != null) {
        final errors = result['errors'] as Map<String, dynamic>;
        final errorList = <String>[];
        errors.forEach((key, value) {
          if (value is List && value.isNotEmpty) {
            final msg = value.first.toString();
            errorList.add(msg);
            if (key == 'email') {
              emailError = 'Email is already registered.';
            }
          }
        });
        if (errorList.isNotEmpty) {
          errorMessage = errorList.join('\n');
        }
      }

      if (!mounted) return;
      setState(() {
        _serverEmailError = emailError;
        _isSubmitting = false;
      });

      if (emailError != null)
        return; // If we showed it inline, don't show dialog as well optionally

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

  void _handleOtpCancelCooldown() {
    _clearAuthFieldsAfterOtpCancel();
    _startOtpReopenCooldown();
    if (!mounted) return;
    setState(() {
      _authError =
          'Verification cancelled. Please wait ${_otpReopenCooldownSeconds}s before requesting OTP again.';
    });
  }

  void _clearAuthFieldsAfterOtpCancel() {
    _firstNameController.clear();
    _lastNameController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    _dobController.clear();
    _phoneController.clear();
    _selectedDob = null;
    _selectedSex = null;
    _isSignUpMode = false;
  }

  /// Same root + nested shape for register vs sign-in OTP responses.
  int? _initialRemainingDailySendsFromAuthResponse(
      Map<String, dynamic> result) {
    final top = (result['remaining_daily_sends'] as num?)?.toInt();
    if (top != null) return top;
    final data = result['data'];
    if (data is Map<String, dynamic>) {
      return (data['remaining_daily_sends'] as num?)?.toInt();
    }
    return null;
  }

  Future<void> _openMailto(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final emailCtrl = TextEditingController(text: _emailController.text.trim());
    var sending = false;
    void closeDialogSafely(BuildContext dialogContext) {
      FocusManager.instance.primaryFocus?.unfocus();
      if (!dialogContext.mounted) return;
      Navigator.of(dialogContext).pop();
    }
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setLocal) {
              return AlertDialog(
              title: const Text('Forgot password'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Enter your registered email. We’ll send a link to reset your password for PESO Connect.',
                    style: TextStyle(
                        fontSize: 13.5, height: 1.35, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: sending ? null : () => closeDialogSafely(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: sending
                      ? null
                      : () async {
                          final email = emailCtrl.text.trim();
                          if (email.isEmpty || !email.contains('@')) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Please enter a valid email address.'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }
                          setLocal(() => sending = true);
                          final res = await ApiService.forgotJobseekerPassword(
                              email: email);
                          if (!ctx.mounted) return;
                          // Do not call setLocal before pop: rebuilding StatefulBuilder while
                          // closing the route can assert in InheritedWidget disposal.
                          closeDialogSafely(ctx);
                          if (!mounted) return;
                          final ok = res['success'] == true;
                          String msg;
                          if (ok) {
                            msg = (res['message'] as String?)?.trim() ??
                                'Check your email for the reset link.';
                          } else {
                            final errs = res['errors'];
                            if (errs is Map &&
                                errs['email'] is List &&
                                (errs['email'] as List).isNotEmpty) {
                              msg = (errs['email'] as List).first.toString();
                            } else {
                              msg = (res['message'] as String?)?.trim() ??
                                  'Could not send reset link. Try again later.';
                            }
                          }
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(msg),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 5),
                                action: ok
                                    ? SnackBarAction(
                                        label: 'Open email',
                                        onPressed: () =>
                                            unawaited(_openMailto(email)),
                                      )
                                    : null,
                              ),
                            );
                          });
                        },
                  child: Text(sending ? 'Sending…' : 'Send link'),
                ),
              ],
              );
            },
          );
        },
      );
    } finally {
      // Defer disposal one frame so the dialog TextField fully detaches
      // before controller teardown (prevents close-time crashes with keyboard up).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        emailCtrl.dispose();
      });
    }
  }

  void _startOtpReopenCooldown([int seconds = 3]) {
    _otpReopenCooldownTimer?.cancel();
    _otpReopenCooldownSeconds = seconds;
    _otpReopenCooldownTimer =
        Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_otpReopenCooldownSeconds <= 1) {
        timer.cancel();
        setState(() {
          _otpReopenCooldownSeconds = 0;
          if (_authError != null &&
              _authError!.contains('Verification cancelled. Please wait')) {
            _authError = null;
          }
        });
      } else {
        setState(() {
          _otpReopenCooldownSeconds -= 1;
          if (_authError != null &&
              _authError!.contains('Verification cancelled. Please wait')) {
            _authError =
                'Verification cancelled. Please wait ${_otpReopenCooldownSeconds}s before requesting OTP again.';
          }
        });
      }
    });
    if (mounted) setState(() {});
  }

  Widget _passwordRequirementRow(String label, bool ok) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            ok ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 16,
            color: ok ? const Color(0xFF16A34A) : const Color(0xFFCBD5E1),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: ok ? const Color(0xFF166534) : const Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordRequirements() {
    if (!_isSignUpMode) return const SizedBox.shrink();
    final p = _passwordController.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Password must include:',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
        _passwordRequirementRow(
          'At least 8 characters',
          PasswordRules.hasMinLength(p),
        ),
        _passwordRequirementRow(
          'Uppercase & lowercase letters',
          PasswordRules.hasUppercase(p) && PasswordRules.hasLowercase(p),
        ),
        _passwordRequirementRow(
          'At least one number',
          PasswordRules.hasNumber(p),
        ),
        _passwordRequirementRow(
          'At least one special character',
          PasswordRules.hasSymbol(p),
        ),
      ],
    );
  }

  InputDecoration _fieldDec(String label, IconData icon, {Widget? suffix}) {
    final fill = widget.renderAsModal ? const Color(0xFFF8F9FA) : Colors.white;
    final enabledBorderColor =
        widget.renderAsModal ? Colors.grey[300]! : const Color(0xFFD8E1EC);
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
          color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
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

  Widget _buildTopErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Color(0xFF991B1B), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF991B1B),
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => setState(() => _authError = null),
            child: const Icon(Icons.close_rounded,
                color: Color(0xFF991B1B), size: 18),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: 24,
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
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _setMode(false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: !_isSignUpMode
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: !_isSignUpMode
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ]
                              : null,
                          border: !_isSignUpMode
                              ? Border.all(
                                  color: const Color(0xFFE2E8F0), width: 1)
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            'LOGIN',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: !_isSignUpMode
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFF64748B),
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _setMode(true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color:
                              _isSignUpMode ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: _isSignUpMode
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ]
                              : null,
                          border: _isSignUpMode
                              ? Border.all(
                                  color: const Color(0xFFE2E8F0), width: 1)
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            'SIGN UP',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _isSignUpMode
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFF64748B),
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isSignUpMode ? 'Create Account' : 'Welcome Back',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.renderAsModal)
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    color: Colors.grey[600],
                    onPressed: () => Navigator.pop(context),
                  ),
              ],
            ),
            SizedBox(height: widget.renderAsModal ? 32 : 16),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!_isSignUpMode && _authError != null) ...[
                    _buildTopErrorBanner(_authError!),
                    const SizedBox(height: 12),
                  ],
                  if (_isSignUpMode) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _firstNameController,
                            decoration: _fieldDec('First Name', Icons.person_outline_rounded),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Please enter your first name';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            controller: _middleInitialController,
                            textCapitalization: TextCapitalization.characters,
                            maxLength: 2,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(1),
                              UpperCaseTextFormatter(),
                            ],
                            decoration: _fieldDec('M.I.', Icons.text_format_rounded).copyWith(counterText: ''),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _lastNameController,
                      decoration:
                          _fieldDec('Last Name', Icons.person_outline_rounded),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return 'Please enter your last name';
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
                    decoration: _fieldDec('Email', Icons.email_outlined),
                    onChanged: (v) {
                      if (_serverEmailError != null) {
                        setState(() => _serverEmailError = null);
                      }
                      if (!_isSignUpMode) return;
                      _emailDebounce?.cancel();
                      if (v.trim().isEmpty ||
                          !v.contains('@') ||
                          !v.contains('.')) return;
                      _emailDebounce =
                          Timer(const Duration(milliseconds: 600), () async {
                        final res =
                            await ApiService.checkJobseekerEmail(v.trim());
                        if (mounted &&
                            _isSignUpMode &&
                            _emailController.text.trim() == v.trim()) {
                          if (res['success'] == true && res['exists'] == true) {
                            setState(() => _serverEmailError =
                                'Email is already registered.');
                          }
                        }
                      });
                    },
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (_isSignUpMode &&
                          (!v.contains('@') || !v.contains('.'))) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  if (_isSignUpMode && _serverEmailError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 4),
                      child: Text(
                        _serverEmailError!,
                        style: const TextStyle(
                          color: Color(0xFFDC2626),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    onChanged: (_) => setState(() {}),
                    decoration: _fieldDec(
                      'Password',
                      Icons.lock_outline_rounded,
                      suffix: IconButton(
                        icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: Colors.grey[600]),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (_isSignUpMode) {
                        return PasswordRules.validateStrongPassword(v);
                      }
                      return null;
                    },
                  ),
                  if (_isSignUpMode) ...[
                    _buildPasswordRequirements(),
                    const SizedBox(height: 8),
                  ],
                  if (!_isSignUpMode) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () =>
                              setState(() => _rememberMe = !_rememberMe),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 2, vertical: 4),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Checkbox(
                                    value: _rememberMe,
                                    onChanged: (v) => setState(
                                        () => _rememberMe = v ?? false),
                                    activeColor: const Color(0xFF2563EB),
                                    visualDensity: VisualDensity.compact,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Remember me',
                                  style: TextStyle(
                                    color: Color(0xFF475569),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _showForgotPasswordDialog,
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
                      ],
                    ),
                  ],
                  if (!_isSignUpMode) const SizedBox(height: 6),
                  if (_isSignUpMode) ...[
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      onChanged: (_) => setState(() {}),
                      decoration: _fieldDec(
                        'Confirm Password',
                        Icons.lock_outline_rounded,
                        suffix: IconButton(
                          icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: Colors.grey[600]),
                          onPressed: () => setState(() =>
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty)
                          return 'Please confirm your password';
                        if (v != _passwordController.text)
                          return 'Passwords do not match';
                        return null;
                      },
                    ),
                    if (_confirmPasswordController.text.isNotEmpty &&
                        _confirmPasswordController.text !=
                            _passwordController.text)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Passwords do not match',
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _dobController,
                            readOnly: true,
                            decoration: _fieldDec(
                                'Birthdate (YYYY-MM-DD)', Icons.cake_outlined),
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
                              DropdownMenuItem(
                                  value: 'male', child: Text('Male')),
                              DropdownMenuItem(
                                  value: 'female', child: Text('Female')),
                            ],
                            onChanged: (value) =>
                                setState(() => _selectedSex = value),
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
                      onPressed: _isSubmitting ||
                              (_isSignUpMode && _serverEmailError != null)
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
                                  if (_otpReopenCooldownSeconds > 0) {
                                    if (!mounted) return;
                                    setState(() {
                                      _authError =
                                          'Please wait ${_otpReopenCooldownSeconds}s before requesting OTP again.';
                                      _isSubmitting = false;
                                    });
                                    return;
                                  }
                                  final result = await ApiService.login(
                                    email: _emailController.text,
                                    password: _passwordController.text,
                                  );

                                  if (result['success'] == true) {
                                    UserSession().setFromApiData(
                                      result['data'] as Map<String, dynamic>,
                                    );
                                    final token = UserSession().token;
                                    if (token != null && token.isNotEmpty) {
                                      await SessionPrefs.saveToken(token);
                                    }
                                    if (!mounted) return;
                                    // Load job action state after login
                                    await JobActionService().loadFromBackend();
                                    await NotificationService().syncTokenNow();
                                    if (!mounted) return;
                                    if (widget.renderAsModal)
                                      Navigator.pop(context);
                                    final needsOnboarding =
                                        await OnboardingPrefs.needsPostAuth(
                                            ignoreDebug: true);
                                    if (!mounted) return;
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => needsOnboarding
                                            ? const PostAuthOnboardingScreen()
                                            : const HomePage(),
                                      ),
                                    );
                                  } else if (result['requires_verification'] ==
                                      true) {
                                    if (!mounted) return;
                                    final initialRemainingDailySends =
                                        _initialRemainingDailySendsFromAuthResponse(
                                            result);
                                    final otpResult =
                                        await showDialog<Map<String, dynamic>>(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (_) => _OtpVerificationDialog(
                                        email: _emailController.text.trim(),
                                        initialRemainingDailySends:
                                            initialRemainingDailySends,
                                      ),
                                    );
                                    if (otpResult != null &&
                                        otpResult['success'] == true) {
                                      final otpData = otpResult['data']
                                              as Map<String, dynamic>? ??
                                          {};
                                      UserSession().setFromApiData(otpData);
                                      final token = UserSession().token;
                                      if (token != null && token.isNotEmpty) {
                                        await SessionPrefs.saveToken(token);
                                      }
                                      if (!mounted) return;
                                      await JobActionService()
                                          .loadFromBackend();
                                      if (!mounted) return;
                                      if (widget.renderAsModal)
                                        Navigator.pop(context);
                                      final needsOnboarding =
                                          await OnboardingPrefs.needsPostAuth(
                                              ignoreDebug: true);
                                      if (!mounted) return;
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => needsOnboarding
                                              ? const PostAuthOnboardingScreen()
                                              : const HomePage(),
                                        ),
                                      );
                                      return;
                                    }
                                    _handleOtpCancelCooldown();
                                    if (!mounted) return;
                                    setState(() {
                                      _isSubmitting = false;
                                    });
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
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
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
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
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
                  const SizedBox(height: 12),
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

class _OtpVerificationDialog extends StatefulWidget {
  final String email;
  final int? initialRemainingDailySends;
  const _OtpVerificationDialog({
    required this.email,
    this.initialRemainingDailySends,
  });

  @override
  State<_OtpVerificationDialog> createState() => _OtpVerificationDialogState();
}

class _OtpVerificationDialogState extends State<_OtpVerificationDialog> {
  final _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();
  Timer? _cooldownTimer;
  int _resendCooldown = 0;
  int? _remainingDailySends;
  String? _statusNote;
  bool _statusIsWarning = false;
  bool _isVerifying = false;
  bool _isResending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _remainingDailySends = widget.initialRemainingDailySends;
    _startResendCooldown(const Duration(seconds: 60));
    _otpFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
    _otpController.addListener(() {
      final raw = _otpController.text;
      final digitsOnly = raw.replaceAll(RegExp(r'[^0-9]'), '');
      final limited =
          digitsOnly.length > 6 ? digitsOnly.substring(0, 6) : digitsOnly;
      if (limited != raw) {
        _otpController.value = TextEditingValue(
          text: limited,
          selection: TextSelection.collapsed(offset: limited.length),
        );
      }
      if (_error != null) {
        setState(() => _error = null);
      } else {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(
          () => _error = 'Please enter the 6-digit OTP sent to your email.');
      return;
    }
    setState(() {
      _isVerifying = true;
      _error = null;
    });
    final res = await ApiService.verifyJobseekerOtp(
      email: widget.email,
      otpCode: otp,
    );
    if (!mounted) return;
    setState(() => _isVerifying = false);
    if (res['success'] == true) {
      setState(() {
        _statusNote = 'Email verified successfully. Redirecting...';
        _statusIsWarning = false;
      });
      FocusManager.instance.primaryFocus?.unfocus();
      Navigator.of(context, rootNavigator: true).pop(res);
      return;
    }
    final msg = _friendlyOtpMessage(res);
    setState(() {
      _error = msg;
      _statusNote = null;
    });
  }

  Widget _buildOtpBoxes() {
    final code = _otpController.text;
    final isFocused = _otpFocusNode.hasFocus;
    return GestureDetector(
      onTap: () => FocusScope.of(context).requestFocus(_otpFocusNode),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD6DFEE)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: TextField(
                controller: _otpController,
                focusNode: _otpFocusNode,
                autofocus: true,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                enableInteractiveSelection: false,
                cursorColor: Colors.transparent,
                style: const TextStyle(color: Colors.transparent),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  counterText: '',
                  contentPadding: EdgeInsets.zero,
                ),
                maxLength: 6,
                onTapOutside: (_) => FocusScope.of(context).unfocus(),
              ),
            ),
            IgnorePointer(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  final hasChar = index < code.length;
                  final isActive = isFocused &&
                      (index == code.length || (code.length == 6 && index == 5));
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 40,
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isActive
                            ? const Color(0xFF4F67A9)
                            : const Color(0xFFD7E0EF),
                        width: isActive ? 2 : 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      hasChar ? code[index] : '',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: Color(0xFF111827),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _resend() async {
    if (_resendCooldown > 0) return;
    setState(() {
      _isResending = true;
      _error = null;
    });
    final res = await ApiService.resendJobseekerOtp(email: widget.email);
    if (!mounted) return;
    setState(() => _isResending = false);
    final msg = _friendlyOtpMessage(res);
    final retryAfter = (res['retry_after_seconds'] as num?)?.toInt();
    final cooldown = (res['cooldown_seconds'] as num?)?.toInt();
    final remaining = (res['remaining_daily_sends'] as num?)?.toInt();
    if (remaining != null) {
      setState(() => _remainingDailySends = remaining);
    }
    if (res['success'] == true) {
      if (cooldown != null && cooldown > 0) {
        _startResendCooldown(Duration(seconds: cooldown));
      } else {
        _startResendCooldown(const Duration(seconds: 60));
      }
      setState(() {
        _statusNote = 'New OTP sent. Check your email.';
        _statusIsWarning = false;
      });
    } else if (retryAfter != null && retryAfter > 0) {
      _startResendCooldown(Duration(seconds: retryAfter));
      setState(() {
        _statusNote = 'Please wait before requesting another OTP.';
        _statusIsWarning = true;
      });
    } else {
      setState(() {
        _statusNote = msg;
        _statusIsWarning = true;
      });
    }
  }

  void _startResendCooldown(Duration duration) {
    _cooldownTimer?.cancel();
    setState(() => _resendCooldown = duration.inSeconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCooldown <= 1) {
        timer.cancel();
        setState(() => _resendCooldown = 0);
      } else {
        setState(() => _resendCooldown--);
      }
    });
  }

  String _friendlyOtpMessage(Map<String, dynamic> res) {
    final raw = (res['message'] as String?)?.trim();
    final message = (raw ?? '').toLowerCase();
    if (message.contains('daily otp limit reached') ||
        message.contains('7/day')) {
      return 'You have reached today\'s OTP limit (7/day). Try again tomorrow.';
    }
    if (message.contains('expired after 24 hours') ||
        message.contains('deleted')) {
      return 'Your unverified account expired after 24 hours. Please register again.';
    }
    if (message.contains('invalid verification code')) {
      return 'Incorrect OTP. Please check the code and try again.';
    }
    if (message.contains('verification code has expired')) {
      return 'This OTP has expired. Tap Resend OTP to get a new code.';
    }
    if (message.contains('please wait')) {
      return 'Please wait before requesting another OTP.';
    }
    if (message.contains('failed to send otp')) {
      return 'Unable to send OTP right now. Please try again shortly.';
    }
    return raw ?? 'Something went wrong. Please try again.';
  }

  Widget _buildStatusBanner() {
    if (_statusNote == null || _statusNote!.isEmpty) {
      return const SizedBox.shrink();
    }
    final color =
        _statusIsWarning ? const Color(0xFFB45309) : const Color(0xFF1D4ED8);
    final bg =
        _statusIsWarning ? const Color(0xFFFFF7ED) : const Color(0xFFEFF6FF);
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _statusIsWarning
                ? Icons.info_outline_rounded
                : Icons.check_circle_outline_rounded,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _statusNote!,
              style: TextStyle(
                fontSize: 12.5,
                color: color,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        FocusManager.instance.primaryFocus?.unfocus();
        return true;
      },
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            const Text(
              'Verify your email',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter the 6-digit OTP sent to ${widget.email}.',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            _buildOtpBoxes(),
            _buildStatusBanner(),
            if (_remainingDailySends != null) ...[
              const SizedBox(height: 8),
              Text(
                '$_remainingDailySends sends left today',
                style: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(
                  color: Color(0xFFDC2626),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed:
                        _isResending || _isVerifying || _resendCooldown > 0
                            ? null
                            : _resend,
                    child: Text(
                      _isResending
                          ? 'Resending...'
                          : _resendCooldown > 0
                              ? 'Resend in ${_resendCooldown}s'
                              : 'Resend OTP',
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    TextButton(
                      onPressed: _isVerifying
                          ? null
                          : () {
                              FocusManager.instance.primaryFocus?.unfocus();
                              Navigator.of(context, rootNavigator: true).pop();
                            },
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: (_isVerifying || _isResending) ? null : _verify,
                      child: Text(_isVerifying ? 'Verifying...' : 'Verify'),
                    ),
                  ],
                ),
              ],
            ),
            ],
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
  State<_RegistrationLoadingDialog> createState() =>
      _RegistrationLoadingDialogState();
}

class _RegistrationLoadingDialogState extends State<_RegistrationLoadingDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat();
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
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 10))
          ],
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
                          border: Border.all(
                              color: const Color(0xFFE2E8F0), width: 4),
                        ),
                        child: CustomPaint(
                          painter: _LoadingArcPainter(
                              color: const Color(0xFF2563EB), strokeWidth: 4),
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
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05), blurRadius: 10)
                    ],
                  ),
                  child: ClipOval(
                      child: Image.asset('assets/PESOLOGO.jpg',
                          fit: BoxFit.cover)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Creating your account',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A))),
            const SizedBox(height: 8),
            Text('Please wait...',
                style: TextStyle(fontSize: 14, color: Colors.grey[600])),
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

  const _RegistrationResultDialog(
      {required this.isSuccess, required this.message});

  @override
  State<_RegistrationResultDialog> createState() =>
      _RegistrationResultDialogState();
}

class _RegistrationResultDialogState extends State<_RegistrationResultDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.0, 0.5, curve: Curves.easeOut)),
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
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 30,
                      offset: const Offset(0, 10))
                ],
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
                      border:
                          Border.all(color: const Color(0xFFE2E8F0), width: 2),
                    ),
                    child: ClipOval(
                        child: Image.asset('assets/PESOLOGO.jpg',
                            fit: BoxFit.cover)),
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
                        widget.isSuccess
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        size: 50,
                        color: widget.isSuccess
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.isSuccess ? 'Success!' : 'Registration Failed',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: widget.isSuccess
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 14, color: Colors.grey[600], height: 1.5),
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
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text('Try Again',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
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

enum ToastType { success, error, info }

class CustomToast {
  static void show(
    BuildContext context, {
    required String message,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 4),
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        type: type,
        onDismiss: () {
          if (entry.mounted) entry.remove();
        },
      ),
    );

    overlay.insert(entry);
    Future.delayed(duration, () {
      if (entry.mounted) {
        entry.remove();
      }
    });
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final ToastType type;
  final VoidCallback onDismiss;

  const _ToastWidget({
    required this.message,
    required this.type,
    required this.onDismiss,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = switch (widget.type) {
      ToastType.success => const Color(0xFF10B981),
      ToastType.error => const Color(0xFFEF4444),
      ToastType.info => const Color(0xFF2563EB),
    };

    final icon = switch (widget.type) {
      ToastType.success => Icons.check_circle_rounded,
      ToastType.error => Icons.error_rounded,
      ToastType.info => Icons.info_rounded,
    };

    return Positioned(
      top: MediaQuery.paddingOf(context).top + 20,
      right: 20,
      child: SlideTransition(
        position: _offsetAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: math.min(MediaQuery.sizeOf(context).width - 40, 320.0),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(color: color.withOpacity(0.2), width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      _controller.reverse().then((_) => widget.onDismiss());
                    },
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.grey[400],
                      size: 18,
                    ),
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
