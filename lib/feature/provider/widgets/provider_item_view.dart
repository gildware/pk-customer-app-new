import 'package:demandium/feature/home/helper/home_provider_section_layout.dart';
import 'package:demandium/util/core_export.dart';
import 'package:get/get.dart';

class ProviderItemView extends StatelessWidget {
  final  bool fromHomePage;
  final ProviderData providerData;
  final GlobalKey<CustomShakingWidgetState>?  signInShakeKey;
  final int index;
  const ProviderItemView({super.key, this.fromHomePage = true, required this.providerData, required this.index, this.signInShakeKey}) ;

  @override
  Widget build(BuildContext context) {

    return GetBuilder<ProviderBookingController>(builder: (providerBookingController){
      final logoSize = fromHomePage ? HomeProviderSectionLayout.homeLogoSize(context) : 65.0;
      final cardPadding = fromHomePage
          ? HomeProviderSectionLayout.homeCardPadding()
          : const EdgeInsets.all(Dimensions.paddingSizeDefault);
      final nameStyle = fromHomePage
          ? robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault)
          : robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge);
      final nameMaxLines = fromHomePage ? 1 : 2;
      final ratingSize = fromHomePage ? 14.0 : 18.0;

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
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.center,children: [

                    ClipRRect(borderRadius: BorderRadius.circular(Dimensions.radiusExtraMoreLarge),
                      child: CustomImage(height: logoSize, width: logoSize, fit: BoxFit.cover,
                        image: providerData.logoFullPath ?? "" , placeholder: Images.userPlaceHolder,
                      ),
                    ),

                    const SizedBox(width: Dimensions.paddingSizeSmall),

                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start,mainAxisAlignment: MainAxisAlignment.center,children: [
                        Row(children: [
                          Flexible(
                            child: Text(providerData.companyName??"", style: nameStyle,
                              maxLines: nameMaxLines, overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!fromHomePage) const SizedBox(width: Dimensions.paddingSizeExtraLarge,)
                        ]),

                        Row(children: [
                          RatingBar(rating: providerData.avgRating, color: Theme.of(context).colorScheme.secondary, size: ratingSize),
                          Gaps.horizontalGapOf(5),
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child:  Text('${providerData.ratingCount} ${'reviews'.tr}', style: robotoRegular.copyWith(
                              fontSize: fromHomePage ? Dimensions.fontSizeSmall : Dimensions.fontSizeDefault,
                              color: Theme.of(context).secondaryHeaderColor,
                            )),
                          ),
                        ],
                        ),
                      ],),
                    ),
                  ],),

                  if (!fromHomePage) ...[
                  const SizedBox(height: Dimensions.paddingSizeSmall),
                  Text(providerData.companyAddress ?? "",
                    style: robotoRegular.copyWith(
                      fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7)
                    ),
                    overflow: TextOverflow.ellipsis, maxLines: 1,
                  ),
                  const SizedBox(height: Dimensions.paddingSizeTine),
                  ] else ...[
                  const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                  Text(providerData.companyAddress ?? "",
                    style: robotoRegular.copyWith(
                      fontSize: Dimensions.fontSizeExtraSmall,
                      color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                    ),
                    overflow: TextOverflow.ellipsis, maxLines: 1,
                  ),
                  ],

                  if (providerData.distance != null)
                    Row(children: [
                      Image.asset(Images.distance, height:12,),
                      const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                      Flexible(
                        child: Text("${providerData.distance!.toStringAsFixed(2)} ${'km_away_from_you'.tr}",
                          style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ])
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