import 'package:flutter/material.dart';
import '../theme/app_radius.dart';
import 'shimmer_box.dart';

/// A quick shimmering skeleton built from a list of block heights — use when
/// a screen's loading state doesn't need a bespoke layout but should still
/// read as "content incoming" rather than a bare spinner.
class GenericSkeleton extends StatelessWidget {
  final List<double> blockHeights;
  const GenericSkeleton({super.key, this.blockHeights = const [90, 140, 180, 120]});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrap(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          for (final h in blockHeights) ...[
            ShimmerBox(height: h, borderRadius: AppRadius.lgAll),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}
