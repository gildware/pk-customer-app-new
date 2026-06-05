import 'package:dotted_line/dotted_line.dart';
import 'package:get/get.dart';
import 'package:demandium/util/core_export.dart';

class Voucher extends StatelessWidget {
  final bool isExpired;
  final CouponModel couponModel;
  final int index;
  final bool fromCheckout;
  final Function(CouponModel couponData)? onTap;
  const Voucher({super.key,required this.couponModel,required this.isExpired, required this.index, this.fromCheckout = false, this.onTap}) ;

  @override
  Widget build(BuildContext context) {

    return GetBuilder<CouponController>(builder: (couponController){
      return Container(
        margin: EdgeInsets.symmetric(horizontal: fromCheckout ? 0 : Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeExtraSmall),
        width: context.width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          color: Theme.of(context).cardColor,
          boxShadow: Get.find<ThemeController>().darkTheme ? null : cardShadow,
        ),
        child: Stack(children: [
          Row(children: [
            SizedBox(width: Dimensions.paddingSizeLarge),

            Container(
              height: 60, width: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).hintColor.withValues(alpha: 0.1),
              ),
              padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),

              child: Image.asset(Images.voucherImage),
            ),
            SizedBox(width: Dimensions.paddingSizeLarge),

            DottedLine(direction: Axis.vertical,dashColor: Theme.of(context).hintColor.withValues(alpha:0.1),lineThickness: 2),

            Expanded(child: Padding(
              padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Flexible(
                        child: DottedBorder(
                          options: RoundedRectDottedBorderOptions(
                            radius: const Radius.circular(Dimensions.radiusSmall),
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                            dashPattern: const [4, 3],
                            strokeWidth: 1,
                            padding: EdgeInsets.zero
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const SizedBox(width: Dimensions.paddingSizeSmall),

                            Flexible(
                              child: Text(
                                couponModel.couponCode ?? "",
                                style: robotoMedium.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: Dimensions.fontSizeDefault,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: Dimensions.paddingSizeSmall),

                            InkWell(
                              onTap:
                              fromCheckout ? (){
                                if(couponModel.isUsed != 1){
                                  onTap!(couponModel);
                                }
                              }:
                              !isExpired ? ()async {
                                couponController.updateSelectedCouponIndex(index: index);
                                if(Get.find<AuthController>().isLoggedIn()){
                                  if( Get.find<CartController>().cartList.isNotEmpty){
                                    bool addCoupon = false;
                                    for (var cart in Get.find<CartController>().cartList) {
                                      if(cart.totalCost >= (couponModel.discount?.minPurchase?.toDouble() ?? 0)) {
                                        addCoupon = true;
                                      }
                                    }
                                    if(addCoupon)  {
                                      await Get.find<CouponController>().applyCoupon(couponModel.couponCode!).then((value) async {
                                        if(value.isSuccess!){
                                          Get.find<CartController>().getCartListFromServer();
                                          if(fromCheckout){
                                            Get.back();
                                          }
                                          customCouponSnackBar("coupon_applied_successfully".tr, subtitle : "review_your_cart_for_applied_discounts".tr, isError: false);
                                        }else{
                                          customCouponSnackBar("can_not_apply_coupon", subtitle :"${value.message}");
                                        }
                                      },);
                                    }else{
                                      customCouponSnackBar("can_not_apply_coupon".tr, subtitle : "${'valid_for_minimum_booking_amount_of'.tr} ${PriceConverter.convertPrice(couponModel.discount?.minPurchase ?? 0)} ");
                                    }
                                  }else{
                                    customCouponSnackBar("oops".tr, subtitle :"looks_like_no_service_is_added_to_your_cart".tr);
                                  }
                                }else{
                                  customCouponSnackBar("sorry_you_can_not_use_coupon".tr,  subtitle :"please_login_to_use_coupon".tr );
                                }
                              } :
                              null,
                              child: Container(
                                padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                                decoration: BoxDecoration(
                                  color: isExpired || couponModel.isUsed == 1 ? Theme.of(context).disabledColor : Theme.of(context).colorScheme.primary,
                                  borderRadius: const BorderRadius.only(
                                    topRight: Radius.circular(Dimensions.radiusSmall),
                                    bottomRight: Radius.circular(Dimensions.radiusSmall),
                                  ),
                                ),
                                child: Text(
                                  isExpired ?'expired'.tr : couponModel.isUsed == 1 ? "used".tr.toUpperCase() :'use'.tr.toUpperCase(),
                                  style: robotoMedium.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeSmall),
                                ),
                              ),
                            )
                          ]),
                        ),
                      ),
                    ]),

                    const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                    RichText(
                      text: TextSpan(
                        text: "${'valid_till'.tr} : ",
                        style: robotoRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: 0.6), fontSize: Dimensions.fontSizeDefault),
                        children: [
                          TextSpan(
                            text: couponModel.discount?.endDate ?? "",
                            style: robotoBold.copyWith(color: Theme.of(context).textTheme.bodyLarge!.color, fontSize: Dimensions.fontSizeDefault),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                    Text(
                      "${'use_code'.tr} ${couponModel.couponCode!} ${'to_save_upto'.tr} ${PriceConverter.convertPrice(couponModel.discount!.discountAmountType == 'amount'? couponModel.discount!.discountAmount!.toDouble() : couponModel.discount!.maxDiscountAmount!.toDouble())} ${'on_your_next_purchase'.tr}",
                      textAlign: TextAlign.center,
                      style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
                    ),
                  ]),
            )),
          ]),

          Positioned(bottom: -15, left: 88,
            child: Container(width: 30, height : 30,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border.all(color: Theme.of(context).hintColor.withValues(alpha:0.1)),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),

          Positioned(top: -15, left: 88,
            child: Container(width: 30, height : 30,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border.all(color: Theme.of(context).hintColor.withValues(alpha:0.1)),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),

          if (couponController.isLoading && index == couponController.selectedCouponIndex && !fromCheckout)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                ),
                child: const Center(child: SizedBox(height: 25, width: 25, child: CircularProgressIndicator())),
              ),
            ),
        ]),
      );
    });
  }
}
