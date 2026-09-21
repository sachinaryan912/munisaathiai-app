import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/gradient_button.dart';
import '../data/auth_provider.dart';
import 'auth_scaffold.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _rememberMe = true;
  String? _error;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().login(_username.text.trim(), _password.text, rememberMe: _rememberMe);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('ApiException: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return AuthScaffold(
      title: 'Welcome back',
      subtitle: 'Sign in to continue tracking the Muni Model',
      centered: true,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null)
              _ErrorBanner(message: _error!)
                  .animate()
                  .fadeIn(duration: 250.ms)
                  .shake(duration: 400.ms, hz: 4),
            AppTextField(
              label: 'Username',
              controller: _username,
              hint: 'your_username',
              prefixIcon: HugeIcons.strokeRoundedUser,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your username' : null,
            ).animate(delay: 50.ms).fadeIn(duration: 320.ms),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Password',
              controller: _password,
              hint: 'Enter your password',
              obscure: true,
              prefixIcon: HugeIcons.strokeRoundedLockPassword,
              validator: (v) => (v == null || v.isEmpty) ? 'Enter your password' : null,
            ).animate(delay: 100.ms).fadeIn(duration: 320.ms),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () => setState(() => _rememberMe = !_rememberMe),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: Checkbox(
                            value: _rememberMe,
                            onChanged: (v) => setState(() => _rememberMe = v ?? true),
                            activeColor: AppColors.saffron500,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Remember me',
                          style: TextStyle(
                            color: s.textSecondary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/forgot-password'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Forgot password?', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                ),
              ],
            ).animate(delay: 150.ms).fadeIn(duration: 320.ms),
            const SizedBox(height: 14),
            GradientButton(
              label: 'Sign In',
              loading: _loading,
              onPressed: _submit,
            ).animate(delay: 200.ms).fadeIn(duration: 320.ms),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Don't have an account? ", style: TextStyle(color: s.textSecondary, fontSize: 13)),
                GestureDetector(
                  onTap: () => context.push('/register'),
                  child: const Text('Create one', style: TextStyle(color: AppColors.saffron600, fontSize: 13, fontWeight: FontWeight.w800)),
                ),
              ],
            ).animate(delay: 240.ms).fadeIn(duration: 320.ms),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedAlertCircle,
              size: 17,
              color: Color(0xFFDC2626),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFB91C1C),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
