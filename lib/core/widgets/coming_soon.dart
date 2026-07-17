import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_theme.dart';

class ComingSoon extends StatelessWidget {
  final String label;
  const ComingSoon({super.key, this.label = 'This screen'});

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.hammer, size: 34, color: s.textMuted),
          const SizedBox(height: 12),
          Text('$label is being built', style: TextStyle(fontWeight: FontWeight.w800, color: s.textPrimary)),
        ],
      ),
    );
  }
}
