import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_config.dart';
import '../l10n/app_localizations.dart';
import '../legal_documents.dart';
import '../password_rules.dart';
import 'auth_shared.dart';
import 'signup_step_indicator.dart';

/// Number of signup wizard steps (name → contact → password → profile).
const int kSignupStepCount = 4;

/// Per-step validation for the signup wizard. Returns an error message or null.
class SignupStepValidation {
  static String? validateStep({
    required int step,
    required String firstName,
    required String lastName,
    required String phone,
    required String email,
    required String password,
    required String confirmPassword,
    required String? sex,
    String? serverEmailError,
  }) {
    switch (step) {
      case 0:
        if (firstName.trim().isEmpty) {
          return 'Please enter your first name';
        }
        if (lastName.trim().isEmpty) {
          return 'Please enter your last name';
        }
        return null;
      case 1:
        final ph = phone.trim();
        if (ph.isEmpty) {
          return 'Please enter your mobile number';
        }
        if (!RegExp(r'^0\d{10}$').hasMatch(ph)) {
          return 'Enter 11-digit PH number (e.g. 09XXXXXXXXX)';
        }
        final em = email.trim();
        if (em.isEmpty) {
          return 'Please enter your email';
        }
        if (!em.contains('@') || !em.contains('.')) {
          return 'Please enter a valid email address';
        }
        if (serverEmailError != null) {
          return serverEmailError;
        }
        return null;
      case 2:
        if (password.isEmpty) {
          return 'Please enter your password';
        }
        if (PasswordRules.hasWhitespace(password)) {
          return 'Password cannot contain spaces';
        }
        final pwError = PasswordRules.validateStrongPassword(password);
        if (pwError != null) return pwError;
        if (confirmPassword.isEmpty) {
          return 'Please confirm your password';
        }
        if (password != confirmPassword) {
          return 'Passwords do not match';
        }
        return null;
      case 3:
        if (sex == null || sex.isEmpty) {
          return 'Please select your sex';
        }
        return null;
      default:
        return null;
    }
  }
}

/// Step-by-step signup form shown inside [LoginModal] when in sign-up mode.
class SignupWizard extends StatelessWidget {
  const SignupWizard({
    super.key,
    required this.currentStep,
    required this.renderAsModal,
    required this.firstNameController,
    required this.middleInitialController,
    required this.lastNameController,
    required this.phoneController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.dobController,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.selectedSex,
    required this.acceptedTermsAndPrivacy,
    required this.serverEmailError,
    required this.onEmailChanged,
    required this.onPasswordChanged,
    required this.onTogglePassword,
    required this.onToggleConfirmPassword,
    required this.onSexChanged,
    required this.onTermsChanged,
    required this.onPickDob,
  });

  final int currentStep;
  final bool renderAsModal;
  final TextEditingController firstNameController;
  final TextEditingController middleInitialController;
  final TextEditingController lastNameController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final TextEditingController dobController;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final String? selectedSex;
  final bool acceptedTermsAndPrivacy;
  final String? serverEmailError;
  final ValueChanged<String> onEmailChanged;
  final VoidCallback onPasswordChanged;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;
  final ValueChanged<String?> onSexChanged;
  final ValueChanged<bool> onTermsChanged;
  final VoidCallback onPickDob;

