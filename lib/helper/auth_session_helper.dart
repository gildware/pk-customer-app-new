import 'dart:async';
import 'dart:convert';

import 'package:demandium/feature/bottomNav/controller/bottom_nav_controller.dart';
import 'package:demandium/helper/address_session_helper.dart';
import 'package:get/get.dart';
import 'package:demandium/util/core_export.dart';

/// Keeps [SecureTokenStorage], [ApiClient.token], and request headers aligned.
class AuthSessionHelper {
  AuthSessionHelper._();

  static bool _authRecoveryInFlight = false;

  /// Clears expired auth and routes away from a stale main shell (e.g. after 401 on `/`).
  static Future<void> recoverFromExpiredAuth({
    Response? response,
    bool showSnackBar = true,
  }) async {
    if (_authRecoveryInFlight || !Get.isRegistered<AuthController>()) {
      return;
    }
    if (!Get.find<AuthController>().isLoggedIn()) {
      return;
    }

    _authRecoveryInFlight = true;
    try {
      await Get.find<AuthController>().clearSharedData(
        response: response,
        clearAddress: false,
      );

      if (Get.isRegistered<BottomNavController>()) {
        Get.find<BottomNavController>().changePage(BnbItem.homePage);
      }

      final route = Get.currentRoute.split('?').first;
      final onMainShell =
          route == RouteHelper.getInitialRoute() || route == RouteHelper.home;

      if (onMainShell) {
        if (!AddressSessionHelper.hasValidActiveAddress()) {
          runAfterFrame(() => AddressSessionHelper.redirectToAddressSetup());
        } else {
          runAfterFrame(() => Get.offAllNamed(RouteHelper.getSignInRoute(redirectUrl: RouteHelper.home)));
        }
      } else if (route != RouteHelper.getInitialRoute()) {
        runAfterFrame(() => Get.offAllNamed(RouteHelper.getInitialRoute()));
      }

      if (showSnackBar) {
        customSnackBar('url_session_expired'.tr, showDefaultSnackBar: true);
      }
    } finally {
      _authRecoveryInFlight = false;
    }
  }

  /// Reloads the token from secure storage and reapplies API headers.
  /// Required after hot restart/reload because [ApiClient] only reads the token once in its constructor.
  static Future<void> syncFromStorage() async {
    if (!Get.isRegistered<SharedPreferences>()) {
      return;
    }

    final sharedPreferences = Get.find<SharedPreferences>();
    await SecureTokenStorage.preload(sharedPreferences);

    if (!Get.isRegistered<ApiClient>()) {
      return;
    }

    final apiClient = Get.find<ApiClient>();
    final token = SecureTokenStorage.cachedToken();
    apiClient.token = token.isEmpty ? null : token;

    AddressModel? addressModel;
    try {
      final addressJson = sharedPreferences.getString(AppConstants.userAddress);
      if (addressJson != null && addressJson.isNotEmpty) {
        addressModel = AddressModel.fromJson(jsonDecode(addressJson));
      }
    } catch (_) {}

    String? guestId;
    if (Get.isRegistered<SplashController>()) {
      guestId = Get.find<SplashController>().getGuestId();
    }
    guestId ??= sharedPreferences.getString(AppConstants.guestId);

    apiClient.updateHeader(
      apiClient.token,
      addressModel?.zoneId,
      sharedPreferences.getString(AppConstants.languageCode),
      guestId,
    );
  }
}
