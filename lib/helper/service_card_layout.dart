import 'package:demandium/util/core_export.dart';
import 'package:get/get.dart';

/// Shared sizing for vertical service cards across home, provider profile, and lists.
class ServiceCardLayout {
  ServiceCardLayout._();

  static double horizontalListHeight(BuildContext context) {
    if (!Get.find<LocalizationController>().isLtr) {
      return 190;
    }
    if (ResponsiveHelper.isMobile(context)) {
      return 175;
    }
    return 190;
  }

  static double horizontalCardWidth(BuildContext context) {
    if (ResponsiveHelper.isDesktop(context)) {
      return Dimensions.webMaxWidth / 5.7;
    }
    if (ResponsiveHelper.isTab(context)) {
      return 195;
    }
    return Get.width / 2.65;
  }

  static double gridMainAxisExtent(BuildContext context) {
    if (ResponsiveHelper.isDesktop(context)) {
      return 225;
    }
    return 175;
  }

  static int gridCrossAxisCount(BuildContext context) {
    if (ResponsiveHelper.isDesktop(context)) {
      return 5;
    }
    if (ResponsiveHelper.isTab(context)) {
      return 3;
    }
    return 2;
  }

  static double gridChildAspectRatio(BuildContext context) {
    if (ResponsiveHelper.isDesktop(context) || ResponsiveHelper.isTab(context)) {
      return .9;
    }
    return .75;
  }

  static double featheredCategoryRowHeight(BuildContext context) {
    return horizontalListHeight(context) + 60;
  }

  static int imageFlex(BuildContext context) {
    if (ResponsiveHelper.isDesktop(context) && !Get.find<LocalizationController>().isLtr) {
      return 4;
    }
    return 5;
  }

  static SliverGridDelegateWithFixedCrossAxisCount gridDelegate(BuildContext context) {
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisSpacing: Dimensions.paddingSizeDefault,
      mainAxisSpacing: Dimensions.paddingSizeDefault,
      childAspectRatio: gridChildAspectRatio(context),
      crossAxisCount: gridCrossAxisCount(context),
      mainAxisExtent: gridMainAxisExtent(context),
    );
  }
}
