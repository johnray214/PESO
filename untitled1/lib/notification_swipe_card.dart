import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_haptics.dart';

/// Interactive notification swipe card featuring two-threshold gesture physics,
/// rubber-band resistance, commit point pop, and first-launch peek discoverability.
class NotificationSwipeCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onDismissed;
  final bool enabled;
  final bool isFirstCard;

  const NotificationSwipeCard({
    super.key,
    required this.child,
    required this.onDismissed,
    this.enabled = true,
    this.isFirstCard = false,
  });

  @override
  State<NotificationSwipeCard> createState() => _NotificationSwipeCardState();
}

class _NotificationSwipeCardState extends State<NotificationSwipeCard>
    with TickerProviderStateMixin {
  static const double _thresholdReveal = 76.0;
  static const double _thresholdCommit = 128.0;
  static const String _kSeenHintPrefKey = 'has_seen_notif_swipe_hint';

  double _dragOffset = 0.0;
  double _rawDrag = 0.0;
  bool _isCommitted = false;
  bool _isOpenChoice = false;
  bool _isDismissing = false;

  late final AnimationController _snapController;
  late final AnimationController _collapseController;
  late final AnimationController _iconPopController;
  late final AnimationController _peekController;

  Animation<double>? _snapAnimation;
  late final Animation<double> _collapseAnimation;
  late final Animation<double> _iconScaleAnimation;

  @override
  void initState() {
    super.initState();

    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    _collapseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _collapseAnimation = CurvedAnimation(
      parent: _collapseController,
      curve: Curves.easeInOutCubic,
    );

    _iconPopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _iconScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.18,
    ).animate(CurvedAnimation(
      parent: _iconPopController,
      curve: Curves.easeOutBack,
    ));

    _peekController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );

    _checkAndRunFirstLaunchPeek();
  }

  @override
  void dispose() {
    _snapController.dispose();
    _collapseController.dispose();
    _iconPopController.dispose();
    _peekController.dispose();
    super.dispose();
  }

  Future<void> _checkAndRunFirstLaunchPeek() async {
    if (!widget.isFirstCard || !widget.enabled) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final seen = prefs.getBool(_kSeenHintPrefKey) ?? false;
      if (!seen && mounted) {
        await prefs.setBool(_kSeenHintPrefKey, true);
        await Future<void>.delayed(const Duration(milliseconds: 500));
        if (!mounted || _isDismissing || _dragOffset != 0.0) return;

        // Smooth peek animation: slide left 48px, pause, slide back
        final peekAnim = TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween(begin: 0.0, end: -48.0)
                .chain(CurveTween(curve: Curves.easeOutCubic)),
            weight: 35,
          ),
          TweenSequenceItem(
            tween: ConstantTween<double>(-48.0),
            weight: 30,
          ),
          TweenSequenceItem(
            tween: Tween(begin: -48.0, end: 0.0)
                .chain(CurveTween(curve: Curves.easeOutCubic)),
            weight: 35,
          ),
        ]).animate(_peekController);

        _peekController.addListener(() {
          if (mounted && _snapAnimation == null && !_isDismissing) {
            setState(() {
              _dragOffset = peekAnim.value;
            });
          }
        });

        _peekController.forward(from: 0.0);
      }
    } catch (_) {}
  }

  double _calculateOffset(double raw) {
    if (!widget.enabled) {
      // Stiff resistance on protected items
      return (raw.clamp(-30.0, 0.0)) * 0.28;
    }

    if (raw > 0) return 0.0; // Restrict swiping to the left only
    final abs = raw.abs();

    if (abs <= _thresholdCommit) {
      // Stage 1: Rubber-band resistance (0.60x speed)
      return -abs * 0.60;
    } else {
      // Stage 2: Resistance releases at the commit line!
      final excess = abs - _thresholdCommit;
      return -(_thresholdCommit * 0.60 + excess * 0.95);
    }
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    if (_isDismissing) return;
    if (_snapController.isAnimating) _snapController.stop();
    if (_peekController.isAnimating) _peekController.stop();
    _rawDrag = _dragOffset;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (_isDismissing) return;
    _rawDrag += details.primaryDelta ?? 0.0;
    final nextOffset = _calculateOffset(_rawDrag);

    final wasCommitted = _isCommitted;
    final isNowCommitted = nextOffset.abs() >= _thresholdCommit;

    if (!wasCommitted && isNowCommitted) {
      _isCommitted = true;
      _iconPopController.forward(from: 0.0);
      AppHaptics.mediumImpact(); // The physical commit detent
    } else if (wasCommitted && !isNowCommitted) {
      _isCommitted = false;
      _iconPopController.reverse();
      AppHaptics.selectionClick(); // The disarm tick
    }

    setState(() {
      _dragOffset = nextOffset;
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_isDismissing) return;
    _handleRelease();
  }

  void _onHorizontalDragCancel() {
    if (_isDismissing) return;
    _handleRelease();
  }

  void _handleRelease() {
    if (!widget.enabled) {
      _animateToOffset(0.0, Curves.easeOutBack);
      AppHaptics.lightImpact();
      return;
    }

    final absOffset = _dragOffset.abs();

    if (_isCommitted) {
      // Crossed Commit Line -> Execute Full Swipe Delete!
      _triggerFullDismissal();
    } else if (absOffset >= 42.0) {
      // Short Pull -> Snap to Reveal Action Button
      _isOpenChoice = true;
      _animateToOffset(-_thresholdReveal, Curves.easeOutBack);
      AppHaptics.lightImpact();
    } else {
      // Cancelled Pull -> Snap Back to Rest Position
      _isOpenChoice = false;
      _animateToOffset(0.0, Curves.easeOutCubic);
    }
  }

  void _animateToOffset(double target, Curve curve) {
    _snapAnimation = Tween<double>(
      begin: _dragOffset,
      end: target,
    ).animate(CurvedAnimation(
      parent: _snapController,
      curve: curve,
    ))..addListener(() {
        if (mounted) {
          setState(() {
            _dragOffset = _snapAnimation!.value;
          });
        }
      });

    _snapController.forward(from: 0.0).then((_) {
      if (mounted) {
        _snapAnimation = null;
      }
    });
  }

  Future<void> _triggerFullDismissal() async {
    if (_isDismissing) return;
    _isDismissing = true;
    AppHaptics.mediumImpact();

    // 1. Accelerate card off-screen
    final screenW = MediaQuery.sizeOf(context).width;
    final flyOffTarget = -(screenW + 60.0);

    _snapAnimation = Tween<double>(
      begin: _dragOffset,
      end: flyOffTarget,
    ).animate(CurvedAnimation(
      parent: _snapController,
      curve: Curves.easeInCubic,
    ))..addListener(() {
        if (mounted) {
          setState(() {
            _dragOffset = _snapAnimation!.value;
          });
        }
      });

    await _snapController.forward(from: 0.0);
    if (!mounted) return;

    // 2. Collapse row height smoothly
    await _collapseController.forward(from: 0.0);
    if (!mounted) return;

    // 3. Fire delete callback
    widget.onDismissed();
  }

  void _closeChoice() {
    if (_isOpenChoice && !_isDismissing) {
      _isOpenChoice = false;
      _animateToOffset(0.0, Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: Tween<double>(begin: 1.0, end: 0.0).animate(_collapseAnimation),
      axisAlignment: 0.0,
      child: Stack(
        children: [
          // ── Background Layer (Dynamic Actions) ───────────────────────────
          Positioned.fill(
            child: _buildBackgroundAction(),
          ),

          // ── Foreground Card Layer (Transforms with Gesture) ───────────────
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: _onHorizontalDragStart,
            onHorizontalDragUpdate: _onHorizontalDragUpdate,
            onHorizontalDragEnd: _onHorizontalDragEnd,
            onHorizontalDragCancel: _onHorizontalDragCancel,
            onTap: _isOpenChoice ? _closeChoice : null,
            child: Transform.translate(
              offset: Offset(_dragOffset, 0),
              child: Transform.scale(
                scale: math.max(0.982, 1.0 - (_dragOffset.abs() / 1200.0)),
                alignment: Alignment.centerLeft,
                child: Opacity(
                  opacity: math.max(0.90, 1.0 - (_dragOffset.abs() / 1500.0)),
                  child: widget.child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundAction() {
    final absOffset = _dragOffset.abs();
    final commitProgress = (absOffset / _thresholdCommit).clamp(0.0, 1.0);

    // Color transition from subtle soft red to rich danger crimson
    final bgColor = Color.lerp(
      const Color(0xFFFEF2F2),
      const Color(0xFFEF4444),
      commitProgress,
    )!;

    final borderColor = Color.lerp(
      const Color(0xFFFECACA),
      const Color(0xFFDC2626),
      commitProgress,
    )!;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _isCommitted ? const Color(0xFFDC2626) : bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isCommitted ? const Color(0xFFB91C1C) : borderColor,
          width: 1.0,
        ),
        boxShadow: _isCommitted
            ? [
                BoxShadow(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.30),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : const [],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // "Delete" text label reveals when passing threshold or committed
          if (_isCommitted || _isOpenChoice) ...[
            Text(
              _isCommitted ? 'Release to Delete' : 'Delete',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: _isCommitted
                    ? Colors.white
                    : const Color(0xFFDC2626),
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(width: 10),
          ],

          // Interactive / Animated Trash Icon Button
          GestureDetector(
            onTap: _triggerFullDismissal,
            child: ScaleTransition(
              scale: _iconScaleAnimation,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: _isCommitted ? 46 : 40,
                height: _isCommitted ? 46 : 40,
                decoration: BoxDecoration(
                  color: _isCommitted
                      ? Colors.white
                      : (_isOpenChoice
                          ? const Color(0xFFEF4444)
                          : const Color(0xFFFEE2E2)),
                  shape: BoxShape.circle,
                  boxShadow: _isCommitted
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : const [],
                ),
                child: Center(
                  child: Icon(
                    Icons.delete_rounded,
                    size: _isCommitted ? 22 : 19,
                    color: _isCommitted
                        ? const Color(0xFFDC2626)
                        : (_isOpenChoice
                            ? Colors.white
                            : const Color(0xFFEF4444)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
