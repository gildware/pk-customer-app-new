import 'package:get/get.dart';
import 'package:demandium/util/core_export.dart';

class CampaignView extends StatelessWidget {
  final String sectionKey;
  const CampaignView({super.key, this.sectionKey = 'campaigns'});


  @override
  Widget build(BuildContext context) {
    return GetBuilder<CampaignController>(
        builder: (campaignController){
          final campaigns = campaignController.campaignsForSection(sectionKey);
          if(campaigns != null && campaigns.isEmpty){
            return const SizedBox();
          }else{
            return Container(
                width: MediaQuery.of(context).size.width,
                height: ResponsiveHelper.isTab(context) || MediaQuery.of(context).size.width > 450 ? 350 :MediaQuery.of(context).size.width * 0.40,
                padding: const EdgeInsets.only(bottom : Dimensions.paddingSizeSmall),
                child: campaigns != null ?
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: CarouselSlider.builder(
                        options: CarouselOptions(
                          enableInfiniteScroll: campaigns.length > 1 ? true : false,
                          autoPlay: true,
                          enlargeCenterPage: false,
                          viewportFraction: campaigns.length  == 1 ? 0.96 : .94,
                          disableCenter: true,
                          autoPlayInterval: const Duration(seconds: 7),
                          onPageChanged: (index, reason) {
                            campaignController.setCurrentIndex(index, true);
                          },
                        ),
                        itemCount: campaigns.length,
                        itemBuilder: (context, index, _) {

                          return InkWell(
                            onTap: () {
                              if(isRedundentClick(DateTime.now())){
                                return;
                              }
                              campaignController.navigateFromCampaign(campaigns[index].id!,campaigns[index].discount!.discountType!);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                                  border: Border.all(color: Theme.of(context).hintColor.withValues(alpha: 0.5),width: 0.5),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                                  child: GetBuilder<SplashController>(builder: (splashController) {
                                    return CustomImage(
                                      image: campaigns[index].coverImageFullPath ?? "",
                                      fit: BoxFit.cover,
                                      placeholder: Images.placeholder,
                                    );
                                  },
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                    campaigns.length > 1 ? Align(
                      alignment: Alignment.center,
                      child: AnimatedSmoothIndicator(
                        activeIndex: campaignController.currentIndex!,
                        count: campaigns.length,
                        effect: ExpandingDotsEffect(
                          dotHeight: 8, dotWidth: 8,
                          activeDotColor: Theme.of(context).colorScheme.primary,
                          dotColor: Theme.of(context).disabledColor,
                        ),
                      ),
                    ) : const SizedBox.shrink(),
                  ],) :
                Padding(padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                  child: Shimmer(
                      duration: const Duration(seconds: 2),
                      enabled: true, color: Colors.grey,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                          boxShadow: Get.isDarkMode ? null:[BoxShadow(color: Colors.grey[200]!, blurRadius: 5, spreadRadius: 1)],
                        ),
                      )
                  ),
                ),
            );
          }
        });
  }
}
