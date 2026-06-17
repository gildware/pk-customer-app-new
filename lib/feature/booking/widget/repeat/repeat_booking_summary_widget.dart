import 'package:demandium/helper/booking_helper.dart';
import 'package:demandium/feature/booking/widget/repeat/repeat_booking_edit_history_widget.dart';
import 'package:demandium/util/core_export.dart';
import 'package:get/get.dart';

class RepeatBookingSummeryWidget extends StatelessWidget{
  final BookingDetailsContent bookingDetails;
  const RepeatBookingSummeryWidget({super.key, required this.bookingDetails});

  @override
  Widget build(BuildContext context){
    return GetBuilder<BookingDetailsController>(builder:(bookingDetailsController){

      bool isEdited = bookingDetails.repeatEditHistory !=null && bookingDetails.repeatEditHistory!.isNotEmpty;

      double totalDiscount =  ((bookingDetails.totalDiscountAmount ?? 0) + (bookingDetails.totalCampaignDiscountAmount ?? 0));
      double totalCouponDiscount = bookingDetails.totalCouponDiscountAmount ?? 0;
      double taxAmount =  bookingDetails.totalTaxAmount ?? 0;
      double referralDiscountAmount = bookingDetails.totalReferralDiscountAmount ?? 0;
      double extraFee = bookingDetails.extraFee ?? 0;
      double totalBookingAmount = bookingDetails.totalBookingAmount ?? 0;

      double initialSubTotal = BookingHelper.getDiscountedSubTotal(bookingDetails) * ((bookingDetails.totalCount ?? 1));
      double updatedSubTotal = (totalBookingAmount + totalDiscount + totalCouponDiscount + referralDiscountAmount) - (extraFee + taxAmount);

      double paidAmount = BookingHelper.getRepeatBookingPaidAmount(bookingDetails);
      double canceledAmount = BookingHelper.getRepeatBookingCanceledAmount(bookingDetails);
      int paidBookingCount = BookingHelper.getRepeatPaidBookingCount(bookingDetails);
      int canceledBookingCount = BookingHelper.getRepeatCanceledBookingCount(bookingDetails);
      double dueAmount = (totalBookingAmount - paidAmount - canceledAmount);


      return Container(
        decoration: BoxDecoration(color: Theme.of(context).cardColor , borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            boxShadow: Get.find<ThemeController>().darkTheme ? null : searchBoxShadow
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          const SizedBox(height: Dimensions.paddingSizeDefault,),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
            child: Text("billing_summary".tr,
              style:robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge,
                color: Theme.of(context).textTheme.bodyLarge!.color?.withValues(alpha: 0.9),
              ),
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),

          Container(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
            height: 40,
            child:  Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("service_info".tr, style:robotoBold.copyWith(
                    fontSize: Dimensions.fontSizeLarge ,
                    color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: 0.8), decoration: TextDecoration.none)
                ),
                Text("price".tr,style:robotoBold.copyWith(
                    fontSize: Dimensions.fontSizeLarge,
                    color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: 0.8),decoration: TextDecoration.none)
                ),
              ],
            ),
          ),

