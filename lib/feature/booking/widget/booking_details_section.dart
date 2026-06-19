import 'package:demandium/feature/booking/widget/booking_otp_widget.dart';
import 'package:demandium/feature/booking/widget/booking_photo_evidence.dart';
import 'package:demandium/feature/booking/widget/booking_service_location.dart';
import 'package:get/get.dart';
import 'package:demandium/util/core_export.dart';
import 'package:demandium/feature/booking/widget/regular/booking_summery_widget.dart';
import 'package:demandium/feature/booking/widget/regular/disputed_settlement_widget.dart';
import 'package:demandium/feature/booking/widget/regular/special_financial_settlement_widget.dart';
import 'package:demandium/feature/booking/widget/provider_info.dart';
import 'package:demandium/feature/booking/widget/service_man_info.dart';
import 'booking_screen_shimmer.dart';

class BookingDetailsSection extends StatelessWidget {
  final String? id;
  final bool isSubBooking;
  const BookingDetailsSection({super.key, this.id, required this.isSubBooking}) ;
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        if(id != null){
          if(isSubBooking) {
            await Get.find<BookingDetailsController>().getSubBookingDetails(bookingId: id!);
          } else {
            await Get.find<BookingDetailsController>().getBookingDetails(bookingId: id!);
          }
        }
      },
      child: Scaffold(
        body: GetBuilder<BookingDetailsController>( builder: (bookingDetailsTabController) {
          BookingDetailsContent? bookingDetails = isSubBooking ?  bookingDetailsTabController.subBookingDetailsContent : bookingDetailsTabController.bookingDetailsContent;
          if(bookingDetails != null){
            String bookingStatus = bookingDetails.bookingStatus ?? "";
            bool isLoggedIn = Get.find<AuthController>().isLoggedIn();

            return SingleChildScrollView( physics: const AlwaysScrollableScrollPhysics(), child: Center(
              child: Padding( padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [

                  const SizedBox(height: Dimensions.paddingSizeDefault),
                  if (BookingHelper.hasDisputedSettlement(bookingDetails)) ...[
                    if (bookingDetails.disputedSettlement?.hasDisputedSettlement == true)
                      DisputedSettlementWidget(settlement: bookingDetails.disputedSettlement!)
                    else
                      DisputedSettlementWidget(
                        settlement: DisputedSettlement(
                          hasDisputedSettlement: true,
                          customerPaidTotal: BookingHelper.resolveDisputedCustomerPaidTotal(bookingDetails),
                          refundTotal: BookingHelper.resolveDisputedRefundTotal(bookingDetails),
                          finalBookingAmount: BookingHelper.resolveDisputedFinalBookingAmount(bookingDetails),
                          retainedFromCustomer: BookingHelper.resolveDisputedFinalBookingAmount(bookingDetails),
                          isPartialRefund: (BookingHelper.resolveDisputedRefundTotal(bookingDetails) ?? 0) > 0.009
                              && (BookingHelper.resolveDisputedFinalBookingAmount(bookingDetails) ?? 0) > 0.009,
                          isFullRefund: (BookingHelper.resolveDisputedRefundTotal(bookingDetails) ?? 0) > 0.009
                              && (BookingHelper.resolveDisputedFinalBookingAmount(bookingDetails) ?? 0) <= 0.009,
                        ),
                      ),
                    const SizedBox(height: Dimensions.paddingSizeLarge),
                  ] else if (bookingDetails.specialFinancialSettlement?.hasSpecialSettlement == true) ...[
                    SpecialFinancialSettlementWidget(settlement: bookingDetails.specialFinancialSettlement!),
                    const SizedBox(height: Dimensions.paddingSizeLarge),
                  ],
                  BookingInfo(bookingDetails: bookingDetails, bookingDetailsTabController: bookingDetailsTabController, isSubBooking: isSubBooking,),

                  ((Get.find<SplashController>().configModel.content?.confirmationOtpStatus ?? false) && (bookingStatus == "accepted" || bookingStatus== "ongoing")) ?
                  Padding(
                    padding: const EdgeInsets.only(top: Dimensions.paddingSizeDefault),
                    child: BookingOtpWidget(bookingDetails: bookingDetails),
                  ) : const SizedBox(height: Dimensions.paddingSizeDefault,),

                  const SizedBox(height: Dimensions.paddingSizeLarge),
                  BookingServiceLocation(bookingDetails: bookingDetails),

                  const SizedBox(height: Dimensions.paddingSizeLarge),
                  BookingSummeryWidget(bookingDetails: bookingDetails),

                  const SizedBox(height: Dimensions.paddingSizeLarge),
                  bookingDetails.provider != null ? ProviderInfo(provider: bookingDetails.provider!) : const SizedBox(),
                  const SizedBox(height: Dimensions.paddingSizeSmall),

                  bookingDetails.serviceman != null ? ServiceManInfo(user: bookingDetails.serviceman!.user!) : const SizedBox(),
                  const SizedBox(height: Dimensions.paddingSizeDefault),

                  bookingDetails.photoEvidenceFullPath != null && bookingDetails.photoEvidenceFullPath!.isNotEmpty ?
                  BookingPhotoEvidence(bookingDetailsContent: bookingDetails): const SizedBox(),

                  SizedBox(height: bookingStatus == "completed" && isLoggedIn ? Dimensions.paddingSizeExtraLarge * 3 : Dimensions.paddingSizeExtraLarge ),

                ]),
              ),
            ),
            );
          }else{
            return const SingleChildScrollView(child: BookingScreenShimmer());
          }
        }),

        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton:
        GetBuilder<BookingDetailsController>(builder: (bookingDetailsController){
          if(bookingDetailsController.bookingDetailsContent != null){
            return Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              const Expanded(child: SizedBox()),
              Padding(padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault, left: Dimensions.paddingSizeDefault, right: Dimensions.paddingSizeDefault,),
                child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [

                  Get.find<AuthController>().isLoggedIn() && (bookingDetailsController.bookingDetailsContent!.bookingStatus == 'accepted'
                      || bookingDetailsController.bookingDetailsContent!.bookingStatus == 'ongoing') ?
                  FloatingActionButton( hoverColor: Colors.transparent, elevation: 0.0,
                    backgroundColor: Theme.of(context).colorScheme.primary, onPressed: () {
                      BookingDetailsContent bookingDetailsContent = bookingDetailsController.bookingDetailsContent!;

                      if (bookingDetailsContent.provider != null ) {
                        showModalBottomSheet( useRootNavigator: true, isScrollControlled: true,
                          backgroundColor: Colors.transparent, context: context, builder: (context) => CreateChannelDialog(
                           isSubBooking: isSubBooking,
                          ),
                        );
                      } else {
                        customSnackBar('provider_or_service_man_assigned'.tr, type: ToasterMessageType.info);
                      }
                    },
                    child: Icon(Icons.message_rounded, color: Theme.of(context).primaryColorLight),
                  ) : const SizedBox(),
                ]),
              ),

              bookingDetailsController.bookingDetailsContent!.bookingStatus == 'completed'
                  && BookingHelper.canLeaveReview(bookingDetailsController.bookingDetailsContent!) ?
              Padding(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                child: Get.find<AuthController>().isLoggedIn() ?
                CustomButton (radius: 5, buttonText: 'review'.tr, onPressed: () {
                  showModalBottomSheet(context: context,
                    useRootNavigator: true, isScrollControlled: true,
                    backgroundColor: Colors.transparent, builder: (context) => ReviewRecommendationDialog(
                      id: bookingDetailsController.bookingDetailsContent!.id!,
                    ),
                  );},
                ) : const SizedBox(),
              )
              : const SizedBox()

            ]);
          }else{
            return const SizedBox();
          }
        }),
      ),
    );
  }
}
