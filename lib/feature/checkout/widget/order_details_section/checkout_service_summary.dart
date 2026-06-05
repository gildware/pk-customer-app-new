import 'package:demandium/feature/checkout/widget/order_details_section/checkout_booking_item_card.dart';
import 'package:demandium/util/core_export.dart';
import 'package:get/get.dart';

class CheckoutServiceSummary extends StatelessWidget {
  const CheckoutServiceSummary({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CartController>(builder: (cartController) {
      final cartList = cartController.cartList;
      if (cartList.isEmpty) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'service_details'.tr,
              style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge),
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            ...List.generate(
              cartList.length,
              (index) => CheckoutBookingItemCard(
                cart: cartList[index],
                index: index,
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),
          ],
        ),
      );
    });
  }
}
