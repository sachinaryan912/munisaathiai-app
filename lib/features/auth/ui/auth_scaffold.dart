import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

class AuthScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final bool showLogo;

  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.showLogo = true,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return Scaffold(
      backgroundColor: s.bg,
      body: Stack(
        children: [
          Positioned(
            top: -120,
            right: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [AppColors.saffron300.withValues(alpha: 0.28), Colors.transparent]),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showLogo) ...[
                        Container(
                          width: 52,
                          height: 52,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: s.card,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: AppColors.saffron500.withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 6))],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(13),
                            child: Image.asset('assets/images/muni_logo.png', fit: BoxFit.cover),
                          ),
                        ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.85, 0.85)),
                        const SizedBox(height: 22),
                      ],
                      Text(title, style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: s.textPrimary))
                          .animate(delay: 60.ms)
                          .fadeIn(duration: 320.ms)
                          .slideY(begin: 0.15, end: 0),
                      const SizedBox(height: 6),
                      Text(subtitle, style: TextStyle(fontSize: 13.5, color: s.textSecondary, fontWeight: FontWeight.w500))
                          .animate(delay: 100.ms)
                          .fadeIn(duration: 320.ms),
                      const SizedBox(height: 28),
                      child.animate(delay: 140.ms).fadeIn(duration: 360.ms).slideY(begin: 0.08, end: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
