import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Jobseeker password policy (aligned with Laravel `JobseekerPassword`).
class PasswordRules {
  PasswordRules._();

  static const int minLength = 8;

  static final RegExp _whitespace = RegExp(r'\s');

  /// Blocks spaces, tabs, and newlines (typing and paste) on password fields.
  static final List<TextInputFormatter> inputFormattersNoWhitespace = [
    FilteringTextInputFormatter.deny(_whitespace),
  ];

  static bool hasWhitespace(String s) => _whitespace.hasMatch(s);

  /// Tooltip beside “Uppercase & lowercase letters” on register / change password.
  static const String tooltipMixedCase =
      'Use at least one uppercase letter (A–Z) and one lowercase letter (a–z). '
      'Example: the “M” and “p” in “MyPassword1!”.';

  /// Tooltip beside “At least one special character” (any non–letter/non-digit).
  static const String tooltipSpecialChar =
      'Use at least one symbol: any character that is not a letter or number. '
      'Examples: ! @ # \$ % ^ & * ( ) _ + - = [ ] { } ; : , . ? / \\ | ~ ` '
      'Example password: Kabsat2026! (the ! is a special character).';

  static bool hasMinLength(String s) => s.length >= minLength;
  static bool hasUppercase(String s) => RegExp(r'[A-Z]').hasMatch(s);
  static bool hasLowercase(String s) => RegExp(r'[a-z]').hasMatch(s);
  static bool hasNumber(String s) => RegExp(r'[0-9]').hasMatch(s);

  /// At least one non-letter-non-digit character (symbol).
  static bool hasSymbol(String s) => RegExp(r'[^A-Za-z0-9]').hasMatch(s);

  /// Full policy: length, mixed case, digit, symbol.
  static bool isStrongPassword(String s) {
    return hasMinLength(s) &&
        hasUppercase(s) &&
        hasLowercase(s) &&
        hasNumber(s) &&
        hasSymbol(s);
  }

  /// `null` if valid; otherwise first human-readable error.
  static String? validateStrongPassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Please enter your password';
    if (hasWhitespace(v)) return 'Password cannot contain spaces';
    if (!hasMinLength(v)) return 'Use at least $minLength characters';
    if (!hasUppercase(v)) return 'Add at least one uppercase letter';
    if (!hasLowercase(v)) return 'Add at least one lowercase letter';
    if (!hasNumber(v)) return 'Add at least one number';
    if (!hasSymbol(v)) return 'Add at least one special character (!@#\$…)';
    return null;
  }
}

/// Tiny “?” shown beside a password rule; tap (or long-press) shows [message].
class PasswordRequirementHelpIcon extends StatelessWidget {
  const PasswordRequirementHelpIcon({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: message,
      triggerMode: TooltipTriggerMode.tap,
      showDuration: const Duration(seconds: 8),
      waitDuration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.only(left: 2),
        child: Icon(
          Icons.help_outline_rounded,
          size: 15,
          color: Colors.grey[600],
        ),
      ),
    );
  }
}
