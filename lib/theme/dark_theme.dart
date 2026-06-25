import 'package:demandium/theme/app_text_theme.dart';
import 'package:demandium/theme/custom_theme_colors.dart';
import 'package:demandium/theme/theme_palette.dart';
import 'package:flutter/material.dart';

ThemeData dark = ThemeData(
  useMaterial3: false,
  fontFamily: 'Outfit',
  primaryColor: const Color(0xFF25274D),
  primaryColorLight: ThemePalette.darkForegroundOnBrand,
  primaryColorDark: ThemePalette.darkText,
  secondaryHeaderColor: ThemePalette.darkTextSecondary,
  disabledColor: const Color(0xFF8797AB),
  scaffoldBackgroundColor: ThemePalette.darkScaffold,
  brightness: Brightness.dark,
  hintColor: ThemePalette.darkTextSecondary,
  focusColor: ThemePalette.darkMutedSurface,
  hoverColor: ThemePalette.invert(const Color(0xFFF8FAFC)),
  shadowColor: ThemePalette.invert(const Color(0xFFE6E5E5)),
  cardColor: ThemePalette.darkCard,
  dividerColor: ThemePalette.darkBorder,
  canvasColor: ThemePalette.darkScaffold,
  textTheme: AppTextTheme.dark,
  iconTheme: const IconThemeData(color: ThemePalette.darkText),
  listTileTheme: const ListTileThemeData(
    textColor: ThemePalette.darkText,
    iconColor: ThemePalette.darkText,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: ThemePalette.darkCard,
    foregroundColor: ThemePalette.darkText,
    iconTheme: IconThemeData(color: ThemePalette.darkText),
    titleTextStyle: TextStyle(
      fontFamily: 'Outfit',
      fontSize: 20,
      fontWeight: FontWeight.w500,
      color: ThemePalette.darkText,
    ),
  ),
  extensions: <ThemeExtension<CustomThemeColors>>[
    CustomThemeColors.dark(),
  ],
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(foregroundColor: ThemePalette.darkText),
  ),
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF25274D),
    onPrimary: ThemePalette.darkText,
    onSurface: ThemePalette.darkText,
    secondary: Color(0xFFf57d00),
    onSecondary: Color(0xffac8c34),
    onSecondaryContainer: Color(0xFF02AA05),
    tertiary: Color(0xFFFF6767),
    error: Color(0xFFBC4040),
  ).copyWith(surface: ThemePalette.darkSurface),
);
