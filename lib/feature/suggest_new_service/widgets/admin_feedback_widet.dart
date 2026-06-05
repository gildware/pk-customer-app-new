import 'package:demandium/common/widgets/custom_image.dart';
import 'package:demandium/feature/suggest_new_service/controller/suggest_service_controller.dart';
import 'package:demandium/util/dimensions.dart';
import 'package:demandium/util/styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AdminFeedbackBottomSheet extends StatelessWidget {
 final int index;

  const AdminFeedbackBottomSheet({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: Get.width,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(Dimensions.paddingSizeDefault), topRight: Radius.circular(Dimensions.paddingSizeDefault))
      ),
      padding: EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
      child: SingleChildScrollView(
        child: GetBuilder<SuggestServiceController>(builder: (controller){
          return Stack(children: [
            Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: Dimensions.paddingSizeExtraMoreLarge,
                  height: Dimensions.paddingSizeExtraSmall,
                  decoration: BoxDecoration(
                    color: Theme.of(context).hintColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall)
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeExtraLarge),

                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor , borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    border: Border.all(color: Theme.of(context).hintColor.withValues(alpha:0.2)),
                  ),
                  padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                  margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start,children: [
                    Row(children: [
                      if(controller.suggestedServiceList[index].category != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                          child: CustomImage(
                            height: 20, width: 20, fit: BoxFit.cover,
                            image: controller.suggestedServiceList[index].category?.imageFullPath??"",
                          ),
                        ),

                      Expanded(child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                        child: Text(
                          controller.suggestedServiceList[index].category?.name??"",
                          style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      )),
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
                      TextSpan(text: controller.suggestedServiceList[index].serviceName ?? "", style: robotoRegular.copyWith(
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
                              textTheme.bodyLarge!.color,
                              fontSize: Dimensions.fontSizeDefault,
                              fontWeight: FontWeight.w400
                          ),
                        ),
                        TextSpan(text: ' ',
                          style: robotoRegular.copyWith(
                              color: Theme.of(Get.context!).
                              textTheme.bodyLarge!.color,
                              fontSize: Dimensions.fontSizeDefault,
                              fontWeight: FontWeight.w400
                          ),
                        ),
                        TextSpan(text: controller.suggestedServiceList[index].serviceDescription ?? "", style: robotoRegular.copyWith(
                            color: Theme.of(Get.context!).
                            textTheme.bodyLarge!.color!.withValues(alpha:0.6),
                            fontSize: Dimensions.fontSizeDefault,
                            fontWeight: FontWeight.w400
                        )),
                      ])),
                    ),
                  ]),
                ),
                const SizedBox(height: Dimensions.paddingSizeSmall),

                Container(
                  decoration: BoxDecoration(
                      color: Theme.of(context).hintColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall)
                  ),
                  margin: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                  padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                  child: Column(children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('feedback_by_admin'.tr, style: robotoMedium),

                      controller.suggestedServiceList[index].adminFeedback != null && controller.suggestedServiceList[index].adminFeedback != "" ?
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall)
                        ),
                        padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeTine),
                        child: Text('review'.tr, style: robotoRegular.copyWith(color: Theme.of(context).colorScheme.secondary)),
                      ) : const SizedBox()
                    ]),
                    const SizedBox(height: Dimensions.paddingSizeSmall),

                    controller.suggestedServiceList[index].adminFeedback != null && controller.suggestedServiceList[index].adminFeedback != "" ?
                    Text(
                      controller.suggestedServiceList[index].adminFeedback.toString(),
                      style: robotoRegular.copyWith(color: Theme.of(context).
                      textTheme.bodyLarge!.color!.withValues(alpha:0.5) ,
                        fontSize: Dimensions.fontSizeDefault,
                      ),textAlign: TextAlign.justify,
                    ):Text(
                      controller.suggestedServiceList[index].status=="pending" ?
                      "under_review".tr :
                      "no_feedback_is_available".tr,
                      style: robotoRegular.copyWith(color: Theme.of(context).
                      textTheme.bodyLarge!.color!.withValues(alpha:0.5) ,
                        fontSize: Dimensions.fontSizeDefault,
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: Dimensions.paddingSizeLarge)
              ]),

            Positioned(
             top: 0, right: Dimensions.paddingSizeSmall,
              child: InkWell(
                onTap: ()=> Get.back(),
                child: Icon(Icons.close, color: Theme.of(context).hintColor.withValues(alpha: 0.7)
                ),
              ),
            ),
          ]);
        }),
      ),
    );
  }
}