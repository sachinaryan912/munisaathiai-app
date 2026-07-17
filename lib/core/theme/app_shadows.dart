import 'package:flutter/material.dart';

/// Centralized soft-shadow presets — cards should look gently elevated, never
/// harsh. Pass the current brightness so dark surfaces get a deeper shadow
/// than light ones (dark UIs need more contrast to read as "elevated").
class AppShadows {
  AppShadows._();

  static List<BoxShadow> soft(bool dark) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: dark ? 0.28 : 0.045),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> floating(bool dark) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: dark ? 0.4 : 0.08),
          blurRadius: 22,
          offset: const Offset(0, -4),
        ),
      ];

  /// The colored "glow" under primary CTAs — same treatment `GradientButton`
  /// already used, generalized so any primary-colored surface can reuse it.
  static List<BoxShadow> glow(Color color, {double alpha = 0.35}) => [
        BoxShadow(
          color: color.withValues(alpha: alpha),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ];
}
