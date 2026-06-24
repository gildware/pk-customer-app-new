import 'package:demandium/util/core_export.dart';
import 'package:get/get.dart';

class ProviderCartItemView extends StatelessWidget {
  final ProviderData providerData;
  final int index;
  final bool compact;
  const ProviderCartItemView({
    super.key,
    required this.providerData,
    required this.index,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CartController>(builder: (cartController) {
      if (compact) {
        return _buildCompactItem(context, cartController);
      }
      return _buildDefaultItem(context, cartController);
    });
  }

  Widget _buildCompactItem(BuildContext context, CartController cartController) {
    final isSelected = cartController.selectedProviderIndex == index;
    final ratingCount = providerData.ratingCount ?? 0;
    final primary = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: () => cartController.updateProviderSelectedIndex(index),
      child: Container(
        margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeExtraSmall),
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeSmall,
          vertical: Dimensions.paddingSizeExtraSmall,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
          border: Border.all(
            color: isSelected ? primary : Theme.of(context).hintColor.withValues(alpha: 0.25),
            width: isSelected ? 1.2 : 0.5,
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
              child: CustomImage(
                image: "${providerData.logoFullPath}",
                height: 40,
                width: 40,
              ),
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          providerData.companyName ?? "",
                          style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      RatingBar(
                        rating: providerData.avgRating,
                        color: Theme.of(context).colorScheme.secondary,
                        size: 11,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        ratingCount > 0
                            ? '($ratingCount)'
                            : providerData.avgRating?.toStringAsFixed(1) ?? '0',
                        style: robotoRegular.copyWith(
                          fontSize: Dimensions.fontSizeExtraSmall,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          providerData.companyAddress ?? '',
                          style: robotoRegular.copyWith(
                            fontSize: Dimensions.fontSizeExtraSmall,
                            color: Theme.of(context).hintColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (providerData.distance != null) ...[
                        Image.asset(Images.distance, height: 10),
                        const SizedBox(width: 2),
                        Text(
                          "${providerData.distance!.toStringAsFixed(1)} ${'km'.tr}",
                          style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(left: Dimensions.paddingSizeExtraSmall),
                child: Icon(Icons.check_circle, color: primary, size: 18),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultItem(BuildContext context, CartController cartController) {
    final isLtr = Get.find<LocalizationController>().isLtr;
    final isSelected = cartController.selectedProviderIndex == index;
    final hasDistance = providerData.distance != null;
    final ratingCount = providerData.ratingCount ?? 0;

    return GestureDetector(
      onTap: () => cartController.updateProviderSelectedIndex(index),
      child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                border: Border.all(color: Theme.of(context).hintColor.withValues(alpha: 0.3)),
              ),
              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
              margin: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                    child: CustomImage(
                      image: "${providerData.logoFullPath}",
                      height: 60,
                      width: 60,
                    ),
                  ),
                  const SizedBox(width: Dimensions.paddingSizeDefault),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: isLtr ? 56 : 0,
                        left: isLtr ? 0 : 56,
                        bottom: hasDistance ? 20 : 0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            providerData.companyName ?? "",
                            style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if ((providerData.companyAddress ?? "").isNotEmpty) ...[
                            const SizedBox(height: Dimensions.paddingSizeTine),
                            Text(
                              providerData.companyAddress!,
                              style: robotoRegular.copyWith(
                                fontSize: Dimensions.fontSizeSmall,
                                color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: Dimensions.paddingSizeDefault,
              right: isLtr ? Dimensions.paddingSizeDefault : null,
              left: isLtr ? null : Dimensions.paddingSizeDefault,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RatingBar(
                    rating: providerData.avgRating,
                    color: Theme.of(context).colorScheme.secondary,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      ratingCount > 0
                          ? '$ratingCount ${'reviews'.tr}'
                          : providerData.avgRating?.toStringAsFixed(1) ?? '0',
                      style: robotoRegular.copyWith(
                        fontSize: Dimensions.fontSizeExtraSmall,
                        color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: Dimensions.paddingSizeDefault,
              right: isLtr ? Dimensions.paddingSizeDefault : null,
              left: isLtr ? null : Dimensions.paddingSizeDefault,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeExtraSmall),
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: Get.isDarkMode ? Colors.white60 : Theme.of(context).primaryColor,
                      ),
                    ),
                  if (hasDistance)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(Images.distance, height: 12),
                        const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                        Text(
                          "${providerData.distance!.toStringAsFixed(2)} ${'km'.tr}",
                          style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      );
  }
}
