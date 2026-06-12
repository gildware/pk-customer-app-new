import 'package:demandium/feature/cart/model/service_booking_step.dart';
import 'package:demandium/feature/cart/widget/service_booking_flow_widget.dart';
import 'package:get/get.dart';
import 'package:demandium/util/core_export.dart';


class ServiceCenterDialog extends StatefulWidget {
  final Service? service;
  final CartModel? cart;
  final int? cartIndex;
  final bool? isFromDetails;
  final ProviderData? providerData;
  final double? minPurchasePrice;

  const ServiceCenterDialog({
    super.key,
    required this.service,
    this.cart,
    this.cartIndex,
    this.isFromDetails = false, this.providerData,
    this.minPurchasePrice
  });

  @override
  State<ServiceCenterDialog> createState() => _ProductBottomSheetState();
}

class _ProductBottomSheetState extends State<ServiceCenterDialog> {
  @override
  void initState() {
    super.initState();
    if (widget.service == null) return;
    Get.find<CartController>().resetBookingFlow(shouldUpdate: false);
    Get.find<CartController>().setInitialCartList(widget.service!);
    Get.find<CartController>().updatePreselectedProvider(null, shouldUpdate: false);
    Get.find<AllSearchController>().searchFocus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.service == null) {
      return Padding(
        padding: EdgeInsets.only(top: ResponsiveHelper.isWeb() ? 0 : Dimensions.cartDialogPadding),
        child: Container(
          padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusExtraLarge)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('no_service_available'.tr, style: robotoMedium),
              const SizedBox(height: Dimensions.paddingSizeDefault),
              CustomButton(buttonText: 'ok'.tr, onPressed: () => Get.back()),
            ],
          ),
        ),
      );
    }
    if(ResponsiveHelper.isDesktop(context)) {
      return  Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge)),
      insetPadding: const EdgeInsets.all(30),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      child: pointerInterceptor(),
    );
    }
    return pointerInterceptor();
  }

  Padding pointerInterceptor(){
    return Padding(
      padding: EdgeInsets.only(top: ResponsiveHelper.isWeb()? 0 :Dimensions.cartDialogPadding),
      child: PointerInterceptor(
        child: Container(
          width:ResponsiveHelper.isDesktop(context)? Dimensions.webMaxWidth/2:Dimensions.webMaxWidth,
          padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusExtraLarge)),
          ),
          child:  GetBuilder<CartController>(builder: (cartControllerInit) {
              return GetBuilder<ServiceController>(builder: (serviceController) {
                if(widget.service!.hasBookableVariations) {
                  final isBookingFlow = cartControllerInit.bookingStep != ServiceBookingStep.variations;
                  return Column(mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(width: Dimensions.paddingSizeLarge,),
                          if (!isBookingFlow)
                          ClipRRect(
                              borderRadius: const BorderRadius.all(Radius.circular(Dimensions.paddingSizeDefault)),
                              child: CustomImage(
                                image: '${widget.service!.thumbnailFullPath}',
                                height: Dimensions.imageSizeButton,
                                width: Dimensions.imageSizeButton,
                              ),
                            ),
                          Container(
                              height: 40, width: 40, alignment: Alignment.center,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white70.withValues(alpha: 0.6),
                                  boxShadow:Get.isDarkMode?null:[BoxShadow(
                                    color: Colors.grey[300]!, blurRadius: 2, spreadRadius: 1,
                                  )]
                              ),
                              child: InkWell(
                                  onTap: () => Get.back(),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.black54,
                                  )
                              ),
                            )
                        ],
                      ),
                      if (!isBookingFlow) ...[
                      const SizedBox(height: Dimensions.paddingSizeEight,),
                      Text(
                        widget.service!.name!,
                        style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                      ),
                      const SizedBox(height: Dimensions.paddingSizeMini,),
                      Text(
                        widget.service!.bookableVariations.length > 1 ?

                        "${widget.service!.bookableVariations.length} ${'variations_available'.tr}" :
                        "${widget.service!.bookableVariations.length} ${'variation_available'.tr}",

                        style: robotoRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: .5)),
                      ),

                      if(widget.minPurchasePrice != null)...[
                        const SizedBox(height: Dimensions.paddingSizeMini),

                        Text('${'to_get_this_offer_you_need_to_spend'.tr} ${PriceConverter.convertPrice(widget.minPurchasePrice)}'),
                      ],
                      ],

                      if (isBookingFlow)
                        ServiceBookingFlowWidget(
                          service: widget.service!,
                          onComplete: () {},
                        )
                      else
                      Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: Dimensions.paddingSizeLarge),
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: Get.height * 0.1,
                                maxHeight: Get.height * 0.4
                              ),
                              child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: cartControllerInit.initialCartList.length,
                                  itemBuilder: (context, index) {
                                    //variation item
                                    return Padding(
                                      padding:  const EdgeInsets.symmetric(vertical:Dimensions.paddingSizeSmall),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical:Dimensions.paddingSizeExtraSmall),
                                        decoration: BoxDecoration(
                                            color: Theme.of(context).hoverColor,
                                            borderRadius: const BorderRadius.all(Radius.circular(Dimensions.paddingSizeDefault))
                                        ),
                                        child: GetBuilder<CartController>(builder: (cartController){
                                          return Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      cartControllerInit.initialCartList[index].variantKey.replaceAll('-', ' '), style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
                                                      maxLines: 2, overflow: TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: Dimensions.paddingSizeExtraSmall,),
                                                    Directionality(
                                                      textDirection: TextDirection.ltr,
                                                      child: Text(
                                                          PriceConverter.convertPrice(double.parse(cartControllerInit.initialCartList[index].price.toString()),isShowLongPrice:true),
                                                          style: robotoMedium.copyWith(color:  Get.isDarkMode? Theme.of(context).primaryColorLight: Theme.of(context).primaryColor, fontSize: Dimensions.fontSizeSmall)),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              // Expanded(child: SizedBox()),
                                              Expanded( flex:1,
                                                child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                                                  cartControllerInit.initialCartList[index].quantity > 0 ? InkWell(
                                                    onTap: () {
                                                      cartController.updateQuantity(index, false);
                                                    },
                                                    child: Container(
                                                      height: 30, width: 30,
                                                      margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                                                      decoration: BoxDecoration(shape: BoxShape.circle, color:  Theme.of(context).colorScheme.secondary),
                                                      alignment: Alignment.center,
                                                      child: Icon(Icons.remove , size: 15, color:Theme.of(context).cardColor,),
                                                    ),
                                                  ) : const SizedBox(),

                                                  cartControllerInit.initialCartList[index].quantity > 0 ? Text(
                                                    cartControllerInit.initialCartList[index].quantity.toString(),
                                                  ) : const SizedBox(),

                                                  GestureDetector(
                                                    onTap: () {
                                                      cartController.updateQuantity(index, true);
                                                    },
                                                    child: Container(
                                                      height: 30, width: 30,
                                                      margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                                                      decoration: BoxDecoration(
                                                          shape: BoxShape.circle,
                                                          color:  Theme.of(context).colorScheme.secondary
                                                      ),
                                                      alignment: Alignment.center,
                                                      child: Icon(
                                                        Icons.add ,
                                                        size: 15,
                                                        color:Theme.of(context).cardColor,
                                                      ),
                                                    ),
                                                  )
                                                ]),
                                              ),
                                            ]),
                                          );
                                        },
                                        ),
                                      ),
                                    );
                                  }),
                            ),
                            const SizedBox(height: Dimensions.paddingSizeLarge),
                          ]),

                      if (!isBookingFlow)
                      GetBuilder<CartController>(builder: (cartController) {
                        return cartController.isLoading ? const Center(child: CircularProgressIndicator()) :

                        Row(spacing: Dimensions.paddingSizeSmall, children: [
                          if(Get.find<SplashController>().configModel.content?.biddingStatus==1)
                          GestureDetector(
                            onTap: (){
                              Get.back();
                              showModalBottomSheet(
                              backgroundColor: Colors.transparent,
                              isScrollControlled: true,
                              context: Get.context!,
                              builder: (BuildContext context){
                                return const BottomCreatePostDialog();
                              });
                              if(widget.service!=null){
                                Get.find<CreatePostController>().resetCreatePostValue(removeService: false);
                                Get.find<CreatePostController>().updateSelectedService(widget.service!);

                              }
                            },
                            child: Container(
                              height:  ResponsiveHelper.isDesktop(context)? 50 : 45,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                                border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),width: 0.7),
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                              child: Center(child: Hero(tag: 'provide_image',
                                child: Image.asset(Images.customPostIcon,height: 30,width: 30,),
                              )),
                            ),
                          ),

                          Expanded(child: CustomButton(
                            height: ResponsiveHelper.isDesktop(context)? 55 : 45,
                            onPressed: cartControllerInit.isButton ? () {
                              cartController.setBookingStep(ServiceBookingStep.address);
                            } : null,
                            buttonText: 'continue'.tr,
                            ),
                          )
                        ]);
                      }),
                    ],
                  );
                }
                return Stack(
                  children: [
                    Positioned(
                      top: 0,
                      right: 20,
                      child: Container(
                        height: 40, width: 40, alignment: Alignment.center,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white70.withValues(alpha: 0.6),
                            boxShadow:[BoxShadow(
                              color: Colors.grey[Get.find<ThemeController>().darkTheme ? 700 : 300]!, blurRadius: 2, spreadRadius: 1,
                            )]
                        ),
                        child: InkWell(
                            onTap: () => Get.back(),
                            child: const Icon(Icons.close)),
                      ),
                    ),
                    SizedBox(
                        height: Get.height / 7,
                        child: Center(child: Text('no_variation_is_available'.tr,style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge),)))
                  ],
                );
              });
            }
          ),
        ),
      ),
    );
  }

}
