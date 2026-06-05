import 'package:demandium/feature/checkout/widget/order_details_section/checkout_service_summary.dart';
import 'package:demandium/util/core_export.dart';
import 'package:get/get.dart';

class OrderDetailsPage extends StatelessWidget {
  const OrderDetailsPage({super.key}) ;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(child: Column(children: [
      const CheckoutServiceSummary(),
      Get.find<AuthController>().isLoggedIn() ? const ShowVoucher() : const SizedBox(),
      const CartSummery(),
    ]));
  }
}

