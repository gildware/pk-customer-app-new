import 'package:get/get.dart';
import 'package:demandium/common/models/config_model.dart';
import 'package:demandium/feature/splash/controller/splash_controller.dart';

class MobileAppHomeHelper {
  static List<HomeSectionConfig> _allSections() {
    try {
      if (!Get.isRegistered<SplashController>()) {
        return HomeSectionConfig.defaults;
      }
      final content = Get.find<SplashController>().configModel.content;
      final fromApi = content?.mobileAppHome?.sections;
      if (fromApi != null && fromApi.isNotEmpty) {
        final enabled = fromApi.where((s) => s.enabled).toList();
        if (enabled.isNotEmpty) {
          return List<HomeSectionConfig>.from(fromApi);
        }
      }
    } catch (_) {
      //
    }
    return HomeSectionConfig.defaults;
  }

  static List<HomeSectionConfig> orderedEnabledSections({bool excludeSearch = false}) {
    final list = _allSections()
        .where((s) => s.enabled && (!excludeSearch || s.key != 'search'))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  }

  static bool isSectionEnabled(String key) {
    return orderedEnabledSections().any((s) => s.key == key);
  }

  static HomeSectionConfig? section(String key) {
    try {
      return _allSections().firstWhere((s) => s.key == key);
    } catch (_) {
      return null;
    }
  }

  static HomeSectionConfig? _section(String key) => section(key);

  static bool usesManualData(String key) => section(key)?.isManualData ?? false;

  static bool isCustomSection(String key) =>
      key.startsWith('custom_') || (section(key)?.isCustom ?? false);

  static List<HomeSectionConfig> manualSections() =>
      orderedEnabledSections().where((s) => s.isManualData).toList();

  /// Custom admin title, or [fallbackTrKey].tr when not set.
  static String sectionTitle(String key, String fallbackTrKey) {
    final custom = _section(key)?.title;
    if (custom != null && custom.trim().isNotEmpty) {
      return custom.trim();
    }
    return fallbackTrKey.tr;
  }

  static int? itemLimit(String key, int defaultLimit) {
    return _section(key)?.itemLimit ?? defaultLimit;
  }

  static bool get usesRemoteConfig {
    try {
      if (!Get.isRegistered<SplashController>()) return false;
      final sections = Get.find<SplashController>().configModel.content?.mobileAppHome?.sections;
      return sections != null && sections.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
