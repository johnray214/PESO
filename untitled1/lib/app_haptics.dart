import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Central manager for app-wide haptic feedback with user setting toggle support.
class AppHaptics {
  static const String _key = 'haptics_enabled';
  static bool _enabled = true;

  static bool get enabled => _enabled;

  /// Load initial setting from SharedPreferences on app launch.
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _enabled = prefs.getBool(_key) ?? true;
    } catch (_) {
      _enabled = true;
    }
  }

  /// Update and persist the haptics enabled state.
  static Future<void> setEnabled(bool value) async {
    _enabled = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, value);
    } catch (_) {}
  }

  /// Light impact for standard button taps or subtle UI triggers.
  static void lightImpact() {
    if (_enabled) HapticFeedback.lightImpact();
  }

  /// Medium impact for successful primary actions (save, apply, register).
  static void mediumImpact() {
    if (_enabled) HapticFeedback.mediumImpact();
  }

  /// Heavy impact for critical alerts or major state changes.
  static void heavyImpact() {
    if (_enabled) HapticFeedback.heavyImpact();
  }

  /// Selection tick for tab switches or scroll item snaps.
  static void selectionClick() {
    if (_enabled) HapticFeedback.selectionClick();
  }

  /// Standard vibration.
  static void vibrate() {
    if (_enabled) HapticFeedback.vibrate();
  }
}
