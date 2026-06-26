import 'package:demandium/util/images.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Full-bleed video fallback that always fills its parent box.
class VideoPlaceholder extends StatelessWidget {
  final double? height;
  final double? width;
  final bool showPlayIcon;

  const VideoPlaceholder({
    super.key,
    this.height,
    this.width,
    this.showPlayIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;

    return SizedBox(
      height: height,
      width: width,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            Images.videoPlaceholder,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          if (showPlayIcon)
            LayoutBuilder(
              builder: (context, constraints) {
                final maxSide = constraints.maxWidth.isFinite && constraints.maxHeight.isFinite
                    ? constraints.maxWidth < constraints.maxHeight
                        ? constraints.maxWidth
                        : constraints.maxHeight
                    : constraints.maxWidth.isFinite
                        ? constraints.maxWidth
                        : constraints.maxHeight.isFinite
                            ? constraints.maxHeight
                            : 120.0;
                final iconSize = (maxSide * 0.22).clamp(40.0, 80.0);

                return Center(
                  child: Container(
                    padding: EdgeInsets.all(iconSize * 0.35),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(iconSize * 0.2),
                      border: Border.all(
                        color: (isDark ? const Color(0xFF6B7280) : const Color(0xFF9AA8B8))
                            .withValues(alpha: 0.55),
                        width: 2,
                      ),
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      size: iconSize,
                      color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9AA8B8),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

/// Fallback UI when network images or videos fail to load.
class MediaPlaceholder extends StatelessWidget {
  final double? height;
  final double? width;
  final BoxFit fit;
  final String? asset;
  final bool _isVideo;

  const MediaPlaceholder({
    super.key,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.asset,
    bool isVideo = false,
  }) : _isVideo = isVideo;

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
      asset: Images.servicePlaceholder,
    );
  }

  factory MediaPlaceholder.video({double? height, double? width, BoxFit fit = BoxFit.cover}) {
    return MediaPlaceholder(
      height: height,
      width: width,
      isVideo: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isVideo) {
      return VideoPlaceholder(height: height, width: width);
    }

    final resolvedAsset = Images.resolvePlaceholder(asset);
    final image = Image.asset(
      resolvedAsset,
      fit: fit,
      width: width ?? double.infinity,
      height: height ?? double.infinity,
    );

    if (height != null || width != null) {
      return SizedBox(height: height, width: width, child: image);
    }
    return image;
  }
}
