import 'package:demandium/feature/checkout/model/placed_booking_summary.dart';
import 'package:get/get.dart';
import 'package:demandium/util/core_export.dart';

class CompletePage extends StatelessWidget {
  final String? token;

  const CompletePage({super.key, this.token});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GetBuilder<CheckOutController>(builder: (controller) {
              final summaries = controller.placedBookingSummaries;
              final bookingCount = summaries.isNotEmpty
                  ? summaries.length
                  : controller.bookingReadableIds.length;
              final successTitle = bookingCount > 1
                  ? 'bookings_have_been_placed_successfully'.tr
                  : 'booking_has_been_placed_successfully'.tr;

              return Column(
                children: [
                  const SizedBox(height: Dimensions.paddingSizeExtraMoreLarge),
                  Image.asset(Images.orderComplete, scale: 4.5),
                  const SizedBox(height: Dimensions.paddingSizeExtraMoreLarge),
                  Text(
                    controller.isPlacedOrderSuccessfully
                        ? successTitle
                        : 'your_bookings_is_failed_to_place'.tr,
                    style: robotoBold.copyWith(
                      fontSize: Dimensions.fontSizeLarge,
                      color: controller.isPlacedOrderSuccessfully
                          ? null
                          : Theme.of(context).colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (controller.isPlacedOrderSuccessfully && summaries.isNotEmpty) ...[
                    const SizedBox(height: Dimensions.paddingSizeLarge),
                    ...summaries.map(
                      (summary) => _PlacedBookingSummaryTile(summary: summary),
                    ),
                  ],
                  const SizedBox(height: Dimensions.paddingSizeExtraMoreLarge),
                  CustomButton(
                    buttonText: 'explore_more_service'.tr,
                    width: 280,
                    backgroundColor:
                        Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    textStyle: robotoRegular.copyWith(
                      fontSize: Dimensions.fontSizeDefault,
                      color: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.color
                          ?.withValues(alpha: 0.8),
                    ),
                    onPressed: () {
                      Get.find<CheckOutController>().updateState(PageState.orderDetails);
                      Get.offAllNamed(RouteHelper.getMainRoute('home'));
                    },
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _PlacedBookingSummaryTile extends StatelessWidget {
  final PlacedBookingSummary summary;

  const _PlacedBookingSummaryTile({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.25),
        ),
      ),
      child: Text(
        '${summary.serviceName} - ${summary.readableId}',
        style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      ),
    );
  }
}
