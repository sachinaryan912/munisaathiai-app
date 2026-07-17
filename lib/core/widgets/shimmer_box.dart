import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_radius.dart';
import '../theme/app_theme.dart';

/// A single shimmering placeholder block — compose several into a skeleton
/// that mirrors a screen's real layout, so the loading state reads as "this
/// page is arriving" rather than a blank spinner.
class ShimmerBox extends StatelessWidget {
  final double? width;
  final double height;
  final BorderRadius borderRadius;

  const ShimmerBox({super.key, this.width, this.height = 16, this.borderRadius = AppRadius.smAll});

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: s.card, borderRadius: borderRadius),
    );
  }
}

/// Wraps [child] in a shimmer sweep — base/highlight colors adapt to theme.
class ShimmerWrap extends StatelessWidget {
  final Widget child;
  const ShimmerWrap({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: dark ? const Color(0xFF1E2430) : const Color(0xFFE9EAEE),
      highlightColor: dark ? const Color(0xFF2A3140) : const Color(0xFFF6F7F9),
      period: const Duration(milliseconds: 1300),
      child: child,
    );
  }
}
