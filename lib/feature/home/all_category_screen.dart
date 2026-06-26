import 'package:demandium/common/widgets/custom_pop_widget.dart';
import 'package:demandium/util/core_export.dart';
import 'package:get/get.dart';
import 'package:demandium/common/widgets/address_selection_drawer.dart';

class AllCategoryScreen extends StatelessWidget {
  const AllCategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Responsive sizing
    final bool isDesktop = ResponsiveHelper.isDesktop(context);
    final double? pageSizeWidth = ResponsiveHelper.isDesktop(context) ? Dimensions.webMaxWidth * 0.6 : null;

    return CustomPopWidget(
      child: Scaffold(
        drawer: ResponsiveHelper.isDesktop(context) ? const AddressSelectionDrawer() : null,

        endDrawer: ResponsiveHelper.isDesktop(context) ? const MenuDrawer(): null,
        appBar: CustomAppBar(title: 'all_categories'.tr),
        body: FooterBaseView(
          child: SizedBox(
            width: pageSizeWidth,
            child: GetBuilder<CategoryController>(builder: (categoryController) {
              return Padding(
                padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                child: GridView.builder(
                    shrinkWrap: true,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: ResponsiveHelper.isMobile(context) ? 3 : 4,
                      crossAxisSpacing: Dimensions.paddingSizeSmall,
                      mainAxisSpacing: Dimensions.paddingSizeSmall,
                      childAspectRatio: MediaQuery.of(context).size.width < 400 ? 0.85 : 0.95,
                    ),
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: categoryController.categoryList?.length ?? 0,
                    itemBuilder: (context, index) {
                      final category = categoryController.categoryList![index];
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
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: 0.05),
                                  offset: const Offset(0, 2),
                                  blurRadius: 10,
                                ),
                                BoxShadow(
                                  color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: 0.04),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: CustomImage(
                                    width: double.infinity,
                                    height: double.infinity,
                                    image: categoryController.categoryList?[index].imageFullPath ?? "",
                                    fit: BoxFit.cover,
                                    placeholder: Images.categoryPlaceholder,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: Dimensions.paddingSizeExtraSmall,
                                    vertical: Dimensions.paddingSizeSmall,
                                  ),
                                  child: Text(
                                    categoryController.categoryList?[index].name ?? '',
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
                                ),
                              ],
                            ),
                          ),
                        );
                      });
                    }),
              );
            }),
          ),
        ),
      ),
    );

  }
}
