import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

/// Labeled step circles with a connecting progress line through the centers.
class SignupStepIndicator extends StatelessWidget {
  const SignupStepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.stepLabels,
  });

  final int currentStep;
  final int totalSteps;
  final List<String> stepLabels;

  static const double _circleSize = 28;
  static const double _activeCircleSize = 32;
  static const double _lineHeight = 3.5;

  @override
  Widget build(BuildContext context) {
    final trackProgress = totalSteps <= 1
        ? 1.0
        : currentStep / (totalSteps - 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: _activeCircleSize,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final trackWidth = constraints.maxWidth;
              final inset = _activeCircleSize / 2;
              final lineWidth = trackWidth - _activeCircleSize;

              return TweenAnimationBuilder<double>(
                tween: Tween<double>(end: trackProgress),
                duration: const Duration(milliseconds: 950),
                curve: const Interval(0.38, 1.0, curve: Curves.easeInOutCubic),
                builder: (context, animProgress, _) {
                  return Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        left: inset,
                        width: lineWidth,
                        top: (_activeCircleSize - _lineHeight) / 2,
                        child: Container(
                          height: _lineHeight,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Positioned(
                        left: inset,
                        width: lineWidth * animProgress,
                        top: (_activeCircleSize - _lineHeight) / 2,
                        child: Container(
                          height: _lineHeight,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2563EB).withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        children: List.generate(totalSteps, (index) {
                          final stepFraction = totalSteps <= 1
                              ? 0.0
                              : index / (totalSteps - 1);
                          final isReached =
                              animProgress >= (stepFraction - 0.04);
                          final isComplete =
                              index < totalSteps - 1 &&
                              animProgress >= (stepFraction + 0.15);
                          final isActive = isReached && !isComplete;

                          final color = isComplete || isActive
                              ? const Color(0xFF2563EB)
                              : const Color(0xFFCBD5E1);
                          final size =
                              isActive ? _activeCircleSize : _circleSize;

                          return Expanded(
                            child: Center(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOutCubic,
                                width: size,
                                height: size,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isComplete
                                      ? const Color(0xFF2563EB)
                                      : isActive
                                          ? const Color(0xFFEFF6FF)
                                          : const Color(0xFFF8FAFC),
                                  border: Border.all(
                                    color: color,
                                    width: isActive ? 2.2 : 1.5,
                                  ),
                                  boxShadow: isActive || isComplete
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFF2563EB)
                                                .withOpacity(0.22),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          )
                                        ]
                                      : null,
                                ),
                                child: Center(
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 220),
                                    switchInCurve: Curves.easeOutBack,
                                    switchOutCurve: Curves.easeIn,
                                    transitionBuilder: (child, anim) =>
                                        ScaleTransition(
                                            scale: anim, child: child),
                                    child: isComplete
                                        ? const HugeIcon(
                                            icon: HugeIcons.strokeRoundedTick01,
                                            key: ValueKey('check'),
                                            size: 15,
                                            color: Colors.white,
                                            strokeWidth: 2.5,
                                          )
                                        : Text(
                                            '${index + 1}',
                                            key: ValueKey<int>(index),
                                            style: GoogleFonts.poppins(
                                              fontSize: isActive ? 12 : 11,
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
        const SizedBox(height: 8),
        Row(
          children: List.generate(totalSteps, (index) {
            final isActive = index == currentStep;
            final isComplete = index < currentStep;
            final label =
                index < stepLabels.length ? stepLabels[index] : '';

            return Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 10.5,
                  fontWeight: isActive || isComplete
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: isActive || isComplete
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF94A3B8),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
