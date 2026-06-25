import 'package:flutter/material.dart';

/// Shared light/dark palette: white in light becomes black in dark, and vice versa.
abstract final class ThemePalette {
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  static const Color lightScaffold = white;
  static const Color darkScaffold = black;

  static const Color lightCard = white;
  static const Color darkCard = black;

  static const Color lightSurface = Color(0xFFFCFCFC);
  static const Color darkSurface = Color(0xFF030303);

  static const Color lightText = black;
  static const Color darkText = white;

  static const Color lightTextSecondary = Color(0xFF6B6B6B);
  static const Color darkTextSecondary = Color(0xFF949494);

  static const Color lightMutedSurface = Color(0xFFF5F5F5);
  static const Color darkMutedSurface = Color(0xFF0A0A0A);

  static const Color lightBorder = Color(0xFFEFF1F4);
  static const Color darkBorder = Color(0xFF100E0B);

  static const Color lightForegroundOnBrand = Color(0xFFEBEBF0);
  static const Color darkForegroundOnBrand = white;

  /// Inverts RGB channels (keeps alpha). Used for strict light/dark pairing.
  static Color invert(Color color) {
    return Color.fromARGB(
      color.alpha,
      255 - color.red,
      255 - color.green,
      255 - color.blue,
    );
  }

  static Color scaffold(bool isDark) => isDark ? darkScaffold : lightScaffold;

  static Color card(bool isDark) => isDark ? darkCard : lightCard;

  static Color surface(bool isDark) => isDark ? darkSurface : lightSurface;

  static Color text(bool isDark) => isDark ? darkText : lightText;

  static Color textSecondary(bool isDark) => isDark ? darkTextSecondary : lightTextSecondary;

  static Color mutedSurface(bool isDark) => isDark ? darkMutedSurface : lightMutedSurface;

  static Color border(bool isDark) => isDark ? darkBorder : lightBorder;

  static Color foregroundOnBrand(bool isDark) =>
      isDark ? darkForegroundOnBrand : lightForegroundOnBrand;
}
