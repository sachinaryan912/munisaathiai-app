import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

const _statusColors = {
  'EXCELLENT': AppColors.success,
  'NEEDS_SUPPORT': AppColors.info,
  'WEAK': AppColors.warning,
  'URGENT': AppColors.danger,
};

const _statusLabels = {
  'EXCELLENT': 'Excellent',
  'NEEDS_SUPPORT': 'Needs Support',
  'WEAK': 'Weak',
  'URGENT': 'Urgent',
};

Color statusColor(String? status) => _statusColors[status] ?? AppColors.info;
String statusLabel(String? status) => _statusLabels[status] ?? (status ?? '');

class SchoolStatusBadge extends StatelessWidget {
  final int mii;
  final String? status;
  const SchoolStatusBadge({super.key, required this.mii, this.status});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('$mii', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: color)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(99)),
          child: Text(statusLabel(status), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: color)),
        ),
      ],
    );
  }
}
