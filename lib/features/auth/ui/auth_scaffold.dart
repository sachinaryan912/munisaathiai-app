import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/system_ui.dart';

class AuthScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final bool showLogo;
  final bool centered;

  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.showLogo = true,
    this.centered = true,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    SystemUi.apply(
      dark: Theme.of(context).brightness == Brightness.dark,
      navigationBarColor: s.bg,
    );
    return Scaffold(
      backgroundColor: s.bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                      children: [
                        if (showLogo) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              'assets/images/muni_logo.png',
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          )
                          .animate()
                          .fadeIn(duration: 350.ms, curve: Curves.easeOutCubic)
                          .scale(begin: const Offset(0.88, 0.88), curve: Curves.easeOutBack),
                          const SizedBox(height: 20),
                        ],
                        Text(
                          title,
                          textAlign: centered ? TextAlign.center : TextAlign.start,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.4,
                            color: s.textPrimary,
                          ),
                        )
                        .animate(delay: 50.ms)
                        .fadeIn(duration: 300.ms, curve: Curves.easeOutCubic)
                        .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
                        const SizedBox(height: 6),
                        if (subtitle.isNotEmpty) ...[
                          Text(
                            subtitle,
                            textAlign: centered ? TextAlign.center : TextAlign.start,
                            style: TextStyle(
                              fontSize: 13.5,
                              color: s.textSecondary,
                              fontWeight: FontWeight.w500,
                              height: 1.35,
                            ),
                          )
                          .animate(delay: 90.ms)
                          .fadeIn(duration: 300.ms, curve: Curves.easeOutCubic)
                          .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic),
                          const SizedBox(height: 24),
                        ] else
                          const SizedBox(height: 16),
                        child
                            .animate(delay: 130.ms)
                            .fadeIn(duration: 320.ms, curve: Curves.easeOutCubic)
                            .slideY(begin: 0.05, end: 0, curve: Curves.easeOutCubic),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
