import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Persists first-run intro + post-registration onboarding completion.
class OnboardingPrefs {
  static const _kIntroV1 = 'onboarding_intro_v1_done';
  static const _kPostAuthV1 = 'onboarding_post_auth_v1_done';

  /// After this version bump, intro can show again (optional future use).
  static const introVersion = 1;

  static Future<bool> isIntroDone() async {
    if (kDebugMode) return false;
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kIntroV1) ?? false;
  }

  static Future<void> setIntroDone() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kIntroV1, true);
  }

  /// Call after successful registration — user must complete post-auth flow.
  static Future<void> setPostAuthPending() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kPostAuthV1, false);
  }

  /// Call when post-auth flow finishes.
  static Future<void> setPostAuthComplete() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kPostAuthV1, true);
  }

  /// `true` only when explicitly set to `false` (new registration).
  /// Missing key → treat as already completed (existing users).
  static Future<bool> needsPostAuth() async {
    if (kDebugMode) return true;
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kPostAuthV1) == false;
  }
}
