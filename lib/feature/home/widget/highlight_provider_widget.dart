import 'package:demandium/feature/home/helper/advertisement_video_helper.dart';
import 'package:demandium/util/core_export.dart';
import 'package:get/get.dart';

double _highlightCardWidth(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  return width < 400 ? width * 0.74 : width * 0.68;
}

double _highlightMediaHeight(double cardWidth) => cardWidth / 2;

double _highlightVideoRowHeight(BuildContext context) {
  final cardWidth = _highlightCardWidth(context);
  return _highlightMediaHeight(cardWidth) + 56;
}

double _highlightProfileRowHeight(BuildContext context) {
  final cardWidth = _highlightCardWidth(context);
  return _highlightMediaHeight(cardWidth) + 68;
}

class _HighlightSectionBadge extends StatelessWidget {
  const _HighlightSectionBadge();

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFFFC107);
    const amber = Color(0xFFFF9800);
    final primary = Theme.of(context).colorScheme.primary;

    Widget sparkle(IconData icon, double size, {Color? color}) {
      return ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) => LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: color != null ? [color, color] : const [gold, amber],
        ).createShader(bounds),
        child: Icon(icon, size: size, color: Colors.white),
      );
    }

    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: 2,
            top: 6,
            child: sparkle(Icons.auto_awesome, 30),
          ),
          Positioned(
            right: 28,
            top: 0,
            child: sparkle(Icons.star_rounded, 12, color: primary.withValues(alpha: 0.85)),
          ),
          Positioned(
            right: 0,
            bottom: 4,
            child: sparkle(Icons.star_rounded, 10, color: primary.withValues(alpha: 0.65)),
          ),
          Positioned(
            right: 34,
            bottom: 10,
            child: sparkle(Icons.auto_awesome, 9, color: gold.withValues(alpha: 0.9)),
          ),
        ],
      ),
    );
  }
}

class _HighlightAdvertisementList extends StatelessWidget {
  final List<Advertisement> items;
  final bool isVideo;

  const _HighlightAdvertisementList({
    required this.items,
    required this.isVideo,
  });

  @override
  Widget build(BuildContext context) {
    final rowHeight = isVideo
        ? _highlightVideoRowHeight(context)
        : _highlightProfileRowHeight(context);

    return SizedBox(
      height: rowHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: Dimensions.paddingSizeSmall),
        itemBuilder: (context, index) => SizedBox(
          width: _highlightCardWidth(context),
          child: isVideo
              ? AdvertisementVideoPromotionWidget(
                  advertisement: items[index],
                  compact: true,
                )
              : AdvertisementProfilePromotionWidget(
                  advertisement: items[index],
                  index: index,
                  compact: true,
                ),
        ),
      ),
    );
  }
}

class HighlightProviderSection extends StatelessWidget {
  final List<Advertisement> items;
  final String title;
  final String subtitle;
  final bool isVideo;

  const HighlightProviderSection({
    super.key,
    required this.items,
    required this.title,
    required this.subtitle,
    required this.isVideo,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox();
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        color: Theme.of(context).colorScheme.primary.withValues(alpha: Get.isDarkMode ? 0.2 : 0.1),
      ),
      child: Stack(
        alignment: Get.find<LocalizationController>().isLtr ? Alignment.topRight : Alignment.topLeft,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                  child: Text(
                    title,
                    style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                  child: Text(
                    subtitle,
                    style: robotoRegular.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: Theme.of(context).hintColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeSmall),
                _HighlightAdvertisementList(items: items, isVideo: isVideo),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
            child: _HighlightSectionBadge(),
          ),
        ],
      ),
    );
  }
}

class HighlightProviderSections extends StatelessWidget {
  final String? videoTitleOverride;

