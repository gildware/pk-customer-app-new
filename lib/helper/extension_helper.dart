import 'package:demandium/util/core_export.dart';
import 'package:demandium/theme/theme_palette.dart';
import 'package:get/get.dart';

extension ContextInfo on BuildContext {
  ThemeData get theme => Theme.of(this);
  CustomThemeColors get customThemeColors => theme.extension<CustomThemeColors>()!;

  /// White surfaces in light, black surfaces in dark.
  Color get adaptiveWhite => ThemePalette.scaffold(Get.isDarkMode);

  /// Black text in light, white text in dark.
  Color get adaptiveBlack => ThemePalette.text(Get.isDarkMode);

  /// Accent for icons, links, and labels on surface backgrounds.
  Color get adaptivePrimaryColor => Get.isDarkMode
      ? ThemePalette.darkText
      : theme.primaryColor;

  /// Body text on surface backgrounds.
  Color get onSurfaceText => ThemePalette.text(Get.isDarkMode);

  /// Selected tab/chip label on surface backgrounds.
  Color get tabSelectedColor => Get.isDarkMode
      ? ThemePalette.white
      : theme.primaryColor;

  /// Selected tab indicator on surface backgrounds.
  Color get tabIndicatorColor => tabSelectedColor;

  /// Unselected tab label on surface backgrounds.
  Color get tabUnselectedColor =>
      theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.5) ??
      theme.hintColor;

  /// Inverts hardcoded black/white (and close grays) when in dark mode.
  Color invertBw(Color color) {
    if (!Get.isDarkMode) return color;
    final rgb = color.toARGB32() & 0xFFFFFF;
    if (rgb == 0xFFFFFF) return ThemePalette.black;
    if (rgb == 0x000000) return ThemePalette.white;
    if (rgb == 0xF5F5F5) return ThemePalette.darkMutedSurface;
    if (rgb == 0x0A0A0A) return ThemePalette.lightMutedSurface;
    return ThemePalette.invert(color);
  }
}
