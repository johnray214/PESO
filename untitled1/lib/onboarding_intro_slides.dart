import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'api_service.dart';
import 'onboarding_prefs.dart';
import 'user_session.dart';

/// Three swipeable intro slides before the welcome screen.
class IntroOnboardingPage extends StatefulWidget {
  /// Called with this widget's [BuildContext] — navigate to [WelcomePage] here.
  final void Function(BuildContext introContext) onComplete;

  const IntroOnboardingPage({super.key, required this.onComplete});

  @override
  State<IntroOnboardingPage> createState() => _IntroOnboardingPageState();
}

class _IntroOnboardingPageState extends State<IntroOnboardingPage> {
  final PageController _pageController = PageController();
  int _page = 0;

  static const _slides = [
    _SlideData(
      assetPath: 'assets/empoy_search.png',
      title: 'Find jobs matched to you',
      subtitle:
          'Browse openings matched to your skills and get a clear match score for every listing.',
      gradient: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
    ),
    _SlideData(
      assetPath: 'assets/empoy_calendar.png',
      title: 'Workshops & hiring events',
      subtitle:
          'Register for PESO events, job fairs, and training — never miss an opportunity.',
      gradient: [Color(0xFF059669), Color(0xFF047857)],
    ),
    _SlideData(
      assetPath: 'assets/empoy_map_walking.png',
      title: 'Explore on the map',
      subtitle:
          'See employers and opportunities around Santiago City and plan your next step.',
      gradient: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final token = UserSession().token;
    await OnboardingPrefs.setIntroDone(token: token);
    
    // Also sync to backend if logged in
    if (token != null && token.isNotEmpty) {
      await ApiService.updateProfile(token: token, isOnboardingDone: true);
      UserSession().isOnboardingDone = true;
    }
    
    if (!mounted) return;
    widget.onComplete(context);
  }

  void _next() {
    if (_page < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _finish,
                child: Text(
                  'Skip',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, index) {
                  final s = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (s.assetPath != null)
                          SizedBox(
                            width: 220,
                            height: 220,
                            child: Image.asset(
                              s.assetPath!,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.work_outline_rounded,
                                size: 80,
                                color: s.gradient[0],
                              ),
                            ),
                          )
                        else
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: s.gradient,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: s.gradient[0].withOpacity(0.35),
                                  blurRadius: 24,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Icon(s.icon!, size: 56, color: Colors.white),
                          ),
                        const SizedBox(height: 40),
                        Text(
                          s.title,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          s.subtitle,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            height: 1.5,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _page ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: i == _page
                        ? const Color(0xFF2563EB)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: _next,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _page == _slides.length - 1 ? 'Get started' : 'Next',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideData {
  /// If set, shown instead of [icon] in a circle (no shadow / no circle).
  final String? assetPath;
  final IconData? icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;

  const _SlideData({
    this.assetPath,
    this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
  }) : assert(
          assetPath != null || icon != null,
          'Slide needs either assetPath or icon',
        );
}
