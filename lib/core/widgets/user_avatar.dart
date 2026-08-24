import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/auth/data/auth_provider.dart';
import '../theme/app_colors.dart';

/// The signed-in user's avatar: their photo if they've set one, otherwise their
/// initials on the role gradient.
///
/// Every place that shows the current user's face goes through this, so uploading a
/// photo updates the settings header and both app bars at once, and there's a single
/// place to get the fallback right.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.size,
    this.fontSize,
    this.border,
    this.boxShadow,
  });

  final double size;
  final double? fontSize;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;

  @override
  Widget build(BuildContext context) {
    // Watches both fields — the bytes arrive after the user does, so listening only
    // to `user` would leave the initials on screen until some other rebuild.
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final image = auth.profileImage;
    final role = user?.role ?? '';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: image == null
            ? LinearGradient(
                colors: AppColors.roleGradient(role),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        border: border,
        boxShadow: boxShadow,
        image: image != null
            ? DecorationImage(image: MemoryImage(image), fit: BoxFit.cover)
            : null,
      ),
      alignment: Alignment.center,
      child: image != null
          ? null
          : Text(
              user?.initials ?? 'U',
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize ?? size * 0.36,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
    );
  }
}