          const SizedBox(height: Dimensions.paddingSizeExtraSmall,),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Column(children: [
              ListView.builder(
                itemCount: bookingDetails.bookingDetails?.length,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemBuilder: (context,index){
                  return _ServiceInfoItem(
                    bookingService : bookingDetails.bookingDetails?[index],
                    bookingDetailsController: bookingDetailsController,
                    index: index,
                  );},
              ),

              if (bookingDetails.extraServiceLines != null)
                ...bookingDetails.extraServiceLines!
                    .where((line) => (line.total ?? line.amount ?? 0) > 0)
                    .map((line) => _ExtraServiceInfoItem(line: line)),

              const Padding(
                padding: EdgeInsets.symmetric( vertical: Dimensions.paddingSizeSmall),
                child: Divider(height: 1, color: Colors.grey, thickness: 0.5,),
              ),

              _SubTotalItemWidget(
                title: isEdited ? "${'initial_sub_total'.tr}  (${bookingDetails.totalCount ?? ""} ${'days'.tr})" : "${'sub_total'.tr}  (${bookingDetails.totalCount ?? ""} ${'days'.tr})",
                amount: initialSubTotal,
                additionalSign: "",
                subTitle: "",
              ),

              if(isEdited) Padding(
                padding: const EdgeInsets.only(top : Dimensions.paddingSizeExtraSmall),
                child: _SubTotalItemWidget(
                  title: "updated_sub_total".tr,
                  amount: updatedSubTotal,
                  additionalSign: "",
                  subTitle: "view_details",
                ),
              ),

              ...BookingHelper.getAdditionalChargeLines(bookingDetails).map((line) => Padding(
                padding: const EdgeInsets.only(top: Dimensions.paddingSizeExtraSmall),
                child: _SubTotalItemWidget(
                  title: BookingHelper.additionalChargeLineLabel(line),
                  amount: line.amount ?? 0,
                  additionalSign: "+",
                  subTitle: "",
                  translateTitle: false,
                ),
              )),

              if (taxAmount > 0) ...[
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                _SubTotalItemWidget(
                  title:  "service_vat",
                  amount: taxAmount,
                  additionalSign: "+",
                  subTitle: "",
                ),
              ],

              const SizedBox(height : Dimensions.paddingSizeSmall),
              const Divider(height: 1, color: Colors.grey, thickness: 0.5,),
              const SizedBox( height:Dimensions.paddingSizeExtraSmall),

              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('grand_total'.tr,
                  style: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).colorScheme.primary),
                  overflow: TextOverflow.ellipsis,
                ),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    PriceConverter.convertPrice( totalBookingAmount,isShowLongPrice: true),
                    style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).colorScheme.primary),),
                ),
              ],),

              if(paidAmount > 0) const SizedBox(height: Dimensions.paddingSizeExtraSmall),

              if(paidAmount > 0) _SubTotalItemWidget(
                title:  "${'paid'.tr} (${'for'.tr} $paidBookingCount ${'bookings'.tr})",
                amount: paidAmount,
                additionalSign: "",
                subTitle: "",
              ),
              if(paidAmount > 0 || canceledAmount > 0) const SizedBox(height: Dimensions.paddingSizeExtraSmall),

              if(canceledAmount> 0)_SubTotalItemWidget(
                title:   "${'canceled_amount'.tr} ($canceledBookingCount ${'bookings'.tr})",
                amount: canceledAmount,
                additionalSign: "-",
                subTitle: "",
              ),
              if(canceledBookingCount > 0) const SizedBox(height: Dimensions.paddingSizeExtraSmall),

              if(paidAmount > 0 && dueAmount > 0) _SubTotalItemWidget(
                title:  "due_amount",
                amount: dueAmount,
                additionalSign: "",
                subTitle: "",
              ),


              const SizedBox(height: Dimensions.paddingSizeSmall,),
            ]),
          )
        ]),
      );
    },
    );
  }
}


class _ExtraServiceInfoItem extends StatelessWidget {
  final BookingExtraServiceLine line;
  const _ExtraServiceInfoItem({required this.line});

  @override
  Widget build(BuildContext context) {
    final bool isSpare = line.isSparePart;
    final Color tagColor = isSpare ? Colors.blue : Theme.of(context).colorScheme.primary;
    final double qty = BookingHelper.getExtraServiceLineQuantity(line);
    final double unitPrice = (line.price != null && line.price! > 0)
        ? line.price!
        : (BookingHelper.getExtraServiceLineSubtotal(line) / qty);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: Dimensions.paddingSizeSmall),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(
          child: Text(line.name ?? "",
            style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault,
                color: Theme.of(context).textTheme.bodyLarge!.color?.withValues(alpha: 0.9)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: Dimensions.paddingSizeDefault),
        _BookingExtraServicePriceColumn(line: line),
      ]),
      const SizedBox(height: Dimensions.paddingSizeExtraSmall),
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 1),
          decoration: BoxDecoration(
            color: tagColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
          ),
          child: Text((isSpare ? 'spare_part' : 'service').tr,
            style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: tagColor),
          ),
        ),
      ),
      if (line.details != null && line.details!.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: Dimensions.paddingSizeExtraSmall),
          child: Text(line.details!,
            style: robotoLight.copyWith(fontSize: Dimensions.fontSizeSmall)),
        ),
      Padding(
        padding: const EdgeInsets.only(top: Dimensions.paddingSizeExtraSmall),
        child: Row(children: [
          Text("${"unit_price".tr} : ", style: robotoLight.copyWith(fontSize: Dimensions.fontSizeSmall)),
          Text(PriceConverter.convertPrice(unitPrice, isShowLongPrice: true),
            style: robotoLight.copyWith(fontSize: Dimensions.fontSizeSmall)),
          Container(
            height: 10, width: 0.5,
            color: Theme.of(context).hintColor,
            margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
          ),
          Text("${"qty".tr} : ${qty.toInt()}", style: robotoLight.copyWith(fontSize: Dimensions.fontSizeSmall)),
        ]),
      ),
      if ((line.discount ?? 0) > 0)
        _ServiceItemText(title: "discount".tr, amount: line.discount!, prefix: '(-) '),
    ]);
  }
}

