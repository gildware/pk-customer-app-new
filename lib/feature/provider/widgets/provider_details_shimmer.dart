import 'package:demandium/util/core_export.dart';
import 'package:get/get.dart';

class ProviderDetailsShimmer extends StatelessWidget {
  const ProviderDetailsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return  SizedBox(
      width: Dimensions.webMaxWidth,
      child: Column(children: [
        if (!ResponsiveHelper.isDesktop(context)) ...[
          Shimmer(
            child: Container(
              width: screenWidth,
              height: screenWidth / 3.5,
              color: Theme.of(context).shadowColor,
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -16),
            child: _buildProfileCardShimmer(context, screenWidth),
          ),
        ] else
          _buildProfileCardShimmer(context, screenWidth),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
          child: ListView.separated(itemBuilder: (context,index){
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 22, width: screenWidth * 0.4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                    color: Get.find<ThemeController>().darkTheme  ? Theme.of(context).cardColor : Theme.of(context).shadowColor,
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeSmall,),
                GridView.builder(
                  key: UniqueKey(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisSpacing: Dimensions.paddingSizeDefault,
                    mainAxisSpacing:  Dimensions.paddingSizeDefault,
                    mainAxisExtent: ServiceCardLayout.gridMainAxisExtent(context),
                    crossAxisCount: ServiceCardLayout.gridCrossAxisCount(context),
                  ),
                  physics:  const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: ResponsiveHelper.isDesktop(context) ? 5 : ResponsiveHelper.isTab(context) ? 3 : 2,
                  itemBuilder: (context, index) {
                    return const ServiceShimmer(isEnabled: true, hasDivider: false);
                  },
                ),
              ],
            );
          },
            itemCount: 5,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            separatorBuilder: (context, index){
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Divider(color: Theme.of(context).hintColor),
              );
            },
          ),
        )
      ]),
    );
  }

  Widget _buildProfileCardShimmer(BuildContext context, double screenWidth) {
    return Shimmer(
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          border: Border.all(color: Theme.of(context).hintColor.withValues(alpha: 0.12)),
        ),
        margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 64,
              width: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Dimensions.radiusExtraMoreLarge),
                color: Theme.of(context).shadowColor,
              ),
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 18,
                    width: screenWidth * 0.4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                      color: Theme.of(context).shadowColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: screenWidth * 0.55,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                      color: Theme.of(context).shadowColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 12,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                            color: Theme.of(context).shadowColor,
                          ),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 12,
                        margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                        color: Theme.of(context).hintColor.withValues(alpha: 0.12),
                      ),
                      Expanded(
                        child: Container(
                          height: 12,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                            color: Theme.of(context).shadowColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
