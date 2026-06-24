import 'package:demandium/common/widgets/custom_pop_widget.dart';
import 'package:get/get.dart';
import 'package:demandium/util/core_export.dart';
import 'package:demandium/feature/cart/widget/cart_service_detail_card.dart';
import 'package:demandium/common/widgets/address_selection_drawer.dart';


class CartScreen extends StatefulWidget {
  final bool fromNav;
  const CartScreen({super.key, required this.fromNav});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  ConfigModel configModel = Get.find<SplashController>().configModel;

  @override
  void initState() {
    super.initState();
    _loadCart();
    if (Get.isRegistered<CompanyAvailabilityConfigWatcher>()) {
      unawaited(Get.find<CompanyAvailabilityConfigWatcher>().refreshNow());
    }
  }

  Future<void> _loadCart() async {
    await Get.find<LocationController>().refreshSavedAddressZone();
    final cartController = Get.find<CartController>();
    await cartController.getCartListFromServer(forceFromServer: true);
    if (cartController.hasCartServiceInfo) {
      await cartController.syncCheckoutFromCartServiceInfo();
    }
    if (cartController.cartLoadFailed && cartController.cartList.isEmpty) {
      customSnackBar('connection_to_api_server_failed'.tr, type: ToasterMessageType.error);
    }
    Future.delayed(const Duration(milliseconds: 500)).then((_) {
      cartController.showMinimumAndMaximumOrderValueToaster();
    });
  }

  @override
  Widget build(BuildContext context) {

    return CustomPopWidget(
      child: Scaffold(
        drawer: ResponsiveHelper.isDesktop(context) ? const AddressSelectionDrawer() : null,

        endDrawer:ResponsiveHelper.isDesktop(context) ? const MenuDrawer():null,
        appBar: CustomAppBar( title: 'cart'.tr,
          isBackButtonExist: (ResponsiveHelper.isDesktop(context) || !widget.fromNav),
          onBackPressed: (){
          if(Navigator.canPop(context)){
            Get.back();
          }else{
            Get.offAllNamed(RouteHelper.getMainRoute("home"));
          }},
        ),
        body: SafeArea(child: GetBuilder<CartController>(builder: (cartController){

          return Column( children: [
            Expanded(
              child: FooterBaseView(
                isCenter: (cartController.cartList.isEmpty),
                child: WebShadowWrap(
                  child: SizedBox( width: Dimensions.webMaxWidth,
                    child: GetBuilder<CartController>(
                      builder: (cartController) {

                        if (cartController.isLoading) {
                          return SizedBox(
                            height: ResponsiveHelper.isMobile(context) ? MediaQuery.of(context).size.height * 0.8 : MediaQuery.of(context).size.height * 0.6,
                              child: const Center(child: CustomLoader())
                          );
                        } else {
                          if (cartController.cartList.isNotEmpty) {
                            return ResponsiveHelper.isDesktop(context) ?
                            Row( spacing : 20,crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Expanded(child:  WebShadowWrap(
                                child: _CartListWidget(),
                              )),
                              Expanded(child: WebShadowWrap(
                                child: _PriceButtonWidget(cartController: cartController),
                              ))
                            ]) : Column(
                              children: [
                                _CartListWidget(),
                              ],
                            );
                          } else {
                            return NoDataScreen(
                              text: "cart_is_empty".tr,
                              type: NoDataType.cart,
                            );
                          }
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),
            if((ResponsiveHelper.isTab(context) || ResponsiveHelper.isMobile(context) )&& cartController.cartList.isNotEmpty )
              _PriceButtonWidget(cartController: cartController)
          ]);},
        )),
      ),
    );
  }
}


class _CartListWidget extends StatelessWidget {
  const _CartListWidget();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CartController>(builder: (cartController) {
      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Dimensions.paddingSizeDefault,
                Dimensions.paddingSizeSmall,
                Dimensions.paddingSizeDefault,
                Dimensions.paddingSizeSmall,
              ),
              child: Text(
                '${cartController.cartList.length} ${'services_in_cart'.tr}',
                style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
              ),
            ),
            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: cartController.cartList.length,
              separatorBuilder: (context, index) => const SizedBox(height: Dimensions.paddingSizeExtraSmall),
              itemBuilder: (context, index) {
                return CartServiceDetailCard(
                  cart: cartController.cartList[index],
                  index: index,
                );
              },
            ),
            const SizedBox(height: Dimensions.paddingSizeLarge),
          ],
        ),
      );
    });
  }
}

class _PriceButtonWidget extends StatelessWidget {
  final CartController cartController;
  const _PriceButtonWidget({required this.cartController});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SplashController>(
      id: CompanyAvailabilityConfigWatcher.bookingConfigUpdateId,
      builder: (_) => _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final minBookingAmount = Get.find<SplashController>().configModel.content?.minBookingAmount ?? 0;
    final isBelowMinimum = minBookingAmount > cartController.totalPrice;
    final hasInvalidSchedule = cartController.hasInvalidScheduleCartItems;

    return Column(children: [


      SizedBox(
        height: 50,
        child: Center(
          child:Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('total_price'.tr,
                style: robotoRegular.copyWith(
                  fontSize: Dimensions.fontSizeLarge,
                  fontWeight: FontWeight.w400,
                  color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: .6),
                ),
              ),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(' ${PriceConverter.convertPrice((cartController.totalPrice),
                    isShowLongPrice: true)} ', style: robotoBold.copyWith(color: Theme.of(context).colorScheme.error, fontSize: Dimensions.fontSizeLarge,),
                ),
              )
            ],
          ),
        ),
      ),
      Padding(padding: const EdgeInsets.only(
        left: Dimensions.paddingSizeDefault,
        right: Dimensions.paddingSizeDefault,
        bottom: Dimensions.paddingSizeSmall,
      ),
        child: CustomButton(
          width: Get.width,
          height:  ResponsiveHelper.isDesktop(context)? 50 : 45,
          radius: Dimensions.radiusDefault,
          buttonText: 'proceed_to_checkout'.tr,
          onPressed: hasInvalidSchedule
              ? null
              : isBelowMinimum
                  ? () {
                      cartController.showMinimumAndMaximumOrderValueToaster();
                    }
                  : () {
                      final checkout = Get.find<CheckOutController>();
                      checkout.changePaymentAmountType('full', shouldUpdate: false);
                      checkout.updateState(PageState.orderDetails);
                      Get.toNamed(RouteHelper.getCheckoutRoute('cart', 'orderDetails', 'null'));
                    },
        ),
      ),
      if (hasInvalidSchedule)
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Dimensions.paddingSizeDefault,
            Dimensions.paddingSizeSmall,
            Dimensions.paddingSizeDefault,
            Dimensions.paddingSizeDefault,
          ),
          child: Text(
            'cart_schedule_needs_update'.tr,
            textAlign: TextAlign.center,
            style: robotoRegular.copyWith(
              fontSize: Dimensions.fontSizeSmall,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ),
    ]);
  }
}
