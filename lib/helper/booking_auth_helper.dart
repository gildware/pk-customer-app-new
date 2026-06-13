import 'package:get/get.dart';
import 'package:demandium/util/core_export.dart';

class BookingAuthHelper {
  static bool get guestCheckoutEnabled {
    return Get.find<SplashController>().configModel.content?.guestCheckout == 1;
  }

  static bool get requiresLoginToBook => !guestCheckoutEnabled;

  /// Returns true when the caller should stop (login redirect was triggered).
  static bool redirectToLoginIfRequired({String? redirectUrl, String pageTitle = 'booking'}) {
    if (!requiresLoginToBook) {
      return false;
    }
    if (Get.find<AuthController>().isLoggedIn()) {
      return false;
    }

    final encodedRoute = Uri.encodeComponent(redirectUrl ?? RouteHelper.initial);
    Get.toNamed(RouteHelper.getNotLoggedScreen(encodedRoute, pageTitle));
    return true;
  }

  static Future<void> ensureGuestSessionIfNeeded() async {
    if (!guestCheckoutEnabled) {
      return;
    }

    final splashController = Get.find<SplashController>();
    if (splashController.getGuestId().isEmpty) {
      await splashController.setGuestId(const Uuid().v1());
    }

    await Get.find<ApiClient>().refreshGuestSessionHeaders();
    try {
      await GuestSessionHelper.ensureRegistered(splashController.getGuestId());
    } catch (_) {}
  }

  static bool shouldSyncCartFromServer() {
    return Get.find<AuthController>().isLoggedIn() || guestCheckoutEnabled;
  }
}
