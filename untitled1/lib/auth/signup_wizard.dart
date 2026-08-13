import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
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

/// Animated Back + Continue button row for the signup wizard.
///
/// When [showBack] is false the row shows a single full-width Continue button.
/// When [showBack] becomes true the Back button expands from zero width
/// (left side) while Continue shrinks to fill the remaining space — giving
/// the illusion that the single button "splits" into two. Reversing [showBack]
/// plays the collapse animation.
class SignupButtonRow extends StatefulWidget {
  const SignupButtonRow({
    super.key,
    required this.showBack,
    required this.onBack,
    required this.onContinue,
    required this.continueLabel,
    this.isSubmitting = false,
    this.isContinueDisabled = false,
    this.backLabel = 'Back',
  });

  final bool showBack;
  final VoidCallback? onBack;
  final VoidCallback? onContinue;
  final String continueLabel;
  final String backLabel;
  final bool isSubmitting;
  final bool isContinueDisabled;

  @override
  State<SignupButtonRow> createState() => _SignupButtonRowState();
}

class _SignupButtonRowState extends State<SignupButtonRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _widthFactor;  // 0 → 1 for Back button width
  late Animation<double> _opacity;       // 0 → 1 for Back button opacity

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
      value: widget.showBack ? 1.0 : 0.0,
    );
    _widthFactor = CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeInOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    );
    _opacity = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      reverseCurve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    );
  }

  @override
  void didUpdateWidget(SignupButtonRow old) {
    super.didUpdateWidget(old);
    if (widget.showBack != old.showBack) {
      if (widget.showBack) {
        _ctrl.forward();
      } else {
        _ctrl.reverse();
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Back button — grows from zero width
            ClipRect(
              child: Align(
                alignment: Alignment.centerLeft,
                widthFactor: _widthFactor.value,
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: FadeTransition(
                    opacity: _opacity,
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed:
                            widget.isSubmitting ? null : widget.onBack,
                        icon: const HugeIcon(
                          icon: HugeIcons.strokeRoundedArrowLeft01,
                          size: 18,
                          color: Color(0xFF475569),
                          strokeWidth: 2.0,
                        ),
                        label: Text(
                          widget.backLabel,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF475569),
                          side:
                              const BorderSide(color: Color(0xFFE2E8F0)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Continue button — always Expanded so it fills remaining space
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: widget.isSubmitting || widget.isContinueDisabled
                      ? null
                      : widget.onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF93C5FD),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                  ),
                  child: widget.isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          widget.continueLabel,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}


/// Step-by-step signup form shown inside [LoginModal] when in sign-up mode.
class SignupWizard extends StatelessWidget {
  const SignupWizard({
    super.key,
    required this.currentStep,
    this.isMovingForward = true,
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
  final bool isMovingForward;
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
        const SizedBox(height: 12),
        ClipRect(
          child: Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 4),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 550),
              layoutBuilder: (currentChild, previousChildren) {
                return Stack(
                  clipBehavior: Clip.hardEdge,
                  alignment: Alignment.topCenter,
                  children: <Widget>[
                    ...previousChildren,
                    if (currentChild != null) currentChild,
                  ],
                );
              },
              transitionBuilder: (Widget child, Animation<double> animation) {
                final childKey = child.key;
                final childStep =
                    childKey is ValueKey<int> ? childKey.value : currentStep;
                final isEntering = childStep == currentStep;

                if (isEntering) {
                  final startOffset = isMovingForward
                      ? const Offset(1.0, 0)
                      : const Offset(-1.0, 0);
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: startOffset,
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeInOutCubic,
                    )),
                    child: child,
                  );
                } else {
                  final exitOffset = isMovingForward
                      ? const Offset(-1.0, 0)
                      : const Offset(1.0, 0);
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: exitOffset,
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeInOutCubic,
                    )),
                    child: child,
                  );
                }
              },
              child: KeyedSubtree(
                key: ValueKey<int>(currentStep),
                child: _buildStep(context),
              ),
            ),
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

  Widget _buildSectionHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameStep(BuildContext context) {
    final s = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(
          'Personal information',
          'Enter your full name as shown on official IDs.',
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildAuthFieldLabel(s?.firstName ?? 'First name'),
                  TextFormField(
                    controller: firstNameController,
                    textInputAction: TextInputAction.next,
                    decoration: authFieldDecoration(
                      HugeIcons.strokeRoundedUser,
                      hintText: 'e.g. Juan',
                      renderAsModal: renderAsModal,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildAuthFieldLabel('M.I.'),
                  TextFormField(
                    controller: middleInitialController,
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 2,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(1),
                      UpperCaseTextFormatter(),
                    ],
                    decoration: authFieldDecoration(
                      HugeIcons.strokeRoundedText,
                      hintText: 'A',
                      renderAsModal: renderAsModal,
                      counterText: '',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        buildAuthFieldLabel(s?.lastName ?? 'Last name'),
        TextFormField(
          controller: lastNameController,
          textInputAction: TextInputAction.done,
          decoration: authFieldDecoration(
            HugeIcons.strokeRoundedUser,
            hintText: 'e.g. Dela Cruz',
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
        _buildSectionHeader(
          'Contact information',
          'Enter your contact details.',
        ),
        buildAuthFieldLabel(s?.contactNumber ?? 'Contact number'),
        TextFormField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          decoration: authFieldDecoration(
            HugeIcons.strokeRoundedSmartPhone01,
            hintText: '09XX XXX XXXX',
            renderAsModal: renderAsModal,
          ),
        ),
        const SizedBox(height: 16),
        buildAuthFieldLabel(s?.email ?? 'Email'),
        TextFormField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.email],
          onChanged: onEmailChanged,
          decoration: authFieldDecoration(
            HugeIcons.strokeRoundedMail01,
            hintText: 'example@email.com',
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
        _buildSectionHeader(
          'Security setup',
          'Create a strong password for your account.',
        ),
        buildAuthFieldLabel(s?.password ?? 'Password'),
        TextFormField(
          controller: passwordController,
          obscureText: obscurePassword,
          keyboardType: TextInputType.visiblePassword,
          enableSuggestions: false,
          autocorrect: false,
          autofillHints: const [AutofillHints.newPassword],
          textInputAction: TextInputAction.next,
          inputFormatters: PasswordRules.inputFormattersNoWhitespace,
          onChanged: (_) => onPasswordChanged(),
          decoration: authFieldDecoration(
            HugeIcons.strokeRoundedLockPassword,
            hintText: '••••••••',
            renderAsModal: renderAsModal,
            suffix: IconButton(
              icon: HugeIcon(
                icon: obscurePassword
                    ? HugeIcons.strokeRoundedViewOffSlash
                    : HugeIcons.strokeRoundedView,
                color: Colors.grey[600]!,
                size: 20,
                strokeWidth: 2.0,
              ),
              onPressed: onTogglePassword,
            ),
          ),
        ),
        const SizedBox(height: 10),
        _buildPasswordRequirements(),
        const SizedBox(height: 16),
        buildAuthFieldLabel(s?.confirmPassword ?? 'Confirm password'),
        TextFormField(
          controller: confirmPasswordController,
          obscureText: obscureConfirmPassword,
          keyboardType: TextInputType.visiblePassword,
          enableSuggestions: false,
          autocorrect: false,
          autofillHints: const [AutofillHints.newPassword],
          textInputAction: TextInputAction.done,
          inputFormatters: PasswordRules.inputFormattersNoWhitespace,
          onChanged: (_) => onPasswordChanged(),
          decoration: authFieldDecoration(
            HugeIcons.strokeRoundedLockPassword,
            hintText: '••••••••',
            renderAsModal: renderAsModal,
            suffix: IconButton(
              icon: HugeIcon(
                icon: obscureConfirmPassword
                    ? HugeIcons.strokeRoundedViewOffSlash
                    : HugeIcons.strokeRoundedView,
                color: Colors.grey[600]!,
                size: 20,
                strokeWidth: 2.0,
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
        _buildSectionHeader(
          'Additional details',
          'Provide your birthdate and gender.',
        ),
        buildAuthFieldLabel(s?.birthdate ?? 'Birthdate'),
        TextFormField(
          controller: dobController,
          readOnly: true,
          style: const TextStyle(
            fontSize: 13.5,
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w500,
          ),
          decoration: authFieldDecoration(
            HugeIcons.strokeRoundedCalendar03,
            hintText: 'YYYY-MM-DD',
            renderAsModal: renderAsModal,
            isDense: true,
          ),
          onTap: onPickDob,
        ),
        const SizedBox(height: 16),
        buildAuthFieldLabel(s?.gender ?? 'Sex'),
        DropdownButtonFormField<String>(
          initialValue: selectedSex,
          decoration: authFieldDecoration(
            HugeIcons.strokeRoundedUser,
            hintText: 'Select sex',
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
          ok
              ? const HugeIcon(
                  icon: HugeIcons.strokeRoundedCheckmarkCircle01,
                  size: 16,
                  color: Color(0xFF16A34A),
                  strokeWidth: 2.0,
                )
              : const HugeIcon(
                  icon: HugeIcons.strokeRoundedCircle,
                  size: 16,
                  color: Color(0xFFCBD5E1),
                  strokeWidth: 2.0,
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
