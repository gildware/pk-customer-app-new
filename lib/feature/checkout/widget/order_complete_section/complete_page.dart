import 'package:demandium/feature/checkout/model/placed_booking_summary.dart';
import 'package:get/get.dart';
import 'package:demandium/util/core_export.dart';

class CompletePage extends StatefulWidget {
  final String? token;

  const CompletePage({super.key, this.token});

  @override
  State<CompletePage> createState() => _CompletePageState();
}

class _CompletePageState extends State<CompletePage> {
  @override
  void initState() {
    super.initState();
    if (widget.token != null &&
        widget.token!.isNotEmpty &&
        widget.token != 'null') {
      return;
    }
    runAfterFrame(() {
      Get.find<CheckOutController>().ensurePlacedBookingSummaries();
    });
  }

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
                      (summary) => _PlacedBookingSummaryCard(summary: summary),
                    ),
                  ],
                  const SizedBox(height: Dimensions.paddingSizeExtraMoreLarge),
                  CustomButton(
                    buttonText: 'back_to_home'.tr,
                    width: 280,
                    onPressed: _goHome,
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  void _goHome() {
    Get.find<CheckOutController>().updateState(PageState.orderDetails);
    Get.offAllNamed(RouteHelper.getMainRoute('home'));
  }
}

class _PlacedBookingSummaryCard extends StatelessWidget {
  final PlacedBookingSummary summary;

  const _PlacedBookingSummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final canViewBooking =
        summary.bookingId != null && summary.bookingId!.isNotEmpty;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeDefault,
        vertical: Dimensions.paddingSizeSmall,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summary.serviceName,
                  style: robotoMedium.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                Text(
                  '${'booking_id'.tr}: ${summary.readableId}',
                  style: robotoRegular.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                    color: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.color
                        ?.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          TextButton(
            onPressed: canViewBooking
                ? () {
                    Get.toNamed(
                      RouteHelper.getBookingDetailsScreen(
                        bookingID: summary.bookingId,
                        fromPage: 'checkout',
                      ),
                    );
                  }
                : null,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeSmall,
                vertical: Dimensions.paddingSizeExtraSmall,
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'view_details'.tr,
              style: robotoMedium.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: canViewBooking
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).disabledColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
