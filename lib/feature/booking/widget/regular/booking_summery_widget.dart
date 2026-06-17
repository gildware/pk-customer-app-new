import 'package:demandium/helper/booking_helper.dart';
import 'package:get/get.dart';
import 'package:demandium/util/core_export.dart';

class BookingSummeryWidget extends StatelessWidget{
  final BookingDetailsContent bookingDetails;
  const BookingSummeryWidget({super.key, required this.bookingDetails}) ;

  @override
  Widget build(BuildContext context){
    double totalBookingAmount = bookingDetails.payableGrandTotal
        ?? bookingDetails.paymentDetails?.total
        ?? bookingDetails.totalBookingAmount
        ?? 0;
    double additionalCharge = bookingDetails.additionalCharge ?? 0;

    return Container(
      decoration: BoxDecoration(color: Theme.of(context).cardColor , borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          boxShadow: Get.find<ThemeController>().darkTheme ? null : searchBoxShadow
      ),
      child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [

        Gaps.verticalGapOf(Dimensions.paddingSizeSmall),
        Padding(padding: ResponsiveHelper.isDesktop(context) ? const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge) : const EdgeInsets.symmetric(horizontal:Dimensions.paddingSizeDefault),
            child: Text( 'booking_summery'.tr,
                style:robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).textTheme.bodyLarge!.color))
        ),
        Gaps.verticalGapOf(Dimensions.paddingSizeSmall),

        Container(
          padding: ResponsiveHelper.isDesktop(context) ? const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge) : const EdgeInsets.symmetric(horizontal:Dimensions.paddingSizeDefault),
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.07),
          child: SizedBox(
            height: 40,
            child:  Row( mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('service_info'.tr, style:robotoBold.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: Theme.of(context).textTheme.bodyLarge!.color!,decoration: TextDecoration.none,
              )),
              Text('price'.tr,style:robotoBold.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: Theme.of(context).textTheme.bodyLarge!.color!,decoration: TextDecoration.none,
              )),
            ]),
          ),
        ),

        Padding(
          padding:  ResponsiveHelper.isDesktop(context) ?  const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall) :  EdgeInsets.zero,
          child: Column(children: [
            ListView.builder(itemBuilder: (context, index){
              return _ServiceInfoItem(
                bookingService : bookingDetails.bookingDetails?[index],
                index: index,
              );
            },
              itemCount: bookingDetails.bookingDetails?.length,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              shrinkWrap: true,
            ),

            if (bookingDetails.extraServiceLines != null)
              ...bookingDetails.extraServiceLines!
                  .where((line) => (line.total ?? line.amount ?? 0) > 0)
                  .map((line) => _ExtraServiceInfoItem(line: line)),

            Gaps.verticalGapOf(Dimensions.paddingSizeSmall),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
              child: Divider(height: 2, color: Colors.grey,),
            ),
            Gaps.verticalGapOf(Dimensions.paddingSizeSmall),

            _AdminAlignedSummaryBreakdown(bookingDetails: bookingDetails),

            if(bookingDetails.additionalCharge != null && additionalCharge < 0 && (bookingDetails.paymentMethod != "cash_after_service" || (bookingDetails.partialPayments?.isNotEmpty ?? false) ))
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("refund".tr,style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall,
                        color: Theme.of(context).textTheme.bodyLarge?.color),overflow: TextOverflow.ellipsis,
                    ),
                    Text(PriceConverter.convertPrice(additionalCharge, isShowLongPrice:true),
                      style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall,
                          color: Theme.of(context).textTheme.bodyLarge!.color
                      ),
                    ),
                  ],
                ),
              ),

            Gaps.verticalGapOf(Dimensions.paddingSizeSmall),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
              child: Divider(height: 2, color: Colors.grey,),
            ),
            Gaps.verticalGapOf(Dimensions.paddingSizeExtraSmall),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('grand_total'.tr,
                  style: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: Get.isDarkMode ? Theme.of(context).textTheme.bodyLarge?.color : Theme.of(context).colorScheme.primary),
                  overflow: TextOverflow.ellipsis,
                ),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    PriceConverter.convertPrice(totalBookingAmount, isShowLongPrice: true),
                    style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: Get.isDarkMode ? Theme.of(context).textTheme.bodyLarge?.color : Theme.of(context).colorScheme.primary),),
                ),
              ]),
            ),

            _BookingPaidDueSummaryRows(bookingDetails: bookingDetails),
            ],
          ),
        ),




        const SizedBox(height: Dimensions.paddingSizeExtraLarge),
      ],
      ),
    );
  }
}


class _AdminAlignedSummaryBreakdown extends StatelessWidget {
  final BookingDetailsContent bookingDetails;

  const _AdminAlignedSummaryBreakdown({required this.bookingDetails});

