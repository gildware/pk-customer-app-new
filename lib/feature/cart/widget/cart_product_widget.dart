import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:demandium/util/core_export.dart';

class CartServiceWidget extends StatelessWidget {
  final CartModel cart;
  final int cartIndex;

  const CartServiceWidget({super.key, 
    required this.cart,
    required this.cartIndex,
  });

  String get _displayName =>
      cart.service?.name ?? cart.variantKey.replaceAll('-', ' ');

  String? get _thumbnail => cart.service?.thumbnailFullPath;

  String? get _slug => cart.service?.slug;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault,left: Dimensions.paddingSizeExtraSmall,right: Dimensions.paddingSizeExtraSmall),
      child: Container(
        height: 90.0,
        decoration: BoxDecoration(
            color: Theme.of(context).hoverColor,
            borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
        child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.antiAliasWithSaveLayer,
            children: [

              Slidable(
                key: const ValueKey(1),
                closeOnScroll: false,
                endActionPane: ActionPane(
                  motion: const ScrollMotion(),
                  dismissible: null,
                  extentRatio: 0.3,
                  children: [
                    CustomSlidableAction(
                      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
                      flex: 1,
                      onPressed: (context) async {
                        Get.dialog(const CustomLoader(), barrierDismissible: false,);
                        await Get.find<CartController>().removeCartFromServer(cart);
                        Get.back();
                      },
                      backgroundColor: Theme.of(context).colorScheme.error.withValues(alpha: 0.12),
                      foregroundColor: Colors.white,
                      borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(Dimensions.radiusSmall),
                          bottomRight:  Radius.circular(Dimensions.radiusSmall)),
                      child: Container(
                        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(Dimensions.paddingSizeDefault),
                          ),
                          child: Image.asset(Images.cartDeleteVariation,
                              height: Dimensions.paddingSizeLarge,
                              width: Dimensions.paddingSizeLarge
                          ),
                      ),
                    ),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault, horizontal: Dimensions.paddingSizeSmall),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    border: Border.all(color: Colors.white.withValues(alpha: .2)),
                    borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                    boxShadow:Get.isDarkMode ? null:[
                      BoxShadow(
                        color: Colors.grey[Get.isDarkMode ? 800 : 200]!,
                        blurRadius: 5,
                        spreadRadius: 1,
                      )
                    ],
                  ),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _slug != null
                                ? () => Get.toNamed(RouteHelper.getServiceRoute(_slug!))
                                : null,
                            child: SizedBox(
                              width:ResponsiveHelper.isMobile(context)? Get.width / 1.8 : Get.width / 4,
                              child: Row(
                                children: [
                                  const SizedBox(width: Dimensions.paddingSizeSmall),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                                    child: _thumbnail != null
                                        ? CustomImage(
                                            image: _thumbnail!,
                                            height: 65,
                                            width: 70,
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            height: 65,
                                            width: 70,
                                            color: Theme.of(context).disabledColor.withValues(alpha: 0.2),
                                            child: Icon(
                                              Icons.home_repair_service,
                                              color: Theme.of(context).hintColor,
                                            ),
                                          ),
                                  ),
                                  const SizedBox(width: Dimensions.paddingSizeSmall),
                                  Expanded(
                                    child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            _displayName,
                                            style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: Dimensions.paddingSizeExtraSmall,),
                                          SizedBox(
                                            width: Get.width * 0.4,
                                            child: Text(
                                              cart.variantKey,
                                              style: robotoMedium.copyWith(color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: .6), fontSize: Dimensions.fontSizeDefault),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Directionality(
                                            textDirection: TextDirection.ltr,
                                            child: Text(
                                              PriceConverter.convertPrice(cart.totalCost.toDouble()),
                                              style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: .6)),
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                        ]),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        Align(
                          alignment: Alignment.centerRight,
                          child: Row(children: [
                            if (cart.quantity > 1)
                              QuantityButton(
                                onTap: () {
                                  Get.find<CartController>().updateCartQuantityToApi(cart.id, cart.quantity - 1);
                                },
                                isIncrement: false,
                              ),
                            if (cart.quantity == 1)
                              InkWell(
                                onTap: () {
                                  Get.dialog(ConfirmationDialog(
                                    icon: Images.deleteProfile,
                                    description: 'are_you_sure_to_delete_this_service'.tr,
                                    onYesPressed: () async {
                                      Get.back();
                                      Get.dialog(const CustomLoader(), barrierDismissible: false);
                                      await Get.find<CartController>().removeCartFromServer(cart);
                                      Get.back();
                                    },
                                  ), useSafeArea: false);
                                },
                                child: Container(
                                  height: 22,
                                  width: 22,
                                  margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                                  child: Image.asset(Images.cartDeleteVariation),
                                ),
                              ),
                            Text(cart.quantity.toString(), style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeExtraLarge)),
                            QuantityButton(
                              onTap: () {
                                Get.find<CartController>().updateCartQuantityToApi(cart.id, cart.quantity + 1);
                              },
                              isIncrement: true,
                            ),
                          ]),
                        ),
                      ]),
              ),),
        ]),
      ),
    );
  }
}
