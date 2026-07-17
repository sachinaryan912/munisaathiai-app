import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

Color miiColor(int mii) {
  if (mii >= 80) return AppColors.success;
  if (mii >= 60) return AppColors.info;
  if (mii >= 40) return AppColors.warning;
  return AppColors.danger;
}

String miiLabel(int mii) {
  if (mii >= 80) return 'Excellent';
  if (mii >= 60) return 'Needs Support';
  if (mii >= 40) return 'Weak';
  return 'Urgent';
}

class SchoolStatusBadge extends StatelessWidget {
  final int mii;
  const SchoolStatusBadge({super.key, required this.mii});

  @override
  Widget build(BuildContext context) {
    final color = miiColor(mii);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('$mii', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: color)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(99)),
          child: Text(miiLabel(mii), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: color)),
        ),
      ],
    );
  }
}
