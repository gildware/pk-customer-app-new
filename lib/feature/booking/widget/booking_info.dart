import 'package:demandium/common/widgets/booking_status_tags_widget.dart';
import 'package:get/get.dart';
import 'package:demandium/util/core_export.dart';

class BookingInfo extends StatelessWidget {
  final BookingDetailsContent bookingDetails;
  final bool isSubBooking;
  final BookingDetailsController bookingDetailsTabController;
  const BookingInfo({super.key, required this.bookingDetails, required this.bookingDetailsTabController, required this.isSubBooking}) ;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Theme.of(context).cardColor , borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        boxShadow: Get.find<ThemeController>().darkTheme ? null : searchBoxShadow,
      ),
      child: Padding(padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  '${'booking'.tr} #${bookingDetails.readableId}',
                  maxLines: 1,
                  softWrap: false,
                  style: robotoMedium.copyWith(
                    fontSize: Dimensions.fontSizeLarge,
                    color: Theme.of(context).textTheme.bodyLarge!.color,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              if (bookingDetails.bookingStatus != null ||
                  (bookingDetails.statusUi?.displayKey?.isNotEmpty ?? false)) ...[
                const SizedBox(width: Dimensions.paddingSizeSmall),
                BookingStatusBadge(
                  rawStatus: bookingDetails.bookingStatus,
                  displayKey: bookingDetails.statusUi?.displayKey,
                  badgeVariant: bookingDetails.statusUi?.badgeVariant,
                ),
              ],
            ],
          ),
          if (bookingDetails.statusUi?.tags.isNotEmpty ?? false) ...[
            const SizedBox(height: Dimensions.paddingSizeSmall),
            BookingStatusTagsScrollRow(tags: bookingDetails.statusUi!.tags),
          ],
          const SizedBox(height: Dimensions.paddingSizeSmall),
          if (bookingDetails.createdAt != null)
            BookingItem(
              img: Images.calendar1,
              title: "${'booking_date'.tr} : ",
              date: DateConverter.dateMonthYearTimeTwentyFourFormat(
                DateConverter.isoUtcStringToLocalDate(bookingDetails.createdAt!),
              ),
            ),


          Gaps.verticalGapOf(Dimensions.paddingSizeExtraSmall),
          if (bookingDetails.serviceSchedule != null)
            BookingItem(
              img: Images.calendar1,
              title: "${'service_schedule_date'.tr} : ",
              date: DateConverter.scheduleStringToDisplay(bookingDetails.serviceSchedule),
            ),

           // Center(
           //   child: InkWell(
           //     onTap: () async{
           //       Get.dialog(const CustomLoader());
           //       String languageCode = Get.find<LocalizationController>().locale.languageCode;
           //       String uri = "${AppConstants.baseUrl}${
           //           isSubBooking ? AppConstants.singleRepeatBookingInvoiceUrl : AppConstants.regularBookingInvoiceUrl}${bookingDetails.id}/$languageCode";
           //       if (kDebugMode) {
           //         print("Uri : $uri");
           //       }
           //       await _launchUrl(Uri.parse(uri));
           //       Get.back();
           //
           //     },
           //     child: Row( mainAxisSize: MainAxisSize.min, children: [
           //         Text('download'.tr,
           //           style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge,
           //               color: Theme.of(context).colorScheme.primary, decoration: TextDecoration.none),
           //         ),
           //         Gaps.horizontalGapOf(Dimensions.paddingSizeSmall),
           //
           //         SizedBox( height: 20, width: 20, child: Image.asset(Images.downloadImage)),
           //       ],
           //     ),
           //   ),
           // ),
           //
           // Gaps.verticalGapOf(Dimensions.paddingSizeExtraSmall),
        ]),
      ),
    );
  }

  // Future<void> _launchUrl(Uri url) async {
  //   if (!await launchUrl(url)) {
  //     throw 'Could not launch $url';
  //   }
  // }
}
