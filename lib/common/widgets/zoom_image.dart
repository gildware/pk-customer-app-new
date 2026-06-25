import 'package:demandium/common/widgets/custom_pop_widget.dart';
import 'package:demandium/util/core_export.dart';
import 'package:photo_view/photo_view.dart';


class ZoomImage extends StatefulWidget {
  final String image;
  final String imagePath;
  final String? createdAt;
  final String? appBarTitle;
  final String? subTitle;
  const ZoomImage({
    super.key,
    required this.image,
    required this.imagePath,
    this.createdAt,
    this.appBarTitle,
    this.subTitle,
  });

  @override
  State<ZoomImage> createState() => _ZoomImageState();
}

class _ZoomImageState extends State<ZoomImage> {
  bool isZoomed = false;

  String? _appBarSubTitle() {
    final createdAt = widget.createdAt;
    if (createdAt != null && createdAt.isNotEmpty && createdAt != 'null') {
      return createdAt;
    }
    return null;
  }

  Widget? _descriptionSection(BuildContext context) {
    if (widget.subTitle == null || widget.subTitle!.isEmpty) {
      return null;
    }
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.28,
      ),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeDefault,
        vertical: Dimensions.paddingSizeSmall,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).hintColor.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: SingleChildScrollView(
        child: Text(
          widget.subTitle!,
          style: robotoRegular.copyWith(
            fontSize: Dimensions.fontSizeDefault,
            color: Theme.of(context).hintColor,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final descriptionSection = _descriptionSection(context);

    return CustomPopWidget(
      child: Scaffold(
        appBar: isZoomed ? null : CustomAppBar(
          title: widget.appBarTitle?.isNotEmpty == true ? widget.appBarTitle : '',
          subTitle: _appBarSubTitle(),
          centerTitle: false,
        ),
        endDrawer:ResponsiveHelper.isDesktop(context) ? const MenuDrawer():null,
        body: FooterBaseView(
          isScrollView: ResponsiveHelper.isDesktop(context) ? true : false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (descriptionSection != null) descriptionSection,
              Expanded(
                child: Center(
                  child: SizedBox(
                    width: ResponsiveHelper.isDesktop(context) ? 300 : Dimensions.webMaxWidth,
                    child: _ZoomableNetworkImage(
                      imagePath: widget.imagePath,
                      onScaleStateChanged: (value) {
                        setState(() {
                          isZoomed = value != PhotoViewScaleState.initial;
                        });
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ZoomableNetworkImage extends StatelessWidget {
  final String imagePath;
  final ValueChanged<PhotoViewScaleState> onScaleStateChanged;

  const _ZoomableNetworkImage({
    required this.imagePath,
    required this.onScaleStateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = MobileAppIconHelper.normalizeMediaUrl(imagePath) ?? imagePath;
    final imageUrl = kIsWeb ? '${AppConstants.baseUrl}/image-proxy?url=$resolvedUrl' : resolvedUrl;

    return PhotoView.customChild(
      initialScale: PhotoViewComputedScale.contained,
      minScale: PhotoViewComputedScale.contained,
      scaleStateChangedCallback: onScaleStateChanged,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.contain,
        placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
        errorWidget: (_, __, ___) => MediaPlaceholder(fit: BoxFit.contain),
      ),
    );
  }
}
