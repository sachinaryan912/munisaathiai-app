import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/otp_input.dart';
import '../../../core/widgets/resend_timer.dart';
import '../data/auth_provider.dart';
import '../data/auth_repository.dart';
import 'auth_scaffold.dart';

String maskEmail(String email) {
  final parts = email.split('@');
  if (parts.length != 2) return email;
  final name = parts[0];
  final domain = parts[1];
  if (name.length <= 3) return '***@$domain';
  final stars = '*' * (name.length - 2).clamp(0, 5);
  return '${name[0]}$stars${name[name.length - 1]}@$domain';
}

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _repo = AuthRepository();
  final _otpKey = GlobalKey<OtpInputState>();
  String _otp = '';
  String? _otpError;
  bool _loading = false;
  bool _success = false;
  String? _sendError;
  bool _sentOnMount = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_sentOnMount) {
      _sentOnMount = true;
      final email = context.read<AuthProvider>().user?.email;
      if (email != null && email.isNotEmpty) {
        _repo.sendVerification(email).catchError((e) {
          if (mounted) setState(() => _sendError = e.toString().replaceFirst('ApiException: ', ''));
          return '';
        });
      }
    }
  }

  Future<void> _verify() async {
    if (_otp.length < 6) {
      setState(() => _otpError = 'Please enter all 6 digits');
      return;
    }
    setState(() {
      _otpError = null;
      _loading = true;
    });
    final email = context.read<AuthProvider>().user?.email ?? '';
    try {
      await _repo.verifyEmail(email: email, otp: _otp);
      if (!mounted) return;
      setState(() => _success = true);
      await Future.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;
      context.read<AuthProvider>().setEmailVerified(true);
    } catch (e) {
      setState(() {
        _otpError = e.toString().replaceFirst('ApiException: ', '');
        _otp = '';
      });
      _otpKey.currentState?.clear();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _sendError = null);
    final email = context.read<AuthProvider>().user?.email ?? '';
    try {
      await _repo.sendVerification(email);
    } catch (e) {
      setState(() => _sendError = e.toString().replaceFirst('ApiException: ', ''));
    }
    _otpKey.currentState?.clear();
  }

  Future<void> _leave() async {
    await context.read<AuthProvider>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final email = context.watch<AuthProvider>().user?.email ?? '';

    if (_success) {
      return Scaffold(
        backgroundColor: s.bg,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(color: Color(0xFFD1FAE5), shape: BoxShape.circle),
                child: const Icon(LucideIcons.checkCheck, color: Color(0xFF059669), size: 38),
              ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 20),
              Text('Email Verified!', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: s.textPrimary)),
              const SizedBox(height: 6),
              Text('Taking you to your dashboard…', style: TextStyle(color: s.textSecondary, fontSize: 13)),
            ],
          ),
        ),
      );
    }

    return AuthScaffold(
      title: 'Verify your email',
      subtitle: '',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: AppColors.saffron50, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.saffron200, width: 2)),
            child: const Icon(LucideIcons.mail, color: AppColors.saffron500, size: 26),
          ),
          const SizedBox(height: 18),
          RichText(
            text: TextSpan(
              style: TextStyle(color: s.textSecondary, fontSize: 13.5, height: 1.5),
              children: [
                const TextSpan(text: "We've sent a 6-digit code to "),
                TextSpan(text: maskEmail(email), style: TextStyle(fontWeight: FontWeight.w800, color: s.textPrimary)),
                const TextSpan(text: '. Enter it below to activate your account.'),
              ],
            ),
          ),
          if (_sendError != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(12)),
              child: Text(_sendError!, style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 12)),
            ),
          ],
          const SizedBox(height: 26),
          OtpInput(key: _otpKey, onChanged: (v) { _otp = v; }, error: _otpError),
          const SizedBox(height: 22),
          GradientButton(label: 'Verify Email', icon: Icons.arrow_forward_rounded, loading: _loading, onPressed: _verify),
          const SizedBox(height: 16),
          ResendTimer(onResend: _resend),
          const SizedBox(height: 8),
          Divider(color: s.border),
          const SizedBox(height: 12),
          Text(
            "Didn't receive the email? Check your spam folder or resend the code.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, color: s.textMuted),
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: _leave,
              child: Text("Not now — I'll verify later", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: s.textMuted)),
            ),
          ),
        ],
      ),
    );
  }
}
