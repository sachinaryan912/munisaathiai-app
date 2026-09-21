import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/system_ui.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/otp_input.dart';
import '../../../core/widgets/resend_timer.dart';
import '../data/auth_repository.dart';
import 'auth_scaffold.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _repo = AuthRepository();
  int _step = 0;
  String _username = '';
  String _otp = '';
  String? _otpError;
  String? _serverError;
  bool _loading = false;
  bool _success = false;

  final _usernameField = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _usernameFormKey = GlobalKey<FormState>();
  final _passFormKey = GlobalKey<FormState>();
  final _otpKey = GlobalKey<OtpInputState>();

  Future<void> _sendOtp() async {
    if (!_usernameFormKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _serverError = null;
    });
    try {
      await _repo.forgotPassword(_usernameField.text.trim());
      setState(() {
        _username = _usernameField.text.trim();
        _step = 1;
      });
    } catch (e) {
      setState(
        () => _serverError = e.toString().replaceFirst('ApiException: ', ''),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _verifyOtpStep() {
    if (_otp.length < 6) {
      setState(() => _otpError = 'Enter all 6 digits');
      return;
    }
    setState(() {
      _otpError = null;
      _step = 2;
    });
  }

  Future<void> _resend() async {
    setState(() => _serverError = null);
    try {
      await _repo.forgotPassword(_username);
    } catch (e) {
      setState(
        () => _serverError = e.toString().replaceFirst('ApiException: ', ''),
      );
    }
    _otpKey.currentState?.clear();
  }

  Future<void> _resetPassword() async {
    if (!_passFormKey.currentState!.validate()) return;
    if (_newPassword.text != _confirmPassword.text) {
      setState(() => _serverError = "Passwords don't match");
      return;
    }
    setState(() {
      _loading = true;
      _serverError = null;
    });
    try {
      await _repo.resetPassword(
        username: _username,
        otp: _otp,
        newPassword: _newPassword.text,
      );
      setState(() => _success = true);
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) context.go('/login');
    } catch (e) {
      setState(() {
        _otp = '';
        _step = 1;
        _otpError = e.toString().replaceFirst('ApiException: ', '');
      });
      _otpKey.currentState?.clear();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.surface;

    if (_success) {
      SystemUi.apply(
        dark: Theme.of(context).brightness == Brightness.dark,
        navigationBarColor: s.bg,
      );
      return Scaffold(
        backgroundColor: s.bg,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Color(0xFFD1FAE5),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedCheckmarkBadge01,
                    color: Color(0xFF059669),
                    size: 38,
                  ),
                ),
              ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 20),
              Text(
                'Password Reset!',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  color: s.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Redirecting you to login…',
                style: TextStyle(color: s.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return AuthScaffold(
      title: _step == 0
          ? 'Forgot password?'
          : _step == 1
          ? 'Enter OTP'
          : 'Set new password',
      subtitle: _step == 0
          ? "Enter your username and we'll send you a 6-digit OTP."
          : _step == 1
          ? ''
          : 'Choose a strong password for your account.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StepIndicator(step: _step),
          const SizedBox(height: 22),
          if (_serverError != null)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                _serverError!,
                style: const TextStyle(
                  color: Color(0xFFB91C1C),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (_step == 0)
            Form(
              key: _usernameFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    label: 'Username',
                    controller: _usernameField,
                    hint: 'your_username',
                    prefixIcon: HugeIcons.strokeRoundedUser,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Enter your username'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  GradientButton(
                    label: 'Send OTP',
                    icon: HugeIcons.strokeRoundedArrowRight01,
                    loading: _loading,
                    onPressed: _sendOtp,
                  ),
                ],
              ),
            ),
          if (_step == 1) ...[
            RichText(
              text: TextSpan(
                style: TextStyle(color: s.textSecondary, fontSize: 13.5),
                children: [
                  const TextSpan(text: 'A 6-digit code was sent to the email registered for '),
                  TextSpan(
                    text: _username,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: s.textPrimary,
                    ),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            OtpInput(
              key: _otpKey,
              onChanged: (v) => _otp = v,
              error: _otpError,
            ),
            const SizedBox(height: 20),
            GradientButton(
              label: 'Verify OTP',
              icon: HugeIcons.strokeRoundedArrowRight01,
              onPressed: _verifyOtpStep,
            ),
            const SizedBox(height: 12),
            ResendTimer(onResend: _resend),
            const SizedBox(height: 6),
            TextButton.icon(
              onPressed: () => setState(() => _step = 0),
              icon: const HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01, size: 16, color: AppColors.saffron600),
              label: const Text('Back'),
            ),
          ],
          if (_step == 2)
            Form(
              key: _passFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    label: 'New password',
                    controller: _newPassword,
                    hint: 'At least 6 characters',
                    obscure: true,
                    prefixIcon: HugeIcons.strokeRoundedLockPassword,
                    validator: (v) => (v == null || v.length < 6)
                        ? 'At least 6 characters'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Confirm password',
                    controller: _confirmPassword,
                    hint: 'Re-enter your password',
                    obscure: true,
                    prefixIcon: HugeIcons.strokeRoundedLockPassword,
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Re-enter your password'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  GradientButton(
                    label: 'Reset Password',
                    icon: HugeIcons.strokeRoundedArrowRight01,
                    loading: _loading,
                    onPressed: _resetPassword,
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          Center(
            child: GestureDetector(
              onTap: () => context.pop(),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(color: s.textSecondary, fontSize: 13),
                  children: const [
                    TextSpan(text: 'Remembered it? '),
                    TextSpan(
                      text: 'Back to Sign In',
                      style: TextStyle(
                        color: AppColors.saffron600,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int step;
  const _StepIndicator({required this.step});

  static const _labels = ['Username', 'Verify OTP', 'New Password'];

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return Row(
      children: List.generate(_labels.length, (i) {
        final done = i < step;
        final active = i == step;
        return Expanded(
          child: Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done || active ? AppColors.saffron500 : Colors.transparent,
                      border: Border.all(
                        color: done || active ? AppColors.saffron500 : s.border,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: done
                          ? const HugeIcon(
                              icon: HugeIcons.strokeRoundedTick01,
                              size: 14,
                              color: Colors.white,
                            )
                          : Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: active ? Colors.white : s.textMuted,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _labels[i],
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: active ? AppColors.saffron600 : s.textMuted,
                    ),
                  ),
                ],
              ),
              if (i < _labels.length - 1)
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(
                      bottom: 16,
                      left: 4,
                      right: 4,
                    ),
                    height: 2,
                    color: done ? AppColors.saffron400 : s.border,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}
