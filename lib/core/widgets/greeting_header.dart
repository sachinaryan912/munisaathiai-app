import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../features/auth/data/auth_provider.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

/// A personalized "Good morning, Amanda 👋" header used at the top of a
/// dashboard's scrollable body, replacing a plain "My Dashboard" app-bar
/// title with something warmer — the app bar itself still carries the
/// theme toggle / notifications / avatar via [AppShell].
class GreetingHeader extends StatelessWidget {
  final String? subtitle;
  const GreetingHeader({super.key, this.subtitle});

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final fullName = context.watch<AuthProvider>().user?.fullName.trim() ?? '';
    final parts = fullName.split(RegExp(r'\s+'));
    final firstName = parts.isNotEmpty && parts.first.isNotEmpty ? parts.first : 'there';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$_greeting, $firstName 👋', style: AppTypography.display(s.textPrimary).copyWith(fontSize: 22)),
        const SizedBox(height: 4),
        Text(subtitle ?? DateFormat('EEEE, d MMMM').format(DateTime.now()), style: AppTypography.body(s.textMuted)),
      ],
    ).animate().fadeIn(duration: 320.ms).slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic);
  }
}
