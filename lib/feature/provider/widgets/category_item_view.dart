import 'package:demandium/feature/provider/view/provider_sub_category_services_screen.dart';
import 'package:demandium/util/core_export.dart';
import 'package:get/get.dart';

class CategorySection extends StatelessWidget {
  final ProviderData? providerData;

  const CategorySection({super.key, required this.category, this.providerData});

  final CategoryModelItem category;

  @override
  Widget build(BuildContext context) {
    if (category.serviceList.isEmpty) {
      return const SizedBox();
    }

    final cardWidth = ServiceCardLayout.horizontalCardWidth(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Dimensions.paddingSizeDefault,
              Dimensions.paddingSizeDefault,
              Dimensions.paddingSizeDefault,
              Dimensions.paddingSizeExtraSmall,
            ),
            child: TitleWidget(
              title: category.title,
              displayTitle: category.title,
              isShowSeeAllButton: category.serviceList.length > 2,
              onTap: () => Get.to(
                () => ProviderSubCategoryServicesScreen(
                  title: category.title,
                  services: category.serviceList,
                  providerData: providerData,
                ),
              ),
            ),
          ),
          SizedBox(
            height: ServiceCardLayout.horizontalListHeight(context),
            child: ListView.builder(
              primary: false,
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.only(
                left: Dimensions.paddingSizeDefault,
                bottom: Dimensions.paddingSizeExtraSmall,
                top: Dimensions.paddingSizeExtraSmall,
              ),
              itemCount: category.serviceList.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: Dimensions.paddingSizeSmall + 2),
                  child: SizedBox(
                    width: cardWidth,
                    child: ServiceWidgetVertical(
                      service: category.serviceList[index],
                      fromType: 'provider_details',
                      providerData: providerData,
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
