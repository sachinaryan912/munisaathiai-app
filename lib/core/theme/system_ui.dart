import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

/// Keeps the Android status bar and system navigation bar in lockstep with
/// the app's current theme — transparent status bar (so it blends with the
/// translucent app bar) and a navigation bar matching the bottom navigation
/// bar or background.
class SystemUi {
  SystemUi._();

  static void enableEdgeToEdge() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  /// Back to the app's normal chrome: portrait-only with the system bars showing. Called when
  /// a video leaves fullscreen — the only place the app is ever allowed to be landscape.
  static void restorePortrait() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    enableEdgeToEdge();
  }

  static SystemUiOverlayStyle overlayStyle({required bool dark, Color? navigationBarColor}) {
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
      statusBarBrightness: dark ? Brightness.dark : Brightness.light,
      systemStatusBarContrastEnforced: false,
      systemNavigationBarColor: navigationBarColor ?? (dark ? AppColors.darkCard : AppColors.lightCard),
      systemNavigationBarIconBrightness: dark ? Brightness.light : Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    );
  }

  static void apply({required bool dark, Color? navigationBarColor}) {
    SystemChrome.setSystemUIOverlayStyle(overlayStyle(
      dark: dark,
      navigationBarColor: navigationBarColor,
    ));
  }

  static const SystemUiOverlayStyle saffronOverlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemStatusBarContrastEnforced: false,
    systemNavigationBarColor: AppColors.saffron500,
    systemNavigationBarIconBrightness: Brightness.light,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarContrastEnforced: false,
  );

  /// Light icons over the solid saffron splash background — used only while
  /// the native/in-app splash is on screen, before a theme is known.
  static void applyOnSaffron() {
    SystemChrome.setSystemUIOverlayStyle(saffronOverlayStyle);
  }
}
