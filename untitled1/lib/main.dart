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
import 'package:hugeicons/hugeicons.dart';
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
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'notification_service.dart';
import 'locale_service.dart';
import 'app_config.dart';
import 'auth/signup_wizard.dart';

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

  await LocaleService.instance.load();

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

class PESOApp extends StatefulWidget {
  const PESOApp({super.key});

  @override
  State<PESOApp> createState() => _PESOAppState();
}

class _PESOAppState extends State<PESOApp> {
  @override
  void initState() {
    super.initState();
    LocaleService.instance.addListener(_onLocaleChanged);
  }

  @override
  void dispose() {
    LocaleService.instance.removeListener(_onLocaleChanged);
    super.dispose();
  }

  void _onLocaleChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      title: kAppDisplayName,
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: scaffoldMessengerKey,
      locale: LocaleService.instance.locale,
      supportedLocales: AppLocales.supported,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
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
    // Wait for 3 seconds for branding / mascot + title shimmer
    await Future.delayed(const Duration(milliseconds: 3000));
    if (!mounted) return;

    // ── CONNECTIVITY GATE ────────────────────────────────────────────────────
    await _proceedIfOnline();
  }

  Future<bool> _hasRealInternet() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.isEmpty ||
          connectivityResult.contains(ConnectivityResult.none)) {
        return false;
      }

      // Local API debugging: LAN-only or blocked Google endpoints should not
      // strand the user on the splash "offline" UI.
      if (kDebugMode && ApiService.isTargetingLocalDevHost) {
        return true;
      }

      // Perform a gold-standard Captive Portal HTTP check.
      // E.g., filters out fake Wi-Fis or dead cellular data by expecting a literal '204 No Content'
      // from Google's reliable network endpoint. If a network intercepts this (e.g. no load),
      // it will return a 200 with an HTML login page or throw an exception.
      final response = await http
          .get(Uri.parse('https://clients3.google.com/generate_204'))
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

        final needsPostAuth =
            await OnboardingPrefs.needsPostAuth(ignoreDebug: true);
        _navigate(
          needsPostAuth ? const PostAuthOnboardingScreen() : const HomePage(),
        );
      } else {
        final hasGuestSession = await SessionPrefs.isGuestSession();
        if (!mounted) return;

        if (hasGuestSession) {
          UserSession().enterGuestMode();
          JobActionService().clear();
          _navigate(const HomePage());
          return;
        }

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
                ).animate().fadeIn(delay: 1400.ms, duration: 500.ms),
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
    )
        .animate(key: const ValueKey('offline_main'))
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
                Positioned(
                  bottom: size.height * 0.12,
                  right: size.width * 0.02,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF93C5FD).withOpacity(0.35),
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
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // ── Mascot + shadow (original asset) ─────────────────────
                                AnimatedBuilder(
                                  animation: Listenable.merge(
                                      [_mascotCtrl, _floatCtrl]),
                                  builder: (context, child) {
                                    return Transform.translate(
                                      offset: Offset(
                                          0, _mascotY.value + _float.value),
                                      child: Transform.scale(
                                        scale: _mascotScale.value,
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: Stack(
                                    alignment: Alignment.bottomCenter,
                                    children: [
                                      Container(
                                        width: size.width * 0.28,
                                        height: 14,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(999),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withOpacity(0.35),
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

                                SizedBox(height: size.height * 0.028),

                                // ── Kabsat Empoy (PESO-style shimmer) + tagline ────────────
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 22),
                                  child: Column(
                                    children: [
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
                                                  Color(0xFF0F172A),
                                                  Color(0xFF0F172A),
                                                  Color(0xFF2563EB),
                                                  Color(0xFF60A5FA),
                                                  Color(0xFF0F172A),
                                                  Color(0xFF0F172A),
                                                ],
                                                stops: [
                                                  0.0,
                                                  math.max(
                                                    0.0,
                                                    (shimmerX / bounds.width) -
                                                        0.25,
                                                  ),
                                                  (shimmerX / bounds.width)
                                                      .clamp(0.0, 1.0),
                                                  math.min(
                                                    1.0,
                                                    (shimmerX / bounds.width) +
                                                        0.15,
                                                  ),
                                                  math.min(
                                                    1.0,
                                                    (shimmerX / bounds.width) +
                                                        0.35,
                                                  ),
                                                  1.0,
                                                ],
                                              ).createShader(bounds);
                                            },
                                            child: child!,
                                          );
                                        },
                                        child: Column(
                                          children: [
                                            Text(
                                              'KABSAT',
                                              style: GoogleFonts.poppins(
                                                fontSize: 38,
                                                fontWeight: FontWeight.w800,
                                                color: const Color(0xFF0F2250),
                                                letterSpacing: 4,
                                                height: 1.05,
                                              ),
                                            ),
                                            Text(
                                              'EMPOY',
                                              style: GoogleFonts.poppins(
                                                fontSize: 38,
                                                fontWeight: FontWeight.w800,
                                                color: const Color(0xFF0F2250),
                                                letterSpacing: 4,
                                                height: 1.05,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Your virtual employment companion',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.poppins(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w400,
                                          color: const Color(0xFF1D4ED8),
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                    .animate()
                                    .fadeIn(delay: 450.ms, duration: 550.ms)
                                    .slideY(
                                        begin: 0.12,
                                        curve: Curves.easeOutCubic),

                                const SizedBox(height: 14),

                                // ── PESO pill ───────────────────────────────────────────
                                Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 28),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: const Color(0xFF3B82F6)
                                          .withOpacity(0.55),
                                      width: 1.2,
                                    ),
                                    color: const Color(0xFFDBEAFE)
                                        .withOpacity(0.65),
                                  ),
                                  child: Text(
                                    'PUBLIC EMPLOYMENT SERVICE OFFICE',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1D4ED8),
                                      letterSpacing: 1.6,
                                      height: 1.25,
                                    ),
                                  ),
                                )
                                    .animate()
                                    .fadeIn(delay: 650.ms, duration: 550.ms)
                                    .slideY(
                                        begin: 0.1, curve: Curves.easeOutCubic),

                                const SizedBox(height: 10),

                                Text(
                                  'Santiago City',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF2563EB),
                                    letterSpacing: 4,
                                  ),
                                )
                                    .animate()
                                    .fadeIn(delay: 800.ms, duration: 550.ms)
                                    .slideY(
                                        begin: 0.08,
                                        curve: Curves.easeOutCubic),
                              ],
                            ),
                          ),

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

