import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import 'app_nav.dart';

/// A global wrapper that monitor's connectivity and shows a premium "No Internet" modal.
class ConnectivityWrapper extends StatefulWidget {
  final Widget child;

  const ConnectivityWrapper({super.key, required this.child});

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  late StreamSubscription<List<ConnectivityResult>> _subscription;
  Timer? _connectivityDebounce;
  bool _isShowingModal = false;
  bool _manualRetryLoading = false;
  int _shakeKey = 0;

  /// When using a local/LAN API, probing Google can produce false offline
  /// results even though the backend is reachable.
  bool get _preferApiReachabilityProbe => ApiService.isTargetingLocalDevHost;

  @override
  void initState() {
    super.initState();
    // 1. Initial check
    _checkConnectivity();

    // 2. Listen for changes (debounced — the stream can spam on some devices.)
    _subscription = Connectivity().onConnectivityChanged.listen(_queueConnectivityCheck);

    // 3. Listen to ApiService explicit network failures (e.g. SocketException)
    ApiService.onNetworkError = () {
      if (!_isShowingModal) {
        _showModal();
      }
    };
  }

  void _queueConnectivityCheck(List<ConnectivityResult> results) {
    _connectivityDebounce?.cancel();
    _connectivityDebounce = Timer(const Duration(milliseconds: 600), () {
      if (mounted) _applyConnectivityResults(results);
    });
  }

  Future<void> _applyConnectivityResults(List<ConnectivityResult> results) async {
    final isOfflineResult =
        results.isEmpty || results.contains(ConnectivityResult.none);

    if (isOfflineResult) {
      if (!_isShowingModal) _showModal();
      return;
    }

    final hasActualInternet = await _checkNetworkReachability();
    if (!hasActualInternet && !_isShowingModal) {
      _showModal();
    }
  }

  @override
  void dispose() {
    _connectivityDebounce?.cancel();
    _subscription.cancel();
    if (ApiService.onNetworkError != null) {
      ApiService.onNetworkError = null;
    }
    super.dispose();
  }

  Future<bool> _checkActualInternet() async {
    try {
      final response = await http.get(Uri.parse('https://clients3.google.com/generate_204'))
          .timeout(const Duration(seconds: 4));
      return response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _checkApiReachability() async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiService.baseUrl}/public/events?page=1&per_page=1'),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 4));
      // Any HTTP response means the API host is reachable.
      return response.statusCode > 0;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _checkNetworkReachability() async {
    if (_preferApiReachabilityProbe) {
      return _checkApiReachability();
    }

    final hasActualInternet = await _checkActualInternet();
    if (hasActualInternet) return true;

    // Fallback: some networks block Google captive-portal probes.
    return _checkApiReachability();
  }

  Future<void> _checkConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    final isOfflineResult = results.isEmpty || results.contains(ConnectivityResult.none);
    
    if (isOfflineResult) {
      _showModal();
      return;
    }

    final hasActualInternet = await _checkNetworkReachability();
    if (!hasActualInternet) {
      _showModal();
    }
  }

  void _showModal() {
    if (_isShowingModal) return;
    setState(() => _isShowingModal = true);
  }

  Future<void> _handleManualRetry() async {
    setState(() => _manualRetryLoading = true);
    
    // Artificial small delay for UX so it doesn't flicker too fast
    await Future.delayed(const Duration(milliseconds: 800));

    final hasActualInternet = await _checkNetworkReachability();

    if (hasActualInternet) {
      // Clean up local state BEFORE navigating, so the modal doesn't persist.
      setState(() {
        _isShowingModal = false;
        _manualRetryLoading = false;
      });
      
      // Hard refresh: go back to splash so it re-validates and re-syncs everything properly.
      rootNavigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/splash',
        (route) => false,
      );
    } else {
      HapticFeedback.lightImpact();
      setState(() {
        _manualRetryLoading = false;
        _shakeKey++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isShowingModal)
          _NoInternetModal(
            isLoading: _manualRetryLoading,
            shakeKey: _shakeKey,
            onRetry: _handleManualRetry,
          ),
      ],
    );
  }
}

class _NoInternetModal extends StatelessWidget {
  final bool isLoading;
  final int shakeKey;
  final VoidCallback onRetry;

  const _NoInternetModal({
    required this.isLoading,
    required this.shakeKey,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: Center(
        child: Container(
          width: MediaQuery.sizeOf(context).width * 0.85,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon with animation
              Container(
                width: 100,
                height: 100,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  'assets/empoy_no_internetconnection.png',
                  fit: BoxFit.contain,
                ),
              )
                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 1000.ms, curve: Curves.easeInOut),
              
              const SizedBox(height: 24),
              
              Text(
                'No Connection',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
              
              const SizedBox(height: 12),
              
              Text(
                'Please check your internet connection and try again.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
              
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: isLoading ? null : onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Retry',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ).animate().shimmer(delay: 2000.ms, duration: 1500.ms),
            ],
          ),
        )
            .animate(key: const ValueKey('modal_main'))
            .fadeIn(duration: 400.ms)
            .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack)
            .animate(key: ValueKey('modal_shake_$shakeKey'))
            .shake(hz: 8, curve: Curves.easeInOutCubic, duration: 400.ms),
      ),
    );
  }
}
