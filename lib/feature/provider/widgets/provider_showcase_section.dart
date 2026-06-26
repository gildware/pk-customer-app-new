import 'package:demandium/util/core_export.dart';
import 'package:get/get.dart';

class ProviderShowcaseSection extends StatelessWidget {
  final bool showTitle;
  const ProviderShowcaseSection({super.key, this.showTitle = true});

  @override
  Widget build(BuildContext context) {
    final items = Get.find<ProviderBookingController>()
            .providerDetailsContent
            ?.showcaseItems ??
        [];

    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
        child: NoDataScreen(text: 'no_showcase_items'.tr, type: NoDataType.provider),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(
        Dimensions.paddingSizeDefault,
        Dimensions.paddingSizeDefault,
        Dimensions.paddingSizeDefault,
        Dimensions.paddingSizeLarge,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showTitle) ...[
            Text(
              'work_showcase'.tr,
              style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge),
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),
          ],
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: ResponsiveHelper.isDesktop(context) ? 4 : 2,
              crossAxisSpacing: Dimensions.paddingSizeDefault,
              mainAxisSpacing: Dimensions.paddingSizeDefault,
              childAspectRatio: 0.9,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _ShowcaseTile(item: item, index: index, items: items);
            },
          ),
        ],
      ),
    );
  }
}

class _ShowcaseTile extends StatelessWidget {
  final ProviderShowcaseItem item;
  final int index;
  final List<ProviderShowcaseItem> items;

  const _ShowcaseTile({
    required this.item,
    required this.index,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _openPreview(context),
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          border: Border.all(color: Theme.of(context).hintColor.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(Dimensions.radiusDefault),
                ),
                child: item.isVideo
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Container(color: context.adaptivePrimaryColor.withValues(alpha: 0.08)),
                          Center(
                            child: Icon(
                              Icons.play_circle_fill,
                              size: 44,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      )
                    : CustomImage(
                        image: item.mediaFullPath ?? '',
                        fit: BoxFit.cover,
                        placeholder: Images.servicePlaceholder,
                      ),
              ),
            ),
            if (item.title?.isNotEmpty == true || item.description?.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.title?.isNotEmpty == true)
                      Text(
                        item.title!,
                        style: robotoMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (item.description?.isNotEmpty == true)
                      Text(
                        item.description!,
                        style: robotoRegular.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          color: Theme.of(context).hintColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openPreview(BuildContext context) {
    if (item.isVideo && item.mediaFullPath != null) {
      Get.dialog(
        Dialog(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: Get.height * 0.85),
            child: Padding(
              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close),
                    ),
                  ),
                  SizedBox(
                    height: 220,
                    width: Get.width * 0.85,
                    child: _ShowcaseVideoPlayer(url: item.mediaFullPath!),
                  ),
                  if (item.title?.isNotEmpty == true || item.description?.isNotEmpty == true)
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (item.title?.isNotEmpty == true)
                              Text(item.title!, style: robotoBold),
                            if (item.description?.isNotEmpty == true)
                              Text(item.description!, style: robotoRegular),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
      return;
    }

    final imageUrls = items
        .where((e) => !e.isVideo && e.mediaFullPath != null)
        .map((e) => e.mediaFullPath!)
        .toList();
    final imageIndex = imageUrls.indexOf(item.mediaFullPath ?? '');
    if (imageUrls.isNotEmpty && imageIndex >= 0) {
      Get.to(() => ImageDetailScreen(
            imageList: imageUrls,
            index: imageIndex,
            appbarTitle: item.title?.isNotEmpty == true ? item.title : 'work_showcase'.tr,
            subTitle: item.description?.isNotEmpty == true ? item.description : null,
          ));
    }
  }
}

class _ShowcaseVideoPlayer extends StatefulWidget {
  final String url;
  const _ShowcaseVideoPlayer({required this.url});

  @override
  State<_ShowcaseVideoPlayer> createState() => _ShowcaseVideoPlayerState();
}

class _ShowcaseVideoPlayerState extends State<_ShowcaseVideoPlayer> {
  late VideoPlayerController _controller;
  ChewieController? _chewieController;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        _chewieController = ChewieController(
          videoPlayerController: _controller,
          autoInitialize: true,
          aspectRatio: _controller.value.aspectRatio,
        );
        if (mounted) {
          setState(() {});
        }
      }).catchError((_) {
        if (mounted) {
          setState(() => _loadFailed = true);
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadFailed) {
      return const VideoPlaceholder();
    }
    if (_chewieController == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Chewie(controller: _chewieController!);
  }
}
