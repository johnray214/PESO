import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'user_session.dart';

/// Persists first-run intro + post-registration onboarding completion.
class OnboardingPrefs {
  static const _kIntroV1 = 'onboarding_intro_v1_done';
  static const _kPostAuthV1 = 'onboarding_post_auth_v1_done';

  /// After this version bump, intro can show again (optional future use).
  static const introVersion = 1;

  static String _getIntroKey(String? token) {
    if (token == null || token.isEmpty) return _kIntroV1;
    // Tie the intro status to a specific token (or a hash of it) to make it per-user
    return '${_kIntroV1}_$token';
  }

  static Future<bool> isIntroDone({String? token, bool ignoreDebug = false}) async {
    if (kDebugMode && !ignoreDebug) return false;
    final p = await SharedPreferences.getInstance();
    return p.getBool(_getIntroKey(token)) ?? false;
  }

  static Future<void> setIntroDone({String? token}) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_getIntroKey(token), true);
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
  static Future<bool> needsPostAuth({bool ignoreDebug = false}) async {
    if (kDebugMode && !ignoreDebug) return true;
    
    // If logged in, the backend source of truth is absolute.
    if (UserSession().isLoggedIn) {
      return !UserSession().isOnboardingDone;
    }

    // If not logged in yet (e.g. just registered but session not fully restored), 
    // check the local pending flag.
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kPostAuthV1) == false;
  }
}
