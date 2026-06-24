import 'package:demandium/firebase_options.dart';
import 'package:demandium/helper/analytics/analytics_helper.dart';
import 'package:demandium/helper/error_logger.dart';
import 'package:demandium/util/core_export.dart';
import 'package:demandium/helper/get_di.dart' as di;
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class AppStartup {
  AppStartup._();

  static Future<void>? _deferredFuture;
  static NotificationBody? initialNotificationBody;
  static String? initialDeepLinkPath;

  static Future<Map<String, Map<String, String>>> prepareForRunApp() async {
    final results = await Future.wait([
      di.init(),
      _initFirebase(),
    ]);
    return results.first as Map<String, Map<String, String>>;
  }

  static Future<void> _initFirebase() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      if (!kIsWeb) {
        await ErrorLogger.initialize();
      }
    } catch (e, stack) {
      ErrorLogger.record(e, stack, reason: 'Firebase.initializeApp');
    }
  }

  static void scheduleDeferredInit(FlutterLocalNotificationsPlugin notificationsPlugin) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _deferredFuture ??= _runDeferredInit(notificationsPlugin);
    });
  }

  static Future<void> ensureDeferredReady() {
    return _deferredFuture ?? Future.value();
  }

  static Future<void> _runDeferredInit(
    FlutterLocalNotificationsPlugin notificationsPlugin,
  ) async {
    final tasks = <Future<void>>[];

    if (ResponsiveHelper.isMobilePhone()) {
      tasks.add(_safeInit('FlutterDownloader', () async {
        await FlutterDownloader.initialize();
      }));
    }

    if (!kIsWeb) {
      tasks.add(_safeInit('AnalyticsHelper', AnalyticsHelper.init));
    }

    if (kIsWeb) {
      tasks.add(_safeInit('FacebookAuth', () async {
        await FacebookAuth.instance.webAndDesktopInitialize(
          appId: '482889663914976',
          cookie: true,
          xfbml: true,
          version: 'v15.0',
        );
      }));
    }

    if (!kIsWeb && GetPlatform.isMobile) {
      tasks.add(_safeInit('FCM permission', _requestNotificationPermission));
    }

    await Future.wait(tasks);

    if (Get.isRegistered<CompanyAvailabilityConfigWatcher>()) {
      Get.find<CompanyAvailabilityConfigWatcher>().start();
    }

    try {
      if (!kIsWeb) {
        initialDeepLinkPath = await _resolveInitialDeepLink();
      }

      if (!kIsWeb && GetPlatform.isMobile) {
        final remoteMessage = await FirebaseMessaging.instance.getInitialMessage();
        if (remoteMessage != null) {
          initialNotificationBody = NotificationHelper.convertNotification(remoteMessage.data);
        }
        await NotificationHelper.initialize(notificationsPlugin);
      }
    } catch (e, stack) {
      ErrorLogger.record(e, stack, reason: 'AppStartup.deferredNotifications');
    }
  }

  static Future<void> _requestNotificationPermission() async {
    if (GetPlatform.isIOS) {
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    } else if (GetPlatform.isAndroid) {
      await Permission.notification.request();
    }

    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  static Future<String?> _resolveInitialDeepLink() async {
    final appLinks = AppLinks();
    final uri = await appLinks.getInitialLink();
    return uri?.path;
  }

  static Future<void> _safeInit(String label, Future<void> Function() action) async {
    try {
      await action();
    } catch (e, stack) {
      ErrorLogger.record(e, stack, reason: 'AppStartup.$label');
    }
  }
}
