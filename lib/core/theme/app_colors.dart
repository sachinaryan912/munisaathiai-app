import 'package:flutter/material.dart';

/// Brand palette — mirrors the web frontend's Tailwind `saffron` scale exactly
/// (muni-saathi-ai-frontend/src/index.css) so both apps read as the same product.
class AppColors {
  AppColors._();

  static const saffron50 = Color(0xFFFFF8EE);
  static const saffron100 = Color(0xFFFFEFD4);
  static const saffron200 = Color(0xFFFFD9A0);
  static const saffron300 = Color(0xFFFFBF66);
  static const saffron400 = Color(0xFFFF9933);
  static const saffron500 = Color(0xFFE8651A);
  static const saffron600 = Color(0xFFC04D0A);
  static const saffron700 = Color(0xFF943806);
  static const saffron800 = Color(0xFF6B2704);
  static const saffron900 = Color(0xFF4A1A02);
  static const saffron950 = Color(0xFF2A0D01);

  static const primary = saffron500;

  // Role accent colors — used for role badges, avatars, and per-role gradients.
  static const roleManagement = Color(0xFF7C3AED); // violet-600
  static const roleManagementEnd = Color(0xFF9333EA);
  static const roleTrainer = Color(0xFF3B82F6); // blue-500
  static const roleTrainerEnd = Color(0xFF4F46E5);
  static const rolePrincipal = Color(0xFF6366F1); // indigo-500
  static const rolePrincipalEnd = Color(0xFF3B82F6);
  static const roleTeacher = Color(0xFF10B981); // emerald-500
  static const roleTeacherEnd = Color(0xFF0D9488);
  static const roleStudent = saffron400;
  static const roleStudentEnd = Color(0xFFF97316);
  static const roleParent = Color(0xFFF43F5E); // rose-500
  static const roleParentEnd = Color(0xFFEC4899);

  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);

  /// Alias for [danger] — matches the "error" naming convention used in
  /// design-system briefs while keeping the original name intact everywhere
  /// it's already referenced.
  static const error = danger;

  static const lightBg = Color(0xFFF7F7FA);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightBorder = Color(0xFFEDEDF2);

  static const darkBg = Color(0xFF0B0E14);
  static const darkCard = Color(0xFF151922);
  static const darkBorder = Color(0xFF262B36);

  // ── Extended semantic tokens ────────────────────────────────────────────
  // A neutral graphite "ink" tone for secondary actions/text — deliberately
  // not a second bright hue, so the brand reads as mono-chromatic (saffron)
  // rather than diluted by a competing accent color.
  static const secondary = Color(0xFF44403C);
  static const secondaryLight = Color(0xFF78716C);

  static const primaryContainerLight = saffron50;
  static const primaryContainerDark = Color(0xFF3A2410);

  static const surfaceVariantLight = Color(0xFFF1ECE4);
  static const surfaceVariantDark = Color(0xFF1D222D);

  static const disabledLight = Color(0xFFD1D5DB);
  static const disabledDark = Color(0xFF3F4552);

  static List<Color> roleGradient(String role) {
    switch (role) {
      case 'MANAGEMENT':
        return [roleManagement, roleManagementEnd];
      case 'TRAINER':
        return [roleTrainer, roleTrainerEnd];
      case 'PRINCIPAL':
        return [rolePrincipal, rolePrincipalEnd];
      case 'TEACHER':
        return [roleTeacher, roleTeacherEnd];
      case 'STUDENT':
        return [roleStudent, roleStudentEnd];
      case 'PARENT':
        return [roleParent, roleParentEnd];
      default:
        return [saffron400, saffron600];
    }
  }

  static Color roleColor(String role) => roleGradient(role).first;
}
