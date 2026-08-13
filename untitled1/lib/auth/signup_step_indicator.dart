import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import '../app_haptics.dart';

/// Helper to compute cartoony keyframe pose (scale up, clockwise tilt, hold pose, scale back down).
class CartoonyTwitchPose {
  final double scale;
  final double rotation;
  final double glowAlpha;

  CartoonyTwitchPose({
    required this.scale,
    required this.rotation,
    required this.glowAlpha,
  });

  static CartoonyTwitchPose calculate(
    double t,
    bool isMovingForward, {
    double popScaleBoost = 0.30,
    double tiltAngleRadians = 0.22,
  }) {
    if (t <= 0.0 || t >= 1.0) {
      return CartoonyTwitchPose(
        scale: 1.0,
        rotation: 0.0,
        glowAlpha: 0.0,
      );
    }

    double stageArc = 0.0;
    if (t < 0.25) {
      // Phase 1: Rapid initial scale pop + clockwise tilt
      stageArc = Curves.easeOutBack.transform(t / 0.25);
    } else if (t <= 0.65) {
      // Phase 2: Continuous slow scale drift — feels like it's still growing.
      // Starts at 1.0 and gently drifts up to 1.10 by end of phase.
      final holdProgress = (t - 0.25) / 0.40; // 0.0 → 1.0 through the hold
      stageArc = 1.0 + (0.10 * holdProgress); // Slow drift: 1.0 → 1.10
    } else {
      // Phase 3: Ease back down to resting size
      final dropProgress = (t - 0.65) / 0.35;
      // Starts from 1.10 (peak drift) and eases back down to 0
      final peakArc = 1.10;
      stageArc =
          peakArc * (1.0 - Curves.easeInOutCubic.transform(dropProgress));
    }

    // Clockwise rotation fades out during hold + drop to match scale feel
    final rotationArc =
        stageArc.clamp(0.0, 1.05); // Cap rotation at initial pop level
    final rotationAngle =
        (isMovingForward ? tiltAngleRadians : -tiltAngleRadians) * rotationArc;
    final scaleBoost = 1.0 + (popScaleBoost * stageArc);
    final glowAlpha = (0.28 * stageArc).clamp(0.0, 1.0);

    return CartoonyTwitchPose(
      scale: scaleBoost,
      rotation: rotationAngle,
      glowAlpha: glowAlpha,
    );
  }
}

/// Labeled step circles with a connecting progress line.
/// When progress line hits a step circle (1, 2, 3, 4), that step badge performs
/// a cartoony clockwise rotation & scale pop, holds that pose longer, then settles back down in place.
class SignupStepIndicator extends StatefulWidget {
  const SignupStepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.stepLabels,
    this.popScaleBoost = 0.15,
    this.tiltAngleRadians = 0.22,
  });

  final int currentStep;
  final int totalSteps;
  final List<String> stepLabels;

  /// Scale boost multiplier during pop (e.g. 0.30 = +30% scale boost, 0.20 = +20% smaller pop).
  final double popScaleBoost;

  /// Clockwise tilt angle in radians (e.g. 0.22 rad ≈ 12.6 degrees).
  final double tiltAngleRadians;

  @override
  State<SignupStepIndicator> createState() => _SignupStepIndicatorState();
}

