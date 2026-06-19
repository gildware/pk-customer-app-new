import 'package:demandium/helper/app_startup.dart';
import 'package:get/get.dart';
import 'package:demandium/util/core_export.dart';

class SplashScreen extends StatefulWidget {
  final NotificationBody? body;
  final String? route;
  const SplashScreen({super.key, required this.body, this.route});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  final GlobalKey<ScaffoldState> _globalKey = GlobalKey();
  StreamSubscription<List<ConnectivityResult>>? _onConnectivityChanged;
  bool _configFailed = false;

  @override
  void initState() {
    super.initState();

    bool firstTime = true;
    _onConnectivityChanged = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> result) {
      if(!firstTime) {
        bool isNotConnected = result.every((status) => status == ConnectivityResult.none);
        isNotConnected ? const SizedBox() : ScaffoldMessenger.of(Get.context!).hideCurrentSnackBar();
        ScaffoldMessenger.of(Get.context!).showSnackBar(SnackBar(
          backgroundColor: isNotConnected ? Colors.red : Colors.green,
          duration: Duration(seconds: isNotConnected ? 6000 : 3),
          content: Text(
            isNotConnected ? 'no_connection'.tr : 'connected'.tr,
            textAlign: TextAlign.center,
          ),
        ));
        if(!isNotConnected) {
          _route();
        }
      }
      firstTime = false;
    });

    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final splashController = Get.find<SplashController>();
    await splashController.initSharedData();
    await Get.find<AuthRepo>().preloadRememberMeCredentials();

    if (splashController.getGuestId().isEmpty) {
      await splashController.setGuestId(const Uuid().v1());
    }

    await AuthSessionHelper.syncFromStorage();

    if (Get.find<AuthController>().isLoggedIn()) {
      await Get.find<AuthController>().updateToken();
    }

    _route();
  }

  @override
  void dispose() {
    super.dispose();
    _onConnectivityChanged?.cancel();
  }

  void _route() {
    if (mounted) {
      setState(() => _configFailed = false);
    }
    Get.find<SplashController>().getConfigData().then((isSuccess) async {
      if (!isSuccess) {
        if (mounted) setState(() => _configFailed = true);
        return;
      }

      try {
        await Get.find<LocationController>().refreshSavedAddressZone();
      } catch (e, stack) {
        ErrorLogger.record(e, stack, reason: 'splash refreshSavedAddressZone');
      }

      await BookingAuthHelper.ensureGuestSessionIfNeeded();

      await AppStartup.ensureDeferredReady();
      if (!mounted) return;

      if (!ResponsiveHelper.isWeb()) {
        unawaited(DigitalPaymentLauncher.tryResumePendingVerification());
      }

      final notificationBody = widget.body ?? AppStartup.initialNotificationBody;

      try {
        if (_checkAvailableUpdate()) {
          Get.offNamed(RouteHelper.getUpdateRoute('update'));
        } else if (_checkMaintenanceModeActive() && !AppConstants.avoidMaintenanceMode) {
          Get.offAllNamed(RouteHelper.getMaintenanceRoute());
        } else if (notificationBody != null) {
          _notificationRoute(notificationBody);
        } else if (Get.find<SplashController>().isShowInitialLanguageScreen()) {
          Get.offNamed(RouteHelper.getLanguageScreen('fromOthers'));
        } else if (Get.find<SplashController>().isShowOnboardingScreen()) {
          Get.offAllNamed(RouteHelper.onBoardScreen);
        } else {
          final canContinue = await AddressSessionHelper.ensureAddressBeforeContinue();
          if (!mounted || !canContinue) return;
          Get.offNamed(RouteHelper.getInitialRoute());
        }
      } catch (e, stack) {
        ErrorLogger.record(e, stack, reason: 'splash navigation');
        if (mounted) setState(() => _configFailed = true);
      }
    }).catchError((e, stack) {
      ErrorLogger.record(e, stack, reason: 'splash getConfigData');
      if (mounted) setState(() => _configFailed = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _globalKey,
      body: GetBuilder<SplashController>(builder: (splashController) {
        PriceConverter.getCurrency();
        if (_configFailed) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'failed_to_load_configuration'.tr,
                    textAlign: TextAlign.center,
                    style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeLarge),
                  CustomButton(buttonText: 'retry'.tr, onPressed: _route),
                ],
              ),
            ),
          );
        }
        return Center(
          child: splashController.hasConnection ? SplashLogoWidget() : NoInternetScreen(child: SplashScreen(body: widget.body)),
        );
      }),
    );
  }

  bool _checkAvailableUpdate (){
    ConfigModel? configModel = Get.find<SplashController>().configModel;
    final localVersion = Version.parse(AppConstants.appVersion);
    final serverVersion = Version.parse(GetPlatform.isAndroid
        ? configModel.content?.minimumVersion?.minVersionForAndroid ?? ""
        :  configModel.content?.minimumVersion?.minVersionForIos ?? ""
    );
    return localVersion.compareTo(serverVersion) == -1;
  }

  bool _checkMaintenanceModeActive(){
    final ConfigModel configModel = Get.find<SplashController>().configModel;
    return (configModel.content?.maintenanceMode?.maintenanceStatus == 1 && configModel.content?.maintenanceMode?.selectedMaintenanceSystem?.mobileApp == 1);
  }

  void _notificationRoute(NotificationBody notificationBody){

    String notificationType = notificationBody.notificationType??"";

    switch(notificationType) {

      case "chatting": {
        Get.toNamed(RouteHelper.getInboxScreenRoute(fromNotification: "fromNotification"));
      } break;

      case "bidding": {
        Get.toNamed(RouteHelper.getMyPostScreen(fromNotification: "fromNotification"));
      } break;

      case "booking" || 'booking_ignored': {
        if( notificationBody.bookingId!=null&& notificationBody.bookingId!=""){
          if(notificationBody.bookingType == "repeat" && notificationBody.repeatBookingType == "single"){
            Get.toNamed(RouteHelper.getBookingDetailsScreen( subBookingId : notificationBody.bookingId!,fromPage: 'fromNotification'));
          }else if(notificationBody.bookingType == "repeat" && notificationBody.repeatBookingType != "single"){
            Get.toNamed(RouteHelper.getRepeatBookingDetailsScreen( bookingId : notificationBody.bookingId, fromPage : "fromNotification"));
          }else{
            Get.toNamed(RouteHelper.getBookingDetailsScreen( bookingID:notificationBody.bookingId!,fromPage: 'fromNotification'));
          }
        }else{
          Get.toNamed(RouteHelper.getMainRoute(""));
        }
      } break;

      case "privacy_policy": {
        Get.toNamed(RouteHelper.getPrivacyPolicyRoute());
      } break;

      case "terms_and_conditions": {
        Get.toNamed(RouteHelper.getTermsAndConditionsRoute());
      } break;

      case "wallet": {
        Get.toNamed(RouteHelper.getMyWalletScreen(fromNotification: "fromNotification"));
      } break;

      case "loyalty_point": {
        Get.toNamed(RouteHelper.getLoyaltyPointScreen(fromNotification: "fromNotification"));
      } break;

      case "service": {
        if (NotificationHelper.isServiceNotification(notificationBody)) {
          NotificationHelper.navigateToServiceNotification(notificationBody);
        } else {
          Get.toNamed(RouteHelper.getNotificationRoute());
        }
      } break;

      default: {
        Get.toNamed(RouteHelper.getNotificationRoute());
      } break;
    }
  }
}

class SplashLogoWidget extends StatelessWidget {
  const SplashLogoWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          MobileAppIconHelper.appLogo(width: Dimensions.logoSize),
          const SizedBox(height: Dimensions.paddingSizeLarge),
        ],
      ),
    );
  }
}
