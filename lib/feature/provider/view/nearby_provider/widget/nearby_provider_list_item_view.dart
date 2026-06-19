import 'package:demandium/feature/home/helper/home_provider_section_layout.dart';
import 'package:demandium/util/core_export.dart';
import 'package:get/get.dart';

class NearbyProviderListItemView extends StatelessWidget {
  final  bool fromHomePage;
  final ProviderData providerData;
  final GlobalKey<CustomShakingWidgetState>?  signInShakeKey;
  final int index;
  const NearbyProviderListItemView({super.key, this.fromHomePage = true, required this.providerData, required this.index, this.signInShakeKey}) ;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<NearbyProviderController>(builder: (providerBookingController){
      final logoSize = fromHomePage ? HomeProviderSectionLayout.homeLogoSize(context) : 70.0;
      final cardPadding = fromHomePage
          ? HomeProviderSectionLayout.homeCardPadding()
          : const EdgeInsets.all(Dimensions.paddingSizeDefault);

      return Padding(padding:EdgeInsets.symmetric(
          horizontal: fromHomePage ? 0 : (ResponsiveHelper.isDesktop(context) ? 5 : Dimensions.paddingSizeEight),
          vertical: fromHomePage?0:Dimensions.paddingSizeEight),

        child: OnHover(
          isItem: true,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                decoration: BoxDecoration(color: Theme.of(context).cardColor , borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                  border: Border.all(color: Theme.of(context).hintColor.withValues(alpha: 0.3)),
                ),
                padding: cardPadding,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.center,children: [

                    ClipRRect(borderRadius: BorderRadius.circular(Dimensions.radiusExtraMoreLarge),
                      child: Stack( children: [
                        CustomImage(height: logoSize, width: logoSize, fit: BoxFit.cover,
                          image: providerData.logoFullPath ?? "" , placeholder: Images.userPlaceHolder,
                        ),
                        if(providerData.serviceAvailability == 0) Positioned.fill(child: Container(
                          color: Colors.black.withValues(alpha: 0.5),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Text(
                                'unavailable'.tr, style: robotoLight.copyWith(
                                fontSize: Dimensions.fontSizeSmall -1,
                                color: Colors.white,
                              )),
                            ),
                          ),
                        ))
                      ]),
                    ),

                    const SizedBox(width: Dimensions.paddingSizeSmall),

                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start,mainAxisAlignment: MainAxisAlignment.center,children: [
                        Row(children: [
                          Flexible(
                            child: Text(providerData.companyName ?? "", style: robotoMedium.copyWith(
                                fontSize: fromHomePage ? Dimensions.fontSizeDefault : Dimensions.fontSizeDefault + 1
                            ),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!fromHomePage) const SizedBox(width: Dimensions.paddingSizeExtraLarge,)
                        ]),
                        Row(children: [
                          SizedBox(height: fromHomePage ? 16 : 20,
                            child: Row(children: [

                              Image(image: AssetImage(Images.starIcon), color: Theme.of(context).colorScheme.secondary, height: fromHomePage ? 12 : null, width: fromHomePage ? 12 : null),
                              Gaps.horizontalGapOf(3),
                              Directionality(
                                textDirection: TextDirection.ltr,
                                child: Text(
                                  (providerData.avgRating ?? 0).toStringAsFixed(2),
                                  style: robotoRegular.copyWith(color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6), fontSize: Dimensions.fontSizeSmall),
                                ),
                              ),
                            ]),
                          ),
                          Gaps.horizontalGapOf(5),
                          Directionality(textDirection: TextDirection.ltr,
                            child: Text(
                              "(${providerData.ratingCount})",
                              style: robotoRegular.copyWith(color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6), fontSize: Dimensions.fontSizeSmall),
                            ),
                          )],
                        ),
                        if (!fromHomePage)
                        Text(providerData.companyAddress??"",
                          style: robotoRegular.copyWith(color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6), fontSize: Dimensions.fontSizeSmall),
                          overflow: TextOverflow.ellipsis, maxLines: 1,
                        ),

                        if (providerData.distance != null) ...[
                          if (!fromHomePage) const SizedBox(height: Dimensions.paddingSizeTine),
                          Row(children: [
                            Image.asset(Images.distance, height:12),
                            const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                            Directionality(
                              textDirection: TextDirection.ltr,
                              child: Flexible(
                                child: Text("${providerData.distance!.toStringAsFixed(2)} ${'km_away_from_you'.tr}",
                                  style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ]),
                        ]
                      ]),
                    ),
                  ]),
                ]),
              ),

              Positioned.fill(child: RippleButton(onTap: () {
                final providerId = providerData.id;
                if (providerId != null) {
                  Get.toNamed(RouteHelper.getProviderDetails(providerId));
                }
              })),

              if (fromHomePage)
                Padding(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                  child: Align(
                    alignment: HomeProviderSectionLayout.homeFavoriteAlignment(),
                    child: FavoriteIconWidget(
                      value: providerData.isFavorite,
                      providerId: providerData.id,
                      signInShakeKey: signInShakeKey,
                    ),
                  ),
                )
              else
                Align(
                  alignment: favButtonAlignment(),
                  child: FavoriteIconWidget(
                    value: providerData.isFavorite,
                    providerId: providerData.id,
                    signInShakeKey: signInShakeKey,
                  ),
                ),

            ],
          ),
        ),
      );
    });
  }
}