import 'package:demandium/feature/profile/model/received_customer_rating_model.dart';
import 'package:demandium/util/core_export.dart';
import 'package:get/get.dart';
import 'package:readmore/readmore.dart';

class ReceivedCustomerReviewItem extends StatelessWidget {
  final ReceivedCustomerReview review;

  const ReceivedCustomerReviewItem({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    final providerName = review.provider?.companyName ?? 'provider_not_available'.tr;
    final bookingLabel = review.booking?.readableId ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          color: Theme.of(context).hoverColor,
          boxShadow: Get.find<ThemeController>().darkTheme ? null : cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                  child: CustomImage(
                    image: review.provider?.logoFullPath ?? '',
                    height: 44,
                    width: 44,
                    placeholder: Images.providerImage,
                  ),
                ),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        providerName,
                        style: robotoMedium.copyWith(
                          fontSize: Dimensions.fontSizeDefault,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                      Row(
                        children: [
                          RatingBar(
                            rating: (review.reviewRating ?? 0).toDouble(),
                            color: Theme.of(context).primaryColor,
                            size: 16,
                          ),
                          const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                          Text(
                            (review.reviewRating ?? 0).toStringAsFixed(1),
                            style: robotoMedium.copyWith(
                              color: Theme.of(context).hintColor,
                              fontSize: Dimensions.fontSizeSmall,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (review.createdAt != null)
                  Text(
                    DateConverter.dateStringMonthYear(
                      DateConverter.isoUtcStringToLocalDate(review.createdAt!),
                    ),
                    style: robotoRegular.copyWith(
                      color: Theme.of(context).hintColor,
                      fontSize: Dimensions.fontSizeSmall,
                    ),
                    textDirection: TextDirection.ltr,
                  ),
              ],
            ),
            if (bookingLabel.isNotEmpty) ...[
              const SizedBox(height: Dimensions.paddingSizeSmall),
              Text(
                '${'booking'.tr}: $bookingLabel',
                style: robotoRegular.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: Theme.of(context).hintColor,
                ),
              ),
            ],
            if (review.reviewComment != null &&
                review.reviewComment!.trim().isNotEmpty) ...[
              const SizedBox(height: Dimensions.paddingSizeSmall),
              ReadMoreText(
                review.reviewComment!.capitalizeFirst ?? '',
                trimCollapsedText: 'see_more'.tr,
                trimExpandedText: '  ${'see_less'.tr}',
                trimMode: TrimMode.Line,
                trimLines: 3,
                style: robotoRegular.copyWith(
                  color: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.color
                      ?.withValues(alpha: 0.7),
                  fontSize: Dimensions.fontSizeSmall,
                  height: 1.5,
                ),
                moreStyle: robotoMedium.copyWith(color: Colors.blueAccent),
                lessStyle: robotoMedium.copyWith(color: Colors.blueAccent),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
