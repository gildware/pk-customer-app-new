import 'package:demandium/util/core_export.dart';
import 'package:get/get.dart';

/// Shared sizing for horizontal provider rows on the customer home screen.
class HomeProviderSectionLayout {
  HomeProviderSectionLayout._();

  /// ~1 full card plus half of the next card visible on mobile.
  static double cardWidth(BuildContext context) {
    if (ResponsiveHelper.isDesktop(context)) {
      return Dimensions.webMaxWidth / 3.2;
    }
    if (ResponsiveHelper.isTab(context)) {
      return Get.width / 2.2;
    }
    const listStart = Dimensions.paddingSizeDefault;
    const itemGap = Dimensions.paddingSizeExtraSmall;
    return (Get.width - listStart - itemGap) / 1.5;
  }

  static double listHeight(BuildContext context) {
    if (ResponsiveHelper.isDesktop(context)) return 124;
    if (ResponsiveHelper.isTab(context)) return 116;
    return 108;
  }

  static double sectionHeight(BuildContext context) => listHeight(context) + 48;

  static double homeLogoSize(BuildContext context) {
    if (ResponsiveHelper.isDesktop(context)) return 56;
    return 48;
  }

  static EdgeInsets homeCardPadding() => const EdgeInsets.all(Dimensions.paddingSizeSmall);

  static EdgeInsets listItemPadding() {
    return const EdgeInsets.only(right: Dimensions.paddingSizeExtraSmall);
  }

  static AlignmentGeometry homeFavoriteAlignment() {
    return Get.find<LocalizationController>().isLtr
        ? Alignment.bottomRight
        : Alignment.bottomLeft;
  }
}
