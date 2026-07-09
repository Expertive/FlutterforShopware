import 'package:flutter/material.dart';

/// Helpers for parsing theme colors and choosing readable foreground colors.
class ColorUtils {
  ColorUtils._();

  static Color hexToColor(String hex) {
    try {
      var value = hex.replaceAll('#', '');
      if (value.length == 6) value = 'FF$value';
      return Color(int.parse(value, radix: 16));
    } catch (e) {
      return Colors.blue;
    }
  }

  static bool isLight(Color color) =>
      ThemeData.estimateBrightnessForColor(color) == Brightness.light;

  /// Text and icon color that contrasts with [background].
  static Color foregroundOn(Color background) =>
      isLight(background) ? Colors.black87 : Colors.white;

  /// Muted text/icon color on [background].
  static Color foregroundOnMuted(Color background) =>
      isLight(background) ? Colors.black54 : Colors.white70;

  /// Divider color on [background].
  static Color dividerOn(Color background) =>
      isLight(background) ? Colors.black26 : Colors.white24;

  /// Accent (e.g. brand color) readable on [surface]; falls back when too
  /// similar (e.g. white primary on white bottom bar).
  static Color accentOnSurface(Color accent, Color surface) {
    if (isLight(accent) == isLight(surface)) {
      return foregroundOn(surface);
    }
    return accent;
  }
}
