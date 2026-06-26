import 'package:demandium/util/core_export.dart';

class CustomImage extends StatelessWidget {
  final String? image;
  final double? height;
  final double? width;
  final BoxFit? fit;
  final BoxFit? placeHolderBoxFit;
  final String? placeholder;

  const CustomImage({
    super.key,
    required this.image,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.placeHolderBoxFit,
  });

  bool _isGif(String? url) {
    if (url == null) return false;
    return url.toLowerCase().endsWith('.gif');
  }

  String _resolvePlaceholderAsset() => Images.resolvePlaceholder(placeholder);

  Widget _placeholderWidget(BuildContext context) {
    return Image.asset(
      _resolvePlaceholderAsset(),
      height: height,
      width: width,
      fit: placeHolderBoxFit ?? fit,
    );
  }

  @override
  Widget build(BuildContext context) {
    final rawUrl = image?.trim() ?? '';
    if (rawUrl.isEmpty) {
      return _placeholderWidget(context);
    }

    final resolvedUrl = MobileAppIconHelper.normalizeMediaUrl(rawUrl) ?? rawUrl;
    final imageUrl = kIsWeb ? '${AppConstants.baseUrl}/image-proxy?url=$resolvedUrl' : resolvedUrl;

    // On web, use Image.network for GIFs to preserve animation
    if (kIsWeb && _isGif(imageUrl)) {
      return Image.network(
        imageUrl,
        height: height,
        width: width,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _placeholderWidget(context);
        },
        errorBuilder: (context, error, stackTrace) {
          return _placeholderWidget(context);
        },
      );
    }

    // Use CachedNetworkImage for mobile or non-GIF images
    return CachedNetworkImage(
      imageUrl: imageUrl,
      height: height,
      width: width,
      fit: fit,
      placeholder: (context, url) => _placeholderWidget(context),
      errorWidget: (context, url, error) => _placeholderWidget(context),
    );
  }
}
