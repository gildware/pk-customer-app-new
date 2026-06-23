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
        final imageFlex = ServiceCardLayout.imageFlex(context);

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
            boxShadow: Get.find<ThemeController>().darkTheme ? null : cardShadow,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: imageFlex,
                child: _buildImageStack(context, service, discountModel),
              ),

              Stack(
                children: [
                  Positioned.fill(child: RippleButton(onTap: () => _openService(service))),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Dimensions.paddingSizeExtraSmall,
                      4,
                      2,
                      4,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          service.name ?? "",
                          style: robotoMedium.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            height: 1.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'starts_from'.tr,
                          style: robotoRegular.copyWith(
                            fontSize: Dimensions.fontSizeExtraSmall,
                            height: 1.1,
                            color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: .5),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if(showDiscountedPrice)
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text(
                              PriceConverter.convertPrice(lowestPrice.toDouble()),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: robotoRegular.copyWith(
                                fontSize: Dimensions.fontSizeExtraSmall,
                                height: 1.1,
                                decoration: TextDecoration.lineThrough,
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        SizedBox(
                          height: 18,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: showDiscountedPrice ?
                                Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: Text(
                                    PriceConverter.convertPrice(
                                      lowestPrice.toDouble(),
                                      discount: discountModel.discountAmount!.toDouble(),
                                      discountType: discountModel.discountAmountType,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: robotoMedium.copyWith(
                                      fontSize: Dimensions.fontSizeSmall,
                                      height: 1.1,
                                      color: Get.isDarkMode ? Theme.of(context).primaryColorLight : Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ) :
                                Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: Text(
                                    PriceConverter.convertPrice(lowestPrice.toDouble()),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: robotoMedium.copyWith(
                                      fontSize: Dimensions.fontSizeSmall,
                                      height: 1.1,
                                      color: Get.isDarkMode ? Theme.of(context).primaryColorLight : Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ),
                              ),
                              FavoriteIconWidget(
                                value: service.isFavorite,
                                serviceId: service.id!,
                                signInShakeKey: signInShakeKey,
                                iconSize: 16,
                                iconPadding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildImageStack(BuildContext context, Service service, Discount discountModel) {
    return Stack(children: [
      CustomImage(
        image: '${service.thumbnailFullPath}',
        fit: BoxFit.cover,
        width: double.maxFinite,
        height: double.infinity,
      ),

      discountModel.discountAmount! > 0 ? Align(alignment: Alignment.topLeft,
        child: DiscountTagWidget(
          discountAmount: discountModel.discountAmount,
          discountAmountType: discountModel.discountAmountType,
        ),
      ) : const SizedBox(),

      Align(
        alignment: Alignment.bottomRight,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeTine,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(Dimensions.radiusSmall),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  service.avgRating!.toStringAsFixed(2),
                  style: robotoRegular.copyWith(
                    fontSize: Dimensions.fontSizeExtraSmall,
                    color: Colors.white,
                  ),
                ),
              ),
              Gaps.horizontalGapOf(3),
              Image(image: AssetImage(Images.starIcon), height: 10, width: 10),
              Gaps.horizontalGapOf(3),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  "(${service.ratingCount})",
                  style: robotoBold.copyWith(
                    color: Colors.white.withValues(alpha: .8),
                    fontSize: Dimensions.fontSizeExtraSmall,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      Positioned.fill(child: RippleButton(onTap: () => _openService(service))),
    ]);
  }

  void _openService(Service service) {
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
  }
}
