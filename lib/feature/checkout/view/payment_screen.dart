// ignore_for_file: deprecated_member_use

import 'dart:developer';

import 'package:demandium/common/widgets/custom_pop_widget.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:demandium/util/core_export.dart';

class PaymentScreen extends StatefulWidget {
  final String url;
  final String? fromPage;
  const PaymentScreen({super.key, required this.url, this.fromPage});

  @override
  PaymentScreenState createState() => PaymentScreenState();
}

class PaymentScreenState extends State<PaymentScreen> {
  final GlobalKey _webViewKey = GlobalKey();
  bool _isLoading = true;
  bool _canRedirect = true;
  bool _paymentCompleted = false;

  static final InAppWebViewSettings _webViewSettings = InAppWebViewSettings(
    javaScriptEnabled: true,
    domStorageEnabled: true,
    useShouldOverrideUrlLoading: true,
    useOnLoadResource: true,
    supportMultipleWindows: true,
    javaScriptCanOpenWindowsAutomatically: true,
    mediaPlaybackRequiresUserGesture: false,
    allowsInlineMediaPlayback: true,
    isInspectable: kDebugMode,
  );

  @override
  void initState() {
    super.initState();
    _initWebView();
    log(widget.url);
  }

  Future<void> _initWebView() async {
    if (GetPlatform.isAndroid) {
      await InAppWebViewController.setWebContentsDebuggingEnabled(kDebugMode);

      final swAvailable = await WebViewFeature.isFeatureSupported(
        WebViewFeature.SERVICE_WORKER_BASIC_USAGE,
      );
      final swInterceptAvailable = await WebViewFeature.isFeatureSupported(
        WebViewFeature.SERVICE_WORKER_SHOULD_INTERCEPT_REQUEST,
      );

      if (swAvailable && swInterceptAvailable) {
        final serviceWorkerController = ServiceWorkerController.instance();
        await serviceWorkerController.setServiceWorkerClient(
          ServiceWorkerClient(
            shouldInterceptRequest: (request) async {
              if (kDebugMode) {
                print(request);
              }
              return null;
            },
          ),
        );
      }
    }
  }

  void _onUserExit() {
    if (_paymentCompleted) {
      Get.back();
      return;
    }

    if (!_canRedirect) {
      Get.back();
      return;
    }

    if (widget.fromPage == 'booking-due-payment' || widget.fromPage == 'switch-payment-method') {
      Get.back();
      PaymentRedirectHandler.handlePaymentResult(
        fromPage: widget.fromPage ?? '',
        flag: 'fail',
      );
      return;
    }

    SafeContext.whenAvailable((context) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return CustomPopWidget(
            child: AlertDialog(
              contentPadding: EdgeInsets.all(Dimensions.paddingSizeSmall),
              content: PaymentFailedDialog(
                isAddFound: widget.fromPage == 'add-fund',
              ),
            ),
          );
        },
      );
    });
  }

  void _pageRedirect(String? url) {
    if (url == null || !_canRedirect) {
      return;
    }

    printLog('url:$url');

    final baseUrl = ApiUrlHelper.resolveBaseUrl();
    final isSuccess = url.contains('success') &&
        url.contains(baseUrl) &&
        url.contains('flag');
    final isFailed = url.contains('fail') &&
        url.contains(baseUrl) &&
        url.contains('flag');
    final isCancel = url.contains('cancel') &&
        url.contains(baseUrl) &&
        url.contains('flag');

    if (!isSuccess && !isFailed && !isCancel) {
      return;
    }

    _canRedirect = false;
    _paymentCompleted = true;

    PaymentRedirectHandler.handleRedirectUrl(
      fromPage: widget.fromPage ?? '',
      url: url,
      closeCurrentRoute: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _onUserExit();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: CustomAppBar(
          title: 'payment'.tr,
          onBackPressed: _onUserExit,
        ),
        body: SafeArea(
          child: Stack(
            children: [
              InAppWebView(
                key: _webViewKey,
                initialUrlRequest: URLRequest(url: WebUri(widget.url)),
                initialSettings: _webViewSettings,
                onLoadStart: (controller, url) {
                  setState(() => _isLoading = true);
                  _pageRedirect(url?.toString());
                },
                onLoadStop: (controller, url) {
                  setState(() => _isLoading = false);
                  _pageRedirect(url?.toString());
                },
                onReceivedError: (controller, request, error) {
                  setState(() => _isLoading = false);
                  if (kDebugMode) {
                    print("Can't load [${request.url}] Error: ${error.description}");
                  }
                },
                onProgressChanged: (controller, progress) {
                  if (progress == 100) {
                    setState(() => _isLoading = false);
                  }
                },
                shouldOverrideUrlLoading: (controller, navigationAction) async {
                  return NavigationActionPolicy.ALLOW;
                },
                onCreateWindow: (controller, createWindowAction) async {
                  final url = createWindowAction.request.url;
                  if (url != null) {
                    await controller.loadUrl(urlRequest: URLRequest(url: url));
                  }
                  return true;
                },
              ),
              if (_isLoading)
                Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