class _BookingExtraServicePriceColumn extends StatelessWidget {
  final BookingExtraServiceLine line;

  const _BookingExtraServicePriceColumn({required this.line});

  @override
  Widget build(BuildContext context) {
    final originalPrice = BookingHelper.getExtraServiceLineSubtotal(line);
    final discountedPrice = BookingHelper.getExtraServiceLineDiscountedTotal(line);
    final hasDiscount = BookingHelper.extraServiceLineHasDiscount(line);
    final defaultStyle = robotoRegular.copyWith(
      fontSize: Dimensions.fontSizeDefault,
      color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.9),
    );

    if (!hasDiscount || originalPrice <= discountedPrice) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Text(
          PriceConverter.convertPrice(originalPrice, isShowLongPrice: true),
          style: defaultStyle,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Directionality(
          textDirection: TextDirection.ltr,
          child: Text(
            PriceConverter.convertPrice(originalPrice, isShowLongPrice: true),
            style: defaultStyle.copyWith(
              fontSize: Dimensions.fontSizeSmall,
              decoration: TextDecoration.lineThrough,
              color: Theme.of(context).hintColor,
            ),
          ),
        ),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Text(
            PriceConverter.convertPrice(discountedPrice, isShowLongPrice: true),
            style: defaultStyle,
          ),
        ),
      ],
    );
  }
}

class _ServiceInfoItem extends StatelessWidget {
  final int index;
  final BookingDetailsController bookingDetailsController;
  final ItemService? bookingService;
  const _ServiceInfoItem({
    required this.bookingService,
    required this.bookingDetailsController,
    required this.index
  });
  @override
  Widget build(BuildContext context) {

    BookingDetailsContent? bookingDetails = bookingDetailsController.bookingDetailsContent;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      const SizedBox(height:Dimensions.paddingSizeSmall),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(
          child: Text(bookingService?.serviceName??"",
            style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault,
                color: Theme.of(context).textTheme.bodyLarge!.color?.withValues(alpha: 0.9)
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: Dimensions.paddingSizeDefault,),
        _BookingServicePriceColumn(bookingService: bookingService),
      ],
      ),
      const SizedBox(height: Dimensions.paddingSizeExtraSmall-2,),
      if(bookingService?.variantKey!=null)
        Padding(padding: const EdgeInsets.only( bottom: Dimensions.paddingSizeTine),
          child: Row( crossAxisAlignment: CrossAxisAlignment.center, children: [
            Text(bookingService?.variantKey?.replaceAll("-", " ").capitalizeFirst ?? "",
              style: robotoLight.copyWith(fontSize: Dimensions.fontSizeSmall,),
            ),
            Container(
              height: 10, width: 0.5,
              color: Theme.of(context).hintColor,
              margin : const EdgeInsets.only(left : Dimensions.paddingSizeSmall, right:  Dimensions.paddingSizeSmall, top: 5),
            ),
            Row(children: [
              Text("${"qty".tr} : ${bookingService?.quantity}",
                style: robotoLight.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                ),
              ),
              const SizedBox(width: Dimensions.paddingSizeExtraSmall),

              if(bookingDetails?.repeatEditHistory!=null && bookingDetails!.repeatEditHistory!.isNotEmpty ) InkWell(
                onTap: (){
                  showDialog(context: context, builder: (ctx) => const RepeatBookingEditHistoryDialog());
                },
                child: Text('(${'updated'.tr})',  style: robotoRegular.copyWith(color: Theme.of(context).colorScheme.primary, decoration: TextDecoration.underline,
                  decorationColor: Theme.of(context).colorScheme.primary, decorationThickness:  0.5, fontSize: Dimensions.fontSizeSmall,
                )),
              ),
            ]),
          ]),
        ),


      _ServiceItemText(title: "unit_price".tr, amount :bookingService?.serviceCost ?? 0, ),

      if ((bookingService?.discountAmount ?? 0) > 0)
        _ServiceItemText(title: "discount".tr, amount: bookingService!.discountAmount!, prefix: '(-) '),
      if ((bookingService?.campaignDiscountAmount ?? 0) > 0)
        _ServiceItemText(title: "campaign".tr, amount: bookingService!.campaignDiscountAmount!, prefix: '(-) '),
      if ((bookingService?.overallCouponDiscountAmount ?? 0) > 0)
        _ServiceItemText(title: "coupon".tr, amount: bookingService!.overallCouponDiscountAmount!, prefix: '(-) '),
    ]);
  }
}

