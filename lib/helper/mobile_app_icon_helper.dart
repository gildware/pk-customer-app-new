import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
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

  static bool _isLocalDevHost(String host) {
    final normalized = host.toLowerCase();
    return normalized == 'localhost' ||
        normalized == '127.0.0.1' ||
        normalized.endsWith('.local');
  }

  /// Align same-origin `/storage` URLs with [AppConstants.baseUrl]. External CDN URLs (R2, S3) are left unchanged.
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
      if (!parsed.hasScheme || !parsed.hasAuthority) {
        return trimmed;
      }

      var path = parsed.path;
      if (path.startsWith('/public/storage/')) {
        path = path.replaceFirst('/public/storage/', '/storage/');
      }
      if (path.startsWith('/storage/') || path.startsWith('/assets/')) {
        return '$_apiBase$path';
      }

      final base = Uri.parse(AppConstants.baseUrl);
      final host = parsed.host.toLowerCase();

      // Rewrite only local dev hosts (e.g. artisan serve) to the configured API base.
      if (_isLocalDevHost(host)) {
        return Uri(
          scheme: base.scheme,
          host: base.host,
          port: base.hasPort ? base.port : null,
          path: path.isNotEmpty ? path : parsed.path,
        ).toString();
      }

      // Same API host — normalize port if needed, otherwise keep URL.
      if (host == base.host.toLowerCase()) {
        if (parsed.port != base.port) {
          return Uri(
            scheme: base.scheme,
            host: base.host,
            port: base.hasPort ? base.port : null,
            path: parsed.path,
            query: parsed.query.isEmpty ? null : parsed.query,
          ).toString();
        }
        return trimmed;
      }

      // External CDN / object storage (R2, S3, CloudFront, etc.).
      return trimmed;
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
    final resolved = normalizeMediaUrl(url);
    if (_isBundledDefaultIconPath(resolved)) {
      return null;
    }
    return resolved;
  }

  /// API default icons live under `mobile-app-defaults` and are already bundled in the app.
  static bool _isBundledDefaultIconPath(String? url) {
    if (url == null || url.isEmpty) {
      return false;
    }
    return url.contains('mobile-app-defaults/');
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

  /// Bottom navigation uses Material icons in white only so icons stay crisp
  /// on the primary bar (tinting colored PNGs breaks transparent cutouts).
  static Widget bottomNavIcon({
    required String iconKey,
    required bool isSelected,
    double size = 20,
  }) {
    final iconData = _bottomNavMaterialIcon(iconKey, isSelected);
    return Icon(
      iconData,
      size: size,
      color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.6),
    );
  }

  static IconData _bottomNavMaterialIcon(String iconKey, bool isSelected) {
    switch (iconKey) {
      case 'bottom_home':
        return isSelected ? Icons.home_rounded : Icons.home_outlined;
      case 'bookings':
        return isSelected ? Icons.assignment_rounded : Icons.assignment_outlined;
      case 'my_favorite':
        return isSelected ? Icons.favorite_rounded : Icons.favorite_border_rounded;
      case 'bottom_more':
        return isSelected ? Icons.apps_rounded : Icons.apps_outlined;
      case 'custom_post':
        return isSelected ? Icons.post_add_rounded : Icons.post_add_outlined;
      default:
        return Icons.circle_outlined;
    }
  }

  /// Profile menu list icons — primary in light mode, white in dark mode.
  static Widget profileMenuIcon({
    required String iconKey,
    required Color color,
    double size = 20,
  }) {
    return Icon(
      _profileMenuMaterialIcon(iconKey),
      size: size,
      color: color,
    );
  }

  static IconData _profileMenuMaterialIcon(String iconKey) {
    switch (iconKey) {
      case 'my_address':
        return Icons.location_on_outlined;
      case 'notifications':
        return Icons.notifications_outlined;
      case 'suggest_new_service':
        return Icons.post_add_outlined;
      case 'delete_account':
        return Icons.person_remove_outlined;
      case 'logout':
        return Icons.logout_rounded;
      case 'sign_in':
        return Icons.login_rounded;
      default:
        return Icons.circle_outlined;
    }
  }

  static String _networkImageUrl(String resolvedUrl) {
    return kIsWeb ? '${AppConstants.baseUrl}/image-proxy?url=$resolvedUrl' : resolvedUrl;
  }

  static Set<String> _allIconUrls() {
    final urls = <String>{};
    final icons = _icons;
    if (icons != null) {
      for (final entry in icons.values) {
        for (final value in entry.values) {
          final resolved = normalizeMediaUrl(value);
          if (resolved != null &&
              resolved.isNotEmpty &&
              !_isBundledDefaultIconPath(resolved)) {
            urls.add(_networkImageUrl(resolved));
          }
        }
      }
    }

    final logo = appLogoUrl();
    if (logo != null && logo.isNotEmpty) {
      urls.add(_networkImageUrl(logo));
    }

    return urls;
  }

  /// Downloads menu / branding icons into the image cache so the More sheet opens without flicker.
  static Future<void>? _readyFuture;

  static void invalidateCache() {
    _readyFuture = null;
  }

  static Future<void> ensureReady(BuildContext context) {
    return _readyFuture ??= _downloadAll(context);
  }

  static Future<void> precacheAll() {
    final context = Get.context;
    if (context == null || !context.mounted) {
      return Future.value();
    }
    return ensureReady(context);
  }

  static Future<void> _downloadAll(BuildContext context) async {
    final urls = _allIconUrls();
    if (urls.isEmpty) {
      return;
    }

    await Future.wait(urls.map((url) async {
      try {
        await precacheImage(CachedNetworkImageProvider(url), context);
      } catch (_) {
        //
      }
    }));
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

    final imageUrl = MobileAppIconHelper._networkImageUrl(url!);

    return Image(
      key: ValueKey(imageUrl),
      image: CachedNetworkImageProvider(imageUrl),
      width: width,
      height: height,
      fit: fit,
      color: color,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) {
          return child;
        }
        return SizedBox(width: width, height: height);
      },
      errorBuilder: (_, error, stack) => Image.asset(
        fallbackAsset,
        width: width,
        height: height,
        fit: fit,
        color: color,
      ),
    );
  }
}
