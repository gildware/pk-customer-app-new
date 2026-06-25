import 'package:get/get.dart';
import 'package:demandium/util/core_export.dart';

class SubCategoryWidget extends GetView<ServiceController> {
  final CategoryModel? categoryModel;
  const SubCategoryWidget({super.key, required this.categoryModel,});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        final slug = categoryModel?.slug?.trim().isNotEmpty == true
            ? categoryModel!.slug!.trim()
            : categoryModel?.id?.trim() ?? '';
        if (slug.isEmpty) {
          return;
        }
        Get.find<ServiceController>().cleanSubCategory();
        Get.toNamed(RouteHelper.allServiceScreenRoute(
          slug,
          title: categoryModel?.name ?? '',
        ));
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal:ResponsiveHelper.isDesktop(context) ? 0 : Dimensions.paddingSizeDefault),
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeExtraSmall),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
            color: Theme.of(context).cardColor,
            boxShadow: Get.find<ThemeController>().darkTheme ? null : cardShadow
        ),
        child: Stack(
          children: [
            Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                child: CustomImage(
                  image: categoryModel?.imageFullPath ?? "",
                  height: 70, width: 70, fit: BoxFit.cover, placeHolderBoxFit: BoxFit.cover,
                  placeholder: Images.categoryPlaceholder,
                ),
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: Dimensions.paddingSizeExtraSmall,
                    right: Dimensions.paddingSizeLarge,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        categoryModel?.name ?? "",
                        style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                      Text(categoryModel?.description ?? '', maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: robotoRegular.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          color: Theme.of(context).textTheme.bodyLarge!.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ]),
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                height: 18,
                width: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${categoryModel?.serviceCount ?? 0}',
                  style: robotoMedium.copyWith(
                    fontSize: 9,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