  const HighlightProviderSections({super.key, this.videoTitleOverride});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AdvertisementController>(builder: (advertisementController) {
      final list = advertisementController.advertisementList;
      if (list == null) {
        return const AdvertisementShimmer(isVideo: true);
      }

      final videos = list.where((ad) => ad.type == 'video_promotion').toList();
      final profiles = list.where((ad) => ad.type == 'profile_promotion').toList();
      if (videos.isEmpty && profiles.isEmpty) {
        return const SizedBox();
      }

      final videoTitle = (videoTitleOverride != null && videoTitleOverride!.trim().isNotEmpty)
          ? videoTitleOverride!.trim()
          : 'expert_videos'.tr;
      final profileTitle = 'profile_promotions'.tr;

      return Column(
        children: [
          if (videos.isNotEmpty)
            HighlightProviderSection(
              items: videos,
              title: videoTitle,
              subtitle: 'see_our_most_popular_providers_and_service'.tr,
              isVideo: true,
            ),
          if (videos.isNotEmpty && profiles.isNotEmpty)
            const SizedBox(height: Dimensions.paddingSizeDefault),
          if (profiles.isNotEmpty)
            HighlightProviderSection(
              items: profiles,
              title: profileTitle,
              subtitle: 'see_our_most_popular_providers_and_service'.tr,
              isVideo: false,
            ),
        ],
      );
    });
  }
}


class HighlightProviderWidget extends StatelessWidget {
  final String? titleOverride;
  const HighlightProviderWidget({super.key, this.titleOverride});

  @override
  Widget build(BuildContext context) {
    return HighlightProviderSections(videoTitleOverride: titleOverride);
  }
}

class WebHighlightProviderWidget extends StatelessWidget {
  const WebHighlightProviderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Expanded(
      child: HighlightProviderSections(),
    );
  }
}


class AdvertisementVideoPromotionWidget extends StatefulWidget {
  final Advertisement advertisement;
  final bool compact;
  const AdvertisementVideoPromotionWidget({
    super.key,
    required this.advertisement,
    this.compact = false,
  });

  @override
  State<AdvertisementVideoPromotionWidget> createState() => _AdvertisementVideoPromotionWidgetState();
}

