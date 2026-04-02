import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'api_service.dart';

/// A global wrapper that monitor's connectivity and shows a premium "No Internet" modal.
class ConnectivityWrapper extends StatefulWidget {
  final Widget child;

  const ConnectivityWrapper({super.key, required this.child});

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  late StreamSubscription<List<ConnectivityResult>> _subscription;
  bool _isShowingModal = false;
  bool _manualRetryLoading = false;

  @override
  void initState() {
    super.initState();
    // 1. Initial check
    _checkConnectivity();

    // 2. Listen for changes
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      final isOffline = results.isEmpty || results.contains(ConnectivityResult.none);
      if (!isOffline && _isShowingModal) {
        // Auto-dismiss when connection comes back suggestively
        _hideModal();
      } else if (isOffline && !_isShowingModal) {
        _showModal();
      }
    });

    // 3. Listen to ApiService explicit network failures (e.g. SocketException)
    ApiService.onNetworkError = () {
      if (!_isShowingModal) {
        _showModal();
      }
    };
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    final isOffline = results.isEmpty || results.contains(ConnectivityResult.none);
    if (isOffline) {
      _showModal();
    }
  }

  void _showModal() {
    if (_isShowingModal) return;
    setState(() => _isShowingModal = true);
  }

  void _hideModal() {
    if (!_isShowingModal) return;
    setState(() {
      _isShowingModal = false;
      _manualRetryLoading = false;
    });
  }

  Future<void> _handleManualRetry() async {
    setState(() => _manualRetryLoading = true);
    
    // Artificial small delay for UX so it doesn't flicker too fast
    await Future.delayed(const Duration(milliseconds: 800));

    final results = await Connectivity().checkConnectivity();
    final isOffline = results.isEmpty || results.contains(ConnectivityResult.none);

    if (!isOffline) {
      _hideModal();
    } else {
      setState(() => _manualRetryLoading = false);
      // Keep modal open, maybe shake the button or show a quick toast
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
            onRetry: _handleManualRetry,
          ),
      ],
    );
  }
}

class _NoInternetModal extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onRetry;

  const _NoInternetModal({
    required this.isLoading,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
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
        ).animate().scale(
              begin: const Offset(0.8, 0.8),
              end: const Offset(1, 1),
              curve: Curves.elasticOut,
              duration: 600.ms,
            ).fadeIn(duration: 300.ms),
      ),
    );
  }
}
