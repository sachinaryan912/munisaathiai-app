import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

class ErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function()? onRetry;

  const ErrorView({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(LucideIcons.triangleAlert, color: AppColors.danger, size: 28),
            ),
            const SizedBox(height: 16),
            Text('Oops! This page could not load', style: AppTypography.headline(s.textPrimary), textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(message, style: AppTypography.body(s.textMuted), textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(LucideIcons.refreshCw, size: 16),
                label: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
