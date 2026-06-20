import 'package:demandium/common/widgets/custom_pop_widget.dart';
import 'package:get/get.dart';
import 'package:demandium/util/core_export.dart';
import 'package:demandium/common/widgets/address_selection_drawer.dart';

class CategorySubCategoryScreen extends StatefulWidget {
  final String categorySlug;
  final String categoryIndex;
   const CategorySubCategoryScreen({super.key, required this.categorySlug, required this.categoryIndex}) ;

  @override
  State<CategorySubCategoryScreen> createState() => _CategorySubCategoryScreenState();
}

class _CategorySubCategoryScreenState extends State<CategorySubCategoryScreen> {
  AutoScrollController? scrollController;
  String? categoryIndex;
  int availableServiceCount = 0;

  @override
  void initState() {
    scrollController = AutoScrollController(
      viewportBoundaryGetter: () => Rect.fromLTRB(0, 0, 0, MediaQuery.of(context).padding.bottom),
      axis: Axis.horizontal,
    );
    scrollController!.scrollToIndex(int.tryParse(widget.categoryIndex) ?? 0, preferPosition: AutoScrollPosition.middle);
    scrollController!.highlight(int.tryParse(widget.categoryIndex) ?? 0);

    if(Get.find<LocationController>().getUserAddress() !=null){
      availableServiceCount = Get.find<LocationController>().getUserAddress()?.availableServiceCountInZone ?? 0;
    }

    categoryIndex = widget.categoryIndex;
    Get.find<CategoryController>().getCategoryList(false);
    _syncZoneAndCounts();

    super.initState();
  }

  Future<void> _syncZoneAndCounts() async {
    await Get.find<LocationController>().refreshSavedAddressZone();
    await Get.find<CategoryController>().getCategoryList(true);
    await Get.find<CategoryController>().getSubCategoryList(widget.categorySlug);
    if (!mounted) return;
    final count = Get.find<LocationController>().getUserAddress()?.availableServiceCountInZone;
    if (count != null) {
      setState(() => availableServiceCount = count);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomPopWidget(
      child: GetBuilder<CategoryController>(
        builder: (categoryController) {
          return Scaffold(
            drawer: ResponsiveHelper.isDesktop(context) ? const AddressSelectionDrawer() : null,

            endDrawer:ResponsiveHelper.isDesktop(context) ? const MenuDrawer():null,
            appBar: CustomAppBar(title: 'available_service'.tr,),
            body: FooterBaseView(
              child: SizedBox(
                width: Dimensions.webMaxWidth,
                child: availableServiceCount > 0 ?
                CustomScrollView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: SizedBox(height: ResponsiveHelper.isDesktop(context) ? Dimensions.paddingSizeExtraLarge : Dimensions.paddingSizeExtraSmall,),),
                    SliverToBoxAdapter(
                      child: (categoryController.categoryList != null && !categoryController.isSearching!) ?
                      Center(
                        child: Container(
                          height: ResponsiveHelper.isDesktop(context) ? 145 : ResponsiveHelper.isTab(context) ? 140 : 125,
                          margin: EdgeInsets.only(
                            left: ResponsiveHelper.isDesktop(context) ? 0 : Dimensions.paddingSizeDefault,
                          ),
                          width: Dimensions.webMaxWidth,
                          padding: const EdgeInsets.only(
                            bottom: Dimensions.paddingSizeExtraSmall,
                            top: Dimensions.paddingSizeDefault,
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            controller: scrollController,
                            scrollDirection: Axis.horizontal,
                            itemCount: categoryController.categoryList!.length,
                            physics: const ClampingScrollPhysics(),
                            itemBuilder: (context, index) {
                              CategoryModel categoryModel = categoryController.categoryList!.elementAt(index);
                              return AutoScrollTag(
                                controller: scrollController!,
                                key: ValueKey(index),
                                index: index,
                                child: InkWell(
                                  onTap: () async {
                                    final slug = categoryModel.slug?.trim().isNotEmpty == true
                                        ? categoryModel.slug!.trim()
                                        : categoryModel.id?.trim() ?? '';
                                    if (slug.isEmpty) return;
                                    categoryIndex = index.toString();
                                    Get.find<CategoryController>().getSubCategoryList(slug);
                                    await scrollController!.scrollToIndex( index, preferPosition: AutoScrollPosition.middle,
                                      duration: const Duration(milliseconds: 500)
                                    );
                                    await scrollController!.highlight(index);
                                  },
                                  hoverColor: Colors.transparent,
                                  child: Builder(
                                    builder: (context) {
                                      final isSelected = index == int.parse(categoryIndex!);
                                      const cardRadius = Dimensions.radiusDefault;
                                      const selectedBorderWidth = 2.0;
                                      final innerRadius = isSelected ? cardRadius - selectedBorderWidth : cardRadius;

                                      return Container(
                                        width: ResponsiveHelper.isDesktop(context) ? 120 : ResponsiveHelper.isTab(context) ? 120 : 88,
                                        height: ResponsiveHelper.isDesktop(context) ? 115 : ResponsiveHelper.isTab(context) ? 110 : 100,
                                        margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(cardRadius),
                                          color: isSelected ? Theme.of(context).colorScheme.primary : null,
                                        ),
                                        padding: isSelected ? const EdgeInsets.all(selectedBorderWidth) : EdgeInsets.zero,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(innerRadius),
                                          ),
                                          clipBehavior: Clip.antiAlias,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.stretch,
                                            children: [
                                              Expanded(
                                                child: ColoredBox(
                                                  color: Theme.of(context).primaryColorLight,
                                                  child: CustomImage(
                                                    fit: BoxFit.cover,
                                                    placeHolderBoxFit: BoxFit.cover,
                                                    height: double.infinity,
                                                    width: double.infinity,
                                                    image: '${categoryController.categoryList![index].imageFullPath}',
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                width: double.infinity,
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: Dimensions.paddingSizeExtraSmall,
                                                  vertical: Dimensions.paddingSizeExtraSmall,
                                                ),
                                                color: isSelected
                                                    ? Theme.of(context).colorScheme.primary
                                                    : Theme.of(context).primaryColorLight,
                                                child: Text(
                                                  categoryController.categoryList![index].name!,
                                                  style: robotoMedium.copyWith(
                                                    fontSize: Dimensions.fontSizeExtraSmall,
                                                    color: isSelected ? Colors.white : Colors.black,
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
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ) : ResponsiveHelper.isDesktop(context)?
                      const CategoryShimmer(fromHomeScreen: false,):const SizedBox(),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(width: Dimensions.webMaxWidth,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeLarge),
                          child: Center(
                            child: Text(
                              'sub_categories'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault,
                                color:Get.isDarkMode ? Colors.white:Theme.of(context).colorScheme.primary),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SubCategoryView(
                      noDataText: "no_subcategory_found".tr,
                      isScrollable: true,
                    ),
                  ],
                ) :
                SizedBox( height: MediaQuery.of(context).size.height*.6, child: const ServiceNotAvailableScreen()),
              ),
            ),
          );
        },
      ),
    );
  }
}
