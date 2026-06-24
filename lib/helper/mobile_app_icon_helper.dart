import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:demandium/feature/splash/controller/splash_controller.dart';
import 'package:demandium/common/widgets/custom_image.dart';
import 'package:demandium/util/app_constants.dart';
import 'package:demandium/util/images.dart';

/// Resolves menu / branding icons from admin `mobile_app_icons` API or bundled assets.
class MobileAppIconHelper {
  static const String appLogoKey = 'customer_app_logo';

  static const String heroTag = 'app_logo';

  static Map<String, Map<String, String?>>? get _icons {
    final raw = Get.find<SplashController>().configModel.content?.mobileAppIcons;
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return raw;
  }

  static bool get _isDark => Get.isDarkMode;

  static String get _apiBase {
    var base = AppConstants.baseUrl.trim();
    if (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }
    return base;
  }

  /// Align icon URLs with [AppConstants.baseUrl] (fixes APP_URL vs local API host mismatch).
  static String? normalizeMediaUrl(String? url) {
    if (url == null) {
      return null;
    }
    final trimmed = url.trim();
    if (trimmed.isEmpty || trimmed == 'null') {
      return null;
    }

    if (trimmed.startsWith('/storage/')) {
      return '$_apiBase$trimmed';
    }
    if (trimmed.startsWith('/assets/')) {
      return '$_apiBase$trimmed';
    }
    if (trimmed.startsWith('storage/')) {
      return '$_apiBase/$trimmed';
    }

    try {
      final parsed = Uri.parse(trimmed);
      var path = parsed.path;
      if (path.startsWith('/public/storage/')) {
        path = path.replaceFirst('/public/storage/', '/storage/');
      }
      if (path.startsWith('/storage/')) {
        return '$_apiBase$path';
      }
      final base = Uri.parse(AppConstants.baseUrl);
      final host = parsed.host.toLowerCase();
      if (host == 'localhost' ||
          host == '127.0.0.1' ||
          parsed.host != base.host ||
          parsed.port != base.port) {
        return Uri(
          scheme: base.scheme,
          host: base.host,
          port: base.hasPort ? base.port : null,
          path: path.isNotEmpty ? path : parsed.path,
        ).toString();
      }
    } catch (_) {
      //
    }
    return trimmed;
  }

  static String? remoteUrl(String iconKey) {
    final entry = _icons?[iconKey];
    if (entry == null) {
      return null;
    }
    final url = _isDark ? (entry['dark'] ?? entry['light']) : (entry['light'] ?? entry['dark']);
    return normalizeMediaUrl(url);
  }

  /// Admin mobile app logo → business logo → bundled asset.
  static String? appLogoUrl() {
    final custom = remoteUrl(appLogoKey);
    if (custom != null && custom.isNotEmpty) {
      return custom;
    }
    final business = normalizeMediaUrl(
      Get.find<SplashController>().configModel.content?.logoFullPath,
    );
    if (business != null && business.isNotEmpty) {
      return business;
    }
    return null;
  }

  static Widget appLogo({
    required double width,
    double? height,
    BoxFit fit = BoxFit.contain,
    bool useHero = false,
    String? heroTag,
    String? fallbackAsset,
  }) {
    return _BrandedLogo(
      width: width,
      height: height,
      fit: fit,
      fallbackAsset: fallbackAsset ?? Images.logo,
      useHero: useHero,
      heroTag: heroTag,
    );
  }

  static Widget icon({
    required String iconKey,
    required String fallbackAsset,
    double height = 30,
    double width = 30,
    BoxFit fit = BoxFit.contain,
    Color? color,
  }) {
    return _BrandedIcon(
      iconKey: iconKey,
      fallbackAsset: fallbackAsset,
      height: height,
      width: width,
      fit: fit,
      color: color,
    );
  }
}

class _BrandedLogo extends StatelessWidget {
  final double width;
  final double? height;
  final BoxFit fit;
  final String fallbackAsset;
  final bool useHero;
  final String? heroTag;

  const _BrandedLogo({
    required this.width,
    this.height,
    required this.fit,
    required this.fallbackAsset,
    this.useHero = false,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SplashController>(
      builder: (_) {
        final h = height ?? width;
        final remote = MobileAppIconHelper.appLogoUrl();

        Widget child = remote != null
            ? CustomImage(
                key: ValueKey(remote),
                image: remote,
                width: width,
                height: h,
                fit: fit,
              )
            : Image.asset(fallbackAsset, width: width, height: h, fit: fit);

        if (useHero) {
          child = Hero(
            tag: heroTag ?? MobileAppIconHelper.heroTag,
            child: child,
          );
        }

        return child;
      },
    );
  }
}

class _BrandedIcon extends StatelessWidget {
  final String iconKey;
  final String fallbackAsset;
  final double height;
  final double width;
  final BoxFit fit;
  final Color? color;

  const _BrandedIcon({
    required this.iconKey,
    required this.fallbackAsset,
    required this.height,
    required this.width,
    required this.fit,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SplashController>(
      builder: (_) {
        return _NetworkOrAssetImage(
          url: MobileAppIconHelper.remoteUrl(iconKey),
          width: width,
          height: height,
          fit: fit,
          fallbackAsset: fallbackAsset,
          color: color,
        );
      },
    );
  }
}

class _NetworkOrAssetImage extends StatelessWidget {
  final String? url;
  final double width;
  final double height;
  final BoxFit fit;
  final String fallbackAsset;
  final Color? color;

  const _NetworkOrAssetImage({
    required this.url,
    required this.width,
    required this.height,
    required this.fit,
    required this.fallbackAsset,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return Image.asset(
        fallbackAsset,
        width: width,
        height: height,
        fit: fit,
        color: color,
      );
    }

    return Image.network(
      url!,
      key: ValueKey(url),
      width: width,
      height: height,
      fit: fit,
      color: color,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, error, stack) => Image.asset(
        fallbackAsset,
        width: width,
        height: height,
        fit: fit,
        color: color,
      ),
      loadingBuilder: (context, child, progress) {
        if (progress == null) {
          return child;
        }
        return SizedBox(
          width: width,
          height: height,
          child: Center(
            child: SizedBox(
              width: width * 0.35,
              height: width * 0.35,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).primaryColor.withValues(alpha: 0.4),
              ),
            ),
          ),
        );
      },
    );
  }
}
