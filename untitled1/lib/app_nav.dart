import 'package:flutter/material.dart';

/// Root [Navigator] for [MaterialApp] — used so jobseeker sign-out can replace
/// the entire stack with the auth screen (see [registerJobseekerSignOut]).
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

void Function()? _jobseekerSignOutToAuth;

/// Called once from [SplashScreen] with a closure that pushes [AuthEntryPage].
void registerJobseekerSignOut(void Function() fn) {
  _jobseekerSignOutToAuth = fn;
}

/// After clearing session — replaces stack with auth (login) flow.
void navigateToAuthEntryReplacingStack() {
  _jobseekerSignOutToAuth?.call();
}
