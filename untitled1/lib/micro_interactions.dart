import 'package:flutter/services.dart';

/// Light haptic for successful primary actions (save, apply, register, etc.).
void microInteractionSuccess() {
  HapticFeedback.mediumImpact();
}

/// Softer tick — e.g. pull-to-refresh completed.
void microInteractionSelection() {
  HapticFeedback.selectionClick();
}
