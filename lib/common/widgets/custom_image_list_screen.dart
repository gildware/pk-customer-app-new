import 'package:demandium/common/widgets/custom_pop_widget.dart';
import 'package:demandium/util/core_export.dart';
import 'package:get/get.dart';


class ImageDetailScreen extends StatefulWidget {
  final List<String> imageList;
  final int index;
  final String? appbarTitle;
  final String? subTitle;
  final String? createdAt;
  const ImageDetailScreen({
    super.key,
    required this.imageList,
    required this.index,
    this.appbarTitle = "image_list",
    this.subTitle,
    this.createdAt,
  });

  @override
  State<ImageDetailScreen> createState() => _ImageDetailScreenState();
}

class _ImageDetailScreenState extends State<ImageDetailScreen> {
  AutoScrollController? scrollController;

  @override
  void initState() {

    if(widget.imageList.length ==1){
      Future.delayed(const Duration(milliseconds: 5), (){
        Get.offNamed(RouteHelper.getZoomImageScreen(
          image: widget.imageList[0],
          imagePath: widget.imageList[0],
          createdAt: widget.createdAt,
          appBarTitle: widget.appbarTitle,
          subTitle: widget.subTitle,
        ));

      });
    }else{
      scrollController = AutoScrollController(
        viewportBoundaryGetter: () => Rect.fromLTRB(0, 0, 0, MediaQuery.of(context).padding.bottom),
        axis: Axis.horizontal,
      );
      scrollController!.scrollToIndex(widget.index, preferPosition: AutoScrollPosition.middle);
      scrollController!.highlight(widget.index);
      super.initState();
    }

  }

  @override
  Widget build(BuildContext context) {
    return CustomPopWidget(
      child: Scaffold(
        endDrawer:ResponsiveHelper.isDesktop(context) ? const MenuDrawer():null,
        appBar: CustomAppBar(
          centerTitle: false,
          title: widget.appbarTitle,
          subTitle: widget.subTitle == null
              ? "${widget.imageList.length} ${'images'.tr}${widget.createdAt != null ? " • ${widget.createdAt}" : ""}"
              : null,
        ),
        body: FooterBaseView(
          child: Center(
            child: SizedBox(
              width: Dimensions.webMaxWidth,
              child: widget.imageList.length > 1
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (widget.subTitle?.isNotEmpty == true)
                          Container(
                            constraints: BoxConstraints(
                              maxHeight: MediaQuery.of(context).size.height * 0.28,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: Dimensions.paddingSizeDefault,
                              vertical: Dimensions.paddingSizeSmall,
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
                          ),
                        Expanded(
                          child: ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
                            itemCount: widget.imageList.length,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemBuilder: (BuildContext context, index) {
                              String imageUrl = widget.imageList[index];

                              return InkWell(
                                onDoubleTap: () {
                                  Get.toNamed(RouteHelper.getZoomImageScreen(
                                    image: widget.imageList[index],
                                    imagePath: imageUrl,
                                    createdAt: widget.createdAt,
                                    appBarTitle: widget.appbarTitle,
                                    subTitle: widget.subTitle,
                                  ));
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: context.adaptivePrimaryColor.withValues(alpha: 0.2),
                                  ),
                                  padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                                  margin: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
                                  child: AutoScrollTag(
                                    controller: scrollController!,
                                    key: ValueKey(index),
                                    index: index,
                                    child: Hero(
                                      tag: widget.imageList[index],
                                      child: CustomImage(
                                        image: imageUrl,
                                        fit: BoxFit.fitWidth,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    )
                  : const SizedBox(),
            ),
          ),
        ),
      ),
    );
  }
}