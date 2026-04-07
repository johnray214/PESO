import 'package:shared_preferences/shared_preferences.dart';

import 'notification_service.dart';
import 'api_service.dart';
import 'user_session.dart';

class SessionPrefs {
  static const _kToken = 'auth_token_v1';

  static Future<void> saveToken(String token) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kToken, token);
    
    // Trigger sync for new logins
    NotificationService().initialize();
  }

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kToken);
  }

  /// Fast, local-only check — no network call.
  /// Returns true if a saved token exists on disk.
  static Future<bool> hasToken() async {
    final p = await SharedPreferences.getInstance();
    final token = p.getString(_kToken)?.trim() ?? '';
    return token.isNotEmpty;
  }

  /// Returns the raw saved token (or empty string). No network call.
  static Future<String> getToken() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kToken)?.trim() ?? '';
  }

  /// Restores session from persisted token by calling profile endpoint.
  /// Returns true only when token exists and backend confirms it's valid.
  static Future<bool> restoreSession() async {
    final p = await SharedPreferences.getInstance();
    final token = p.getString(_kToken)?.trim() ?? '';
    if (token.isEmpty) return false;

    final profile = await ApiService.getUser(token);
    if (profile['success'] != true) {
      await clear();
      return false;
    }

    final data = profile['data'];
    if (data is! Map<String, dynamic>) {
      await clear();
      return false;
    }

    final user = (data['jobseeker'] as Map<String, dynamic>?) ??
        (data['user'] as Map<String, dynamic>?) ??
        data;

    UserSession().token = token;
    UserSession().updateFromUser(user);

    // Trigger sync for restored sessions
    NotificationService().initialize();

    return true;
  }
}

