import 'package:get/get.dart';
import 'package:demandium/util/core_export.dart';


class CartSummery extends StatelessWidget {
  const CartSummery({super.key}) ;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CheckOutController>(builder: (checkoutController){
      return GetBuilder<ScheduleController>(builder: (scheduleController){
        return GetBuilder<CartController>(
            builder: (cartController){

              int scheduleDaysCount = scheduleController.scheduleDaysCount > 0 ? scheduleController.scheduleDaysCount : 1;

              ConfigModel configModel = Get.find<SplashController>().configModel;
              List<CartModel> cartList = cartController.cartList;
              bool walletPaymentStatus = cartController.walletPaymentStatus;
              int applicableCouponCount = CheckoutHelper.getNumberOfDaysForApplicableCoupon(pickedScheduleDays:scheduleDaysCount) ?? 1;
              final additionalChargeLines = cartController.additionalChargeLines;
              final additionalChargeTotal = cartController.additionalChargeTotal;
              final double payableBookingAmount = checkoutController.payableCheckoutAmount(cartController.totalPrice);
              bool isPartialPayment = CheckoutHelper.checkPartialPayment(walletBalance: cartController.walletBalance, bookingAmount: payableBookingAmount);
              double paidAmount = CheckoutHelper.calculatePaidAmount(walletBalance: cartController.walletBalance, bookingAmount: payableBookingAmount);
              double subTotalPrice =  CheckoutHelper.calculateSubTotal(cartList: cartList, daysCount: scheduleDaysCount);
              double disCount = CheckoutHelper.calculateDiscount(cartList: cartList, discountType: DiscountType.general, daysCount: scheduleDaysCount);
              double campaignDisCount = CheckoutHelper.calculateDiscount(cartList: cartList, discountType: DiscountType.campaign, daysCount: scheduleDaysCount);
              double couponDisCount = CheckoutHelper.calculateDiscount(cartList: cartList, discountType: DiscountType.coupon, daysCount: applicableCouponCount);
              double referDisCount = cartController.referralAmount;
              double vat =  CheckoutHelper.calculateVat(cartList: cartList, daysCount: scheduleDaysCount);
              double grandTotal = cartController.totalPrice;
              double dueAmount = CheckoutHelper.calculateDueAmount(cartList: cartList, walletPaymentStatus: walletPaymentStatus, walletBalance:cartController.walletBalance, bookingAmount: payableBookingAmount, referralDiscount: referDisCount, daysCount: scheduleDaysCount);

              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                Padding(padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault, horizontal: Dimensions.paddingSizeDefault),
                    child: Text( 'cart_summary'.tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault))
                ),

                Padding( padding: const EdgeInsets.all( Dimensions.paddingSizeDefault),
                  child: Column( children: [
                    ListView.builder(
                      itemCount: cartList.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context,index){
                        double totalCost = (cartList.elementAt(index).serviceCost.toDouble() * cartList.elementAt(index).quantity) * scheduleDaysCount;
                        return Column( mainAxisAlignment: MainAxisAlignment.start,  crossAxisAlignment: CrossAxisAlignment.start, children: [
                          RowText(
                            title: cartList.elementAt(index).service?.name ?? 'service'.tr,
                            quantity: cartList.elementAt(index).quantity,
                            price: totalCost,
                          ),
                          SizedBox( width:Get.width / 2.5,
                            child: Text( cartList.elementAt(index).variantKey,
                              style: robotoMedium.copyWith( color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: .4), fontSize: Dimensions.fontSizeSmall),
                              maxLines: 2, overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: Dimensions.paddingSizeDefault,)
                        ]);
                      },
                    ),

                    Divider(color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: .6)),
                    const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                    RowText(title: 'sub_total'.tr, price: subTotalPrice),
                    if (disCount > 0) RowText(title: 'discount'.tr, price: disCount),
                    if (campaignDisCount > 0) RowText(title: 'campaign_discount'.tr, price: campaignDisCount),
                    if (couponDisCount > 0) RowText(title: 'coupon_discount'.tr, price: couponDisCount),
                    if(referDisCount > 0)
                      RowText(title: 'referral_discount'.tr, price: referDisCount),
                    if (vat > 0) RowText(title: 'vat'.tr, price: vat),

                    if (additionalChargeLines.isNotEmpty)
                      ...additionalChargeLines.map((line) => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              line.name.isNotEmpty ? line.name : 'service_charge'.tr,
                              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            "(+) ${PriceConverter.convertPrice(line.amount, isShowLongPrice: true)}",
                            style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault),
                          ),
                        ],
                      ))
                    else if (additionalChargeTotal > 0)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              configModel.content?.additionalChargeLabelName?.isNotEmpty == true
                                  ? configModel.content!.additionalChargeLabelName!
                                  : 'service_charge'.tr,
                              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            "(+) ${PriceConverter.convertPrice(additionalChargeTotal, isShowLongPrice: true)}",
                            style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault),
                          ),
                        ],
                      )
                    else if (configModel.content?.additionalChargeLabelName != "" && configModel.content?.additionalCharge == 1)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              configModel.content?.additionalChargeLabelName ?? "",
                              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            "(+) ${PriceConverter.convertPrice(CheckoutHelper.getAdditionalCharge(), isShowLongPrice: true)}",
                            style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault),
                          ),
                        ],
                      ),

                    Padding( padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
                      child: Divider(color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: .6)),
                    ),

                    RowText(title:'grand_total'.tr , price: grandTotal),
                    (Get.find<CartController>().walletPaymentStatus) ? RowText(title:'paid_by_wallet'.tr , price: paidAmount) : const SizedBox(),
                    (Get.find<CartController>().walletPaymentStatus && isPartialPayment) ? RowText(title:'due_amount'.tr , price: dueAmount) : const SizedBox(),
                  ]),
                ),

                Padding(padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeSmall),
                  child: ConditionCheckBox(
                    checkBoxValue: checkoutController.acceptTerms,
                    onTap: (bool? value){
                      checkoutController.toggleTerms();
                    },
                  ),
                ),

              ]);
            }
        );
      });
    });
  }
}
