import 'package:demandium/util/images.dart';
import 'package:flutter/material.dart';

/// Fallback UI when network images or videos fail to load.
class MediaPlaceholder extends StatelessWidget {
  final double? height;
  final double? width;
  final BoxFit fit;
  final String asset;
  final bool showVideoIcon;

  MediaPlaceholder({
    super.key,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    String? asset,
    this.showVideoIcon = false,
  }) : asset = asset ?? Images.placeholder;

  factory MediaPlaceholder.category({double? height, double? width, BoxFit fit = BoxFit.cover}) {
    return MediaPlaceholder(
      height: height,
      width: width,
      fit: fit,
      asset: Images.categoryPlaceholder,
    );
  }

  factory MediaPlaceholder.service({double? height, double? width, BoxFit fit = BoxFit.cover}) {
    return MediaPlaceholder(
      height: height,
      width: width,
      fit: fit,
      asset: Images.categoryPlaceholder,
    );
  }

  factory MediaPlaceholder.video({double? height, double? width, BoxFit fit = BoxFit.cover}) {
    return MediaPlaceholder(
      height: height,
      width: width,
      fit: fit,
      asset: Images.placeholder,
      showVideoIcon: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width,
      child: Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
          Image.asset(
            asset,
            height: height,
            width: width,
            fit: fit,
          ),
          if (showVideoIcon)
            Icon(
              Icons.videocam_off_outlined,
              size: (height ?? 48) * 0.28,
              color: Theme.of(context).hintColor.withValues(alpha: 0.7),
            ),
        ],
      ),
    );
  }
}
