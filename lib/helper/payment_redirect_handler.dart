import 'dart:convert';

import 'package:get/get.dart';
import 'package:demandium/util/core_export.dart';

class PaymentRedirectHandler {
  static void handlePaymentResult({
    required String fromPage,
    required String flag,
    String? token,
    bool closeCurrentRoute = false,
  }) {
    final isSuccess = flag.contains('success');
    final isFailed = flag.contains('fail') || flag.contains('cancel');

    if (!isSuccess && !isFailed) {
      return;
    }

    if (isSuccess) {
      _handleSuccess(fromPage, token, closeCurrentRoute);
      return;
    }

    _handleFailure(fromPage, closeCurrentRoute);
  }

  static void handleRedirectUrl({
    required String fromPage,
    required String url,
    bool closeCurrentRoute = false,
  }) {
    if (!url.contains(AppConstants.baseUrl) || !url.contains('flag')) {
      return;
    }

    final isSuccess = url.contains('success');
    final isFailed = url.contains('fail');
    final isCancel = url.contains('cancel');

    if (!isSuccess && !isFailed && !isCancel) {
      return;
    }

    final token = isSuccess ? StringParser.parseString(url, 'token') : null;
    handlePaymentResult(
      fromPage: fromPage,
      flag: isSuccess ? 'success' : 'fail',
      token: token,
      closeCurrentRoute: closeCurrentRoute,
    );
  }

  static void _handleSuccess(
    String fromPage,
    String? token,
    bool closeCurrentRoute,
  ) {
    if (fromPage == 'checkout') {
      Get.find<CartController>().getCartListFromServer();
      if (closeCurrentRoute) {
        Get.back();
      }
      Get.offNamed(
        RouteHelper.getCheckoutRoute(
          RouteHelper.checkout,
          'complete',
          'null',
          token: token ?? '',
        ),
      );
      return;
    }

    if (fromPage == 'custom-checkout') {
      Get.offNamed(RouteHelper.getOrderSuccessRoute('success'));
      return;
    }

    if (fromPage == 'add-fund') {
      if (closeCurrentRoute) {
        Get.back();
      }
      final uuid = const Uuid().v1();
      Get.offNamed(
        RouteHelper.getMyWalletScreen(flag: 'success', token: uuid),
      );
      return;
    }

    if (fromPage == 'switch-payment-method' || fromPage == 'booking-due-payment') {
      if (closeCurrentRoute) {
        Get.back();
      }
      _refreshBookingDetailsAfterPayment(fromPage: fromPage, token: token);
      customSnackBar(
        'your_payment_confirm_successfully'.tr,
        toasterTitle: 'payment_status'.tr,
        type: ToasterMessageType.success,
        duration: 4,
      );
      return;
    }

    if (fromPage == 'repeat-booking') {
      if (closeCurrentRoute) {
        Get.back();
      }
      String? subBookingId;

      if (token != null && token.isNotEmpty) {
        try {
          subBookingId = StringParser.parseString(
            utf8.decode(base64Url.decode(token)),
            'booking_repeat_id',
          );
        } catch (e, stack) {
          ErrorLogger.record(
            e,
            stack,
            reason: 'PaymentRedirectHandler.repeat-booking.token',
          );
        }
      }

      if (subBookingId != null) {
        Get.find<BookingDetailsController>().getSubBookingDetails(
          bookingId: subBookingId,
        );
        customSnackBar('paid_successfully'.tr, type: ToasterMessageType.success);
      } else {
        customSnackBar(
          'payment_failed_try_again'.tr,
          type: ToasterMessageType.error,
          showDefaultSnackBar: false,
        );
      }
    }
  }

  static void _refreshBookingDetailsAfterPayment({String? fromPage, String? token}) {
    if (!Get.isRegistered<BookingDetailsController>()) {
      return;
    }

    final bookingDetailsController = Get.find<BookingDetailsController>();

    if (fromPage == 'booking-due-payment' && token != null && token.isNotEmpty) {
      try {
        final subBookingId = StringParser.parseString(
          utf8.decode(base64Url.decode(token)),
          'booking_repeat_id',
        );
        if (subBookingId.isNotEmpty) {
          bookingDetailsController.getSubBookingDetails(bookingId: subBookingId);
          final parentBookingId = bookingDetailsController.subBookingDetailsContent?.bookingId;
          if (parentBookingId != null && parentBookingId.isNotEmpty) {
            bookingDetailsController.getBookingDetails(bookingId: parentBookingId, reload: false);
          }
          if (Get.isRegistered<ServiceBookingController>()) {
            Get.find<ServiceBookingController>().refreshCurrentBookingTab();
          }
          return;
        }
      } catch (e, stack) {
        ErrorLogger.record(e, stack, reason: 'PaymentRedirectHandler.booking-due-payment.token');
      }
    }

    final subBooking = bookingDetailsController.subBookingDetailsContent;
    if (subBooking?.id != null && subBooking!.id!.isNotEmpty) {
      bookingDetailsController.getSubBookingDetails(bookingId: subBooking.id!);
      final parentBookingId = subBooking.bookingId;
      if (parentBookingId != null && parentBookingId.isNotEmpty) {
        bookingDetailsController.getBookingDetails(bookingId: parentBookingId, reload: false);
      }
    } else {
      final bookingId = bookingDetailsController.bookingDetailsContent?.id;
      if (bookingId != null && bookingId.isNotEmpty) {
        bookingDetailsController.getBookingDetails(bookingId: bookingId, reload: false);
      }
    }

    if (Get.isRegistered<ServiceBookingController>()) {
      Get.find<ServiceBookingController>().refreshCurrentBookingTab();
    }
  }

  static void _handleFailure(String fromPage, bool closeCurrentRoute) {
    if (fromPage == 'add-fund') {
      Get.offNamed(RouteHelper.getMyWalletScreen(flag: 'failed'));
      return;
    }

    if (fromPage == 'repeat-booking' || fromPage == 'booking-due-payment' || fromPage == 'switch-payment-method') {
      if (closeCurrentRoute) {
        Get.back();
      }
      _refreshBookingDetailsAfterPayment(fromPage: fromPage);
      customSnackBar(
        'payment_failed_try_again'.tr,
        toasterTitle: 'payment_status'.tr,
        type: ToasterMessageType.error,
        showDefaultSnackBar: false,
      );
      return;
    }

    Get.offNamed(RouteHelper.getOrderSuccessRoute('fail'));
  }
}
