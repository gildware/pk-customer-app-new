import 'package:flutter/material.dart';

/// Time picker colors with readable hour/minute and dial labels.
class AppTimePickerTheme {
  static const Color _primary = Color(0xFF25274D);
  static const Color _accent = Color(0xFFF58F2A);

  static TimePickerThemeData forBrightness(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return const TimePickerThemeData(
        backgroundColor: Color(0xff0c131e),
        hourMinuteColor: Color(0xFF3D4268),
        hourMinuteTextColor: Colors.white,
        dayPeriodColor: _accent,
        dayPeriodTextColor: Colors.white,
        dialHandColor: _accent,
        dialBackgroundColor: Color(0xFF1A1F35),
        entryModeIconColor: Colors.white,
      );
    }

    return const TimePickerThemeData(
      backgroundColor: Colors.white,
      hourMinuteColor: Color(0xFFEBEBF0),
      hourMinuteTextColor: _primary,
      dayPeriodColor: _accent,
      dayPeriodTextColor: _primary,
      dialHandColor: _primary,
      dialBackgroundColor: Color(0xFFF0F2F8),
      entryModeIconColor: _primary,
    );
  }

  static ColorScheme colorSchemeFor(Brightness brightness, ColorScheme base) {
    if (brightness == Brightness.dark) {
      return base.copyWith(
        primary: _primary,
        onPrimary: Colors.white,
        onSurface: Colors.white,
        surface: const Color(0xff0c131e),
      );
    }
    return base.copyWith(
      primary: _primary,
      onPrimary: Colors.white,
      onSurface: _primary,
      surface: Colors.white,
    );
  }
}
