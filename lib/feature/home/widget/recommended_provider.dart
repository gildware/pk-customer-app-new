import 'package:demandium/feature/home/helper/home_provider_section_layout.dart';
import 'package:demandium/feature/home/widget/home_provider_horizontal_section.dart';
import 'package:demandium/util/core_export.dart';
import 'package:get/get.dart';

class HomeRecommendProvider extends StatelessWidget {
  final double? height;
  final GlobalKey<CustomShakingWidgetState>? signInShakeKey;
  final String? titleOverride;
  const HomeRecommendProvider({
    super.key,
    this.height,
    this.signInShakeKey,
    this.titleOverride,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProviderBookingController>(
      builder: (controller) => HomeProviderHorizontalSection(
        titleKey: 'recommended_experts_for_you',
        displayTitle: titleOverride,
        onSeeAll: () => Get.toNamed(RouteHelper.getAllProviderRoute()),
        showSeeAll: (controller.providerList?.length ?? 0) > 7,
        providers: controller.providerList,
        signInShakeKey: signInShakeKey,
        height: height,
      ),
    );
  }
}

class HomeRecommendedProviderShimmer extends StatelessWidget {
  final double height;
  const HomeRecommendedProviderShimmer({super.key, required this.height});

  @override
  Widget build(BuildContext context) {
    final cardWidth = HomeProviderSectionLayout.cardWidth(context);
    final listHeight = HomeProviderSectionLayout.listHeight(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Dimensions.paddingSizeDefault,
        Dimensions.paddingSizeSmall,
        Dimensions.paddingSizeDefault,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(height: 15, width: 130, color: Theme.of(context).shadowColor),
              Container(height: 15, width: 80, color: Theme.of(context).shadowColor),
            ],
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          SizedBox(
            height: listHeight,
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: Dimensions.paddingSizeDefault),
              itemCount: 2,
              itemBuilder: (context, index) {
                return Container(
                  width: cardWidth,
                  margin: const EdgeInsets.only(right: Dimensions.paddingSizeExtraSmall),
                  padding: HomeProviderSectionLayout.homeCardPadding(),
                  decoration: BoxDecoration(
                    color: Theme.of(context).shadowColor,
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                  ),
                  child: Shimmer(
                    duration: const Duration(seconds: 1),
                    interval: const Duration(seconds: 1),
                    enabled: true,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          height: HomeProviderSectionLayout.homeLogoSize(context),
                          width: HomeProviderSectionLayout.homeLogoSize(context),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(height: 12, width: 90, color: Theme.of(context).cardColor),
                                const SizedBox(height: 5),
                                Container(height: 10, width: 110, color: Theme.of(context).cardColor),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
