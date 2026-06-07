import 'package:flutter/material.dart';

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
  static const double _activeCircleSize = 30;
  static const double _lineHeight = 3;

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
                    width: lineWidth * trackProgress,
                    top: (_activeCircleSize - _lineHeight) / 2,
                    child: Container(
                      height: _lineHeight,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: List.generate(totalSteps, (index) {
                      final isActive = index == currentStep;
                      final isComplete = index < currentStep;
                      final color = isComplete || isActive
                          ? const Color(0xFF2563EB)
                          : const Color(0xFFCBD5E1);
                      final size = isActive ? _activeCircleSize : _circleSize;

                      return Expanded(
                        child: Center(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            width: size,
                            height: size,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isComplete
                                  ? const Color(0xFF2563EB)
                                  : isActive
                                      ? const Color(0xFFEFF6FF)
                                      : const Color(0xFFF1F5F9),
                              border: Border.all(
                                color: color,
                                width: isActive ? 2 : 1.5,
                              ),
                            ),
                            child: Center(
                              child: isComplete
                                  ? const Icon(
                                      Icons.check_rounded,
                                      size: 14,
                                      color: Colors.white,
                                    )
                                  : Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: isActive
                                            ? const Color(0xFF2563EB)
                                            : const Color(0xFF94A3B8),
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
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(totalSteps, (index) {
            final isActive = index == currentStep;
            final label =
                index < stepLabels.length ? stepLabels[index] : '';

            return Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                  color: isActive
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
