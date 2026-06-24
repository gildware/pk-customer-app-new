import 'package:demandium/helper/app_startup.dart';
import 'package:get/get.dart';
import 'package:url_strategy/url_strategy.dart';
import 'util/core_export.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && AppConstants.sslPinSha256.isNotEmpty) {
    HttpOverrides.global = CertificatePinningHttpOverrides(
      expectedPinSha256: AppConstants.sslPinSha256,
    );
  }
  setPathUrlStrategy();

  final languages = await AppStartup.prepareForRunApp();

  if (!kIsWeb && GetPlatform.isMobile) {
    FirebaseMessaging.onBackgroundMessage(myBackgroundMessageHandler);
  }

  runApp(MyApp(languages: languages));
  AppStartup.scheduleDeferredInit(flutterLocalNotificationsPlugin);
}

class MyApp extends StatefulWidget {
  final Map<String, Map<String, String>>? languages;
  const MyApp({super.key, required this.languages});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void reassemble() {
    super.reassemble();
    AuthSessionHelper.syncFromStorage();
  }

  Future<void> _route() async {
    final success = await Get.find<SplashController>().getConfigData();
    await Get.find<LocationController>().refreshSavedAddressZone();
    if (Get.find<AuthController>().isLoggedIn()) {
      await Get.find<AuthController>().updateToken();
    }
    await BookingAuthHelper.ensureGuestSessionIfNeeded();
    if (success && Get.isRegistered<CartController>() && BookingAuthHelper.shouldSyncCartFromServer()) {
      await Get.find<CartController>().getCartListFromServer();
    }
  }

  @override
  void initState() {
    super.initState();

    if (kIsWeb || AppStartup.initialDeepLinkPath != null) {
      _prepareSessionAndRoute();
    }
  }

  Future<void> _prepareSessionAndRoute() async {
    await Get.find<SplashController>().initSharedData();
    Get.find<SplashController>().getCookiesData();
    await Get.find<AuthRepo>().preloadRememberMeCredentials();
    await AuthSessionHelper.syncFromStorage();

    if (Get.find<AuthController>().isLoggedIn()) {
      await Get.find<UserController>().getUserInfo();
    }

    if (Get.find<SplashController>().getGuestId().isEmpty) {
      await Get.find<SplashController>().setGuestId(const Uuid().v1());
    }

    await _route();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeController>(builder: (themeController) {
      return GetBuilder<LocalizationController>(builder: (localizeController) {
        return GetBuilder<SplashController>(builder: (splashController) {
          if (kIsWeb &&
              splashController.configModel.content == null &&
              !Get.currentRoute.contains('/splash')) {
            return const Material(
              child: SplashLogoWidget(),
            );
          }

          return GetMaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            navigatorKey: Get.key,
            scrollBehavior: const MaterialScrollBehavior().copyWith(
              dragDevices: {PointerDeviceKind.mouse, PointerDeviceKind.touch},
            ),
            theme: themeController.darkTheme ? dark : light,
            locale: localizeController.locale,
            translations: Messages(languages: widget.languages),
            fallbackLocale: Locale(
              AppConstants.languages[0].languageCode!,
              AppConstants.languages[0].countryCode,
            ),
            initialRoute: GetPlatform.isWeb
                ? RouteHelper.getInitialRoute()
                : RouteHelper.getSplashRoute(null, AppStartup.initialDeepLinkPath),
            getPages: RouteHelper.routes,
            defaultTransition: Transition.fadeIn,
            transitionDuration: const Duration(milliseconds: 200),
            builder: (context, widget) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1)),
              child: Material(
                color: Colors.transparent,
                child: SafeArea(
                  top: false,
                  bottom: GetPlatform.isAndroid,
                  child: Stack(
                    children: [
                      if (widget != null) widget,
                      GetBuilder<SplashController>(builder: (splashController) {
                        if (!splashController.savedCookiesData ||
                            !splashController.getAcceptCookiesStatus(
                              splashController.configModel.content?.cookiesText ?? '',
                            )) {
                          return ResponsiveHelper.isWeb()
                              ? const Align(
                                  alignment: Alignment.bottomCenter,
                                  child: CookiesView(),
                                )
                              : const SizedBox();
                        }
                        return const SizedBox();
                      }),
                    ],
                  ),
                ),
              ),
            ),
          );
        });
      });
    });
  }
}
