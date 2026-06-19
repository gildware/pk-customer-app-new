import 'package:demandium/feature/home/widget/home_provider_horizontal_section.dart';
import 'package:demandium/util/core_export.dart';
import 'package:get/get.dart';

class CuratedProviderHorizontalView extends StatelessWidget {
  final String sectionKey;
  final String? titleOverride;
  final GlobalKey<CustomShakingWidgetState>? signInShakeKey;

  const CuratedProviderHorizontalView({
    super.key,
    required this.sectionKey,
    this.titleOverride,
    this.signInShakeKey,
  });

  @override
  Widget build(BuildContext context) {
    if (sectionKey == 'nearby_providers') {
      return GetBuilder<NearbyProviderController>(
        builder: (controller) => HomeProviderHorizontalSection(
          titleKey: sectionKey,
          displayTitle: titleOverride,
          onSeeAll: () => Get.toNamed(RouteHelper.getNearByProviderScreen(tabIndex: 0)),
          showSeeAll: (controller.providersForHomeSection(sectionKey)?.length ?? 0) > 7,
          providers: controller.providersForHomeSection(sectionKey),
          useNearbyItem: true,
          signInShakeKey: signInShakeKey,
        ),
      );
    }
    return GetBuilder<ProviderBookingController>(
      builder: (controller) => HomeProviderHorizontalSection(
        titleKey: sectionKey,
        displayTitle: titleOverride,
        onSeeAll: () => Get.toNamed(RouteHelper.getAllProviderRoute()),
        showSeeAll: (controller.providersForHomeSection(sectionKey)?.length ?? 0) > 7,
        providers: controller.providersForHomeSection(sectionKey),
        signInShakeKey: signInShakeKey,
      ),
    );
  }
}
