import 'dart:async';

import 'package:flutter/material.dart';

import 'api_service.dart';
import 'main.dart';
import 'user_session.dart';

enum _ChangeEmailStep { enterEmail, verifyOtp }

class ChangeEmailPage extends StatefulWidget {
  const ChangeEmailPage({super.key});

  @override
  State<ChangeEmailPage> createState() => _ChangeEmailPageState();
}

class _ChangeEmailPageState extends State<ChangeEmailPage> {
  final _emailFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();
  final _newEmailController = TextEditingController();
  final _otpController = TextEditingController();
  Timer? _cooldownTimer;

  _ChangeEmailStep _step = _ChangeEmailStep.enterEmail;
  bool _isSendingOtp = false;
  bool _isResendingOtp = false;
  bool _isVerifyingOtp = false;
  int _resendCooldown = 0;
  String? _pendingEmail;

  String get _currentEmail => (UserSession().email ?? '').trim();

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _newEmailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_emailFormKey.currentState!.validate()) return;
    final email = _newEmailController.text.trim().toLowerCase();
    setState(() => _isSendingOtp = true);

    try {
      final token = UserSession().token ?? '';
      if (token.isEmpty) {
        _showToast('Session expired. Please log in again.', isError: true);
        return;
      }
      final sendRes = await ApiService.requestJobseekerEmailChangeOtp(
        token: token,
        newEmail: email,
      );
      if (!mounted) return;

      if (sendRes['success'] == true) {
        final cooldown = (sendRes['cooldown_seconds'] as num?)?.toInt() ?? 60;
        _startResendCooldown(Duration(seconds: cooldown));
        setState(() {
          _pendingEmail = email;
          _step = _ChangeEmailStep.verifyOtp;
        });
        _showToast('OTP sent to $email');
      } else {
        final retryAfter = (sendRes['retry_after_seconds'] as num?)?.toInt();
        if (retryAfter != null && retryAfter > 0) {
          _startResendCooldown(Duration(seconds: retryAfter));
        }
        _showToast(_friendlyOtpMessage(sendRes), isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSendingOtp = false);
    }
  }

  Future<void> _resendOtp() async {
    if (_pendingEmail == null || _resendCooldown > 0) return;
    setState(() => _isResendingOtp = true);
    try {
      final token = UserSession().token ?? '';
      if (token.isEmpty) {
        _showToast('Session expired. Please log in again.', isError: true);
        return;
      }
      final res = await ApiService.requestJobseekerEmailChangeOtp(
        token: token,
        newEmail: _pendingEmail!,
      );
      if (!mounted) return;
      if (res['success'] == true) {
        final cooldown = (res['cooldown_seconds'] as num?)?.toInt() ?? 60;
        _startResendCooldown(Duration(seconds: cooldown));
        _showToast('New OTP sent to $_pendingEmail');
      } else {
        final retryAfter = (res['retry_after_seconds'] as num?)?.toInt();
        if (retryAfter != null && retryAfter > 0) {
          _startResendCooldown(Duration(seconds: retryAfter));
        }
        _showToast(_friendlyOtpMessage(res), isError: true);
      }
    } finally {
      if (mounted) setState(() => _isResendingOtp = false);
    }
  }

  Future<void> _verifyOtpAndChangeEmail() async {
    if (_pendingEmail == null) return;
    if (!_otpFormKey.currentState!.validate()) return;
    final token = UserSession().token ?? '';
    if (token.isEmpty) {
      _showToast('Session expired. Please log in again.', isError: true);
      return;
    }

    setState(() => _isVerifyingOtp = true);
    try {
      final verifyRes = await ApiService.confirmJobseekerEmailChangeOtp(
        token: token,
        newEmail: _pendingEmail!,
        otpCode: _otpController.text.trim(),
      );
      if (!mounted) return;
      if (verifyRes['success'] != true) {
        _showToast(_friendlyOtpMessage(verifyRes), isError: true);
        return;
      }

      final updatedUser = verifyRes['data'] as Map<String, dynamic>?;
      if (updatedUser != null) {
        UserSession().updateFromUser(updatedUser);
      } else {
        final userRes = await ApiService.getUser(token);
        if (!mounted) return;
        if (userRes['success'] == true && userRes['data'] is Map<String, dynamic>) {
          UserSession().updateFromUser(userRes['data'] as Map<String, dynamic>);
        }
      }
      if (!mounted) return;
      if (verifyRes['success'] == true) {
        if (updatedUser != null) {
          // keep local input in sync in case this page is reused.
          _newEmailController.text = (updatedUser['email'] ?? _pendingEmail).toString();
        }
        _showToast('Email updated successfully.');
        Navigator.of(context).pop(true);
      }
    } finally {
      if (mounted) setState(() => _isVerifyingOtp = false);
    }
  }

  void _startResendCooldown(Duration duration) {
    _cooldownTimer?.cancel();
    setState(() => _resendCooldown = duration.inSeconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCooldown <= 1) {
        timer.cancel();
        setState(() => _resendCooldown = 0);
      } else {
        setState(() => _resendCooldown--);
      }
    });
  }

  void _showToast(String message, {bool isError = false}) {
    if (!mounted) return;
    CustomToast.show(
      context,
      message: message,
      type: isError ? ToastType.error : ToastType.success,
    );
  }

  String _friendlyOtpMessage(Map<String, dynamic> res) {
    final raw = (res['message'] as String?)?.trim();
    final message = (raw ?? '').toLowerCase();
    if (message.contains('daily otp limit reached') || message.contains('7/day')) {
      return 'You have reached today\'s OTP limit (7/day). Try again tomorrow.';
    }
    if (message.contains('invalid otp')) {
      return 'Invalid OTP. Please check and try again.';
    }
    if (message.contains('expired')) {
      return 'OTP expired. Request a new one and try again.';
    }
    return raw?.isNotEmpty == true ? raw! : 'Something went wrong. Please try again.';
  }

  String? _validateEmail(String? value) {
    final email = (value ?? '').trim().toLowerCase();
    if (email.isEmpty) return 'Please enter your new email';
    final looksLikeEmail = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!looksLikeEmail.hasMatch(email)) return 'Please enter a valid email address';
    if (email == _currentEmail.toLowerCase()) {
      return 'New email must be different from your current email';
    }
    return null;
  }

  String? _validateOtp(String? value) {
    final otp = (value ?? '').trim();
    if (otp.isEmpty) return 'Please enter the OTP code';
    if (!RegExp(r'^\d{6}$').hasMatch(otp)) return 'OTP must be a 6-digit code';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF1F5F9),
        foregroundColor: const Color(0xFF1E3A8A),
        title: const Text(
          'Change Email',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: ListView(
          children: [
            _buildCurrentEmailCard(),
            const SizedBox(height: 12),
            _step == _ChangeEmailStep.enterEmail
                ? _buildEnterEmailCard()
                : _buildOtpVerificationCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentEmailCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current email',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1D4ED8),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _currentEmail.isEmpty ? 'No email found' : _currentEmail,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnterEmailCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Form(
        key: _emailFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Step 1: Enter new email',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'We will send an OTP to your new email address.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF1D4ED8),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _newEmailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'New email',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFBFDBFE)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF2563EB), width: 2),
                ),
              ),
              validator: _validateEmail,
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSendingOtp ? null : _sendOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isSendingOtp
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Send OTP'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtpVerificationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Form(
        key: _otpFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Step 2: Verify OTP',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter the 6-digit code sent to $_pendingEmail',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF1D4ED8),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'OTP code',
                prefixIcon: Icon(Icons.verified_user_outlined),
                border: OutlineInputBorder(),
                counterText: '',
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFBFDBFE)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF2563EB), width: 2),
                ),
              ),
              validator: _validateOtp,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: (_isResendingOtp || _resendCooldown > 0) ? null : _resendOtp,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1D4ED8),
                      side: const BorderSide(color: Color(0xFF93C5FD)),
                    ),
                    child: _isResendingOtp
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _resendCooldown > 0
                                ? 'Resend in ${_resendCooldown}s'
                                : 'Resend OTP',
                          ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isVerifyingOtp ? null : _verifyOtpAndChangeEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                    ),
                    child: _isVerifyingOtp
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child:
                                CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Verify and Update'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                setState(() {
                  _step = _ChangeEmailStep.enterEmail;
                  _otpController.clear();
                  _pendingEmail = null;
                });
              },
              child: const Text(
                'Use a different email',
                style: TextStyle(color: Color(0xFF1D4ED8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
