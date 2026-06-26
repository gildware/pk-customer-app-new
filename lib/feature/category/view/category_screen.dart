import 'package:demandium/common/widgets/custom_pop_widget.dart';
import 'package:get/get.dart';
import 'package:demandium/util/core_export.dart';
import 'package:demandium/common/widgets/address_selection_drawer.dart';

class CategoryScreen extends StatefulWidget {
   final String? fromPage;
   final String? campaignID;

  const CategoryScreen({super.key,this.fromPage,this.campaignID}) ;

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  List<CategoryModel>? categoryList;


  @override
  Widget build(BuildContext context) {
    return CustomPopWidget(
      child: Scaffold(
        drawer: ResponsiveHelper.isDesktop(context) ? const AddressSelectionDrawer() : null,

        endDrawer:ResponsiveHelper.isDesktop(context) ? const MenuDrawer():null,
        appBar: CustomAppBar(title: 'categories'.tr),
        body: SafeArea(
            child: Scrollbar(
                child: widget.fromPage == 'fromCampaign' ?
                GetBuilder<CategoryController>(
                  initState: (state){
                    Get.find<CategoryController>().getCampaignBasedCategoryList(widget.campaignID ?? "" ,false);
                  },
                    builder: (categoryController) {
                      return _buildBody(categoryController.campaignBasedCategoryList);
                    }) :
                GetBuilder<CategoryController>(
                    initState: (state){
                      Get.find<CategoryController>().getCategoryList(false);
                    },
                    builder: (categoryController) {
                      return _buildBody(categoryController.categoryList);
                    }))),
      ),
    );
  }

  Widget _buildBody(List<CategoryModel>? categoryList){
     if(categoryList != null && categoryList.isEmpty){
      return FooterBaseView(
          isCenter: true,
          child: NoDataScreen(
              type: NoDataType.categorySubcategory,
              text: 'no_category_found'.tr));
    }else{
      if(categoryList != null){
        return FooterBaseView(
          child: SizedBox(
            width: Dimensions.webMaxWidth,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: ResponsiveHelper.isDesktop(context) ? 6 : ResponsiveHelper.isTab(context) ? 4 : 3,
                      childAspectRatio: (1 / 1),
                      mainAxisSpacing: Dimensions.paddingSizeSmall,
                      crossAxisSpacing: Dimensions.paddingSizeSmall,
                    ),
                    padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                    itemCount: categoryList.length,
                    itemBuilder: (context, index) {
                      return InkWell(
                        onTap: () {
                          final category = categoryList[index];
                          final slug = category.slug?.trim().isNotEmpty == true
                              ? category.slug!.trim()
                              : category.id?.trim() ?? '';
                          if (slug.isEmpty) return;
                          final name = category.name ?? '';
                          if(widget.fromPage == 'fromCampaign'){
                            Get.find<CategoryController>().getSubCategoryList(slug);
                            Get.toNamed(RouteHelper.subCategoryScreenRoute(name, slug, index));
                          }else{
                            Get.toNamed(RouteHelper.getCategoryProductRoute(slug, name, index.toString()));
                          }
                        },

                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                            boxShadow: Get.isDarkMode
                                ? null
                                : [BoxShadow(color: Colors.grey[Get.isDarkMode ? 800 : 200]!, blurRadius: 5, spreadRadius: 1)],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: CustomImage(
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                  image: '${categoryList[index].imageFullPath}',
                                  placeholder: Images.categoryPlaceholder,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: Dimensions.paddingSizeExtraSmall,
                                  vertical: Dimensions.paddingSizeSmall,
                                ),
                                child: Text(
                                  categoryList[index].name!,
                                  textAlign: TextAlign.center,
                                  style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      }else{
        return const Center(child: CircularProgressIndicator());
      }
    }
  }
}