class _AdvertisementVideoPromotionWidgetState extends State<AdvertisementVideoPromotionWidget> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _disposed = false;
  bool _loadFailed = false;
  bool _isInitializing = false;
  bool _isPlaying = false;
  bool? _videoUrlReachable;

  bool get _showPlayButton =>
      widget.advertisement.hasPlayableVideo &&
      _videoUrlReachable == true &&
      !_loadFailed &&
      !_isPlaying;

  @override
  void initState() {
    super.initState();
    _verifyVideoUrl();
  }

  Future<void> _verifyVideoUrl() async {
    if (!widget.advertisement.hasPlayableVideo) {
      if (mounted) {
        setState(() => _videoUrlReachable = false);
      }
      return;
    }

    final reachable = await AdvertisementVideoHelper.isUrlReachable(
      widget.advertisement.promotionalVideoFullPath!,
    );

    if (!mounted || _disposed) {
      return;
    }

    setState(() {
      _videoUrlReachable = reachable;
      if (!reachable) {
        _loadFailed = true;
      }
    });
  }

  void _onVideoTick() {
    final controller = _videoPlayerController;
    if (_disposed || !mounted || controller == null || !controller.value.isInitialized) {
      return;
    }
    if (controller.value.hasError) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _handlePlaybackFailure());
      return;
    }
    if (controller.value.duration == controller.value.position) {
      Get.find<AdvertisementController>().updateAutoPlayStatus(status: true, shouldUpdate: true);
    }
  }

  Future<void> _handlePlaybackFailure() async {
    if (_disposed || !mounted) {
      return;
    }
    await _disposePlayer();
    if (mounted) {
      setState(() {
        _loadFailed = true;
        _isInitializing = false;
        _isPlaying = false;
        _videoUrlReachable = false;
      });
    }
  }

  Future<void> _disposePlayer() async {
    _chewieController?.dispose();
    _chewieController = null;
    final controller = _videoPlayerController;
    if (controller != null) {
      controller.removeListener(_onVideoTick);
      await controller.dispose();
      _videoPlayerController = null;
    }
  }

  Future<void> _startPlayback() async {
    if (!_showPlayButton || _isInitializing) {
      return;
    }

    setState(() => _isInitializing = true);

    try {
      if (_chewieController != null) {
        await _chewieController!.play();
        if (mounted) {
          setState(() {
            _isInitializing = false;
            _isPlaying = true;
          });
        }
        return;
      }

      final url = widget.advertisement.promotionalVideoFullPath!.trim();
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      _videoPlayerController = controller;
      controller.addListener(_onVideoTick);

      final initialized = await Future.any<bool>([
        controller.initialize().then((_) => true),
        Future<bool>.delayed(const Duration(seconds: 10), () => false),
      ]);

      if (!initialized || controller.value.hasError || !controller.value.isInitialized) {
        controller.removeListener(_onVideoTick);
        await controller.dispose();
        _videoPlayerController = null;
        throw Exception('video_unavailable');
      }

      if (_disposed || !mounted) {
        await controller.dispose();
        return;
      }

      _chewieController = ChewieController(
        videoPlayerController: controller,
        autoPlay: true,
        aspectRatio: controller.value.aspectRatio,
      );

      if (mounted) {
        setState(() {
          _isInitializing = false;
          _isPlaying = true;
        });
      }
    } catch (_) {
      if (!_disposed && mounted) {
        await _handlePlaybackFailure();
      }
    } finally {
      if (mounted && _isInitializing && !_isPlaying) {
        setState(() => _isInitializing = false);
      }
    }
  }

  Widget _buildVideoPoster() {
    final coverImage = widget.advertisement.providerCoverImageFullPath?.trim() ?? '';
    if (coverImage.isNotEmpty && !coverImage.contains('placeholder')) {
      return CustomImage(
        image: coverImage,
        height: double.infinity,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: Images.videoPlaceholderLight,
        placeHolderBoxFit: BoxFit.cover,
      );
    }
    return const VideoPlaceholder(showPlayIcon: false);
  }

  Widget _buildPlayOverlay({bool showLoading = false}) {
    if (showLoading) {
      return ColoredBox(
        color: Colors.black.withValues(alpha: 0.28),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.28),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.92),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.play_arrow_rounded,
            size: 36,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _chewieController?.dispose();
    final controller = _videoPlayerController;
    if (controller != null) {
      controller.removeListener(_onVideoTick);
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    List<String> subcategory=[];
    widget.advertisement.providerData?.subscribedServices?.forEach((element) {
      if(element.subCategory!=null){
        subcategory.add(element.subCategory?.name??"");
      }
    });

    String subcategories = subcategory.toString().replaceAll('[', '');
    subcategories = subcategories.replaceAll(']', '');
    subcategories = subcategories.replaceAll('&', ' and ');

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: widget.compact ? 0 : Dimensions.paddingSizeDefault,
      ),
      child: Column(
        children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(widget.compact ? Dimensions.radiusDefault : Dimensions.radiusLarge),
                topRight: Radius.circular(widget.compact ? Dimensions.radiusDefault : Dimensions.radiusLarge),
              ),
              child: AspectRatio(
                aspectRatio: widget.compact ? 2 : 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_isPlaying &&
                        _chewieController != null &&
                        _chewieController!.videoPlayerController.value.isInitialized)
                      Chewie(controller: _chewieController!)
                    else if (_showPlayButton || _isInitializing)
                      GestureDetector(
                        onTap: _isInitializing ? null : _startPlayback,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _buildVideoPoster(),
                            if (_showPlayButton || _isInitializing)
                              _buildPlayOverlay(showLoading: _isInitializing),
                          ],
                        ),
                      )
                    else
                      _buildVideoPoster(),
                  ],
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(widget.compact ? Dimensions.radiusDefault : Dimensions.radiusLarge),
                bottomRight: Radius.circular(widget.compact ? Dimensions.radiusDefault : Dimensions.radiusLarge),
              ),
              color: Theme.of(context).cardColor,
              boxShadow: Get.find<ThemeController>().darkTheme ? null : cardShadow,
            ),
            height: widget.compact
                ? 56
                : (ResponsiveHelper.isDesktop(context) ? 110 : 100),
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? Dimensions.paddingSizeDefault : Dimensions.paddingSizeLarge,
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center,children: [
              Row( children: [

                Expanded(
                  child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [

                    Text(widget.advertisement.title ?? "",
                      style: robotoBold.copyWith(
                        fontSize: widget.compact ? Dimensions.fontSizeDefault : Dimensions.fontSizeLarge,
                      ),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),

                    SizedBox(height: widget.compact ? 2 : Dimensions.paddingSizeSmall),
                    Text(
                      widget.advertisement.description ?? "",
                      style: robotoRegular.copyWith(
                        color: Theme.of(context).hintColor,
                        fontSize: widget.compact ? Dimensions.fontSizeSmall : null,
                      ),
                      maxLines: widget.compact ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ]),
                ),

                SizedBox(width: widget.compact ? Dimensions.paddingSizeSmall : Dimensions.paddingSizeLarge),

                InkWell(
                  onTap: () => Get.toNamed(RouteHelper.getProviderDetails( widget.advertisement.providerId! )),
                  child: Container(
                    margin: const EdgeInsets.only(top: Dimensions.paddingSizeExtraSmall),
                    padding: EdgeInsets.symmetric(
                      horizontal: widget.compact ? Dimensions.paddingSizeSmall : Dimensions.paddingSizeSmall + 5,
                      vertical: Dimensions.paddingSizeExtraSmall,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: widget.compact ? 16 : 20,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                )
              ],)
            ],),
          )
        ],
      ),
    );
  }
}

