// ignore_for_file: deprecated_member_use
import 'package:demandium/util/core_export.dart';
import 'package:get/get.dart';
import 'package:demandium/common/widgets/address_selection_drawer.dart';


class CheckoutScreen extends StatefulWidget {
  final String pageState;
  final String addressId;
  final bool? reload;
  final String? token;
  const CheckoutScreen(this.pageState, this.addressId, {super.key,this.reload = true, this.token}) ;
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();}

class _CheckoutScreenState extends State<CheckoutScreen> {

  final tooltipController = JustTheController();
  bool _isHydratingCart = false;

  Future<void> _hydrateCheckoutCart() async {
    if (_isHydratingCart) return;
    _isHydratingCart = true;
    if (mounted) setState(() {});
    await Get.find<LocationController>().refreshSavedAddressZone();
    await Get.find<CartController>().getCartListFromServer(shouldUpdate: false, forceFromServer: true);
    final cartController = Get.find<CartController>();
    if (!mounted) return;
    if (cartController.cartList.isEmpty) {
      if (cartController.cartLoadFailed) {
        customSnackBar('connection_to_api_server_failed'.tr, type: ToasterMessageType.error);
      }
      Get.offAllNamed(RouteHelper.home);
      return;
    }
    if (cartController.hasCartServiceInfo) {
      await cartController.syncCheckoutFromCartServiceInfo();
    }
    _isHydratingCart = false;
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    if(widget.pageState == 'complete') {
      Get.find<CheckOutController>().updateState(PageState.complete,shouldUpdate: false);
    }
    Get.find<CheckOutController>().ensureDefaultDigitalPaymentSelected(shouldUpdate: false);

    if (widget.pageState == 'payment' || widget.pageState == 'orderDetails') {
      if (Get.isRegistered<CompanyAvailabilityConfigWatcher>()) {
        unawaited(Get.find<CompanyAvailabilityConfigWatcher>().refreshNow());
      } else {
        Get.find<SplashController>().refreshConfigFromServer();
      }
    }

    if(widget.pageState == 'orderDetails'){
      _hydrateCheckoutCart();
      Get.find<ScheduleController>().resetScheduleData(shouldUpdate: false);
      Get.find<ScheduleController>().updateSelectedBookingType(type: ServiceType.regular);
      Get.find<CheckOutController>().resetCreateAccountWithExistingInfo();
      Get.find<CheckOutController>().toggleTerms(value: false, shouldUpdate: false);
      Get.find<ScheduleController>().resetSchedule();
      Get.find<LocationController>().updateSelectedServiceLocationType();
    }else{
      Get.find<CheckOutController>().toggleTerms(value: true, shouldUpdate: false);
    }
    if(widget.token !=null && widget.token != "null" && widget.token != ""){
      Get.find<CheckOutController>().parseToken(widget.token!);
    }
    Get.find<CartController>().updateWalletPaymentStatus(false, shouldUpdate: false);

    Get.find<CouponController>().getCouponList();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CheckOutController>(builder: (checkoutController) {
      final isCompletePage = widget.pageState == 'complete' ||
          checkoutController.currentPageState == PageState.complete;
      final isPaymentPage = widget.pageState == 'payment' ||
          checkoutController.currentPageState == PageState.payment;

      return PopScope(
        canPop: !isCompletePage && !isPaymentPage,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (isCompletePage) {
            Get.offAllNamed(RouteHelper.getMainRoute('home'));
            return;
          }
          if (isPaymentPage) {
            checkoutController.ensureDefaultDigitalPaymentSelected();
            checkoutController.updateState(PageState.orderDetails);
            checkoutController.getPaymentMethodList(shouldUpdate: true);
            checkoutController.ensureDefaultDigitalPaymentSelected(shouldUpdate: true);
            if (ResponsiveHelper.isWeb()) {
              Get.toNamed(
                RouteHelper.getCheckoutRoute('cart', 'orderDetails', 'null', reload: false),
              );
            }
          }
        },
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          drawer: ResponsiveHelper.isDesktop(context) ? const AddressSelectionDrawer() : null,

          endDrawer: ResponsiveHelper.isDesktop(context) ? const MenuDrawer() : null,
          appBar: CustomAppBar( title: 'checkout'.tr,
            onBackPressed: isCompletePage ? () {
              Get.offAllNamed(RouteHelper.getMainRoute('home'));
            } : () {
              if(widget.pageState == 'payment' || checkoutController.currentPageState == PageState.payment) {
                checkoutController.ensureDefaultDigitalPaymentSelected();
                checkoutController.updateState(PageState.orderDetails);
                if(ResponsiveHelper.isWeb()) {
                  Get.toNamed(RouteHelper.getCheckoutRoute('cart','orderDetails','null'));
                }
              } else {
                checkoutController.updateState(PageState.orderDetails);
                Get.back();
              }
            },
            isBackButtonExist: !isCompletePage,
          ),
          body: SafeArea(child: _isHydratingCart && widget.pageState == 'orderDetails'
              ? const Center(child: CustomLoader())
              : FooterBaseView( child: WebShadowWrap(
            child: SizedBox(width: Dimensions.webMaxWidth, child:  Column(mainAxisAlignment: MainAxisAlignment.start, children: [

              const SizedBox(height: Dimensions.paddingSizeDefault,),
              CheckoutHeaderWidget(pageState: widget.pageState,),

              checkoutController.currentPageState == PageState.orderDetails  && PageState.orderDetails.name == widget.pageState ? ResponsiveHelper.isDesktop(context) ?
              OrderDetailsPageWeb(pageState: widget.pageState,addressId: widget.addressId) :
              const OrderDetailsPage() :
              checkoutController.currentPageState == PageState.payment || PageState.payment.name == widget.pageState ?
              PaymentPage(addressId: widget.addressId, tooltipController: tooltipController,fromPage: "checkout",) :
              CompletePage(token: widget.token,),


              ResponsiveHelper.isDesktop(context)  &&  (checkoutController.currentPageState == PageState.payment || widget.pageState == 'payment') ?
              ProceedToCheckoutButtonWidget(pageState: widget.pageState,addressId: widget.addressId,) : const SizedBox(height: 120,)

            ]))
          ))),

          bottomSheet:  !(ResponsiveHelper.isDesktop(context)) ? SafeArea( child: SizedBox( height: checkoutController.currentPageState.name=="complete"? 70 : 100,
            child: (checkoutController.currentPageState == PageState.complete || widget.pageState == 'complete') ?
            const SizedBox() : ProceedToCheckoutButtonWidget(pageState: widget.pageState,addressId: widget.addressId,),
          )): const SizedBox(),
        ),
      );
    });
  }
}



