import 'package:demandium/theme/custom_theme_colors.dart';
import 'package:demandium/theme/app_text_theme.dart';
import 'package:demandium/theme/theme_palette.dart';
import 'package:flutter/material.dart';

ThemeData light = ThemeData(
  useMaterial3: false,
  fontFamily: 'Outfit',
  primaryColor: const Color(0xFF25274D),
  primaryColorLight: ThemePalette.lightForegroundOnBrand,
  primaryColorDark: const Color(0xff1A1C38),
  secondaryHeaderColor: const Color(0xFF758493),
  disabledColor: const Color(0xFF8797AB),
  scaffoldBackgroundColor: ThemePalette.lightScaffold,
  brightness: Brightness.light,
  hintColor: const Color(0xFFA4A4A4),
  focusColor: const Color(0xFFFFF9E5),
  hoverColor: const Color(0xFFF8FAFC),
  shadowColor: const Color(0xFFE6E5E5),
  cardColor: ThemePalette.lightCard,
  dividerColor: ThemePalette.lightBorder,
  canvasColor: ThemePalette.lightScaffold,
  textTheme: AppTextTheme.light,
  iconTheme: const IconThemeData(color: ThemePalette.lightText),
  listTileTheme: const ListTileThemeData(
    textColor: ThemePalette.lightText,
    iconColor: ThemePalette.lightText,
  ),
  appBarTheme: const AppBarTheme(
    foregroundColor: ThemePalette.lightForegroundOnBrand,
    iconTheme: IconThemeData(color: ThemePalette.lightForegroundOnBrand),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(foregroundColor: const Color(0xFF25274D)),
  ),
  extensions: <ThemeExtension<CustomThemeColors>>[
    CustomThemeColors.light(),
  ],
  colorScheme: const ColorScheme.light(
    primary: Color(0xFF25274D),
    onPrimary: ThemePalette.lightForegroundOnBrand,
    onSurface: ThemePalette.lightText,
    secondary: Color(0xFFFF9900),
    onSecondary: Color(0xFFffda6d),
    tertiary: Color(0xFFd35221),
    onSecondaryContainer: Color(0xFF02AA05),
    error: Color(0xFFf76767),
  ).copyWith(surface: ThemePalette.lightSurface),
);