class AdvertisementProfilePromotionWidget extends StatelessWidget {
  final Advertisement advertisement;
  final int index;
  final bool compact;
  const AdvertisementProfilePromotionWidget({
    super.key,
    required this.advertisement,
    required this.index,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {


    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 0 : Dimensions.paddingSizeDefault,
      ),
      child: GetBuilder<AdvertisementController>(builder: (advertisementController){

        return InkWell(
          onTap: () => Get.toNamed(RouteHelper.getProviderDetails(advertisement.providerId!, )),
          child: Stack(children: [
            Column(
              children: [
                AspectRatio(
                  aspectRatio: compact ? 2 : 16 / 9,
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(compact ? Dimensions.radiusDefault : Dimensions.radiusLarge),
                      topRight: Radius.circular(compact ? Dimensions.radiusDefault : Dimensions.radiusLarge),
                    ),
                    child: CustomImage(
                      height: double.infinity, width: double.infinity,
                      image:  advertisement.providerCoverImageFullPath ?? "",
                    ),
                  ),
                ),
                Container(
                  constraints: BoxConstraints(
                    minHeight: compact
                        ? 68
                        : (ResponsiveHelper.isDesktop(context) ? 110 : 100),
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(compact ? Dimensions.radiusDefault : Dimensions.radiusLarge),
                      bottomRight: Radius.circular(compact ? Dimensions.radiusDefault : Dimensions.radiusLarge),
                    ),
                    color: Theme.of(context).cardColor,
                    boxShadow: Get.find<ThemeController>().darkTheme ? null : cardShadow,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? Dimensions.paddingSizeDefault : Dimensions.paddingSizeLarge,
                    vertical: Dimensions.paddingSizeExtraSmall,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row( children: [

                    ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: CustomImage(
                        image:  advertisement.providerProfileImageFullPath ??"",
                        height: compact ? 36 : 60,
                        width: compact ? 36 : 60,
                      ),
                    ),

                    SizedBox(width: compact ? Dimensions.paddingSizeSmall : Dimensions.paddingSizeDefault),

                    Expanded(
                      child: Column( crossAxisAlignment: CrossAxisAlignment.start,mainAxisAlignment: MainAxisAlignment.center, children: [

                        Text(advertisement.title ?? "",
                          style: robotoBold.copyWith(
                            fontSize: compact ? Dimensions.fontSizeDefault : Dimensions.fontSizeLarge,
                          ),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 2,),
                        Text(advertisement.description ?? "",
                          style: robotoRegular.copyWith(
                            color: Theme.of(context).hintColor,
                            fontSize: Dimensions.fontSizeSmall,
                          ),
                          maxLines: compact ? 1 : 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        if (!compact) ...[
                        const SizedBox(height: 2,),
                        Row(children: [
                          if(advertisement.providerRating == '1')
                          Row(children: [
                            Icon(Icons.star, color: Theme.of(context).colorScheme.secondary, size: Dimensions.fontSizeDefault),
                            Gaps.horizontalGapOf(5),

                            Directionality(
                              textDirection: TextDirection.ltr,
                              child: Text(
                                "${advertisement.providerData?.avgRating?.toStringAsFixed(1)}",
                                style: robotoRegular.copyWith(color: Theme.of(context).hintColor,fontSize: Dimensions.fontSizeSmall),
                              ),
                            ),
                          ]),

                          if(advertisement.providerRating == '1' && advertisement.providerReview == '1')
                          Container(
                            width: 1,height: 10,
                            margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall),
                            decoration: BoxDecoration(
                              color: context.adaptivePrimaryColor.withValues(alpha: 0.5),
                            ),
                          ),

                          if(advertisement.providerReview == '1')
                          Text('${advertisement.providerData?.ratingCount} ${'reviews'.tr}', style: robotoRegular.copyWith(
                              color: Theme.of(context).hintColor, fontSize: Dimensions.fontSizeSmall
                          )),
                        ])
                        ],
                      ]),
                    ),

                    const SizedBox(width: Dimensions.paddingSizeSmall,),

                    Align(
                      alignment: favButtonAlignment(),
                      child: FavoriteIconWidget(
                        isTap: false,
                        value: advertisement.providerData?.isFavorite,
                      ),
                    ),
                      ]),

                      if (!compact && advertisement.providerShowcase == '1' && (advertisement.showcaseItems?.isNotEmpty ?? false)) ...[
                        const SizedBox(height: Dimensions.paddingSizeSmall),
                        SizedBox(
                          height: 44,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: advertisement.showcaseItems!.length,
                            separatorBuilder: (_, __) => const SizedBox(width: Dimensions.paddingSizeSmall),
                            itemBuilder: (context, showcaseIndex) {
                              final item = advertisement.showcaseItems![showcaseIndex];
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                                child: item.isVideo
                                    ? Container(
                                        width: 44,
                                        height: 44,
                                        color: Theme.of(context).hintColor.withValues(alpha: 0.1),
                                        child: Icon(Icons.play_circle_outline, color: context.adaptivePrimaryColor, size: 22),
                                      )
                                    : CustomImage(
                                        image: item.mediaFullPath,
                                        width: 44,
                                        height: 44,
                                        fit: BoxFit.cover,
                                      ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                )
              ],
            ),
          ],
          ),
        );
      }),
    );
  }
}


class AdvertisementShimmer extends StatelessWidget {
  final bool isVideo;
  const AdvertisementShimmer({super.key, this.isVideo = true});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          color: Theme.of(context).cardColor ,
          boxShadow: Get.isDarkMode ? null : [BoxShadow(color: Colors.grey[300]!, blurRadius: 10, spreadRadius: 1)],
        ),
        margin:  EdgeInsets.only(
          top: ResponsiveHelper.isDesktop(context) ? Dimensions.paddingSizeLarge * 3.5 : 0 ,
          right: Get.find<LocalizationController>().isLtr && ResponsiveHelper.isDesktop(context) ? Dimensions.paddingSizeLarge : 0,
          left: !Get.find<LocalizationController>().isLtr && ResponsiveHelper.isDesktop(context) ? Dimensions.paddingSizeLarge : 0,
        ),
        child: Padding( padding : const EdgeInsets.symmetric(vertical : Dimensions.paddingSizeDefault),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
      
              const SizedBox(height: Dimensions.paddingSizeLarge,),
      
              Container(height: 20, width: 200,
                margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Theme.of(context).shadowColor
              ),),
      
