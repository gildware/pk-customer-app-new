import 'package:demandium/feature/suggest_new_service/widgets/admin_feedback_widet.dart';
import 'package:demandium/util/core_export.dart';
import 'package:demandium/feature/suggest_new_service/model/suggest_service_model.dart';
import 'package:get/get.dart';

class SuggestServiceItemView extends StatelessWidget {
  final SuggestedService suggestedService;
  final int index;

  const SuggestServiceItemView({super.key, required this.suggestedService, required this.index}) ;

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeEight),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor , borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          border: Border.all(color: Theme.of(context).hintColor.withValues(alpha:0.5)),
        ),
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,children: [
          Row(children: [
            if(suggestedService.category != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                child: CustomImage(
                  height: 20, width: 20, fit: BoxFit.cover,
                  image: suggestedService.category?.imageFullPath??"",
                ),
              ),

            Expanded(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
              child: Text(
                suggestedService.category?.name??"",
                style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
            )),

            Container(
              decoration: BoxDecoration(
                  color: Theme.of(context).hintColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall)
              ),
              padding: EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall, horizontal: Dimensions.paddingSizeSmall),
              child: Tooltip(
                message: suggestedService.adminFeedback ?? suggestedService.status.toString().tr,
                child: InkWell(
                  onTap: () => Get.bottomSheet(AdminFeedbackBottomSheet(index: index)),
                  child: Image.asset(
                    Images.approvedStatusIcon, width: 20,
                    color: suggestedService.status=="pending"?
                    Theme.of(context).primaryColor : suggestedService.status=="denied"?Theme.of(context).colorScheme.error : null,
                  ),
                ),
              ),
            ),
          ]),
          const SizedBox(height: Dimensions.paddingSizeExtraSmall),

          RichText(text: TextSpan(children: <TextSpan>[
            TextSpan(text: "suggested_service".tr,
              style: robotoRegular.copyWith(
                  color: Theme.of(Get.context!).
                  textTheme.bodyLarge!.color!.withValues(alpha:0.6),
                  fontSize: Dimensions.fontSizeDefault,
                  fontWeight: FontWeight.w400
              ),
            ),
            TextSpan(text: ' ',
              style: robotoRegular.copyWith(
                  color: Theme.of(Get.context!).
                  textTheme.bodyLarge!.color!.withValues(alpha:0.6),
                  fontSize: Dimensions.fontSizeDefault,
                  fontWeight: FontWeight.w400
              ),
            ),
            TextSpan(text: suggestedService.serviceName ?? "", style: robotoRegular.copyWith(
                color: Theme.of(Get.context!).
                textTheme.bodyLarge!.color,
                fontSize: Dimensions.fontSizeDefault,
                fontWeight: FontWeight.w400
            )),
          ])),
          const SizedBox(height: Dimensions.paddingSizeSmall),

          Container(
            width: Get.width,
            decoration: BoxDecoration(
                color: Theme.of(context).hintColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall)
            ),
            padding: EdgeInsets.all(Dimensions.paddingSizeSmall),
            child: RichText(text: TextSpan(children: <TextSpan>[
              TextSpan(text: "description".tr,
                style: robotoRegular.copyWith(
                    color: Theme.of(Get.context!).
                    textTheme.bodyLarge!.color!.withValues(alpha:0.6),
                    fontSize: Dimensions.fontSizeDefault,
                    fontWeight: FontWeight.w400
                ),
              ),
              TextSpan(text: ' ',
                style: robotoRegular.copyWith(
                    color: Theme.of(Get.context!).
                    textTheme.bodyLarge!.color!.withValues(alpha:0.6),
                    fontSize: Dimensions.fontSizeDefault,
                    fontWeight: FontWeight.w400
                ),
              ),
              TextSpan(text: suggestedService.serviceDescription ?? "", style: robotoRegular.copyWith(
                  color: Theme.of(Get.context!).
                  textTheme.bodyLarge!.color,
                  fontSize: Dimensions.fontSizeDefault,
                  fontWeight: FontWeight.w400
              )),
            ])),
          ),
        ]),
      ),
    );
  }
}

