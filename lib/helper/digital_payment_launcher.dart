import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:demandium/util/core_export.dart';

class DigitalPaymentLauncher {
  static Razorpay? _razorpay;
  static String? _activeFromPage;
  static String? _activePaymentRequestId;
  static Completer<void>? _activeCompleter;

  static bool isRazorpayEnabled() {
    if (GetPlatform.isWeb || kIsWeb) {
      return false;
    }
    return CheckoutHelper.enabledDigitalPaymentGateways().any(
      (method) => (method.gateway ?? '').trim().toLowerCase() == 'razor_pay',
    );
  }

  static bool shouldUseNativeRazorpay({String? gateway, String? paymentUrl}) {
    if (!isRazorpayEnabled()) {
      return false;
    }

    final resolvedGateway = (gateway ?? _extractGatewayFromUrl(paymentUrl ?? ''))
        .trim()
        .toLowerCase();
    return resolvedGateway == 'razor_pay';
  }

  static Future<void> start({
    required String paymentUrl,
    required String fromPage,
    String? gateway,
  }) async {
    if (shouldUseNativeRazorpay(gateway: gateway, paymentUrl: paymentUrl)) {
      final launched = await _startNativePayment(
        paymentUrl: paymentUrl,
        fromPage: fromPage,
      );
      if (launched) {
        _activeCompleter = Completer<void>();
        return _activeCompleter!.future;
      }
    }

    await Get.to(() => PaymentScreen(url: paymentUrl, fromPage: fromPage));
  }

  static Future<bool> _startNativePayment({
    required String paymentUrl,
    required String fromPage,
  }) async {
    _showLoading();

    try {
      final prepareData = await _fetchNativePrepareData(paymentUrl);
      if (prepareData == null) {
        return false;
      }

      _activeFromPage = fromPage;
      _activePaymentRequestId = prepareData['payment_request_id']?.toString();
      _razorpay?.clear();
      _razorpay = Razorpay();
      _razorpay!
        ..on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess)
        ..on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError)
        ..on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

      final options = <String, dynamic>{
        'key': prepareData['key'],
        'amount': prepareData['amount'],
        'currency': prepareData['currency'],
        'name': prepareData['name'],
        'description': prepareData['description']?.toString() ?? '',
        'order_id': prepareData['order_id'],
        'prefill': prepareData['prefill'] ?? {},
      };

      if (prepareData['image'] != null &&
          prepareData['image'].toString().isNotEmpty) {
        options['image'] = prepareData['image'];
      }

      _hideLoading();
      _razorpay!.open(options);
      return true;
    } catch (e, stack) {
      ErrorLogger.record(e, stack, reason: 'DigitalPaymentLauncher.startNative');
      _hideLoading();
      customSnackBar(
        'payment_failed_try_again'.tr,
        type: ToasterMessageType.error,
        showDefaultSnackBar: false,
      );
      return false;
    }
  }

  static Future<Map<String, dynamic>?> _fetchNativePrepareData(
    String paymentUrl,
  ) async {
    final uri = Uri.parse(paymentUrl);

    if (uri.path.contains('razor-pay/pay')) {
      final paymentId = uri.queryParameters['payment_id'];
      if (paymentId != null && paymentId.isNotEmpty) {
        final response = await http.get(
          Uri.parse(
            '${AppConstants.baseUrl}/payment/razor-pay/native-prepare?payment_id=$paymentId',
          ),
        );
        return _decodePrepareResponse(response);
      }
    }

    final nativeUri = uri.replace(
      queryParameters: {
        ...uri.queryParameters,
        'native_sdk': '1',
      },
    );

    final response = await http.get(nativeUri);
    return _decodePrepareResponse(response);
  }

  static Map<String, dynamic>? _decodePrepareResponse(http.Response response) {
    if (response.statusCode != 200) {
      return null;
    }

    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic>) {
      return null;
    }

    if (body['status'] != true) {
      return null;
    }

    return body;
  }

  static Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final fromPage = _activeFromPage ?? '';
    final paymentRequestId = _activePaymentRequestId ?? '';

    _showLoading();

    try {
      final verifyUri = Uri.parse(
        '${AppConstants.baseUrl}/payment/razor-pay/verify-payment',
      ).replace(
        queryParameters: {
          'payment_request_id': paymentRequestId,
          'payment_id': response.paymentId ?? '',
          'order_id': response.orderId ?? '',
          'signature': response.signature ?? '',
          'native_sdk': '1',
        },
      );

      final verifyResponse = await http.get(verifyUri);
      _hideLoading();
      _clearNativeSession();

      if (verifyResponse.statusCode != 200) {
        PaymentRedirectHandler.handlePaymentResult(
          fromPage: fromPage,
          flag: 'fail',
        );
        _completeNativeFlow();
        return;
      }

      final body = jsonDecode(verifyResponse.body);
      if (body is! Map<String, dynamic> || body['flag'] == null) {
        PaymentRedirectHandler.handlePaymentResult(
          fromPage: fromPage,
          flag: 'fail',
        );
        _completeNativeFlow();
        return;
      }

      PaymentRedirectHandler.handlePaymentResult(
        fromPage: fromPage,
        flag: body['flag'].toString(),
        token: body['token']?.toString(),
      );
      _completeNativeFlow();
    } catch (e, stack) {
      ErrorLogger.record(e, stack, reason: 'DigitalPaymentLauncher.verify');
      _hideLoading();
      _clearNativeSession();
      PaymentRedirectHandler.handlePaymentResult(
        fromPage: fromPage,
        flag: 'fail',
      );
      _completeNativeFlow();
    }
  }

  static void _handlePaymentError(PaymentFailureResponse response) {
    _hideLoading();
    final fromPage = _activeFromPage ?? '';
    _clearNativeSession();

    if (response.code != Razorpay.PAYMENT_CANCELLED) {
      PaymentRedirectHandler.handlePaymentResult(
        fromPage: fromPage,
        flag: 'fail',
      );
    }

    _completeNativeFlow();
  }

  static void _handleExternalWallet(ExternalWalletResponse response) {
    if (kDebugMode) {
      print('External wallet selected: ${response.walletName}');
    }
  }

  static String _extractGatewayFromUrl(String paymentUrl) {
    if (paymentUrl.isEmpty) {
      return '';
    }

    final uri = Uri.tryParse(paymentUrl);
    return uri?.queryParameters['payment_method'] ?? '';
  }

  static void _showLoading() {
    if (Get.isDialogOpen ?? false) {
      return;
    }
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );
  }

  static void _hideLoading() {
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
  }

  static void _clearNativeSession() {
    _razorpay?.clear();
    _razorpay = null;
    _activeFromPage = null;
    _activePaymentRequestId = null;
  }

  static void _completeNativeFlow() {
    if (_activeCompleter != null && !_activeCompleter!.isCompleted) {
      _activeCompleter!.complete();
    }
    _activeCompleter = null;
  }
}