              const SizedBox(height: Dimensions.paddingSizeSmall,),
      
              Container(height: 15, width: 250,
                margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                  color: Theme.of(context).shadowColor,
              ),),
      
              const SizedBox(height: Dimensions.paddingSizeDefault),

              SizedBox(
                height: isVideo ? _highlightVideoRowHeight(context) : _highlightProfileRowHeight(context),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                  itemCount: 2,
                  separatorBuilder: (_, __) => const SizedBox(width: Dimensions.paddingSizeSmall),
                  itemBuilder: (context, index) {
                    final cardWidth = _highlightCardWidth(context);
                    if (isVideo) {
                      return Container(
                        width: cardWidth,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                          color: Theme.of(context).shadowColor,
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(Dimensions.radiusDefault),
                                  ),
                                  color: Theme.of(context).shadowColor,
                                ),
                                child: const Center(
                                  child: Icon(Icons.play_circle, color: Colors.white, size: 36),
                                ),
                              ),
                            ),
                            Container(
                              height: 56,
                              padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.vertical(
                                  bottom: Radius.circular(Dimensions.radiusDefault),
                                ),
                                color: Theme.of(context).cardColor,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(height: 12, width: double.infinity, color: Theme.of(context).shadowColor),
                                        const SizedBox(height: 6),
                                        Container(height: 10, width: 100, color: Theme.of(context).shadowColor),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    height: 28,
                                    width: 28,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                                      color: Theme.of(context).shadowColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return Container(
                      width: cardWidth,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                        color: Theme.of(context).cardColor,
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(Dimensions.radiusDefault),
                                ),
                                color: Theme.of(context).shadowColor,
                              ),
                            ),
                          ),
                          Container(
                            height: 68,
                            padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                            child: Row(
                              children: [
                                Container(
                                  height: 36,
                                  width: 36,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Theme.of(context).shadowColor,
                                  ),
                                ),
                                const SizedBox(width: Dimensions.paddingSizeSmall),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(height: 12, width: double.infinity, color: Theme.of(context).shadowColor),
                                      const SizedBox(height: 6),
                                      Container(height: 10, width: 120, color: Theme.of(context).shadowColor),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: Dimensions.paddingSizeExtraSmall,),
            ],
          ),
        ),
      ),
    );
  }
}

