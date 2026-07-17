import 'package:flutter/material.dart';
import '../../../core/widgets/shimmer_box.dart';

/// Mirrors the real dashboard's block layout so the loading state reads as
/// "content is arriving" instead of a blank spinner.
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrap(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          ShimmerBox(height: 150, borderRadius: BorderRadius.circular(28)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: ShimmerBox(height: 92, borderRadius: BorderRadius.circular(22))),
              const SizedBox(width: 12),
              Expanded(child: ShimmerBox(height: 92, borderRadius: BorderRadius.circular(22))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: ShimmerBox(height: 92, borderRadius: BorderRadius.circular(22))),
              const SizedBox(width: 12),
              Expanded(child: ShimmerBox(height: 92, borderRadius: BorderRadius.circular(22))),
            ],
          ),
          const SizedBox(height: 22),
          ShimmerBox(width: 140, height: 16),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: ShimmerBox(height: 110, borderRadius: BorderRadius.circular(22))),
              const SizedBox(width: 12),
              Expanded(child: ShimmerBox(height: 110, borderRadius: BorderRadius.circular(22))),
            ],
          ),
          const SizedBox(height: 22),
          ShimmerBox(height: 200, borderRadius: BorderRadius.circular(24)),
        ],
      ),
    );
  }
}
