import 'package:flutter/material.dart';

/// Centralized soft-shadow presets refined for a premium iOS aesthetic:
/// subtle, ambient, never harsh or muddy.
class AppShadows {
  AppShadows._();

  static List<BoxShadow> soft(bool dark) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: dark ? 0.2 : 0.025),
          blurRadius: 10,
          offset: const Offset(0, 1.5),
        ),
      ];

  static List<BoxShadow> floating(bool dark) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: dark ? 0.25 : 0.04),
          blurRadius: 16,
          offset: const Offset(0, -2),
        ),
      ];

  /// The colored "glow" under primary CTAs — subtle and refined.
  static List<BoxShadow> glow(Color color, {double alpha = 0.25}) => [
        BoxShadow(
          color: color.withValues(alpha: alpha),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
}
