import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../theme/app_theme.dart';

class ProgressRing extends StatelessWidget {
  final int value;
  final int max;
  final double radius;
  final Color color;
  final String? centerLabel;
  final String subLabel;

  const ProgressRing({
    super.key,
    required this.value,
    this.max = 100,
    this.radius = 46,
    required this.color,
    this.centerLabel,
    this.subLabel = '',
  });

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final pct = max == 0 ? 0.0 : (value / max).clamp(0, 1).toDouble();
    return CircularPercentIndicator(
      radius: radius,
      lineWidth: 9,
      percent: pct,
      animation: true,
      animationDuration: 900,
      circularStrokeCap: CircularStrokeCap.round,
      backgroundColor: s.border,
      progressColor: color,
      center: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(centerLabel ?? '$value', style: TextStyle(fontWeight: FontWeight.w900, fontSize: radius * 0.42, color: s.textPrimary)),
          if (subLabel.isNotEmpty)
            Text(subLabel, style: TextStyle(fontSize: radius * 0.16, color: s.textMuted, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
