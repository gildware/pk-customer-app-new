import 'package:demandium/util/core_export.dart';
import 'package:get/get.dart';

class ConversationListTabview extends StatelessWidget {
  final TabController? tabController;
  const ConversationListTabview({super.key, this.tabController}) ;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ConversationController>(
      builder: (conversationController) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
          child: Row(
            children: [
              TabBar(
                controller: tabController,
                unselectedLabelColor: Colors.grey,
                isScrollable: true,
                indicatorColor: Theme.of(context).colorScheme.primary,
                labelColor:  Theme.of(context).colorScheme.primary,
                labelStyle: robotoMedium,
                indicatorWeight: 1.5,
                tabAlignment: TabAlignment.start,
                indicatorPadding: const EdgeInsets.only(right: 40),
                labelPadding: EdgeInsets.only(
                  right: conversationController.isActiveSuffixIcon && conversationController.isSearchComplete
                      && conversationController.searchedProviderChannelList!.isNotEmpty ? 8 : 18,
                ),
                tabs:  [
                  SizedBox(
                    height: 28,
                    child:Center(
                      child: Row(
                        children: [
                          Text("provider".tr),
                          conversationController.isActiveSuffixIcon && conversationController.isSearchComplete  && conversationController.searchedProviderChannelList!.isNotEmpty?
                          Container(height: 13 , width: 13,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle, color: context.adaptivePrimaryColor,
                            ),
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            padding: const EdgeInsets.all(2),
                            child: FittedBox(child: Text(
                              conversationController.searchedProviderChannelList!.length.toString(),
                              style: robotoRegular.copyWith(color: Colors.white),
                            ),
                            ),
                          ) : const SizedBox(),
                        ],
                      ),
                    ),
                  ),
                  // SERVICEMAN_DISABLED
                  if (AppFeatureFlags.servicemanEnabled)
                  SizedBox(
                    height: 28,
                    child:  Center(
                      child: Row(
                        children: [
                          Text("serviceman".tr),
                          conversationController.isActiveSuffixIcon && conversationController.isSearchComplete  && conversationController.searchedServicemanChannelList!.isNotEmpty?
                          Container(height: 13 , width: 13,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle, color: context.adaptivePrimaryColor,
                            ),
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            padding: const EdgeInsets.all(2),
                            child: FittedBox(child: Text(
                              conversationController.searchedServicemanChannelList!.length.toString(),
                              style: robotoRegular.copyWith(color: Colors.white),
                            ),
                            ),
                          ) : const SizedBox(),
                        ],
                      ),
                    ),
                  ),
                ],
                onTap: (index){
                  if( conversationController.isActiveSuffixIcon && conversationController.isSearchComplete){

                  }else{
                    Get.find<ConversationController>().getChannelList(1,type: index == 0 ? "provider": "serviceman");
                  }

                },
              ),
              const Expanded(child: SizedBox()),
            ],
          ),
        );
      }
    );
  }
}
