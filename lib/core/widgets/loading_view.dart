import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

class LoadingView extends StatelessWidget {
  final String? message;
  const LoadingView({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final s = context.surface;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 34,
            height: 34,
            child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation(color)),
          ),
          const SizedBox(height: 14),
          Text(message ?? 'Loading...', style: AppTypography.body(s.textMuted).copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
