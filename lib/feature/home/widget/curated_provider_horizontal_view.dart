import 'package:demandium/feature/provider/widgets/provider_item_view.dart';
import 'package:demandium/util/core_export.dart';
import 'package:get/get.dart';

class CuratedProviderHorizontalView extends StatelessWidget {
  final String sectionKey;
  final double height;
  final String? titleOverride;
  final GlobalKey<CustomShakingWidgetState>? signInShakeKey;

  const CuratedProviderHorizontalView({
    super.key,
    required this.sectionKey,
    required this.height,
    this.titleOverride,
    this.signInShakeKey,
  });

  @override
  Widget build(BuildContext context) {
    if (sectionKey == 'nearby_providers') {
      return GetBuilder<NearbyProviderController>(
        builder: (controller) => _buildContent(context, controller.providersForHomeSection(sectionKey)),
      );
    }
    return GetBuilder<ProviderBookingController>(
      builder: (controller) => _buildContent(context, controller.providersForHomeSection(sectionKey)),
    );
  }

  Widget _buildContent(BuildContext context, List<ProviderData>? list) {
    if (list == null) {
      return SizedBox(height: height * 0.5);
    }
    if (list.isEmpty) {
      return const SizedBox();
    }
    return Container(
          color: Get.isDarkMode
              ? Colors.grey.shade900
              : Theme.of(context).primaryColor.withValues(alpha: 0.12),
          height: height,
          child: Stack(
            children: [
              Image.asset(Images.homeProviderBackground, width: Get.width, fit: BoxFit.cover),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Column(
                  children: [
                    const SizedBox(height: Dimensions.paddingSizeDefault),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        Dimensions.paddingSizeDefault,
                        15,
                        Dimensions.paddingSizeDefault,
                        Dimensions.paddingSizeSmall,
                      ),
                      child: TitleWidget(
                        textDecoration: TextDecoration.underline,
                        title: sectionKey,
                        displayTitle: titleOverride,
                        onTap: () => Get.toNamed(RouteHelper.getAllProviderRoute()),
                        isShowSeeAllButton: list.length > 7,
                      ),
                    ),
                    SizedBox(
                      height: ResponsiveHelper.isMobile(context) ? 160 : 170,
                      child: ListView.builder(
                        physics: const ClampingScrollPhysics(),
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: Dimensions.paddingSizeExtraSmall + 2,
                        ),
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeLarge),
                            child: SizedBox(
                              width: ResponsiveHelper.isDesktop(context)
                                  ? Dimensions.webMaxWidth / 3.2
                                  : ResponsiveHelper.isTab(context)
                                      ? Get.width / 2.5
                                      : Get.width / 1.16,
                              child: ProviderItemView(
                                providerData: list[index],
                                index: index,
                                signInShakeKey: signInShakeKey,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
  }
}
