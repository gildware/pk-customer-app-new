import 'package:demandium/feature/checkout/widget/order_details_section/checkout_service_summary.dart';
import 'package:demandium/util/core_export.dart';
import 'package:get/get.dart';

class OrderDetailsPageWeb extends StatelessWidget {
  final String pageState;
  final String addressId;
  const OrderDetailsPageWeb({super.key, required this.pageState, required this.addressId}) ;

  @override
  Widget build(BuildContext context) {
    return Center(child: SizedBox(
      width: Dimensions.webMaxWidth * 0.9,
      child: GetBuilder<CartController>(builder: (cartController) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: WebShadowWrap(
                backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.03),
                minHeight: Get.height * 0.1,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CheckoutServiceSummary(),
                    Get.find<AuthController>().isLoggedIn() ? const ShowVoucher() : const SizedBox(),
                    const SizedBox(height: Dimensions.paddingSizeDefault),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: WebShadowWrap(
                backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.03),
                minHeight: Get.height * 0.1,
                child: Column(
                  children: [
                    const CartSummery(),
                    const SizedBox(height: Dimensions.paddingSizeEight),
                    ProceedToCheckoutButtonWidget(pageState: pageState, addressId: addressId),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    ));
  }
}
