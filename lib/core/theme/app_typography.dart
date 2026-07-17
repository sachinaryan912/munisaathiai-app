import 'package:flutter/material.dart';

/// The app's type scale — five sizes/weights cover the vast majority of text
/// across every screen, replacing hand-written `TextStyle(fontSize: ..,
/// fontWeight: .., color: ..)` literals scattered per screen with one shared
/// source of truth. Callers pass the color explicitly (usually a
/// `context.surface` token) since text color varies with theme/emphasis.
class AppTypography {
  AppTypography._();

  static TextStyle display(Color color) =>
      TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: color, height: 1.15);

  static TextStyle title(Color color) =>
      TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color, height: 1.25);

  static TextStyle headline(Color color) =>
      TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color, height: 1.3);

  static TextStyle body(Color color) =>
      TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: color, height: 1.5);

  static TextStyle caption(Color color) =>
      TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: color, height: 1.3);
}
