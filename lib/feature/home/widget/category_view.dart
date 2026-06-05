import 'package:demandium/feature/home/helper/mobile_app_home_helper.dart';
import 'package:demandium/helper/extension_helper.dart';
import 'package:get/get.dart';
import 'package:demandium/util/core_export.dart';

class CategoryView extends StatelessWidget {
  final String sectionKey;
  const CategoryView({super.key, this.sectionKey = 'categories'});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CategoryController>(builder: (categoryController) {
      final categoryList = categoryController.categoriesForSection(sectionKey);

      // Responsive sizing
      final bool isDesktop = ResponsiveHelper.isDesktop(context);
      final double containerSize = isDesktop ? 80 : 65;
      final double imageSize = isDesktop ? 50 : 40;
      final double itemWidth = isDesktop ? 80 : 65;

      return categoryList != null && categoryList.isEmpty ? const SizedBox() :
      categoryList != null ? Center(
        child: SizedBox(width: Dimensions.webMaxWidth,
          child: Padding(padding: const EdgeInsets.symmetric( vertical:Dimensions.paddingSizeDefault),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              TitleWidget(
                textDecoration: TextDecoration.underline,
                title: MobileAppHomeHelper.sectionTitle(sectionKey, 'all_categories'),
                onTap: ()=> Get.toNamed(RouteHelper.getAllCategoriesScreen()),
                isShowSeeAllButton: categoryList.length > 7,
              ),
              const SizedBox(height: Dimensions.paddingSizeDefault),

              SizedBox(
                height: ResponsiveHelper.isDesktop(context) ? 150 : 110,
                child: ListView.builder(
                  itemCount: categoryList.length,
                  scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                    final category = categoryList[index];
                    final categorySlug = category.slug ?? category.id ?? '';
                    if (categorySlug.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return TextHover(builder: (hovered){
                      return InkWell(
                        onTap: () => Get.toNamed(RouteHelper.getCategoryProductRoute(
                          categorySlug,
                          category.name ?? '',
                          index.toString(),
                        )),
                        child: Padding(
                          padding: EdgeInsetsDirectional.only(end: Dimensions.paddingSizeSmall),
                          child: Column(children: [
                            Container(
                              height: containerSize,
                              width: containerSize,
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.all(Radius.circular(Dimensions.radiusDefault)),
                                color: context.customThemeColors.searchBarBorder,
                              ),
                              child: Center(child: ClipRRect(
                                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                                child: CustomImage(
                                  width: imageSize,
                                  height: imageSize,
                                  image: category.imageFullPath ?? '',
                                  fit: BoxFit.cover,
                                ),
                              )),
                            ),
                            SizedBox(height: Dimensions.paddingSizeSmall),

                            Flexible(child: SizedBox(
                              width: itemWidth,
                              child: Text(
                                category.name ?? '',
                                style: robotoRegular.copyWith(
                                  fontSize: isDesktop ? Dimensions.fontSizeDefault : Dimensions.fontSizeSmall,
                                  color: hovered ? Get.isDarkMode
                                      ? Theme.of(context).textTheme.bodyMedium?.color
                                      : Theme.of(context).colorScheme.primary
                                      : Theme.of(context).textTheme.bodySmall?.color,
                                ),
                                maxLines: 2,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            )),

                          ]),
                        ),
                      );
                    });
                  },
                ),
              ),
            ]),
          ),
        ),
      ) : const CategoryShimmer();
    });
  }
}


class CategoryShimmer extends StatelessWidget {
  final bool? fromHomeScreen;

  const CategoryShimmer({super.key, this.fromHomeScreen=true});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: Dimensions.webMaxWidth,
        child: Column(
          children: [
            if(fromHomeScreen!) const SizedBox(height: Dimensions.paddingSizeLarge,),
            if(fromHomeScreen!) Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  height: 25, width: 120,
                  decoration: BoxDecoration(
                    color: Get.isDarkMode ? Theme.of(context).cardColor : Theme.of(context).shadowColor,
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    boxShadow: Get.isDarkMode ? null : cardShadow,
                  ),
                ), Container(
                  height: 25, width: 100,
                  decoration: BoxDecoration(
                    color: Get.find<ThemeController>().darkTheme ?  Theme.of(context).cardColor : Theme.of(context).shadowColor,
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    boxShadow: Get.isDarkMode ? null : cardShadow,
                  ),
                ),
              ],),
            if(fromHomeScreen!)const SizedBox(height: Dimensions.paddingSizeSmall,),
            GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount:  !fromHomeScreen! ? 8 : ResponsiveHelper.isDesktop(context) ? 10 : ResponsiveHelper.isTab(context)? 12 : 8,
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    boxShadow: Get.isDarkMode ? null: cardShadow,
                  ),
                  child: Shimmer(
                    duration: const Duration(seconds: 2),
                    enabled: true,
                    child: Column(mainAxisAlignment: MainAxisAlignment.center,children: [

                      const SizedBox(height: Dimensions.paddingSizeDefault,),
                      Expanded(
                        child: Container(
                          height: double.infinity,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                            color: Theme.of(context).shadowColor,
                          ),
                          margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
                        ),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeDefault),
                      Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: Theme.of(context).shadowColor,
                          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                        ),
                        margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                      ),

                      const SizedBox(height: Dimensions.paddingSizeDefault),
                    ]),
                  ),
                );
              },
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: !fromHomeScreen! ? 8 : ResponsiveHelper.isDesktop(context) ? 10 : ResponsiveHelper.isTab(context) ? 6 : 4,
                crossAxisSpacing: Dimensions.paddingSizeSmall + 2,
                mainAxisSpacing: Dimensions.paddingSizeSmall + 2,
                childAspectRatio: 1,
              ),
            ),

            SizedBox(height: ResponsiveHelper.isDesktop(context) ? 0 : Dimensions.paddingSizeLarge,)
          ],
        ),
      ),
    );
  }
}
