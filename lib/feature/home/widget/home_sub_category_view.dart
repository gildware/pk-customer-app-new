import 'package:demandium/feature/home/helper/mobile_app_home_helper.dart';
import 'package:demandium/helper/extension_helper.dart';
import 'package:get/get.dart';
import 'package:demandium/util/core_export.dart';

class HomeSubCategoryView extends StatefulWidget {
  final String sectionKey;
  const HomeSubCategoryView({super.key, required this.sectionKey});

  @override
  State<HomeSubCategoryView> createState() => _HomeSubCategoryViewState();
}

class _HomeSubCategoryViewState extends State<HomeSubCategoryView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<CategoryController>().ensureSubCategoriesForSection(widget.sectionKey);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CategoryController>(builder: (categoryController) {
      final subCategoryList = categoryController.subCategoriesForSection(widget.sectionKey);
      final bool isLoaded = categoryController.subCategoriesLoadedForSection(widget.sectionKey);
      final title = MobileAppHomeHelper.sectionTitle(widget.sectionKey, 'sub_categories');

      final metrics = _HomeSubCategoryCardMetrics.fromContext(context);

      return Center(
        child: SizedBox(
          width: Dimensions.webMaxWidth,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TitleWidget(
                  title: title,
                  onTap: () => Get.toNamed(RouteHelper.getAllCategoriesScreen()),
                  isShowSeeAllButton: (subCategoryList?.length ?? 0) > 3,
                ),
                const SizedBox(height: Dimensions.paddingSizeDefault),
                if (!isLoaded)
                  SizedBox(
                    height: metrics.rowHeight,
                    child: _HomeSubCategoryRowShimmer(metrics: metrics),
                  )
                else if (subCategoryList == null || subCategoryList.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
                    child: Text(
                      'no_subcategory_found'.tr,
                      style: robotoRegular.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: metrics.rowHeight,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: subCategoryList.length,
                      itemBuilder: (context, index) {
                        final category = subCategoryList[index];
                        final slug = category.slug?.trim().isNotEmpty == true
                            ? category.slug!.trim()
                            : category.id?.trim() ?? '';
                        if (slug.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return TextHover(builder: (hovered) {
                          return InkWell(
                            onTap: () {
                              Get.find<ServiceController>().cleanSubCategory();
                              Get.toNamed(RouteHelper.allServiceScreenRoute(
                                slug,
                                title: category.name ?? '',
                              ));
                            },
                            child: Padding(
                              padding: EdgeInsetsDirectional.only(
                                end: Dimensions.paddingSizeSmall,
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    height: metrics.containerSize,
                                    width: metrics.containerSize,
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.all(
                                        Radius.circular(Dimensions.radiusDefault),
                                      ),
                                      color: context.customThemeColors.searchBarBorder,
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: CustomImage(
                                      width: double.infinity,
                                      height: double.infinity,
                                      image: category.imageFullPath ?? '',
                                      fit: BoxFit.cover,
                                      placeholder: Images.categoryPlaceholder,
                                    ),
                                  ),
                                  const SizedBox(height: Dimensions.paddingSizeSmall),
                                  Flexible(
                                    child: SizedBox(
                                      width: metrics.itemWidth,
                                      child: Text(
                                        category.name ?? '',
                                        style: robotoRegular.copyWith(
                                          fontSize: metrics.labelFontSize,
                                          color: hovered
                                              ? Get.isDarkMode
                                                  ? Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.color
                                                  : Theme.of(context).colorScheme.primary
                                              : Theme.of(context).textTheme.bodySmall?.color,
                                        ),
                                        maxLines: 2,
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        });
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

/// ~3.5 cards visible per screen width (matches parent horizontal padding).
class _HomeSubCategoryCardMetrics {
  final double containerSize;
  final double imageSize;
  final double itemWidth;
  final double rowHeight;
  final double labelFontSize;

  const _HomeSubCategoryCardMetrics({
    required this.containerSize,
    required this.imageSize,
    required this.itemWidth,
    required this.rowHeight,
    required this.labelFontSize,
  });

  factory _HomeSubCategoryCardMetrics.fromContext(BuildContext context) {
    const visibleOnScreen = 3.5;
    const sectionHorizontalPad = Dimensions.paddingSizeDefault;
    const itemGap = Dimensions.paddingSizeSmall;
    final isDesktop = ResponsiveHelper.isDesktop(context);

    final screenWidth = MediaQuery.sizeOf(context).width;
    final maxContentWidth = isDesktop
        ? (screenWidth > Dimensions.webMaxWidth ? Dimensions.webMaxWidth : screenWidth)
        : screenWidth;
    final contentWidth = maxContentWidth - (sectionHorizontalPad * 2);

    final itemSlot = contentWidth / visibleOnScreen;
    final container = (itemSlot - itemGap).clamp(78.0, 110.0);
    final image = container * 0.64;
    final labelSize = isDesktop ? Dimensions.fontSizeDefault : Dimensions.fontSizeDefault;

    return _HomeSubCategoryCardMetrics(
      containerSize: container,
      imageSize: image,
      itemWidth: itemSlot,
      rowHeight: container + Dimensions.paddingSizeSmall + 44,
      labelFontSize: labelSize,
    );
  }
}

class _HomeSubCategoryRowShimmer extends StatelessWidget {
  final _HomeSubCategoryCardMetrics metrics;
  const _HomeSubCategoryRowShimmer({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: 4,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsetsDirectional.only(end: Dimensions.paddingSizeSmall),
          child: Shimmer(
            duration: const Duration(seconds: 2),
            enabled: true,
            child: Column(
              children: [
                Container(
                  height: metrics.containerSize,
                  width: metrics.containerSize,
                  decoration: BoxDecoration(
                    color: Theme.of(context).shadowColor,
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeSmall),
                Container(
                  height: 14,
                  width: metrics.itemWidth,
                  decoration: BoxDecoration(
                    color: Theme.of(context).shadowColor,
                    borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
