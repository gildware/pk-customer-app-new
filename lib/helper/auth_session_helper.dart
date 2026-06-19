import 'dart:convert';

import 'package:get/get.dart';
import 'package:demandium/util/core_export.dart';

/// Keeps [SecureTokenStorage], [ApiClient.token], and request headers aligned.
class AuthSessionHelper {
  AuthSessionHelper._();

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
