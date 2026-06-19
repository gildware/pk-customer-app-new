import 'package:demandium/feature/home/widget/home_provider_horizontal_section.dart';
import 'package:demandium/util/core_export.dart';
import 'package:get/get.dart';

class NearbyProviderListview extends StatelessWidget {
  final double? height;
  final GlobalKey<CustomShakingWidgetState>? signInShakeKey;
  final String? titleOverride;
  const NearbyProviderListview({
    super.key,
    this.height,
    this.signInShakeKey,
    this.titleOverride,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<NearbyProviderController>(
      builder: (controller) => HomeProviderHorizontalSection(
        titleKey: 'providers_near_you',
        displayTitle: titleOverride,
        onSeeAll: () => Get.toNamed(RouteHelper.getNearByProviderScreen(tabIndex: 0)),
        showSeeAll: (controller.providerList?.length ?? 0) > 7,
        providers: controller.providerList,
        useNearbyItem: true,
        signInShakeKey: signInShakeKey,
        height: height,
      ),
    );
  }
}
