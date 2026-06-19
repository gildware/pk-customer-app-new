import 'dart:convert';
import 'package:demandium/util/core_export.dart';
import 'package:universal_html/html.dart' as html;
import 'package:get/get.dart';

class ProceedToCheckoutButtonWidget extends StatefulWidget {
  final String pageState;
  final String addressId;
  const ProceedToCheckoutButtonWidget({super.key, required this.pageState, required this.addressId}) ;

  @override
  State<ProceedToCheckoutButtonWidget> createState() => _ProceedToCheckoutButtonWidgetState();
}

class _ProceedToCheckoutButtonWidgetState extends State<ProceedToCheckoutButtonWidget> {
  @override
  Widget build(BuildContext context) {
    return GetBuilder<ScheduleController>(builder: (scheduleController){
      return GetBuilder<CartController>(builder: (cartController){

        String? errorText = cartController.checkScheduleBookingAvailability();
        double totalAmount = cartController.totalPrice ;
        final bool isRepeatBooking = scheduleController.selectedServiceType == ServiceType.repeat;
        final bool showPaymentAmountOptions = CheckoutHelper.showBookingPaymentAmountOptions(
          fromPage: 'checkout',
          isRepeatBooking: isRepeatBooking,
        );
        final bool requiresUpfront = CheckoutHelper.requiresBookingUpfrontPayment() && !isRepeatBooking;
        String? schedule = scheduleController.scheduleTime;
        if (cartController.hasCartServiceInfo && cartController.cartList.isNotEmpty) {
          schedule = CartBookingDisplayHelper.resolveRawScheduleForCartItem(cartController.cartList.first)
              ?? cartController.cartServiceInfo?.serviceSchedule
              ?? schedule;
        }

        ConfigModel configModel = Get.find<SplashController>().configModel;
        bool isLoggedIn  = Get.find<AuthController>().isLoggedIn();
        bool createGuestAccount = Get.find<SplashController>().configModel.content?.createGuestUserAccount == 1;


        return GetBuilder<CheckOutController>(builder: (checkoutController){
          final bool onPaymentStep = widget.pageState == "payment" || checkoutController.currentPageState == PageState.payment;
          final double displayAmount = (onPaymentStep && showPaymentAmountOptions)
              ? checkoutController.payableCheckoutAmount(totalAmount)
              : totalAmount;
          final String priceLabel = (onPaymentStep && showPaymentAmountOptions && requiresUpfront)
              ? 'pay_now'.tr
              : 'total_price'.tr;

          return Padding( padding: const EdgeInsets.symmetric(horizontal : Dimensions.paddingSizeDefault),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [ Padding(padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),

              child: Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children:[
                Text(priceLabel, style: robotoRegular.copyWith(
                  fontSize: Dimensions.fontSizeDefault , color: Theme.of(context).textTheme.bodyLarge!.color,
                )),
                const SizedBox(width: 5,),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(PriceConverter.convertPrice(displayAmount),
                    style: robotoBold.copyWith(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: Dimensions.fontSizeDefault,
                    ),
                  ),
                ),
              ]))),

              CustomButton(
                height: 50,
                radius: Dimensions.radiusDefault,
                isLoading: checkoutController.isLoading || checkoutController.isPaymentInProgress,
                fontSize: Dimensions.fontSizeDefault + 1,
                buttonText: cartController.cartList.isEmpty ? "empty_cart_go_back".tr : (widget.pageState == "orderDetails" && checkoutController.currentPageState == PageState.orderDetails) ? "make_payment".tr : 'confirm_booking'.tr,
                onPressed : checkoutController.isPaymentInProgress ? null : ((widget.pageState == "payment" || checkoutController.currentPageState == PageState.payment) && checkoutController.othersPaymentList.isEmpty && checkoutController.digitalPaymentList.isEmpty
                    ? () => customSnackBar("no_payment_method_available".tr, type: ToasterMessageType.info)
                    : () {
                  final bool onPaymentStep = widget.pageState == "payment" || checkoutController.currentPageState == PageState.payment;
                  if(!onPaymentStep && errorText !=null && scheduleController.selectedScheduleType != ScheduleType.asap ){
                    customSnackBar(errorText.tr);
                  }
                  else if( checkoutController.acceptTerms || cartController.cartList.isEmpty ){
                    final locationController = Get.find<LocationController>();
                    AddressModel? addressModel = cartController.hasCartServiceInfo && locationController.selectedAddress != null
                        ? AddressHelper.ensureContactPerson(locationController.selectedAddress!)
                        : CheckoutHelper.selectedAddressModel(
                            selectedAddress: locationController.selectedAddress,
                            pickedAddress: locationController.getUserAddress(),
                            selectedLocationType: locationController.selectedServiceLocationType,
                          );
                    if (addressModel != null) {
                      addressModel = AddressHelper.ensureContactPerson(addressModel);
                    }
                    if(Get.find<CartController>().cartList.isEmpty) {

                      Get.offAllNamed(RouteHelper.getMainRoute('home'));
                    }
                    else if(cartController.cartList.isNotEmpty &&  cartController.cartList.first.provider !=null
                        && (cartController.cartList[0].provider?.serviceAvailability == 0 || cartController.cartList[0].provider?.isActive== 0)){

                      Future.delayed(const Duration(milliseconds: 50)).then((value){

                        Future.delayed(const Duration(milliseconds: 500)).then((value){
                          SafeContext.whenAvailable((sheetContext) {
                            showModalBottomSheet(
                              useRootNavigator: true,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              context: sheetContext,
                              builder: (context) => AvailableProviderWidget(
                                subcategoryId:Get.find<CartController>().cartList.first.subCategoryId,
                                showUnavailableError: true,
                              ),
                            );
                          });
                        });

                        customSnackBar("your_selected_provider_is_unavailable_right_now".tr,duration: 3, type: ToasterMessageType.info);

                      });

                    }

                    else if(checkoutController.currentPageState == PageState.orderDetails && PageState.orderDetails.name == widget.pageState){

                      if(cartController.hasCartServiceInfo) {
                        final cartValidation = CartBookingDisplayHelper.validateCartItemsForCheckout(cartController.cartList);
                        if (cartValidation != null) {
                          customSnackBar(cartValidation.tr, type: ToasterMessageType.info);
                        } else if (cartController.hasPastScheduleCartItems) {
                          customSnackBar('cart_items_need_attention'.tr, type: ToasterMessageType.info);
                        } else {
                          checkoutController.updateState(PageState.payment);
                        }
                      }
                      else if(schedule == null && scheduleController.selectedScheduleType != ScheduleType.asap && scheduleController.selectedServiceType == ServiceType.regular) {
                        customSnackBar("select_your_preferable_booking_time".tr, type: ToasterMessageType.info);
                      }
                      else if(scheduleController.selectedScheduleType == ScheduleType.schedule
                          && configModel.content?.scheduleBookingTimeRestriction == 1
                          && scheduleController.checkValidityOfTimeRestriction(Get.find<SplashController>().configModel.content!.advanceBooking!) != null
                          && scheduleController.selectedServiceType == ServiceType.regular){
                        customSnackBar(scheduleController.checkValidityOfTimeRestriction(Get.find<SplashController>().configModel.content!.advanceBooking!));
                      }else if(scheduleController.selectedServiceType == ServiceType.repeat && scheduleController.selectedRepeatBookingType == RepeatBookingType.daily && scheduleController.pickedDailyRepeatBookingDateRange == null){
                        customSnackBar("daily_select_time_and_date_hint".tr,type: ToasterMessageType.info);
                      }
                      else if(scheduleController.selectedServiceType == ServiceType.repeat  && scheduleController.selectedRepeatBookingType == RepeatBookingType.daily && scheduleController.pickedDailyRepeatTime == null){
                        customSnackBar("select_time_hint".tr,type: ToasterMessageType.info);
                      }
                      else if(scheduleController.selectedServiceType == ServiceType.repeat && scheduleController.selectedRepeatBookingType == RepeatBookingType.weekly && scheduleController.getWeeklyPickedDays().isEmpty){
                        customSnackBar("weekly_select_time_and_date_hint".tr,type: ToasterMessageType.info);
                      }
                      else if(scheduleController.selectedServiceType == ServiceType.repeat && scheduleController.selectedRepeatBookingType == RepeatBookingType.weekly && scheduleController.pickedWeeklyRepeatTime == null){
                        customSnackBar("select_time_hint".tr,type: ToasterMessageType.info);
                      }
                      else if(scheduleController.selectedServiceType == ServiceType.repeat && scheduleController.selectedRepeatBookingType == RepeatBookingType.weekly && (scheduleController.pickedWeeklyRepeatBookingDateRange == null || !scheduleController.isFinalRepeatWeeklyBooking)){
                        customSnackBar("weekly_select_time_and_date_hint".tr,type: ToasterMessageType.info);
                      }
                      else if(scheduleController.selectedServiceType == ServiceType.repeat && scheduleController.selectedRepeatBookingType == RepeatBookingType.custom && scheduleController.pickedCustomRepeatBookingDateTimeList.isEmpty){
                        customSnackBar("custom_select_time_and_date_hint".tr,type: ToasterMessageType.info);
                      }
                      else if(addressModel == null){
                        customSnackBar("add_address_first".tr, type: ToasterMessageType.info);
                      }
                      else if(!AddressHelper.hasValidContactPerson(addressModel)){
                        customSnackBar("please_input_contact_person_name_and_phone_number".tr, type: ToasterMessageType.info);
                      } else if(checkoutController.isCheckedCreateAccount && checkoutController.passwordController.text.isEmpty){
                        customSnackBar("please_input_new_account_password".tr, type: ToasterMessageType.info);
                      }
                      else if(checkoutController.isCheckedCreateAccount && checkoutController.confirmPasswordController.text.isEmpty){
                        customSnackBar("please_input_confirm_password".tr, type: ToasterMessageType.info);
                      }
                      else if(checkoutController.isCheckedCreateAccount && checkoutController.confirmPasswordController.text != checkoutController.passwordController.text ){
                        customSnackBar("confirm_password_does_not_matched".tr, type: ToasterMessageType.info);
                      }
                      else{
                        if(checkoutController.isCheckedCreateAccount && !isLoggedIn && createGuestAccount){
                          checkoutController.checkExistingUser(phone: "${addressModel.contactPersonNumber}").then((value){
                            if(!value){
                              customSnackBar('phone_already_taken'.tr,type : ToasterMessageType.info);
                            }else{
                              checkoutController.updateState(PageState.payment);
                              // if(GetPlatform.isWeb) {
                              //   Get.toNamed(RouteHelper.getCheckoutRoute(
                              //     'cart',Get.find<CheckOutController>().currentPageState.name,widget.pageState == 'payment' ? widget.addressId : addressModel.id.toString(),
                              //     reload: false,
                              //   ));
                              // }
                            }
                          });
                        }else{
                          checkoutController.updateState(PageState.payment);
                          // if(GetPlatform.isWeb) {
                          //   Get.toNamed(RouteHelper.getCheckoutRoute(
                          //     'cart',Get.find<CheckOutController>().currentPageState.name,widget.pageState == 'payment' ? widget.addressId : addressModel.id.toString(),
                          //     reload: false,
                          //   ));
                          // }
                        }

                      }
                    }
                    else if(checkoutController.currentPageState == PageState.payment || PageState.payment.name == widget.pageState){

                      if (addressModel == null) {
                        customSnackBar("add_address_first".tr, type: ToasterMessageType.info);
                        return;
                      }

                      if ((schedule == null || schedule.isEmpty) && !isRepeatBooking) {
                        customSnackBar("select_your_preferable_booking_time".tr, type: ToasterMessageType.info);
                        return;
                      }

                      final String? paymentAmountType = showPaymentAmountOptions
                          ? (checkoutController.paymentAmountType ?? 'full')
                          : null;
                      final double payableAmount = showPaymentAmountOptions
                          ? checkoutController.payableCheckoutAmount(totalAmount)
                          : totalAmount;
                      bool isPartialPayment = CheckoutHelper.checkPartialPayment(
                        walletBalance: cartController.walletBalance,
                        bookingAmount: payableAmount,
                      );

                      if (showPaymentAmountOptions && (checkoutController.paymentAmountType == null || checkoutController.paymentAmountType!.isEmpty)) {
                        customSnackBar("select_payment_amount_type".tr, type: ToasterMessageType.info);
                      }
                      else if(isRepeatBooking){
                        checkoutController.placeBookingRequest(
                          paymentMethod: "cash_after_service",
                          schedule: schedule,
                          isPartial: 0,
                          address: addressModel,
                        );
                      }
                      else if(cartController.walletPaymentStatus && isPartialPayment && checkoutController.selectedPaymentMethod == PaymentMethodName.walletMoney){
                        customSnackBar("select_another_payment_method_to_pay_remaining_bill".tr, type: ToasterMessageType.info);
                      }
                      else if(checkoutController.selectedPaymentMethod == PaymentMethodName.none){
                        customSnackBar("select_payment_method".tr, type: ToasterMessageType.info);
                      }
                      else if(checkoutController.selectedPaymentMethod == PaymentMethodName.cos && !requiresUpfront){
                        checkoutController.placeBookingRequest(
                          paymentMethod: "cash_after_service",
                          schedule: schedule,
                          isPartial: isPartialPayment && cartController.walletPaymentStatus ? 1 : 0,
                          address: addressModel,
                          paymentAmountType: paymentAmountType,
                        );
                      }
                      else if(checkoutController.selectedPaymentMethod == PaymentMethodName.offline){
                        if (checkoutController.selectedOfflineMethod != null) {
                          final selectedOfflinePaymentIndex = checkoutController.offlinePaymentModelList
                              .indexOf(checkoutController.selectedOfflineMethod!);
                          checkoutController.placeBookingRequest(
                            paymentMethod: "offline_payment",
                            schedule: schedule,
                            isPartial: isPartialPayment && cartController.walletPaymentStatus ? 1 : 0,
                            address: addressModel,
                            paymentAmountType: paymentAmountType,
                            offlinePaymentId: checkoutController.selectedOfflineMethod?.id,
                            bookingAmount: payableAmount,
                            selectedOfflinePaymentIndex: selectedOfflinePaymentIndex >= 0 ? selectedOfflinePaymentIndex : 0,
                          );
                        } else {
                          customSnackBar("provide_offline_payment_info".tr, type: ToasterMessageType.info);
                        }
                      }
                      else if(checkoutController.selectedPaymentMethod == PaymentMethodName.walletMoney){
                        checkoutController.placeBookingRequest(
                            paymentMethod: "wallet_payment",
                            schedule: schedule,
                            isPartial:  isPartialPayment && cartController.walletPaymentStatus ? 1 : 0,
                            address: addressModel,
                            paymentAmountType: paymentAmountType,
                        );
                      }
                      else if( checkoutController.selectedPaymentMethod == PaymentMethodName.digitalPayment){

                        if(checkoutController.selectedDigitalPaymentMethod != null && checkoutController.selectedDigitalPaymentMethod?.gateway != "offline"){
                          checkoutController.setPaymentInProgress(true);
                          _makeDigitalPayment(
                            addressModel,
                            checkoutController.selectedDigitalPaymentMethod,
                            isPartialPayment,
                            checkoutController,
                            paymentAmountType,
                          ).whenComplete(() {
                            checkoutController.setPaymentInProgress(false);
                          }).catchError((_) {
                            customSnackBar('connection_to_api_server_failed'.tr, type: ToasterMessageType.error);
                          });
                        }else{
                          customSnackBar("select_any_payment_method".tr, type: ToasterMessageType.info);
                        }

                      }
                      else {
                        customSnackBar("select_payment_method".tr, type: ToasterMessageType.info);
                      }
                    }
                    else {
                      if (kDebugMode) {
                        print("In Here");
                      }
                    }
                  }
                  else{
                    customSnackBar('please_agree_with_terms_conditions'.tr, type: ToasterMessageType.info);
                  }
                }),
              ),
            ]),
          );
        });
      });
    });
  }

  Future<void> _makeDigitalPayment(AddressModel? address , DigitalPaymentMethod?  paymentMethod, bool isPartialPayment, CheckOutController checkoutController, String? paymentAmountType) async {

    if (address == null) {
      customSnackBar("add_address_first".tr, type: ToasterMessageType.info);
      return;
    }

    if (!Get.find<AuthController>().isLoggedIn() && BookingAuthHelper.guestCheckoutEnabled) {
      await BookingAuthHelper.ensureGuestSessionIfNeeded();
    }

    String url = '';
    String hostname = html.window.location.hostname!;
    String protocol = html.window.location.protocol;
    String port = html.window.location.port;
    String? path = html.window.location.pathname;
    SignUpBody? newUserInfo = CheckoutHelper.getNewUserInfo(address: address, password: checkoutController.passwordController.text, isCheckedCreateAccount: checkoutController.isCheckedCreateAccount);

    String? schedule = Get.find<ScheduleController>().scheduleTime;
    String userId = Get.find<UserController>().userInfoModel?.id?? Get.find<SplashController>().getGuestId();
    String encodedAddress = base64Encode(utf8.encode(jsonEncode(address?.toJson())));
    String encodedNewUserInfo = base64Encode(utf8.encode(jsonEncode(newUserInfo?.toJson())));
    String serviceLocation = Get.find<LocationController>().selectedServiceLocationType.name;

    String addressId = (address?.id == "null" || address?.id == null) ? "" : address?.id ?? "";
    String  zoneId = Get.find<LocationController>().getUserAddress()?.zoneId??"";
    String callbackUrl = GetPlatform.isWeb ? "$protocol//$hostname:$port$path" : AppConstants.baseUrl;
    int isPartial = Get.find<CartController>().walletPaymentStatus && isPartialPayment ? 1 : 0;
    String platform = ResponsiveHelper.isWeb() ? "web" : "app" ;
    final accessToken = await PaymentAccessTokenHelper.forSubject(userId);

    url = '${AppConstants.baseUrl}/payment?payment_method=${paymentMethod?.gateway}&access_token=$accessToken&zone_id=$zoneId'
        '&service_schedule=$schedule&service_address_id=$addressId&callback=$callbackUrl'
        '&service_address=$encodedAddress&new_user_info=$encodedNewUserInfo&is_partial=$isPartial'
        '&payment_platform=$platform&service_location=$serviceLocation';
    if (paymentAmountType != null && paymentAmountType.isNotEmpty) {
      url += '&payment_amount_type=$paymentAmountType';
    }

    if (GetPlatform.isWeb) {
      printLog("url_with_digital_payment:$url");
      html.window.open(url, "_self");
    } else {
      printLog("url_with_digital_payment_mobile:$url");
      await DigitalPaymentLauncher.start(
        paymentUrl: url,
        fromPage: 'checkout',
        gateway: paymentMethod?.gateway,
      );
    }
  }
}
