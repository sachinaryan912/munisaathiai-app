import 'package:flutter/material.dart';

/// The app's single corner-radius scale. Every card, button, sheet, input,
/// and chip pulls from here instead of repeating ad-hoc numbers (12, 13, 14,
/// 18, 22, 24, 26, 28...) per widget.
class AppRadius {
  AppRadius._();

  static const double sm = 10;
  static const double md = 16;
  static const double lg = 22;
  static const double xl = 28;
  static const double pill = 999;

  static const smAll = BorderRadius.all(Radius.circular(sm));
  static const mdAll = BorderRadius.all(Radius.circular(md));
  static const lgAll = BorderRadius.all(Radius.circular(lg));
  static const xlAll = BorderRadius.all(Radius.circular(xl));
  static const pillAll = BorderRadius.all(Radius.circular(pill));

  static const xlTop = BorderRadius.vertical(top: Radius.circular(xl));
}