  @override
  Widget build(BuildContext context) {
    final summary = bookingDetails.bookingSummary;
    if (summary == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        _SummaryAmountRow(
          title: 'sub_total'.tr,
          amount: BookingHelper.getDiscountedSubTotal(bookingDetails),
          isBold: true,
        ),
        ...?_namedLines(summary.additionalChargeLines),
        if (summary.hasTax == true && (summary.tax ?? 0) > 0)
          _SummaryAmountRow(
            title: 'service_vat'.tr,
            amount: summary.tax ?? 0,
            prefix: '(+) ',
          ),
      ],
    );
  }

  List<Widget>? _namedLines(List<BookingSummaryLine>? lines) {
    if (lines == null || lines.isEmpty) {
      return null;
    }
    return lines
        .where((line) => (line.amount ?? 0) > 0)
        .map((line) => _SummaryAmountRow(
              title: BookingHelper.additionalChargeLineLabel(line),
              amount: line.amount ?? 0,
              prefix: '(+) ',
            ))
        .toList();
  }
}

class _SummaryAmountRow extends StatelessWidget {
  final String title;
  final double amount;
  final String prefix;
  final bool isBold;

  const _SummaryAmountRow({
    required this.title,
    required this.amount,
    this.prefix = '',
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: Dimensions.paddingSizeDefault,
        right: Dimensions.paddingSizeDefault,
        top: Dimensions.paddingSizeSmall,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: (isBold ? robotoBold : robotoRegular).copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              '$prefix${PriceConverter.convertPrice(amount, isShowLongPrice: true)}',
              style: (isBold ? robotoBold : robotoRegular).copyWith(
                fontSize: isBold ? Dimensions.fontSizeDefault : Dimensions.fontSizeSmall,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingPaidDueSummaryRows extends StatelessWidget {
  final BookingDetailsContent bookingDetails;

  const _BookingPaidDueSummaryRows({required this.bookingDetails});

  @override
  Widget build(BuildContext context) {
    final summary = bookingDetails.bookingSummary;
    final dueAmount = summary?.dueAmount ?? bookingDetails.paymentDetails?.dueBalance ?? 0;

    if (dueAmount <= 0) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        if (dueAmount > 0)
          Padding(
            padding: const EdgeInsets.only(
              left: Dimensions.paddingSizeDefault,
              right: Dimensions.paddingSizeDefault,
              top: Dimensions.paddingSizeSmall,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'due_amount'.tr,
                  style: robotoMedium.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    PriceConverter.convertPrice(dueAmount, isShowLongPrice: true),
                    style: robotoMedium.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 1),
          decoration: BoxDecoration(
            color: tagColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
          ),
          child: Text((isSpare ? 'spare_part' : 'service').tr,
            style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: tagColor),
          ),
        ),
        if (line.details != null && line.details!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: Dimensions.paddingSizeExtraSmall),
            child: Text(line.details!,
              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall,
                  color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7)),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: Dimensions.paddingSizeExtraSmall),
          child: Row(children: [
            Text("${"unit_price".tr} : ",
              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall,
                  color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7)),
            ),
            Text(PriceConverter.convertPrice(unitPrice, isShowLongPrice: true),
              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall,
                  color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7)),
            ),
            Container(
              height: 10, width: 0.5,
              color: Theme.of(context).hintColor,
              margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
            ),
            Text("${"qty".tr} : ${qty.toInt()}",
              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall,
                  color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7)),
            ),
          ]),
        ),
        if ((line.discount ?? 0) > 0)
          _ServiceItemText(title: "discount".tr, amount: line.discount!, prefix: '(-) '),
      ]),
    );
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

  final ItemService? bookingService;
  const _ServiceInfoItem({
    required this.bookingService,
    required this.index
  });
  @override
  Widget build(BuildContext context) {

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

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
          Padding(padding: const EdgeInsets.only( bottom: Dimensions.paddingSizeExtraSmall),
            child: Row(children: [

              Text(bookingService?.variantKey?.replaceAll("-", " ").capitalizeFirst ?? "",
                style: robotoRegular.copyWith(
                    fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7)
                ),
              ),

              Container(
                height: 10, width: 0.5,
                color: Theme.of(context).hintColor,
                margin : const EdgeInsets.only(left : Dimensions.paddingSizeSmall, right:  Dimensions.paddingSizeSmall, top: 5),
              ),

              Row(children: [
                Text("${"qty".tr} : ${bookingService?.quantity}",
                  style: robotoRegular.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                    color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                  ),
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
      ]),
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
            style: robotoRegular.copyWith(
                fontSize: Dimensions.fontSizeSmall,color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7)
            ),
          ),
          Text('$prefix${PriceConverter.convertPrice(amount,isShowLongPrice:true)}',
            style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall,color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7)),
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
