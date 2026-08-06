import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'api_service.dart';
import 'l10n/app_localizations.dart';
import 'password_rules.dart';
import 'user_session.dart';
import 'auth/auth_shared.dart';
import 'micro_interactions.dart';

/// Signed-in jobseeker: current + new + confirm. Uses `POST /jobseeker/profile/password`.
class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _submitting = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String? _validateNew(String? v) => PasswordRules.validateStrongPassword(v);

  String? _validateConfirm(String? v) {
    final l10n = S.of(context);
    if (v == null || v.isEmpty) {
      return l10n?.confirmYourNewPassword ?? 'Confirm your new password';
    }
    if (PasswordRules.hasWhitespace(v)) {
      return 'Password cannot contain spaces';
    }
    if (v != _newCtrl.text) {
      return l10n?.passwordsDoNotMatch ?? 'Passwords do not match';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final l10n = S.of(context);
    final token = UserSession().token;
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n?.sessionExpired ?? 'Session expired. Please log in again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    final res = await ApiService.changeJobseekerPassword(
      token: token,
      currentPassword: _currentCtrl.text,
      password: _newCtrl.text,
      passwordConfirmation: _confirmCtrl.text,
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (res['success'] == true) {
      _currentCtrl.clear();
      _newCtrl.clear();
      _confirmCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            (res['message'] as String?)?.trim() ?? l10n?.passwordChanged ?? 'Password changed successfully.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
      return;
    }

    final msg = _messageFromApi(res);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _messageFromApi(Map<String, dynamic> res) {
    final raw = res['message'];
    if (raw is String && raw.trim().isNotEmpty) {
      return raw.trim();
    }
    final errors = res['errors'];
    if (errors is Map) {
      for (final key in ['current_password', 'password', 'password_confirmation']) {
        final list = errors[key];
        if (list is List && list.isNotEmpty && list.first is String) {
          return (list.first as String).trim();
        }
      }
    }
    return 'Failed to change password. Please check your current password.';
  }

  Widget _passwordRequirementRow(String label, bool ok,
      {String? helpTooltip}) {
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

  Widget _buildNewPasswordRequirements() {
    final p = _newCtrl.text;
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

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF8FAFC),
        foregroundColor: const Color(0xFF0F172A),
        title: Text(
          l10n?.changePassword ?? 'Change password',
          style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Use a strong password you haven’t used elsewhere.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.4,
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              buildAuthFieldLabel(l10n?.currentPassword ?? 'Current password'),
              TextFormField(
                controller: _currentCtrl,
                obscureText: _obscureCurrent,
                keyboardType: TextInputType.visiblePassword,
                enableSuggestions: false,
                autocorrect: false,
                autofillHints: const [AutofillHints.password],
                inputFormatters: PasswordRules.inputFormattersNoWhitespace,
                decoration: authFieldDecoration(
                  HugeIcons.strokeRoundedLockPassword,
                  hintText: '••••••••',
                  suffix: IconButton(
                    icon: HugeIcon(
                      icon: _obscureCurrent
                          ? HugeIcons.strokeRoundedViewOffSlash
                          : HugeIcons.strokeRoundedView,
                      color: const Color(0xFF64748B),
                      size: 20,
                      strokeWidth: 2.0,
                    ),
                    onPressed: () =>
                        setState(() => _obscureCurrent = !_obscureCurrent),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return l10n?.currentPassword ?? 'Current password';
                  }
                  if (PasswordRules.hasWhitespace(v)) {
                    return 'Password cannot contain spaces';
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              buildAuthFieldLabel(l10n?.newPassword ?? 'New password'),
              TextFormField(
                controller: _newCtrl,
                obscureText: _obscureNew,
                keyboardType: TextInputType.visiblePassword,
                enableSuggestions: false,
                autocorrect: false,
                autofillHints: const [AutofillHints.newPassword],
                inputFormatters: PasswordRules.inputFormattersNoWhitespace,
                decoration: authFieldDecoration(
                  HugeIcons.strokeRoundedLockPassword,
                  hintText: '••••••••',
                  suffix: IconButton(
                    icon: HugeIcon(
                      icon: _obscureNew
                          ? HugeIcons.strokeRoundedViewOffSlash
                          : HugeIcons.strokeRoundedView,
                      color: const Color(0xFF64748B),
                      size: 20,
                      strokeWidth: 2.0,
                    ),
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                ),
                validator: (v) => _validateNew(v),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              _buildNewPasswordRequirements(),
              const SizedBox(height: 16),
              buildAuthFieldLabel(
                  l10n?.confirmNewPassword ?? 'Confirm new password'),
              TextFormField(
                controller: _confirmCtrl,
                obscureText: _obscureConfirm,
                keyboardType: TextInputType.visiblePassword,
                enableSuggestions: false,
                autocorrect: false,
                autofillHints: const [AutofillHints.newPassword],
                inputFormatters: PasswordRules.inputFormattersNoWhitespace,
                decoration: authFieldDecoration(
                  HugeIcons.strokeRoundedLockPassword,
                  hintText: '••••••••',
                  suffix: IconButton(
                    icon: HugeIcon(
                      icon: _obscureConfirm
                          ? HugeIcons.strokeRoundedViewOffSlash
                          : HugeIcons.strokeRoundedView,
                      color: const Color(0xFF64748B),
                      size: 20,
                      strokeWidth: 2.0,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                validator: (v) => _validateConfirm(v),
                onChanged: (_) => setState(() {}),
              ),
              if (_confirmCtrl.text.isNotEmpty &&
                  _confirmCtrl.text != _newCtrl.text)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    l10n?.passwordsDoNotMatch ?? 'Passwords do not match',
                    style: TextStyle(
                      color: Colors.red[700],
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: PressableButton(
                  onTap: _submitting ? null : _submit,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: _submitting
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            l10n?.changePassword ?? 'Change password',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
