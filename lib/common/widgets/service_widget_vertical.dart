import 'package:get/get.dart';
import 'package:demandium/util/core_export.dart';

class ServiceWidgetVertical extends StatelessWidget {
  final Service service;
  final String fromType;
  final String fromPage;
  final ProviderData? providerData;
  final GlobalKey<CustomShakingWidgetState>?  signInShakeKey;

  const ServiceWidgetVertical({
    super.key, required this.service, required this.fromType,
    this.fromPage ="", this.providerData, this.signInShakeKey}) ;

  @override
  Widget build(BuildContext context) {
    num lowestPrice = service.resolveLowestPrice(fromCampaign: fromType == 'fromCampaign');
    bool showDiscountedPrice = false;


    Discount discountModel =  PriceConverter.discountCalculation(service);
    if(discountModel.minPurchase != null){
      showDiscountedPrice = discountModel.minPurchase! <= lowestPrice.toDouble();
    }

    return OnHover(
      isItem: true,
      child: GetBuilder<ServiceController>(builder: (serviceController){
        return Stack(alignment: Alignment.bottomRight, children: [
          Stack(children: [
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                boxShadow: Get.find<ThemeController>().darkTheme ? null : cardShadow,
              ),

              child: Padding(padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.start, children: [
                  Expanded(
                    flex: ResponsiveHelper.isDesktop(context) && !Get.find<LocalizationController>().isLtr ? 5 : 8,
                    child: Stack(children: [

                      ClipRRect(
                        borderRadius: const BorderRadius.all(Radius.circular(Dimensions.radiusSmall)),
                        child: CustomImage(
                          image: '${service.thumbnailFullPath}',
                          fit: BoxFit.cover,width: double.maxFinite,
                          height: double.infinity,
                        ),
                      ),

                      discountModel.discountAmount! > 0 ? Align(alignment: Alignment.topLeft,
                        child: DiscountTagWidget(
                          discountAmount: discountModel.discountAmount,
                          discountAmountType: discountModel.discountAmountType,
                        ),
                      ) : const SizedBox(),

                    ],),
                  ),

                  Padding(
                    padding: const EdgeInsets.only(top: Dimensions.paddingSizeEight -2 ),
                    child: Text(
                      service.name ?? "",
                      style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge),
                      maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.start,
                    ),
                  ),

                  Row(children: [
                    SizedBox(
                      height: 20,
                      child: Row(children: [
                        Gaps.horizontalGapOf(3),

                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(
                            service.avgRating!.toStringAsFixed(2),
                            style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
                          ),
                        ),
                        Gaps.horizontalGapOf(3),

                        Image(image: AssetImage(Images.starIcon), height: 12, width: 12),

                      ]),
                    ),
                    Gaps.horizontalGapOf(5),

                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text("(${service.ratingCount})", style: robotoBold.copyWith(
                        color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: .6),
                        fontSize: Dimensions.fontSizeSmall
                      )),
                    )
                  ]),

                  Expanded(
                    flex: 3,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'starts_from'.tr,
                            style: robotoRegular.copyWith(
                                fontSize: Dimensions.fontSizeSmall,
                                color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: .5)),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if(showDiscountedPrice)
                                Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: Text(
                                    PriceConverter.convertPrice(lowestPrice.toDouble()),
                                    maxLines: 2,
                                    style: robotoRegular.copyWith(
                                        fontSize: Dimensions.fontSizeSmall,
                                        decoration: TextDecoration.lineThrough,
                                        color: Theme.of(context).colorScheme.error),),
                                ),
                              showDiscountedPrice ?
                              Directionality(
                                textDirection: TextDirection.ltr,
                                child: Text(
                                  PriceConverter.convertPrice(
                                      lowestPrice.toDouble(),
                                      discount: discountModel.discountAmount!.toDouble(),
                                      discountType: discountModel.discountAmountType),
                                  style: robotoMedium.copyWith(
                                      fontSize: Dimensions.fontSizeDefault,
                                      color:  Get.isDarkMode? Theme.of(context).primaryColorLight: Theme.of(context).primaryColor),
                                ),
                              ):
                              Directionality(
                                textDirection: TextDirection.ltr,
                                child: Text(
                                  PriceConverter.convertPrice(lowestPrice.toDouble()),
                                  style: robotoMedium.copyWith(
                                      fontSize:Dimensions.fontSizeDefault ,
                                      color: Get.isDarkMode? Theme.of(context).primaryColorLight: Theme.of(context).primaryColor),
                                ),
                              ),
                            ],
                          ),
                        ]),
                  ),
                ],),
              ),
            ),
            Positioned.fill(child: RippleButton(onTap: () {
              final slug = service.slug;
              if (slug == null || slug.isEmpty) {
                customSnackBar('no_service_available'.tr, type: ToasterMessageType.info);
                return;
              }
              if(fromPage=="search_page"){
                Get.toNamed(RouteHelper.getServiceRoute(slug,fromPage:"search_page"),);
              }else{
                Get.toNamed(RouteHelper.getServiceRoute(slug),);
              }
            }))
          ],),

          if(fromType != 'fromCampaign')
            Align(
              alignment:Get.find<LocalizationController>().isLtr ? Alignment.bottomRight : Alignment.bottomLeft,
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                    child: Icon(Icons.add,
                      color: Get.isDarkMode? Theme.of(context).primaryColorLight : Theme.of(context).primaryColor,
                      size: Dimensions.paddingSizeExtraLarge,
                    ),
                  ),
                  Positioned.fill(child: RippleButton(onTap: () {
                    ServiceCenterDialog.show(
                      context,
                      service: service,
                      providerData: providerData,
                      minPurchasePrice: discountModel.minPurchase,
                    );
                  }))
                ],
              ),
            ),

          Align(
            alignment: Alignment.topRight,
            child: FavoriteIconWidget(
              value: service.isFavorite,
              serviceId:  service.id!,
              signInShakeKey: signInShakeKey,
            ),
          )

        ],);
      }),
    );
  }
}
