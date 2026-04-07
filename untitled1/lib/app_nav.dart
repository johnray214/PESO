import 'package:flutter/material.dart';

/// Root [Navigator] for [MaterialApp] — used so jobseeker sign-out can replace
/// the entire stack with the auth screen (see [registerJobseekerSignOut]).
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

void Function()? _jobseekerSignOutToAuth;

/// Called once from [SplashScreen] with a closure that pushes [AuthEntryPage].
void registerJobseekerSignOut(void Function() fn) {
  _jobseekerSignOutToAuth = fn;
}

void navigateToAuthEntryReplacingStack() {
  _jobseekerSignOutToAuth?.call();
}

/// A global toggle to turn off the ConnectivityWrapper's global modal
/// on pages that have their own dedicated offline UI (like the Splash Screen).
final ValueNotifier<bool> disableConnectivityModalNotifier = ValueNotifier<bool>(true);

