import 'package:get/get.dart';
import 'package:demandium/util/core_export.dart';


class ServiceWidgetHorizontal extends StatelessWidget {
  final List<Service> serviceList;
  final int index;
  final num? discountAmount;
  final String? discountAmountType;
  final bool showIsFavoriteButton;
  final GlobalKey<CustomShakingWidgetState>?  signInShakeKey;

  const  ServiceWidgetHorizontal({super.key,
    required this.serviceList,
    required this.index,
    required this.discountAmount,
    required this.discountAmountType,
    this.showIsFavoriteButton = true, this.signInShakeKey,
  }) ;

  @override
  Widget build(BuildContext context) {
    final double lowestPrice = serviceList[index].resolveLowestPrice().toDouble();
    bool showDiscountedPrice = false;
    Discount discountModel =  PriceConverter.discountCalculation(serviceList[index]);
    if(discountModel.minPurchase != null){
      showDiscountedPrice = discountModel.minPurchase! <= lowestPrice.toDouble();
    }

    return Padding(
      padding:const EdgeInsets.symmetric(horizontal:  Dimensions.paddingSizeEight, vertical: Dimensions.paddingSizeExtraSmall),
      child: GetBuilder<ServiceController>(builder: (serviceController){
        return OnHover(
          isItem: true,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor ,
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                  boxShadow:  Get.find<ThemeController>().darkTheme ? null : cardShadow,
                  border: Border.all(color: Theme.of(context).hintColor.withValues(alpha: 0.1)),
                ),
                padding: const EdgeInsets.symmetric(horizontal : Dimensions.paddingSizeDefault, vertical: 10),
                child: Row(children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                        child: CustomImage(
                          image: '${serviceList[index].thumbnailFullPath}',
                          height: 100, width: 100, fit: BoxFit.cover,
                          placeholder: Images.servicePlaceholder,
                        ),
                      ),

                      discountModel.discountAmount! > 0 ? Align(alignment: Alignment.topLeft,
                        child: DiscountTagWidget(
                          discountAmount: discountModel.discountAmount,
                          discountAmountType: discountModel.discountAmountType,
                        ),
                      ) : const SizedBox(),
                    ],
                  ),

                  const SizedBox(width: Dimensions.paddingSizeSmall,),

                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              serviceList[index].name ?? "",
                              style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: Dimensions.paddingSizeExtraLarge,),
                        ],
                      ),
                      const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                      RatingBar(
                        rating: double.parse(serviceList[index].avgRating.toString()), size: 15,
                        ratingCount: serviceList[index].ratingCount,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                      Text(serviceList[index].shortDescription ?? "",
                        style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5)),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("starts_from".tr,style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall,
                              color: Theme.of(context).textTheme.bodyMedium!.color!.withValues(alpha: 0.5)),),

                          Column(
                              children: [
                                if(showDiscountedPrice)
                                  Directionality(
                                    textDirection: TextDirection.ltr,
                                    child: Text("${PriceConverter.convertPrice(lowestPrice)} ",
                                      style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall,
                                          decoration: TextDecoration.lineThrough,
                                          color: Theme.of(context).colorScheme.error.withValues(alpha: .8)),
                                    ),
                                  ),

                                showDiscountedPrice ?
                                Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: Text(PriceConverter.convertPrice(lowestPrice,
                                      discount: discountAmount!.toDouble(),
                                      discountType: discountAmountType
                                  ),
                                    style: robotoBold.copyWith(fontSize: Dimensions.paddingSizeDefault,
                                        color: Get.isDarkMode? Theme.of(context).primaryColorLight: Theme.of(context).primaryColor),
                                  ),
                                ): Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: Text(PriceConverter.convertPrice(lowestPrice),
                                    style: robotoBold.copyWith(
                                        fontSize: Dimensions.fontSizeLarge,
                                        color: Get.isDarkMode? Theme.of(context).primaryColorLight: Theme.of(context).primaryColor),
                                  ),
                                ),
                              ]
                          ),


                        ],
                      ),
                    ]),
                  ),

                ]),
              ),
              Positioned.fill(child: RippleButton(onTap: () {
                final slug = serviceController.recommendedServiceList![index].slug;
                if (slug == null || slug.isEmpty) {
                  customSnackBar('no_service_available'.tr, type: ToasterMessageType.info);
                  return;
                }
                Get.toNamed(
                  RouteHelper.getServiceRoute(slug),
                  arguments: ServiceDetailsScreen(serviceID: slug),
                );
              })),

              if(showIsFavoriteButton)Align(
                alignment: favButtonAlignment(),
                child: FavoriteIconWidget(
                  value: serviceList[index].isFavorite,
                  serviceId: serviceList[index].id!,
                  signInShakeKey: signInShakeKey,

                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}





