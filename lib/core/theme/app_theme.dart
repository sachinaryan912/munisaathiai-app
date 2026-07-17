import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    final textTheme = GoogleFonts.interTextTheme(base.textTheme);

    return base.copyWith(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBg,
      textTheme: textTheme,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.saffron500,
        brightness: Brightness.light,
        primary: AppColors.saffron500,
        secondary: AppColors.saffron400,
        surface: AppColors.lightCard,
        error: AppColors.danger,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightBg.withValues(alpha: 0.85),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: const Color(0xFF0F172A),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF0F172A),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF64748B)),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.lightBorder, thickness: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF2F2F6),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.saffron400, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.4),
        ),
        hintStyle: GoogleFonts.inter(color: const Color(0xFF9CA3AF), fontSize: 14.5),
        labelStyle: GoogleFonts.inter(color: const Color(0xFF6B7280), fontSize: 13.5, fontWeight: FontWeight.w600),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.saffron500,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.saffron600,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
      ),
      splashFactory: InkSparkle.splashFactory,
      extensions: const [MuniSurface(bg: AppColors.lightBg, card: AppColors.lightCard, border: AppColors.lightBorder, textPrimary: Color(0xFF0F172A), textSecondary: Color(0xFF64748B), textMuted: Color(0xFF9CA3AF))],
    );
  }

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = GoogleFonts.interTextTheme(base.textTheme);

    return base.copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBg,
      textTheme: textTheme.apply(bodyColor: const Color(0xFFE5E7EB), displayColor: const Color(0xFFE5E7EB)),
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.saffron500,
        brightness: Brightness.dark,
        primary: AppColors.saffron400,
        secondary: AppColors.saffron300,
        surface: AppColors.darkCard,
        error: AppColors.danger,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBg.withValues(alpha: 0.9),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: const Color(0xFFF1F5F9),
        titleTextStyle: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800, color: const Color(0xFFF1F5F9)),
        iconTheme: const IconThemeData(color: Color(0xFF94A3B8)),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.darkBorder, thickness: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1B202B),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.saffron400, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.4),
        ),
        hintStyle: GoogleFonts.inter(color: const Color(0xFF6B7280), fontSize: 14.5),
        labelStyle: GoogleFonts.inter(color: const Color(0xFF9CA3AF), fontSize: 13.5, fontWeight: FontWeight.w600),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.saffron500,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.saffron300,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
      ),
      splashFactory: InkSparkle.splashFactory,
      extensions: const [MuniSurface(bg: AppColors.darkBg, card: AppColors.darkCard, border: AppColors.darkBorder, textPrimary: Color(0xFFF1F5F9), textSecondary: Color(0xFF94A3B8), textMuted: Color(0xFF64748B))],
    );
  }
}

/// Extra semantic surface colors not modeled by [ColorScheme], read via
/// `Theme.of(context).extension<MuniSurface>()!` from anywhere in the tree.
@immutable
class MuniSurface extends ThemeExtension<MuniSurface> {
  final Color bg;
  final Color card;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  const MuniSurface({
    required this.bg,
    required this.card,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
  });

  @override
  MuniSurface copyWith({Color? bg, Color? card, Color? border, Color? textPrimary, Color? textSecondary, Color? textMuted}) {
    return MuniSurface(
      bg: bg ?? this.bg,
      card: card ?? this.card,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
    );
  }

  @override
  MuniSurface lerp(ThemeExtension<MuniSurface>? other, double t) {
    if (other is! MuniSurface) return this;
    return MuniSurface(
      bg: Color.lerp(bg, other.bg, t)!,
      card: Color.lerp(card, other.card, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
    );
  }
}

extension BuildContextTheme on BuildContext {
  MuniSurface get surface => Theme.of(this).extension<MuniSurface>()!;
}