class AdvertisementIndicator extends StatelessWidget {
  const AdvertisementIndicator({super.key});

  @override
  Widget build(BuildContext context) {

    return GetBuilder<AdvertisementController>(
      builder: (advertisementController) {
        return advertisementController.advertisementList != null && advertisementController.advertisementList!.length > 2?
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(height: 7, width: 7,
            decoration:  BoxDecoration(color: context.tabSelectedColor,
              shape: BoxShape.circle,
            ),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.center,
            children: advertisementController.advertisementList!.map((advertisement) {
              int index = advertisementController.advertisementList!.indexOf(advertisement);
              return index == advertisementController.currentIndex ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 10,vertical: 3),
                margin: const EdgeInsets.symmetric(horizontal: 6.0),
                decoration: BoxDecoration(
                    color: context.tabSelectedColor,
                    borderRadius: BorderRadius.circular(50)),
                child:  Text("${index+1}/ ${advertisementController.advertisementList!.length}",
                  style: const TextStyle(color: Colors.white,fontSize: 12),),
              ):const SizedBox();
            }).toList(),
          ),
          Container(height: 7, width: 7,

            decoration:  BoxDecoration(color: context.tabSelectedColor,
              shape: BoxShape.circle,
            ),
          )
        ],
        ): advertisementController.advertisementList != null && advertisementController.advertisementList!.length == 2 ?
        Align(
          alignment: Alignment.center,
          child: AnimatedSmoothIndicator(
            activeIndex: advertisementController.currentIndex,
            count: advertisementController.advertisementList!.length,
            effect: ExpandingDotsEffect(
              dotHeight: 7,
              dotWidth: 7,
              spacing: 5,
              activeDotColor: Theme.of(context).colorScheme.primary,
              dotColor: Theme.of(context).hintColor.withValues(alpha: 0.6),
            ),
          ),
        ): const SizedBox();
      }
    );
  }
}


