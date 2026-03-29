/// Jobseeker password policy (aligned with Laravel `JobseekerPassword`).
class PasswordRules {
  PasswordRules._();

  static const int minLength = 8;

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
    if (!hasMinLength(v)) return 'Use at least $minLength characters';
    if (!hasUppercase(v)) return 'Add at least one uppercase letter';
    if (!hasLowercase(v)) return 'Add at least one lowercase letter';
    if (!hasNumber(v)) return 'Add at least one number';
    if (!hasSymbol(v)) return 'Add at least one special character (!@#\$…)';
    return null;
  }
}
