import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'app_haptics.dart';

/// Light haptic for successful primary actions (save, apply, register, etc.).
void microInteractionSuccess() {
  AppHaptics.mediumImpact();
}

/// Softer tick — e.g. pull-to-refresh completed.
void microInteractionSelection() {
  AppHaptics.selectionClick();
}

/// Animated Bookmark / Favorite Icon Button featuring an Elastic Bounce
/// and expanding Radial Burst ring effect.
class AnimatedBookmarkButton extends StatefulWidget {
  final bool isSaved;
  final VoidCallback onTap;
  final String? tooltip;
  final Color activeColor;
  final Color inactiveColor;
  final double size;

  const AnimatedBookmarkButton({
    super.key,
    required this.isSaved,
    required this.onTap,
    this.tooltip,
    this.activeColor = const Color(0xFF2563EB),
    this.inactiveColor = const Color(0xFF64748B),
    this.size = 20,
  });

  @override
  State<AnimatedBookmarkButton> createState() => _AnimatedBookmarkButtonState();
}

class _AnimatedBookmarkButtonState extends State<AnimatedBookmarkButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _burstScaleAnimation;
  late final Animation<double> _burstOpacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.72), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.72, end: 1.28), weight: 45),
      TweenSequenceItem(tween: Tween(begin: 1.28, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _burstScaleAnimation = Tween<double>(begin: 0.5, end: 1.85).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.15, 1.0, curve: Curves.easeOutQuad),
      ),
    );

    _burstOpacityAnimation = Tween<double>(begin: 0.65, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.25, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    AppHaptics.mediumImpact();
    _controller.forward(from: 0.0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip ?? (widget.isSaved ? 'Saved' : 'Save'),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handleTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Radial Burst Ring Animation
              Positioned.fill(
                child: OverflowBox(
                  maxWidth: 80,
                  maxHeight: 80,
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      if (!_controller.isAnimating ||
                          _burstOpacityAnimation.value <= 0) {
                        return const SizedBox.shrink();
                      }
                      return Transform.scale(
                        scale: _burstScaleAnimation.value,
                        child: Opacity(
                          opacity: _burstOpacityAnimation.value,
                          child: Container(
                            width: widget.size * 1.4,
                            height: widget.size * 1.4,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: widget.activeColor.withValues(alpha: 0.25),
                              border: Border.all(
                                color: widget.activeColor,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Elastic Bouncing Icon
              AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: widget.isSaved
                        ? Icon(
                            Icons.bookmark_rounded,
                            color: widget.activeColor,
                            size: widget.size + 1,
                          )
                        : HugeIcon(
                            icon: HugeIcons.strokeRoundedBookmark01,
                            color: widget.inactiveColor,
                            size: widget.size,
                            strokeWidth: 2.0,
                          ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Wrapper widget that adds an Elastic Bounce & Radial Burst animation to any
/// existing bookmark container box or button.
class AnimatedBookmarkBounce extends StatefulWidget {
  final bool isSaved;
  final VoidCallback onTap;
  final Widget child;

  const AnimatedBookmarkBounce({
    super.key,
    required this.isSaved,
    required this.onTap,
    required this.child,
  });

  @override
  State<AnimatedBookmarkBounce> createState() => _AnimatedBookmarkBounceState();
}

class _AnimatedBookmarkBounceState extends State<AnimatedBookmarkBounce>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _burstScaleAnimation;
  late final Animation<double> _burstOpacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.72), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.72, end: 1.28), weight: 45),
      TweenSequenceItem(tween: Tween(begin: 1.28, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _burstScaleAnimation = Tween<double>(begin: 0.5, end: 1.85).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.15, 1.0, curve: Curves.easeOutQuad),
      ),
    );

    _burstOpacityAnimation = Tween<double>(begin: 0.65, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.25, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    AppHaptics.mediumImpact();
    _controller.forward(from: 0.0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: OverflowBox(
              maxWidth: 80,
              maxHeight: 80,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  if (!_controller.isAnimating ||
                      _burstOpacityAnimation.value <= 0) {
                    return const SizedBox.shrink();
                  }
                  return Transform.scale(
                    scale: _burstScaleAnimation.value,
                    child: Opacity(
                      opacity: _burstOpacityAnimation.value,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                          border: Border.all(
                            color: const Color(0xFF2563EB),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: widget.child,
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Wrapper widget for Job Cards and List Items.
/// Applies a subtle 0.97x spring press-down on touch and spring bounce-back on release
/// with light haptic feedback.
class BouncingCardContainer extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressScale;

  const BouncingCardContainer({
    super.key,
    required this.child,
    this.onTap,
    this.pressScale = 0.97,
  });

  @override
  State<BouncingCardContainer> createState() => _BouncingCardContainerState();
}

class _BouncingCardContainerState extends State<BouncingCardContainer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 180),
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.pressScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      AppHaptics.lightImpact();
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      _controller.reverse();
      widget.onTap!();
    }
  }

  void _onTapCancel() {
    if (widget.onTap != null) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null) return widget.child;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Wrapper for category filter pills and toggle chips.
/// Adds a 1.08x elastic scale pop on selection with crisp selection haptics.
class ElasticFilterChip extends StatefulWidget {
  final Widget child;
  final bool isSelected;
  final VoidCallback onTap;

  const ElasticFilterChip({
    super.key,
    required this.child,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<ElasticFilterChip> createState() => _ElasticFilterChipState();
}

class _ElasticFilterChipState extends State<ElasticFilterChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.09), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.09, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));
  }

  @override
  void didUpdateWidget(ElasticFilterChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected && widget.isSelected) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    AppHaptics.selectionClick();
    _controller.forward(from: 0.0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Wrapper for primary action buttons (Apply Now, Submit, Save Profile).
/// Provides 0.95x press compression + medium haptic feedback.
class PressableButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressScale;

  const PressableButton({
    super.key,
    required this.child,
    this.onTap,
    this.pressScale = 0.95,
  });

  @override
  State<PressableButton> createState() => _PressableButtonState();
}

class _PressableButtonState extends State<PressableButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 160),
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.pressScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      AppHaptics.lightImpact();
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      AppHaptics.mediumImpact();
      _controller.reverse();
      widget.onTap!();
    }
  }

  void _onTapCancel() {
    if (widget.onTap != null) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null) return widget.child;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: widget.child,
        ),
      ),
    );
  }
}
