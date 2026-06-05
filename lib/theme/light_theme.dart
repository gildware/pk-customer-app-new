import 'package:demandium/theme/custom_theme_colors.dart';
import 'package:flutter/material.dart';

ThemeData light = ThemeData(
  useMaterial3: false,
  fontFamily: 'Outfit',
  primaryColor: const Color(0xFF25274D),
  primaryColorLight: const Color(0xFFEBEBF0),
  primaryColorDark: const Color(0xff1A1C38),
  secondaryHeaderColor: const Color(0xFF758493),

  disabledColor: const Color(0xFF8797AB),
  scaffoldBackgroundColor: const Color(0xFFFFFFFF),
  brightness: Brightness.light,
  hintColor: const Color(0xFFA4A4A4),
  focusColor: const Color(0xFFFFF9E5),
  hoverColor: const Color(0xFFF8FAFC),
  shadowColor:  const Color(0xFFE6E5E5),
  cardColor: Colors.white,
  textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: const Color(
      0xFF25274D))),
  extensions: <ThemeExtension<CustomThemeColors>>[
    CustomThemeColors.light(),
  ],

  colorScheme: const ColorScheme.light(
    primary: Color(0xFF25274D),
    secondary: Color(0xFFFF9900),
    onSecondary: Color(0xFFffda6d),
    tertiary: Color(0xFFd35221),
    onSecondaryContainer: Color(0xFF02AA05),
    error: Color(0xFFf76767),
    onPrimary: Color(0xFFF8FAFC)
  ).copyWith(surface: const Color(0xffFCFCFC)),
);