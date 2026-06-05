import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:demandium/util/app_constants.dart';
import 'package:url_launcher/url_launcher_string.dart';

/// Opens the Panun Kaergar Provider app when installed, otherwise the store listing.
class ProviderAppLauncher {
  static const MethodChannel _channel =
      MethodChannel('com.sixamtech.demandium.user/provider_app');

  static Future<void> open() async {
    if (GetPlatform.isWeb) {
      await _launchWeb(
        '${AppConstants.baseUrl}/provider/auth/sign-up',
      );
      return;
    }

    if (GetPlatform.isAndroid || GetPlatform.isIOS) {
      try {
        await _channel.invokeMethod<bool>('openProviderApp', {
          'packageName': AppConstants.providerAndroidPackageId,
          'fallbackPackageNames': AppConstants.providerAndroidFallbackPackageIds,
          'playStoreUrl': AppConstants.providerPlayStoreUrl,
          'appStoreId': AppConstants.providerIosAppStoreId,
          'urlSchemes': AppConstants.providerIosUrlSchemes,
          'appStoreUrl': AppConstants.providerAppStoreUrl,
        });
        return;
      } on PlatformException {
        // Fall through to url_launcher below.
      }
    }

    await _fallbackLaunch();
  }

  static Future<void> _fallbackLaunch() async {
    if (GetPlatform.isIOS) {
      await _launchStore(AppConstants.providerIosAppStoreUri);
      return;
    }
    if (GetPlatform.isAndroid) {
      await _launchStore(
        'market://details?id=${AppConstants.providerAndroidPackageId}',
      );
      return;
    }
  }

  static Future<void> _launchStore(String url) async {
    if (await canLaunchUrlString(url)) {
      await launchUrlString(
        url,
        mode: LaunchMode.externalNonBrowserApplication,
      );
      return;
    }
    final httpsFallback = GetPlatform.isIOS
        ? AppConstants.providerAppStoreUrl
        : AppConstants.providerPlayStoreUrl;
    await _launchWeb(httpsFallback);
  }

  static Future<void> _launchWeb(String url) async {
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url, mode: LaunchMode.externalApplication);
    }
  }
}
