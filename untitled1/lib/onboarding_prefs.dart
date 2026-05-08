import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'user_session.dart';

/// Persists first-run intro + post-registration onboarding completion,
/// plus in-app coach-mark tour flags (Home, Map).
class OnboardingPrefs {
  static const _kIntroV1 = 'onboarding_intro_v1_done';
  static const _kPostAuthV1 = 'onboarding_post_auth_v1_done';
  static const _kHomeTourV1 = 'home_tour_v1_done';
  static const _kMapTourV1 = 'map_tour_v1_done';
  static const _kSkillsProfileGuideV1 = 'skills_profile_guide_v1_done';
  static const _kSkillsProfileGuidePendingV1 = 'skills_profile_guide_v1_pending';

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

  // ─── Home coach-mark tour ─────────────────────────────────────────────────

  static String _homeTourKey(String? token) {
    if (token == null || token.isEmpty) return _kHomeTourV1;
    return '${_kHomeTourV1}_$token';
  }

  static Future<bool> isHomeTourDone({String? token}) async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_homeTourKey(token)) ?? false;
  }

  static Future<void> setHomeTourDone({String? token}) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_homeTourKey(token), true);
  }

  static Future<void> clearHomeTourDone({String? token}) async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_homeTourKey(token));
  }

  // ─── Map coach-mark tour ──────────────────────────────────────────────────

  // Map tour is device-local (not token-scoped) to avoid retriggering when
  // auth tokens rotate between sessions for the same user.
  static String _mapTourKey(String? token) => _kMapTourV1;

  static Future<bool> isMapTourDone({String? token}) async {
    final p = await SharedPreferences.getInstance();
    final current = p.getBool(_mapTourKey(token));
    if (current == true) return true;

    // Backward-compatible migration from old token-scoped keys.
    final legacyDone = p.getKeys().any(
      (k) => k.startsWith('${_kMapTourV1}_') && (p.getBool(k) ?? false),
    );
    if (legacyDone) {
      await p.setBool(_mapTourKey(token), true);
      return true;
    }
    return false;
  }

  static Future<void> setMapTourDone({String? token}) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_mapTourKey(token), true);
  }

  static Future<void> clearMapTourDone({String? token}) async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_mapTourKey(token));
  }

  // ─── Skills Profile guided setup ──────────────────────────────────────────

  static String _skillsProfileGuideKey(String? token) {
    if (token == null || token.isEmpty) return _kSkillsProfileGuideV1;
    return '${_kSkillsProfileGuideV1}_$token';
  }

  static Future<bool> isSkillsProfileGuideDone({String? token}) async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_skillsProfileGuideKey(token)) ?? false;
  }

  static Future<void> setSkillsProfileGuideDone({String? token}) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_skillsProfileGuideKey(token), true);
  }

  static Future<void> clearSkillsProfileGuideDone({String? token}) async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_skillsProfileGuideKey(token));
  }

  static String _skillsProfileGuidePendingKey(String? token) {
    if (token == null || token.isEmpty) return _kSkillsProfileGuidePendingV1;
    return '${_kSkillsProfileGuidePendingV1}_$token';
  }

  /// Set to `true` right after registration/first auth for brand-new accounts.
  static Future<void> setSkillsProfileGuidePending({String? token}) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_skillsProfileGuidePendingKey(token), true);
  }

  /// Returns `true` only when explicitly set to true (brand-new accounts).
  static Future<bool> isSkillsProfileGuidePending({String? token}) async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_skillsProfileGuidePendingKey(token)) == true;
  }

  static Future<void> clearSkillsProfileGuidePending({String? token}) async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_skillsProfileGuidePendingKey(token));
  }
}
