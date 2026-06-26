import 'package:demandium/util/core_export.dart';
import 'package:get/get.dart';

class ProviderDetailsTopCard extends StatelessWidget {
  final String providerId;
  final Color? color;
  final VoidCallback? onReviewsTap;

  const ProviderDetailsTopCard({
    super.key,
    required this.providerId,
    this.color,
    this.onReviewsTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLtr = Get.find<LocalizationController>().isLtr;
    final bool isDesktop = ResponsiveHelper.isDesktop(context);

    return GetBuilder<ProviderBookingController>(
      builder: (providerController) {
        final ProviderData providerDetails = providerController.providerDetailsContent!.provider!;
        final Rating? providerReview = providerController.providerDetailsContent?.providerRating;

        final cardDecoration = BoxDecoration(
          color: color ?? Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          border: Border.all(
            color: color != null ? Colors.transparent : Theme.of(context).hintColor.withValues(alpha: 0.12),
          ),
        );

        final identitySection = _ProviderIdentitySection(
          providerDetails: providerDetails,
          providerReview: providerReview,
          providerId: providerId,
          isLtr: isLtr,
          avatarSize: isDesktop ? 72 : 64,
          onReviewsTap: onReviewsTap,
        );

        if (isDesktop) {
          return Container(
            decoration: cardDecoration,
            margin: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                    child: identitySection,
                  ),
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        bottomRight: Radius.circular(isLtr ? Dimensions.radiusDefault : 0),
                        topRight: Radius.circular(isLtr ? Dimensions.radiusDefault : 0),
                        bottomLeft: Radius.circular(isLtr ? 0 : Dimensions.radiusDefault),
                        topLeft: Radius.circular(isLtr ? 0 : Dimensions.radiusDefault),
                      ),
                      border: Border.all(
                        color: color != null ? Colors.transparent : Theme.of(context).hintColor.withValues(alpha: 0.12),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.only(
                        bottomRight: Radius.circular(isLtr ? Dimensions.radiusDefault : 0),
                        topRight: Radius.circular(isLtr ? Dimensions.radiusDefault : 0),
                        bottomLeft: Radius.circular(isLtr ? 0 : Dimensions.radiusDefault),
                        topLeft: Radius.circular(isLtr ? 0 : Dimensions.radiusDefault),
                      ),
                      child: CustomImage(
                        image: providerController.providerDetailsContent?.provider?.coverImageFullPath ?? '',
                        placeholder: Images.placeholder,
                        width: Dimensions.webMaxWidth / 2,
                        height: Dimensions.webMaxWidth / 6,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          decoration: cardDecoration,
          margin: const EdgeInsets.fromLTRB(
            Dimensions.paddingSizeDefault,
            Dimensions.paddingSizeSmall,
            Dimensions.paddingSizeDefault,
            Dimensions.paddingSizeDefault,
          ),
          padding: const EdgeInsets.fromLTRB(
            Dimensions.paddingSizeDefault,
            Dimensions.paddingSizeDefault,
            Dimensions.paddingSizeSmall,
            Dimensions.paddingSizeDefault,
          ),
          child: identitySection,
        );
      },
    );
  }
}

class _ProviderIdentitySection extends StatelessWidget {
  final ProviderData providerDetails;
  final Rating? providerReview;
  final String providerId;
  final bool isLtr;
  final double avatarSize;
  final VoidCallback? onReviewsTap;

  const _ProviderIdentitySection({
    required this.providerDetails,
    required this.providerReview,
    required this.providerId,
    required this.isLtr,
    required this.avatarSize,
    this.onReviewsTap,
  });

  void _openReviews(BuildContext context) {
    if (onReviewsTap != null) {
      onReviewsTap!();
      return;
    }
    if (ResponsiveHelper.isDesktop(context)) {
      Get.dialog(
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: Get.height * 0.8),
            child: Container(
              width: Dimensions.webMaxWidth / 2,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Dimensions.radiusSeven),
                color: Theme.of(context).cardColor,
              ),
              padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
              child: ProviderReviewBody(providerId: providerId),
            ),
          ),
        ),
      );
    } else {
      Get.toNamed(RouteHelper.getProviderReviewScreen(providerId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final availabilityStatus = ProviderAvailabilityHelper.getLiveAvailabilityStatus(providerDetails);
    final (statusColor, statusText) = switch (availabilityStatus) {
      ProviderLiveAvailability.available => (Colors.green, 'available'.tr),
      ProviderLiveAvailability.onBreak => (Colors.orange, 'on_break'.tr),
      ProviderLiveAvailability.unavailable => (
        Theme.of(context).colorScheme.error,
        'unavailable'.tr,
      ),
    };
    final secondaryColor = Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6);

    return InkWell(
      splashColor: Colors.transparent,
      hoverColor: Colors.transparent,
      onTap: () {
        if (ResponsiveHelper.isDesktop(context)) {
          Get.dialog(Center(child: ProviderAvailabilityWidget(providerId: providerId)));
        } else {
          showModalBottomSheet(
            backgroundColor: Colors.transparent,
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            builder: (context) => ProviderAvailabilityWidget(providerId: providerId),
          );
        }
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(Dimensions.radiusExtraMoreLarge),
                child: CustomImage(
                  height: avatarSize,
                  width: avatarSize,
                  fit: BoxFit.cover,
                  image: providerDetails.logoFullPath ?? '',
                  placeholder: Images.userPlaceHolder,
                ),
              ),
              Positioned(
                bottom: -4,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(
                        color: Theme.of(context).hintColor.withValues(alpha: 0.15),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingSizeExtraSmall,
                      vertical: 2,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 7, color: statusColor),
                        const SizedBox(width: 3),
                        Text(
                          statusText,
                          style: robotoMedium.copyWith(
                            color: statusColor,
                            fontSize: Dimensions.fontSizeExtraSmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    providerDetails.companyName ?? '',
                    style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Image.asset(Images.iconLocation, height: 11),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          providerDetails.companyAddress ?? '',
                          style: robotoRegular.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Dimensions.paddingSizeSmall),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => _openReviews(context),
                          behavior: HitTestBehavior.opaque,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              RatingBar(
                                rating: providerDetails.avgRating,
                                size: 11,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                              const SizedBox(width: 6),
                              Directionality(
                                textDirection: TextDirection.ltr,
                                child: Text(
                                  '${providerDetails.avgRating!.toStringAsFixed(1)} of (${providerReview?.reviewCount ?? providerReview?.ratingCount ?? 0})',
                                  style: robotoMedium.copyWith(
                                    fontSize: Dimensions.fontSizeSmall,
                                    color: secondaryColor,
                                  ),
                                  maxLines: 1,
                                  softWrap: false,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 12,
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          color: Theme.of(context).hintColor.withValues(alpha: 0.25),
                        ),
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(
                            '${providerDetails.totalServiceServed ?? '0'} ${'services_provided'.tr}',
                            style: robotoRegular.copyWith(
                              fontSize: Dimensions.fontSizeSmall,
                              color: secondaryColor,
                            ),
                            maxLines: 1,
                            softWrap: false,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: Dimensions.paddingSizeExtraSmall),
            child: FavoriteIconWidget(
              value: providerDetails.isFavorite,
              providerId: providerDetails.id,
            ),
          ),
        ],
      ),
    );
  }
}
