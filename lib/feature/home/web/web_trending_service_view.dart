import 'package:demandium/util/core_export.dart';
import 'package:get/get.dart';

class WebTrendingServiceView extends StatelessWidget {
  final GlobalKey<CustomShakingWidgetState>?  signInShakeKey;
  const WebTrendingServiceView({super.key, this.signInShakeKey}) ;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ServiceController>(
        builder: (serviceController){

          if(serviceController.trendingServiceList != null && serviceController.trendingServiceList!.isEmpty){
            return const SizedBox();
          }else{
            if(serviceController.trendingServiceList != null){
              return  Column(
                children: [

                  const SizedBox(height: Dimensions.paddingSizeTextFieldGap),
                  TitleWidget(
                    title: 'trending_services'.tr,
                    onTap: () => Get.toNamed(RouteHelper.getSearchResultRoute(fromPage: "trending")),
                    isShowSeeAllButton: serviceController.trendingServiceList!.length > 5,
                  ),
                  const SizedBox(height: Dimensions.paddingSizeDefault,),

                  GridView.builder(
                    key: UniqueKey(),
                    gridDelegate: ServiceCardLayout.gridDelegate(context),
                    physics:const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: serviceController.trendingServiceList!.length>5?5:serviceController.trendingServiceList!.length,
                    itemBuilder: (context, index) {
                      return ServiceWidgetVertical(service: serviceController.trendingServiceList![index],fromType: '', signInShakeKey: signInShakeKey,);
                    },
                  )
                ],
              );
            }else{
              return const SizedBox();
            }
          }
    });
  }
}
