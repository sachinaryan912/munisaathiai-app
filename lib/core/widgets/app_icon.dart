import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// Universal icon renderer that supports both [HugeIcons] (vector path data)
/// and standard Flutter [IconData].
class AppIcon extends StatelessWidget {
  final dynamic icon;
  final Color? color;
  final double? size;

  const AppIcon(
    this.icon, {
    super.key,
    this.color,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final iconColor = color ?? iconTheme.color ?? Colors.black;
    final iconSize = size ?? iconTheme.size ?? 24.0;

    if (icon is List<List<dynamic>>) {
      return HugeIcon(
        icon: icon as List<List<dynamic>>,
        color: iconColor,
        size: iconSize,
      );
    } else if (icon is List) {
      return HugeIcon(
        icon: (icon as List).map((e) => (e as List).cast<dynamic>()).toList(),
        color: iconColor,
        size: iconSize,
      );
    } else if (icon is IconData) {
      return Icon(icon as IconData, color: iconColor, size: iconSize);
    }

    return const SizedBox.shrink();
  }
}