  List<String> _stepLabels(BuildContext context) {
    final s = S.of(context);
    return [
      s?.signupStepName ?? 'Name',
      s?.signupStepContact ?? 'Contact',
      s?.signupStepSecurity ?? 'Security',
      s?.signupStepDetails ?? 'Details',
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SignupStepIndicator(
          currentStep: currentStep,
          totalSteps: kSignupStepCount,
          stepLabels: _stepLabels(context),
        ),
        const SizedBox(height: 20),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: KeyedSubtree(
            key: ValueKey<int>(currentStep),
            child: _buildStep(context),
          ),
        ),
      ],
    );
  }

  Widget _buildStep(BuildContext context) {
    return switch (currentStep) {
      0 => _buildNameStep(context),
      1 => _buildContactStep(context),
      2 => _buildPasswordStep(context),
      _ => _buildProfileStep(context),
    };
  }

  Widget _buildNameStep(BuildContext context) {
    final s = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: firstNameController,
                textInputAction: TextInputAction.next,
                decoration: authFieldDecoration(
                  s?.firstName ?? 'First name',
                  Icons.person_outline_rounded,
                  renderAsModal: renderAsModal,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: TextFormField(
                controller: middleInitialController,
                textCapitalization: TextCapitalization.characters,
                maxLength: 2,
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(1),
                  UpperCaseTextFormatter(),
                ],
                decoration: authFieldDecoration(
                  'M.I.',
                  Icons.text_format_rounded,
                  renderAsModal: renderAsModal,
                  counterText: '',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: lastNameController,
          textInputAction: TextInputAction.done,
          decoration: authFieldDecoration(
            s?.lastName ?? 'Last name',
            Icons.person_outline_rounded,
            renderAsModal: renderAsModal,
          ),
        ),
      ],
    );
  }

  Widget _buildContactStep(BuildContext context) {
    final s = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          decoration: authFieldDecoration(
            s?.contactNumber ?? 'Phone number (11 digits)',
            Icons.phone_outlined,
            renderAsModal: renderAsModal,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.email],
          onChanged: onEmailChanged,
          decoration: authFieldDecoration(
            s?.email ?? 'Email',
            Icons.email_outlined,
            renderAsModal: renderAsModal,
          ),
        ),
        if (serverEmailError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(
              serverEmailError!,
              style: const TextStyle(
                color: Color(0xFFDC2626),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPasswordStep(BuildContext context) {
    final s = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: passwordController,
          obscureText: obscurePassword,
          textInputAction: TextInputAction.next,
          inputFormatters: PasswordRules.inputFormattersNoWhitespace,
          onChanged: (_) => onPasswordChanged(),
          decoration: authFieldDecoration(
            s?.password ?? 'Password',
            Icons.lock_outline_rounded,
            renderAsModal: renderAsModal,
            suffix: IconButton(
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: Colors.grey[600],
              ),
              onPressed: onTogglePassword,
            ),
          ),
        ),
        const SizedBox(height: 10),
        _buildPasswordRequirements(),
        const SizedBox(height: 16),
        TextFormField(
          controller: confirmPasswordController,
          obscureText: obscureConfirmPassword,
          textInputAction: TextInputAction.done,
          inputFormatters: PasswordRules.inputFormattersNoWhitespace,
          onChanged: (_) => onPasswordChanged(),
          decoration: authFieldDecoration(
            s?.confirmPassword ?? 'Confirm password',
            Icons.lock_outline_rounded,
            renderAsModal: renderAsModal,
            suffix: IconButton(
              icon: Icon(
                obscureConfirmPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: Colors.grey[600],
              ),
              onPressed: onToggleConfirmPassword,
            ),
          ),
        ),
        if (confirmPasswordController.text.isNotEmpty &&
            confirmPasswordController.text != passwordController.text)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Passwords do not match',
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProfileStep(BuildContext context) {
    final s = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: dobController,
          readOnly: true,
          style: const TextStyle(
            fontSize: 12.5,
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w500,
          ),
          decoration: authFieldDecoration(
            s?.birthdate ?? 'Birthdate (YYYY-MM-DD)',
            Icons.cake_outlined,
            renderAsModal: renderAsModal,
            labelStyle: const TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
              fontSize: 12.5,
            ),
            floatingLabelStyle: const TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
            isDense: true,
          ),
          onTap: onPickDob,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: selectedSex,
          decoration: authFieldDecoration(
            s?.gender ?? 'Sex',
            Icons.person_outline,
            renderAsModal: renderAsModal,
          ),
          items: [
            DropdownMenuItem(
              value: 'male',
              child: Text(s?.male ?? 'Male'),
            ),
            DropdownMenuItem(
              value: 'female',
              child: Text(s?.female ?? 'Female'),
            ),
          ],
          onChanged: onSexChanged,
        ),
        const SizedBox(height: 16),
        _buildLegalConsentRow(context),
      ],
    );
  }

  Widget _buildPasswordRequirements() {
    final p = passwordController.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Password must include:',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
        _passwordRequirementRow(
          'At least 8 characters',
          PasswordRules.hasMinLength(p),
        ),
        _passwordRequirementRow(
          'Uppercase & lowercase letters',
          PasswordRules.hasUppercase(p) && PasswordRules.hasLowercase(p),
          helpTooltip: PasswordRules.tooltipMixedCase,
        ),
        _passwordRequirementRow(
          'At least one number',
          PasswordRules.hasNumber(p),
        ),
        _passwordRequirementRow(
          'At least one special character',
          PasswordRules.hasSymbol(p),
          helpTooltip: PasswordRules.tooltipSpecialChar,
        ),
      ],
    );
  }

  Widget _passwordRequirementRow(String label, bool ok, {String? helpTooltip}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            ok ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 16,
            color: ok ? const Color(0xFF16A34A) : const Color(0xFFCBD5E1),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color:
                          ok ? const Color(0xFF166534) : const Color(0xFF64748B),
                    ),
                  ),
                ),
                if (helpTooltip != null)
                  PasswordRequirementHelpIcon(message: helpTooltip),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalConsentRow(BuildContext context) {
    const baseStyle = TextStyle(
      fontSize: 13,
      height: 1.35,
      color: Color(0xFF334155),
      fontWeight: FontWeight.w500,
    );
    const linkStyle = TextStyle(
      color: Color(0xFF2563EB),
      fontSize: 13,
      fontWeight: FontWeight.w700,
      height: 1.35,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Transform.translate(
          offset: const Offset(-4, -2),
          child: SizedBox(
            width: 28,
            height: 28,
            child: Checkbox(
              value: acceptedTermsAndPrivacy,
              onChanged: (v) => onTermsChanged(v ?? false),
              activeColor: const Color(0xFF2563EB),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: RichText(
              text: const TextSpan(
                style: baseStyle,
                children: [
                  TextSpan(text: 'I have read and agree to the '),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.baseline,
                    baseline: TextBaseline.alphabetic,
                    child: _TermsLink(style: linkStyle),
                  ),
                  TextSpan(text: ' and the '),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.baseline,
                    baseline: TextBaseline.alphabetic,
                    child: _PrivacyLink(style: linkStyle),
                  ),
                  TextSpan(text: ' of $kAppDisplayName.'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TermsLink extends StatelessWidget {
  const _TermsLink({required this.style});

  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Navigator.of(context).push<void>(
          MaterialPageRoute(builder: (_) => const TermsOfServicePage()),
        );
      },
      child: Text('Terms & Conditions', style: style),
    );
  }
}

class _PrivacyLink extends StatelessWidget {
  const _PrivacyLink({required this.style});

  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Navigator.of(context).push<void>(
          MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
        );
      },
      child: Text('Privacy Policy', style: style),
    );
  }
}
