import 'package:get/get.dart';
import 'package:demandium/util/core_export.dart';

class TitleWidget extends StatelessWidget {
  final String? title;
  /// When set, shown as-is (admin custom section title). Otherwise [title] is translated.
  final String? displayTitle;
  final TextDecoration? textDecoration;
  final Function()? onTap;
  final bool isShowSeeAllButton;
  const TitleWidget({
    super.key,
    required this.title,
    this.displayTitle,
    this.onTap,
    this.textDecoration,
    required this.isShowSeeAllButton,
  });

  @override
  Widget build(BuildContext context) {
    final label = displayTitle ?? title!.tr;
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [

      Flexible(
        child: Text(label, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge,color: title=='recently_view_services'
            ? Colors.white:Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: .8),
        ),maxLines: 1,overflow: TextOverflow.ellipsis,),
      ),
      const SizedBox(width: Dimensions.paddingSizeSmall,),
      (isShowSeeAllButton) ? InkWell(
        onTap: onTap,
        child: Text('see_all'.tr,
          style: robotoRegular.copyWith(
            decoration: textDecoration,
            color:Get.isDarkMode ?Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: .8):
            title=='recently_view_services'? Colors.white : Theme.of(context).colorScheme.primary,
            fontSize: Dimensions.fontSizeLarge,
          ),
        ),
      ) : const SizedBox(),
    ]);
  }
}
