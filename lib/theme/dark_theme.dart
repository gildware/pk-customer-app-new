import 'package:demandium/theme/custom_theme_colors.dart';
import 'package:flutter/material.dart';

ThemeData dark = ThemeData(
  useMaterial3: false,
  fontFamily: 'Outfit',
  primaryColor: const Color(0xFF25274D),
  primaryColorLight: const Color(0xFFEBEBF0),
  primaryColorDark: const Color(0xff1A1C38),
  secondaryHeaderColor: const Color(0xFF9BB8DA),
  disabledColor: const Color(0xFF8797AB),
  scaffoldBackgroundColor: const Color(0xFF151515),
  brightness: Brightness.dark,
  hintColor: const Color(0xFFC0BFBF),
  focusColor: const Color(0xFF484848),
  hoverColor: const Color(0x4025274D),
  shadowColor: const Color(0x33e2f1ff),
  cardColor: const Color(0xFF1A1C38),
  extensions: <ThemeExtension<CustomThemeColors>>[
    CustomThemeColors.dark(),
  ],

  textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: const Color(0xFFFFFFFF))), colorScheme: const ColorScheme.dark(
  primary: Color(0xFF25274D),
  secondary: Color(0xFFf57d00),
  onSecondary: Color(0xffac8c34),
  onSecondaryContainer: Color(0xFF02AA05),
  tertiary: (Color(0xFFFF6767) ),
  error: (Color(0xFFBC4040) ),
  onPrimary: Color(0xFFF8FAFC),
  ).copyWith(surface: const Color(0xff010D15)),
);