class _SubTotalItemWidget extends StatelessWidget {
  final String title;
  final String subTitle;
  final double amount;
  final String additionalSign;
  final bool translateTitle;
  const _SubTotalItemWidget({
    required this.title,
    required this.amount,
    required this.additionalSign,
    required this.subTitle,
    this.translateTitle = true,
  });

  @override
  Widget build(BuildContext context) {

    return Row(
      children: [
        Expanded(
          child: Row(children: [
            Text(translateTitle ? title.tr : title,style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault - 1,
              color: Theme.of(context).textTheme.bodyLarge!.color?.withValues(alpha: 0.7),
            ),overflow: TextOverflow.ellipsis,),
            const SizedBox(width: Dimensions.paddingSizeExtraSmall,),

            if(subTitle != "") InkWell(
              onTap: (){
                showDialog(context: context, builder: (ctx) => const RepeatBookingEditHistoryDialog());
              },
              child: Text('(${'view_details'.tr})',  style: robotoRegular.copyWith(color: Theme.of(context).colorScheme.primary, decoration: TextDecoration.underline,
                decorationColor: Theme.of(context).colorScheme.primary, decorationThickness:  0.5, fontSize: Dimensions.fontSizeSmall,
              )),
            ),
          ]),
        ),
        const SizedBox(width: Dimensions.paddingSizeDefault,),
        Text("${additionalSign != "" ? "($additionalSign)" : ""} ${PriceConverter.convertPrice(amount,isShowLongPrice:true)}",
          style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault,
              color: Theme.of(context).textTheme.bodyLarge!.color?.withValues(alpha: 0.7)
          ),
        ),
      ],
    );
  }
}



class _ServiceItemText extends StatelessWidget {
  final String title;
  final double amount;
  final String prefix;

  const _ServiceItemText({
    required this.title,
    required this.amount,
    this.prefix = '',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeExtraSmall),
      child: Row(
        children: [
          Text("$title : ",
            style: robotoLight.copyWith(fontSize: Dimensions.fontSizeSmall),
          ),
          Text('$prefix${PriceConverter.convertPrice(amount,isShowLongPrice:true)}',
            style: robotoLight.copyWith(fontSize: Dimensions.fontSizeSmall),
          ),
        ],
      ),
    );
  }
}

class _BookingServicePriceColumn extends StatelessWidget {
  final ItemService? bookingService;

  const _BookingServicePriceColumn({required this.bookingService});

  @override
  Widget build(BuildContext context) {
    final originalPrice = BookingHelper.getBookingServiceLineSubtotal(bookingService);
    final discountedPrice = BookingHelper.getBookingServiceDiscountedTotal(bookingService);
    final hasDiscount = BookingHelper.bookingServiceHasDiscount(bookingService);
    final defaultStyle = robotoRegular.copyWith(
      fontSize: Dimensions.fontSizeDefault,
      color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.9),
    );

    if (!hasDiscount || originalPrice <= discountedPrice) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Text(
          PriceConverter.convertPrice(originalPrice, isShowLongPrice: true),
          style: defaultStyle,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Directionality(
          textDirection: TextDirection.ltr,
          child: Text(
            PriceConverter.convertPrice(originalPrice, isShowLongPrice: true),
            style: defaultStyle.copyWith(
              fontSize: Dimensions.fontSizeSmall,
              decoration: TextDecoration.lineThrough,
              color: Theme.of(context).hintColor,
            ),
          ),
        ),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Text(
            PriceConverter.convertPrice(discountedPrice, isShowLongPrice: true),
            style: defaultStyle,
          ),
        ),
      ],
    );
  }
}