import 'package:demandium/util/core_export.dart';
import 'package:get/get.dart';

class ImageDialog extends StatelessWidget {
  final String imageUrl;
  final String? title;
  final String? subTitle;
  final String? actionButtonText;
  final VoidCallback? onActionPressed;
  const ImageDialog({
    super.key,
    required this.imageUrl,
    this.title,
    this.subTitle,
    this.actionButtonText,
    this.onActionPressed,
  });

  bool get _hasDisplayableImage {
    final url = imageUrl.trim().toLowerCase();
    if (url.isEmpty) {
      return false;
    }
    return !url.contains('placeholder');
  }

  bool get _hasTitle => title != null && title!.trim().isNotEmpty;
  bool get _hasSubTitle => subTitle != null && subTitle!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
      ),
      backgroundColor: Theme.of(context).cardColor,
      clipBehavior: Clip.antiAliasWithSaveLayer,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: ResponsiveHelper.isDesktop(context) ? 480 : 420,
          maxHeight: screenHeight * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_hasTitle) _DialogHeader(title: title!.trim()),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  Dimensions.paddingSizeDefault,
                  Dimensions.paddingSizeSmall,
                  Dimensions.paddingSizeDefault,
                  actionButtonText != null && onActionPressed != null
                      ? Dimensions.paddingSizeSmall
                      : Dimensions.paddingSizeDefault,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_hasDisplayableImage) _DialogImage(imageUrl: imageUrl),
                    if (_hasSubTitle) ...[
                      SizedBox(height: _hasDisplayableImage ? Dimensions.paddingSizeDefault : 0),
                      Text(
                        subTitle!.trim(),
                        textAlign: TextAlign.start,
                        style: robotoRegular.copyWith(
                          fontSize: Dimensions.fontSizeDefault,
                          color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.65),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (actionButtonText != null && onActionPressed != null)
              _DialogFooter(
                actionButtonText: actionButtonText!,
                onActionPressed: onActionPressed!,
              ),
          ],
        ),
      ),
    );
  }
}

class _DialogHeader extends StatelessWidget {
  final String title;

  const _DialogHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Dimensions.paddingSizeDefault,
            Dimensions.paddingSizeDefault,
            Dimensions.paddingSizeDefault,
            0,
          ),
          child: Text(
            title,
            textAlign: TextAlign.start,
            style: robotoBold.copyWith(
              fontSize: Dimensions.fontSizeLarge,
              color: Theme.of(context).textTheme.bodyLarge?.color,
              height: 1.25,
            ),
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
        Divider(
          height: 1,
          thickness: 1,
          color: Theme.of(context).hintColor.withValues(alpha: 0.15),
        ),
      ],
    );
  }
}

class _DialogFooter extends StatelessWidget {
  final String actionButtonText;
  final VoidCallback onActionPressed;

  const _DialogFooter({
    required this.actionButtonText,
    required this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Divider(
          height: 1,
          thickness: 1,
          color: Theme.of(context).hintColor.withValues(alpha: 0.15),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Dimensions.paddingSizeDefault,
            Dimensions.paddingSizeDefault,
            Dimensions.paddingSizeDefault,
            Dimensions.paddingSizeLarge,
          ),
          child: Center(
            child: CustomButton(
              height: 44,
              width: 200,
              buttonText: actionButtonText,
              onPressed: () {
                Get.back();
                onActionPressed();
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _DialogImage extends StatelessWidget {
  final String imageUrl;

  const _DialogImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxHeight: 280),
        color: context.adaptivePrimaryColor.withValues(alpha: 0.08),
        child: CustomImage(image: imageUrl, fit: BoxFit.contain),
      ),
    );
  }
}
