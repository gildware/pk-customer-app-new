import 'package:demandium/util/core_export.dart';
import 'package:get/get.dart';

class WebRecentlyServiceView extends StatelessWidget {
  final GlobalKey<CustomShakingWidgetState>?  signInShakeKey;
  const WebRecentlyServiceView({super.key, this.signInShakeKey}) ;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ServiceController>(
        builder: (serviceController){
      if(serviceController.recentlyViewServiceList != null && serviceController.recentlyViewServiceList!.isEmpty){
        return const SizedBox();
      }else{
        if(serviceController.recentlyViewServiceList != null){
          return  Column(
            children: [

              const SizedBox(height: Dimensions.paddingSizeTextFieldGap),
              TitleWidget(
                title: 'recently_view_services'.tr,
                onTap: () => Get.toNamed(RouteHelper.allServiceScreenRoute("recently_view_services")),
                isShowSeeAllButton: serviceController.recentlyViewServiceList!.length > 7,
              ),
              const SizedBox(height: Dimensions.paddingSizeDefault,),

              GridView.builder(
                key: UniqueKey(),
                gridDelegate: ServiceCardLayout.gridDelegate(context),
                physics:const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: serviceController.recentlyViewServiceList!.length>5?5:serviceController.recentlyViewServiceList!.length,
                itemBuilder: (context, index) {
                  return ServiceWidgetVertical(service: serviceController.recentlyViewServiceList![index],fromType: '', signInShakeKey: signInShakeKey,);
                },
              ),

            ],
          );
        }
        else{
          return const SizedBox();
        }
      }
    });
  }
}