class _AuthEntryPageState extends State<AuthEntryPage> {
  /// Sign-up is the primary entry; login is one tap away at the bottom.
  bool _isSignUpMode = true;

  void _toggleAuthMode() {
    setState(() => _isSignUpMode = !_isSignUpMode);
  }

  Future<void> _continueAsGuest() async {
    await SessionPrefs.saveGuestSession();
    JobActionService().clear();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(builder: (_) => const HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.verified_user_rounded,
                      color: Color(0xFF2563EB),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isSignUpMode
                              ? (s?.createAccount ?? 'Create account')
                              : (s?.welcomeBack ?? 'Welcome back'),
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isSignUpMode
                              ? (s?.authSignupSubtitle ??
                                  'Find and apply for jobs   near you.')
                              : (s?.authLoginSubtitle ??
                                  'Sign in to continue where you left off.'),
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            height: 1.35,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: LoginModal(
                  key: ValueKey<bool>(_isSignUpMode),
                  isSignUp: _isSignUpMode,
                  renderAsModal: false,
                  useCompactLayout: true,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 6),
              child: OutlinedButton.icon(
                onPressed: _continueAsGuest,
                icon: const Icon(Icons.explore_outlined, size: 19),
                label: const Text('Continue as guest'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2563EB),
                  side: const BorderSide(color: Color(0xFFBFDBFE)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  textStyle: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isSignUpMode
                        ? (s?.alreadyHaveAccount ?? 'Already have an account?')
                        : (s?.dontHaveAccount ?? "Don't have an account?"),
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextButton(
                    onPressed: _toggleAuthMode,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      _isSignUpMode
                          ? (s?.login ?? 'Log in')
                          : (s?.signup ?? 'Sign up'),
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2563EB),
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

/// Forgot-password UI using [AppDialog]; keeps [TextEditingController] lifetime
/// aligned with the route so exit animations cannot touch a disposed controller.
class _ForgotPasswordDialogShell extends StatefulWidget {
  const _ForgotPasswordDialogShell({
    required this.animation,
    required this.initialEmail,
    required this.hostContext,
    required this.hostMounted,
    required this.onOpenMailto,
  });

  final Animation<double> animation;
  final String initialEmail;
  final BuildContext hostContext;
  final bool Function() hostMounted;
  final Future<void> Function(String email) onOpenMailto;

  @override
  State<_ForgotPasswordDialogShell> createState() =>
      _ForgotPasswordDialogShellState();
}

class _ForgotPasswordDialogShellState
    extends State<_ForgotPasswordDialogShell> {
  late final TextEditingController _emailCtrl =
      TextEditingController(text: widget.initialEmail);
  bool _sending = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  void _closeDialog() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!context.mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _sendResetLink() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      if (!widget.hostMounted()) return;
      CustomToast.show(
        widget.hostContext,
        message: 'Please enter a valid email address.',
        type: ToastType.error,
      );
      return;
    }
    setState(() => _sending = true);
    final res = await ApiService.forgotJobseekerPassword(email: email);
    if (!mounted) return;
    _closeDialog();
    if (!widget.hostMounted()) return;
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
      if (!widget.hostMounted()) return;
      CustomToast.show(
        widget.hostContext,
        message: msg,
        type: ok ? ToastType.success : ToastType.error,
        duration: ok ? const Duration(seconds: 5) : const Duration(seconds: 4),
        actionLabel: ok ? 'Open email' : null,
        onAction: ok ? () => unawaited(widget.onOpenMailto(email)) : null,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return _appDialogScaleFadeTransition(
      animation: widget.animation,
      child: AppDialog(
        type: AppDialogType.info,
        icon: Icons.mark_email_unread_rounded,
        title: S.of(context)?.forgotPassword ?? 'Forgot password?',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Enter your registered email. We’ll send a link to reset your password for $kAppDisplayName.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF64748B),
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF2563EB),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
        confirmLabel: 'Send link',
        confirmBusyLabel: 'Sending…',
        confirmBusy: _sending,
        onCancel: _closeDialog,
        onConfirm: () => unawaited(_sendResetLink()),
      ),
    );
  }
}

// ─── Login Modal ──────────────────────────────────────────────────────────────
class LoginModal extends StatefulWidget {
  final bool isSignUp;

  /// When false, this widget renders as a plain embedded form (no bottom-sheet,
  /// no slide animation, no close button).
  final bool renderAsModal;

  /// Full-page auth: no tab switcher or duplicate title (header lives on page).
  final bool useCompactLayout;

  const LoginModal({
    super.key,
    this.isSignUp = false,
    this.renderAsModal = true,
    this.useCompactLayout = false,
  });

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
  bool _acceptedTermsAndPrivacy = false;
  int _signupStep = 0;
  String? _signupStepError;

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
      _signupStep = 0;
      _signupStepError = null;
      _formKey.currentState?.reset();
      _authError = null;
      _serverEmailError = null;
      _acceptedTermsAndPrivacy = false;
    });
  }

  void _goBackSignupStep() {
    if (_signupStep <= 0) return;
    setState(() {
      _signupStep -= 1;
      _signupStepError = null;
    });
  }

  bool _advanceSignupStep() {
    final error = SignupStepValidation.validateStep(
      step: _signupStep,
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      phone: _phoneController.text,
      email: _emailController.text,
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
      sex: _selectedSex,
      serverEmailError: _serverEmailError,
    );
    if (error != null) {
      setState(() => _signupStepError = error);
      return false;
    }
    setState(() {
      _signupStepError = null;
      _signupStep += 1;
    });
    return true;
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
      final otpResult = await showJobseekerOtpDialog(
        context: context,
        email: _emailController.text.trim(),
        initialRemainingDailySends: initialRemainingDailySends,
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
      // Brand-new account: show Skills Profile guided setup on first open.
      await OnboardingPrefs.setSkillsProfileGuidePending(token: token);
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
        errorMessage = _friendlyRegistrationError(result['message'].toString());
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
            final msg = _friendlyRegistrationError(value.first.toString());
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

  String _friendlyRegistrationError(String raw) {
    final message = raw.trim();
    final lower = message.toLowerCase();
    if (lower.contains('sqlstate') ||
        lower.contains('integrity constraint violation') ||
        lower.contains('duplicate entry')) {
      if (lower.contains('email') ||
          lower.contains('jobseekers_email_unique')) {
        return 'Email is already registered.';
      }
      return 'Registration failed because the submitted information conflicts with an existing record.';
    }
    if (message.isEmpty) {
      return 'Registration failed. Please try again.';
    }
    return message;
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
    _signupStep = 0;
    _signupStepError = null;
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

  void _showForgotPasswordDialog() {
    const dialogTransition = Duration(milliseconds: 280);
    unawaited(showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: const Color(0xFF0F172A).withOpacity(0.5),
      transitionDuration: dialogTransition,
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (_, animation, __, ___) {
        return _ForgotPasswordDialogShell(
          animation: animation,
          initialEmail: _emailController.text.trim(),
          hostContext: context,
          hostMounted: () => mounted,
          onOpenMailto: _openMailto,
        );
      },
    ));
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

  Widget _buildTopErrorBanner(String message, {VoidCallback? onDismiss}) {
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
            onTap: onDismiss ?? () => setState(() => _authError = null),
            child: const Icon(Icons.close_rounded,
                color: Color(0xFF991B1B), size: 18),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formBody = Padding(
      padding: EdgeInsets.only(
        bottom: widget.useCompactLayout ? 8 : 24,
        left: widget.useCompactLayout ? 0 : 24,
        right: widget.useCompactLayout ? 0 : 24,
        top: widget.renderAsModal ? 16 : (widget.useCompactLayout ? 0 : 4),
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
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          if (widget.renderAsModal) const SizedBox(height: 24),
          if (!widget.useCompactLayout) ...[
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
          ],
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
                  if (_signupStepError != null) ...[
                    _buildTopErrorBanner(
                      _signupStepError!,
                      onDismiss: () => setState(() => _signupStepError = null),
                    ),
                    const SizedBox(height: 12),
                  ],
                  SignupWizard(
                    currentStep: _signupStep,
                    renderAsModal: widget.renderAsModal,
                    firstNameController: _firstNameController,
                    middleInitialController: _middleInitialController,
                    lastNameController: _lastNameController,
                    phoneController: _phoneController,
                    emailController: _emailController,
                    passwordController: _passwordController,
                    confirmPasswordController: _confirmPasswordController,
                    dobController: _dobController,
                    obscurePassword: _obscurePassword,
                    obscureConfirmPassword: _obscureConfirmPassword,
                    selectedSex: _selectedSex,
                    acceptedTermsAndPrivacy: _acceptedTermsAndPrivacy,
                    serverEmailError: _serverEmailError,
                    onEmailChanged: (v) {
                      if (_serverEmailError != null) {
                        setState(() => _serverEmailError = null);
                      }
                      if (_signupStepError != null) {
                        setState(() => _signupStepError = null);
                      }
                      _emailDebounce?.cancel();
                      if (v.trim().isEmpty ||
                          !v.contains('@') ||
                          !v.contains('.')) {
                        return;
                      }
                      _emailDebounce = Timer(
                        const Duration(milliseconds: 600),
                        () async {
                          final res = await ApiService.checkJobseekerEmail(
                            v.trim(),
                          );
                          if (mounted &&
                              _isSignUpMode &&
                              _emailController.text.trim() == v.trim()) {
                            if (res['success'] == true &&
                                res['exists'] == true) {
                              setState(() => _serverEmailError =
                                  'Email is already registered.');
                            }
                          }
                        },
                      );
                    },
                    onPasswordChanged: () => setState(() {}),
                    onTogglePassword: () => setState(
                      () => _obscurePassword = !_obscurePassword,
                    ),
                    onToggleConfirmPassword: () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    ),
                    onSexChanged: (value) =>
                        setState(() => _selectedSex = value),
                    onTermsChanged: (value) =>
                        setState(() => _acceptedTermsAndPrivacy = value),
                    onPickDob: _pickDob,
                  ),
                ],
                if (!_isSignUpMode) ...[
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _fieldDec('Email', Icons.email_outlined),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Please enter your email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    inputFormatters: PasswordRules.inputFormattersNoWhitespace,
                    decoration: _fieldDec(
                      'Password',
                      Icons.lock_outline_rounded,
                      suffix: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: Colors.grey[600],
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (PasswordRules.hasWhitespace(v)) {
                        return 'Password cannot contain spaces';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                ],
                if (!_isSignUpMode) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => setState(() => _rememberMe = !_rememberMe),
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
                                  onChanged: (v) =>
                                      setState(() => _rememberMe = v ?? false),
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
                        child: Text(
                          S.of(context)?.forgotPassword ?? 'Forgot password?',
                          style: const TextStyle(
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
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (_isSignUpMode && _signupStep > 0) ...[
                      SizedBox(
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: _isSubmitting ? null : _goBackSignupStep,
                          icon: const Icon(Icons.arrow_back_rounded, size: 18),
                          label: Text(
                            S.of(context)?.back ?? 'Back',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF475569),
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ||
                                  (_isSignUpMode &&
                                      _signupStep == 1 &&
                                      _serverEmailError != null) ||
                                  (_isSignUpMode &&
                                      _signupStep == kSignupStepCount - 1 &&
                                      !_acceptedTermsAndPrivacy)
                              ? null
                              : () async {
                                  if (_isSignUpMode) {
                                    if (_signupStep < kSignupStepCount - 1) {
                                      _advanceSignupStep();
                                      return;
                                    }
                                    final stepError =
                                        SignupStepValidation.validateStep(
                                      step: _signupStep,
                                      firstName: _firstNameController.text,
                                      lastName: _lastNameController.text,
                                      phone: _phoneController.text,
                                      email: _emailController.text,
                                      password: _passwordController.text,
                                      confirmPassword:
                                          _confirmPasswordController.text,
                                      sex: _selectedSex,
                                      serverEmailError: _serverEmailError,
                                    );
                                    if (stepError != null) {
                                      setState(
                                          () => _signupStepError = stepError);
                                      return;
                                    }
                                    if (!_acceptedTermsAndPrivacy) return;
                                    setState(() {
                                      _signupStepError = null;
                                      _isSubmitting = true;
                                    });
                                    await _handleRegistration();
                                    if (mounted) {
                                      setState(() => _isSubmitting = false);
                                    }
                                    return;
                                  }
                                  if (_formKey.currentState!.validate()) {
                                    setState(() {
                                      _authError = null;
                                      _isSubmitting = true;
                                    });
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
                                      await JobActionService()
                                          .loadFromBackend();
                                      await NotificationService()
                                          .syncTokenNow();
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
                                    } else if (result[
                                            'requires_verification'] ==
                                        true) {
                                      if (!mounted) return;
                                      final initialRemainingDailySends =
                                          _initialRemainingDailySendsFromAuthResponse(
                                              result);
                                      final otpResult =
                                          await showJobseekerOtpDialog(
                                        context: context,
                                        email: _emailController.text.trim(),
                                        initialRemainingDailySends:
                                            initialRemainingDailySends,
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
                                      final msg = result['message']
                                              as String? ??
                                          'Login failed. Check your email and password.';
                                      if (!mounted) return;
                                      setState(() {
                                        _authError = msg;
                                        _isSubmitting = false;
                                      });
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
                                  : Text(
                                      _isSignUpMode
                                          ? (_signupStep < kSignupStepCount - 1
                                              ? (S
                                                      .of(context)
                                                      ?.continueButton ??
                                                  'Continue')
                                              : (S.of(context)?.createAccount ??
                                                  'Create account'))
                                          : (S.of(context)?.login ?? 'Log in'),
                                      style: const TextStyle(
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
                                      _isSignUpMode
                                          ? (S.of(context)?.signup ?? 'Sign Up')
                                          : (S.of(context)?.login ?? 'Sign In'),
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700),
                                    ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );

    if (widget.useCompactLayout) return formBody;

    final content = SingleChildScrollView(child: formBody);

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
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
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
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                enableInteractiveSelection: false,
                cursorColor: Colors.transparent,
                style: const TextStyle(color: Colors.transparent),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  counterText: '',
                  contentPadding: EdgeInsets.zero,
                ),
                onTapOutside: (_) => FocusScope.of(context).unfocus(),
              ),
            ),
            IgnorePointer(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  final hasChar = index < code.length;
                  final isActive = isFocused &&
                      (index == code.length ||
                          (code.length == 6 && index == 5));
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
                            ? const Color(0xFF2563EB)
                            : const Color(0xFFE2E8F0),
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
        _statusIsWarning ? const Color(0xFFB45309) : const Color(0xFF2563EB);
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
    const primary = Color(0xFF2563EB);
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          FocusManager.instance.primaryFocus?.unfocus();
        }
      },
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 360),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: primary.withOpacity(0.15),
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primary.withOpacity(0.10),
                        primary.withOpacity(0.02),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.12),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: primary.withOpacity(0.22),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.mark_email_read_rounded,
                          color: primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Verify your email',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 8, 22, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Enter the 6-digit OTP sent to ${widget.email}.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 13.5,
                          color: const Color(0xFF64748B),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildOtpBoxes(),
                      _buildStatusBanner(),
                      if (_remainingDailySends != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          '$_remainingDailySends sends left today',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            color: const Color(0xFFDC2626),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.center,
                        child: TextButton(
                          onPressed: _isResending ||
                                  _isVerifying ||
                                  _resendCooldown > 0
                              ? null
                              : _resend,
                          style: TextButton.styleFrom(
                            foregroundColor: primary,
                          ),
                          child: Text(
                            _isResending
                                ? 'Resending...'
                                : _resendCooldown > 0
                                    ? 'Resend in ${_resendCooldown}s'
                                    : 'Resend OTP',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: _isVerifying
                                  ? null
                                  : () {
                                      FocusManager.instance.primaryFocus
                                          ?.unfocus();
                                      Navigator.of(context, rootNavigator: true)
                                          .pop();
                                    },
                              style: TextButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: const BorderSide(
                                      color: Color(0xFFE2E8F0)),
                                ),
                                backgroundColor: const Color(0xFFF8FAFC),
                              ),
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: (_isVerifying || _isResending)
                                  ? null
                                  : _verify,
                              style: FilledButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                backgroundColor: primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                _isVerifying ? 'Verifying...' : 'Verify',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
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
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.82,
              ),
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
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                              color: const Color(0xFFE2E8F0), width: 2),
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
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        type: type,
        actionLabel: actionLabel,
        onAction: onAction == null
            ? null
            : () {
                if (entry.mounted) entry.remove();
                onAction();
              },
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
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onDismiss;

  const _ToastWidget({
    required this.message,
    required this.type,
    this.actionLabel,
    this.onAction,
    required this.onDismiss,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
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
                maxWidth:
                    math.min(MediaQuery.sizeOf(context).width - 40, 320.0),
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
                  if (widget.actionLabel != null &&
                      widget.onAction != null) ...[
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: widget.onAction,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: color,
                      ),
                      child: Text(
                        widget.actionLabel!,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
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

// ─── Unified App Dialog ───────────────────────────────────────────────────────

/// Dialog variants that determine color scheme and icon.
enum AppDialogType {
  confirm, // Blue primary — general confirmations
  destructive, // Red — sign out, delete, etc.
  info, // Blue — informational
  success, // Green — success confirmation
  warning, // Amber — warnings
}

/// A professional, animated confirmation/alert dialog matching the app theme.
class AppDialog extends StatefulWidget {
  final AppDialogType type;
  final String title;
  final String? message;
  final Widget? content;
  final String confirmLabel;
  final String cancelLabel;

  /// When true, primary and cancel actions are disabled and [confirmBusyLabel]
  /// is shown on the primary button (if non-null).
  final bool confirmBusy;

  /// Shown on the confirm button while [confirmBusy] is true.
  final String? confirmBusyLabel;

  final VoidCallback? onConfirm;
  final FutureOr<void> Function()? onConfirmAsync;
  final VoidCallback? onCancel;
  final dynamic icon;

  const AppDialog({
    super.key,
    this.type = AppDialogType.confirm,
    required this.title,
    this.message,
    this.content,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.confirmBusy = false,
    this.confirmBusyLabel,
    this.onConfirm,
    this.onConfirmAsync,
    this.onCancel,
    this.icon,
  });

  @override
  State<AppDialog> createState() => _AppDialogState();

  static ({Color primary, Color surface}) _dialogColors(AppDialogType type) {
    return switch (type) {
      AppDialogType.confirm => (
          primary: const Color(0xFF2563EB),
          surface: const Color(0xFFEFF6FF)
        ),
      AppDialogType.destructive => (
          primary: const Color(0xFFDC2626),
          surface: const Color(0xFFFEF2F2)
        ),
      AppDialogType.info => (
          primary: const Color(0xFF2563EB),
          surface: const Color(0xFFEFF6FF)
        ),
      AppDialogType.success => (
          primary: const Color(0xFF10B981),
          surface: const Color(0xFFF0FDF4)
        ),
      AppDialogType.warning => (
          primary: const Color(0xFFF59E0B),
          surface: const Color(0xFFFFFBEB)
        ),
    };
  }

  static dynamic _defaultIcon(AppDialogType type) {
    return switch (type) {
      AppDialogType.confirm => HugeIcons.strokeRoundedHelpCircle,
      AppDialogType.destructive => HugeIcons.strokeRoundedAlertCircle,
      AppDialogType.info => HugeIcons.strokeRoundedInformationCircle,
      AppDialogType.success => HugeIcons.strokeRoundedCheckmarkCircle01,
      AppDialogType.warning => HugeIcons.strokeRoundedAlertCircle,
    };
  }
}

class _AppDialogState extends State<AppDialog> {
  bool _internalBusy = false;

  @override
  Widget build(BuildContext context) {
    final isBusy = widget.confirmBusy || _internalBusy;
    final colors = AppDialog._dialogColors(widget.type);
    final dialogIcon = widget.icon ?? AppDialog._defaultIcon(widget.type);

    // App's primary blue color shade for top header banner & badge accent
    const headerColor = AppColors.blueAccent;

    // Determine primary button base color
    final primaryButtonColor = (widget.type == AppDialogType.destructive ||
            widget.confirmLabel == 'Sign Out' ||
            widget.confirmLabel == 'Delete')
        ? const Color(0xFFDC2626)
        : ((widget.type == AppDialogType.warning ||
                widget.confirmLabel == 'Leave')
            ? const Color(0xFFF97316)
            : colors.primary);

    // Primary button 3D gradient colors matching button action type (red for sign out/delete, orange for leave, blue for confirm)
    final buttonGradientColors = (widget.type == AppDialogType.destructive ||
            widget.confirmLabel == 'Sign Out' ||
            widget.confirmLabel == 'Delete')
        ? const [
            Color(0xFFEF4444), // Bright red top gloss highlight
            Color(0xFFDC2626), // Mid red
            Color(0xFF991B1B), // Deep red bottom depth
          ]
        : ((widget.type == AppDialogType.warning ||
                widget.confirmLabel == 'Leave')
            ? const [
                Color(0xFFFB923C), // Bright orange top gloss highlight
                Color(0xFFF97316), // Mid orange
                Color(0xFFC2410C), // Deep orange bottom depth
              ]
            : [
                const Color(0xFF60A5FA), // Bright blue top gloss highlight
                colors.primary,          // Mid primary blue
                const Color(0xFF1D4ED8), // Deep blue bottom depth
              ]);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            // Deep Ambient Drop Shadow
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 40,
              spreadRadius: -2,
              offset: const Offset(0, 20),
            ),
            // Subtle Accent Glow Shadow
            BoxShadow(
              color: headerColor.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Blue Banner Box with Soft Shine Reflection
              Stack(
                alignment: Alignment.topCenter,
                clipBehavior: Clip.none,
                children: [
                  // Blue Header Banner Bar with Glossy Multi-Stop Gradient
                  Container(
                    height: 82,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF3B82F6), // Vibrant bright blue at top-left
                          AppColors.blueAccent, // Mid primary blue
                          Color(0xFF1E3A8A), // Deep navy blue at bottom-right
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Stack(
                      children: [
                        // Softened Specular Glass Gloss Bar
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: 42,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0.16),
                                  Colors.white.withValues(alpha: 0.02),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(24)),
                            ),
                          ),
                        ),
                        // Subtle Inner Top Highlight Border Line
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 1.5,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(24)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 3D Floating Icon Circle Badge overlapping the banner edge
                  Padding(
                    padding: const EdgeInsets.only(top: 44),
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Colors.white,
                            Color(0xFFF8FAFC),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: headerColor,
                          width: 3.0,
                        ),
                        boxShadow: [
                          // 3D Directional Drop Shadow
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.16),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                          // Blue Accent Glow Shadow
                          BoxShadow(
                            color: headerColor.withValues(alpha: 0.25),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: dialogIcon is IconData
                            ? Icon(dialogIcon, color: headerColor, size: 34)
                            : HugeIcon(
                                icon: dialogIcon as List<List<dynamic>>,
                                color: headerColor,
                                size: 32,
                                strokeWidth: 2.2,
                              ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 48),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  widget.title,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E293B),
                    letterSpacing: -0.3,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // Message / Custom Content
              if (widget.message != null || widget.content != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: widget.content ??
                      Text(
                        widget.message!,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF334155),
                          height: 1.45,
                        ),
                        textAlign: TextAlign.center,
                      ),
                )
              else
                const SizedBox(height: 20),

              // 3D Action Buttons Row
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  children: [
                    // 3D Secondary/Cancel Action Button
                    Expanded(
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFF8FAFC),
                              Color(0xFFE2E8F0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          border: Border.all(
                            color: const Color(0xFFCBD5E1),
                            width: 1,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: isBusy
                                ? null
                                : (widget.onCancel ??
                                    () => Navigator.pop(context)),
                            borderRadius: BorderRadius.circular(16),
                            child: Center(
                              child: Text(
                                widget.cancelLabel,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF475569),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // 3D Primary Action Button with Matching Gradient Shine & Subdued Shadow
                    Expanded(
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: buttonGradientColors,
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          boxShadow: [
                            // Faintest minimal shadow to keep it clean and soft
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: isBusy
                                ? null
                                : () async {
                                    if (widget.onConfirmAsync != null) {
                                      setState(() {
                                        _internalBusy = true;
                                      });
                                      try {
                                        await widget.onConfirmAsync!();
                                        if (mounted) {
                                          Navigator.pop(context, true);
                                        }
                                      } catch (_) {
                                        if (mounted) {
                                          setState(() {
                                            _internalBusy = false;
                                          });
                                        }
                                      }
                                    } else if (widget.onConfirm != null) {
                                      widget.onConfirm!();
                                    } else {
                                      Navigator.pop(context, true);
                                    }
                                  },
                            borderRadius: BorderRadius.circular(16),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isBusy) ...[
                                    const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Text(
                                    (isBusy && widget.confirmBusyLabel != null)
                                        ? widget.confirmBusyLabel!
                                        : widget.confirmLabel,
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      shadows: const [
                                        Shadow(
                                          color: Color(0x40000000),
                                          offset: Offset(0, 1),
                                          blurRadius: 2,
                                        ),
                                      ],
                                    ),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _appDialogScaleFadeTransition({
  required Animation<double> animation,
  required Widget child,
}) {
  final curvedAnimation = CurvedAnimation(
    parent: animation,
    curve: Curves.easeOutBack,
    reverseCurve: Curves.easeInCubic,
  );
  return Center(
    child: ScaleTransition(
      scale: Tween<double>(begin: 0.85, end: 1.0).animate(curvedAnimation),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOut),
        ),
        child: child,
      ),
    ),
  );
}

/// Shows a unified app dialog with scale + fade animation.
Future<T?> showAppDialog<T>({
  required BuildContext context,
  AppDialogType type = AppDialogType.confirm,
  required String title,
  String? message,
  Widget? content,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  VoidCallback? onConfirm,
  FutureOr<void> Function()? onConfirmAsync,
  VoidCallback? onCancel,
  dynamic icon,
  bool barrierDismissible = true,
  String? confirmBusyLabel,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: 'Dismiss',
    barrierColor: const Color(0xFF0F172A).withOpacity(0.5),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (ctx, animation, secondaryAnimation, child) {
      return _appDialogScaleFadeTransition(
        animation: animation,
        child: AppDialog(
          type: type,
          title: title,
          message: message,
          content: content,
          confirmLabel: confirmLabel,
          cancelLabel: cancelLabel,
          onConfirm: onConfirm,
          onConfirmAsync: onConfirmAsync,
          onCancel: onCancel,
          icon: icon,
          confirmBusyLabel: confirmBusyLabel,
        ),
      );
    },
  );
}

/// Email OTP entry — same barrier + scale/fade animation as [showAppDialog].
Future<Map<String, dynamic>?> showJobseekerOtpDialog({
  required BuildContext context,
  required String email,
  int? initialRemainingDailySends,
}) {
  return showGeneralDialog<Map<String, dynamic>>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Dismiss',
    barrierColor: const Color(0xFF0F172A).withOpacity(0.5),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (ctx, animation, _, __) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInCubic,
      );
      return Center(
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.88, end: 1.0).animate(curved),
          child: FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: _OtpVerificationDialog(
              email: email,
              initialRemainingDailySends: initialRemainingDailySends,
            ),
          ),
        ),
      );
    },
  );
}
