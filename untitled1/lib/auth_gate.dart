import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'app_nav.dart';
import 'main.dart';
import 'session_prefs.dart';
import 'user_session.dart';

Future<void> openAuthForGuest(BuildContext context) async {
  UserSession().clear();
  await SessionPrefs.clear();
  if (!context.mounted) return;
  navigateToAuthEntryReplacingStack();
}

Future<bool> requireAuthenticatedSession(
  BuildContext context, {
  String title = 'Sign in required',
  String message =
      'Please sign in or create an account to continue with this action.',
  String confirmLabel = 'Sign in',
}) async {
  if (UserSession().canUseProtectedFeatures) return true;

  final proceed = await showAppDialog<bool>(
    context: context,
    type: AppDialogType.info,
    icon: HugeIcons.strokeRoundedLock,
    title: title,
    message: message,
    confirmLabel: confirmLabel,
    cancelLabel: 'Not now',
  );

  if (proceed == true && context.mounted) {
    await openAuthForGuest(context);
  }
  return false;
}