class _SignupStepIndicatorState extends State<SignupStepIndicator>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnim;

  late AnimationController _cartoonyController;

  int _previousStep = 0;
  int _targetStep = 0;

  static const double _circleSize = 28;
  static const double _activeCircleSize = 32;
  static const double _lineHeight = 3.5;

  @override
  void initState() {
    super.initState();
    _previousStep = widget.currentStep;
    _targetStep = widget.currentStep;

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _progressAnim = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOutCubic,
    );

    _cartoonyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 780), // Cartoony hold duration
    );

    _progressController.value = 1.0;
    _cartoonyController.value = 1.0;
  }

  double _calculateProgress(int step) {
    if (widget.totalSteps <= 1) return 1.0;
    return (step / (widget.totalSteps - 1)).clamp(0.0, 1.0);
  }

  @override
  void didUpdateWidget(SignupStepIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentStep != widget.currentStep) {
      _previousStep = oldWidget.currentStep;
      _targetStep = widget.currentStep;

      final isMovingForward = widget.currentStep > oldWidget.currentStep;

      if (!isMovingForward) {
        _cartoonyController.value = 1.0; // Suppress animation when going back
      }

      // Fill the progress line first, then celebrate the completed step circle
      _progressController.forward(from: 0.0).then((_) {
        if (mounted && isMovingForward) {
          AppHaptics
              .lightImpact(); // Step completed — subtle tactile confirmation
          _cartoonyController.forward(from: 0.0);
        }
      });
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _cartoonyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalSteps = widget.totalSteps;
    final stepLabels = widget.stepLabels;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: _activeCircleSize + 6,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final trackWidth = constraints.maxWidth;
              final inset = _activeCircleSize / 2;
              final lineWidth = trackWidth - _activeCircleSize;

              final startProgress = _calculateProgress(_previousStep);
              final endProgress = _calculateProgress(_targetStep);

              return AnimatedBuilder(
                animation: Listenable.merge(
                    [_progressController, _cartoonyController]),
                builder: (context, _) {
                  final lineT = _progressAnim.value;
                  final currentProgress =
                      startProgress + (endProgress - startProgress) * lineT;

                  final cartoonyT = _cartoonyController.value;
                  final isMovingForward = _targetStep > _previousStep;

                  // Compute cartoony pose keyframes ONLY when moving forward
                  final pose = isMovingForward
                      ? CartoonyTwitchPose.calculate(
                          cartoonyT,
                          isMovingForward,
                          popScaleBoost: widget.popScaleBoost,
                          tiltAngleRadians: widget.tiltAngleRadians,
                        )
                      : CartoonyTwitchPose(
                          scale: 1.0,
                          rotation: 0.0,
                          glowAlpha: 0.0,
                        );

                  return Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      // Base background track (grey line)
                      Positioned(
                        left: inset,
                        width: lineWidth,
                        top: (_activeCircleSize - _lineHeight) / 2 + 3,
                        child: Container(
                          height: _lineHeight,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      // Active progress blue line
                      Positioned(
                        left: inset,
                        width:
                            (lineWidth * currentProgress).clamp(0.0, lineWidth),
                        top: (_activeCircleSize - _lineHeight) / 2 + 3,
                        child: Container(
                          height: _lineHeight,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF1D4ED8),
                                Color(0xFF2563EB),
                                Color(0xFF3B82F6),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2563EB)
                                    .withValues(alpha: 0.30),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Step Circles (1, 2, 3, 4)
                      Row(
                        children: List.generate(totalSteps, (index) {
                          final stepFraction =
                              totalSteps <= 1 ? 0.0 : index / (totalSteps - 1);
                          final isComplete = index < totalSteps - 1 &&
                              currentProgress >= (stepFraction + 0.15);
                          final isActive = index == widget.currentStep;
                          // Celebrate the COMPLETED step (previousStep), not the new active one
                          final isCompletedCircle =
                              isMovingForward && index == _previousStep;

                          final color = isComplete || isActive
                              ? const Color(0xFF2563EB)
                              : const Color(0xFFCBD5E1);

                          // Cartoony pop plays on the just-completed circle (checkmark reveal moment)
                          final finalScale =
                              isCompletedCircle ? pose.scale : 1.0;

                          final finalRotation =
                              isCompletedCircle ? pose.rotation : 0.0;

                          final circleTransform = Matrix4.identity()
                            ..rotateZ(finalRotation)
                            ..scale(finalScale, finalScale);

                          return Expanded(
                            child: Center(
                              child: Transform(
                                transform: circleTransform,
                                alignment: Alignment.center,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeOutCubic,
                                  width: isActive
                                      ? _activeCircleSize
                                      : _circleSize,
                                  height: isActive
                                      ? _activeCircleSize
                                      : _circleSize,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isComplete
                                        ? const Color(0xFF2563EB)
                                        : isActive
                                            ? const Color(0xFFEFF6FF)
                                            : const Color(0xFFF8FAFC),
                                    border: Border.all(
                                      color: color,
                                      width: isActive ? 2.5 : 1.5,
                                    ),
                                    boxShadow: isActive || isComplete
                                        ? [
                                            BoxShadow(
                                              color: const Color(0xFF2563EB)
                                                  .withValues(
                                                      alpha: 0.22 +
                                                          pose.glowAlpha),
                                              blurRadius:
                                                  6 + (8 * pose.glowAlpha),
                                              offset: const Offset(0, 2),
                                            )
                                          ]
                                        : null,
                                  ),
                                  child: Center(
                                    child: AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      switchInCurve: Curves.easeOutBack,
                                      switchOutCurve: Curves.easeIn,
                                      transitionBuilder: (child, anim) =>
                                          ScaleTransition(
                                              scale: anim, child: child),
                                      child: isComplete
                                          ? const HugeIcon(
                                              icon:
                                                  HugeIcons.strokeRoundedTick01,
                                              key: ValueKey('check'),
                                              size: 15,
                                              color: Colors.white,
                                              strokeWidth: 2.5,
                                            )
                                          : Text(
                                              '${index + 1}',
                                              key: ValueKey<int>(index),
                                              style: GoogleFonts.poppins(
                                                fontSize: isActive ? 13 : 11,
                                                fontWeight: FontWeight.w800,
                                                color: isActive
                                                    ? const Color(0xFF2563EB)
                                                    : const Color(0xFF94A3B8),
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: List.generate(totalSteps, (index) {
            final isActive = index == widget.currentStep;
            final isComplete = index < widget.currentStep;
            final label = index < stepLabels.length ? stepLabels[index] : '';

            return Expanded(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: GoogleFonts.poppins(
                  fontSize: isActive ? 11 : 10.5,
                  fontWeight: isActive || isComplete
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: isActive || isComplete
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF94A3B8),
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
