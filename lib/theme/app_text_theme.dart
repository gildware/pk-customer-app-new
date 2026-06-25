import 'package:flutter/material.dart';
import 'package:demandium/theme/theme_palette.dart';

abstract final class AppTextTheme {
  static TextTheme get light {
    const base = TextStyle(
      fontFamily: 'Outfit',
      color: ThemePalette.lightText,
    );

    return TextTheme(
      displayLarge: base.copyWith(fontSize: 57, fontWeight: FontWeight.w400),
      displayMedium: base.copyWith(fontSize: 45, fontWeight: FontWeight.w400),
      displaySmall: base.copyWith(fontSize: 36, fontWeight: FontWeight.w400),
      headlineLarge: base.copyWith(fontSize: 32, fontWeight: FontWeight.w600),
      headlineMedium: base.copyWith(fontSize: 28, fontWeight: FontWeight.w600),
      headlineSmall: base.copyWith(fontSize: 24, fontWeight: FontWeight.w600),
      titleLarge: base.copyWith(fontSize: 22, fontWeight: FontWeight.w500),
      titleMedium: base.copyWith(fontSize: 16, fontWeight: FontWeight.w500),
      titleSmall: base.copyWith(fontSize: 14, fontWeight: FontWeight.w500),
      bodyLarge: base.copyWith(fontSize: 16, fontWeight: FontWeight.w400),
      bodyMedium: base.copyWith(fontSize: 14, fontWeight: FontWeight.w400),
      bodySmall: base.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: ThemePalette.lightTextSecondary,
      ),
      labelLarge: base.copyWith(fontSize: 14, fontWeight: FontWeight.w500),
      labelMedium: base.copyWith(fontSize: 12, fontWeight: FontWeight.w500),
      labelSmall: base.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: ThemePalette.lightTextSecondary,
      ),
    );
  }

  static TextTheme get dark {
    const base = TextStyle(
      fontFamily: 'Outfit',
      color: ThemePalette.darkText,
    );

    return TextTheme(
      displayLarge: base.copyWith(fontSize: 57, fontWeight: FontWeight.w400),
      displayMedium: base.copyWith(fontSize: 45, fontWeight: FontWeight.w400),
      displaySmall: base.copyWith(fontSize: 36, fontWeight: FontWeight.w400),
      headlineLarge: base.copyWith(fontSize: 32, fontWeight: FontWeight.w600),
      headlineMedium: base.copyWith(fontSize: 28, fontWeight: FontWeight.w600),
      headlineSmall: base.copyWith(fontSize: 24, fontWeight: FontWeight.w600),
      titleLarge: base.copyWith(fontSize: 22, fontWeight: FontWeight.w500),
      titleMedium: base.copyWith(fontSize: 16, fontWeight: FontWeight.w500),
      titleSmall: base.copyWith(fontSize: 14, fontWeight: FontWeight.w500),
      bodyLarge: base.copyWith(fontSize: 16, fontWeight: FontWeight.w400),
      bodyMedium: base.copyWith(fontSize: 14, fontWeight: FontWeight.w400),
      bodySmall: base.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: ThemePalette.darkTextSecondary,
      ),
      labelLarge: base.copyWith(fontSize: 14, fontWeight: FontWeight.w500),
      labelMedium: base.copyWith(fontSize: 12, fontWeight: FontWeight.w500),
      labelSmall: base.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: ThemePalette.darkTextSecondary,
      ),
    );
  }
}
