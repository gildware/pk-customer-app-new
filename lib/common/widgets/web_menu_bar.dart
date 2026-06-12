import 'package:get/get.dart';
import 'package:demandium/util/core_export.dart';

class WebMenuBar extends StatelessWidget implements PreferredSizeWidget {
  final bool openSearchDialog;
  final GlobalKey<CustomShakingWidgetState>? searchbarShakeKey;
  final GlobalKey<CustomShakingWidgetState>? signInShakeKey;
  const WebMenuBar({super.key, this.openSearchDialog = true, this.searchbarShakeKey, this.signInShakeKey});

  void _closeSearchDialog() {
    if (Get.isDialogOpen! && Navigator.canPop(Get.context!)) {
      Get.back();
    }
  }

  void _navigateWithAddress(String redirectRoute, VoidCallback action) {
    _closeSearchDialog();
    Get.find<AllSearchController>().clearSearchController();
    AddressSessionHelper.requireAddressForNavigation(
      redirectRoute: redirectRoute,
      whenReady: action,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(child: Container( width: Dimensions.webMaxWidth,
      decoration: BoxDecoration(
        boxShadow: [BoxShadow(offset: const Offset(1, 1), blurRadius: 8, color: Theme.of(context).primaryColor.withValues(alpha: 0.15),)],
        color: Theme.of(context).cardColor, borderRadius: const BorderRadius.only(
          bottomRight: Radius.circular(Dimensions.radiusDefault),
          bottomLeft: Radius.circular(Dimensions.radiusDefault),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
      child: Row(children: [

        InkWell( onTap: (){
          _closeSearchDialog();
          Get.find<AllSearchController>().clearSearchController();
          Get.toNamed(RouteHelper.getInitialRoute());
        },
          child: MobileAppIconHelper.appLogo(
            width: 150,
            fallbackAsset: Images.webAppbarLogo,
          ),
        ),

        Expanded(
          child: InkWell( onTap: () {
            _closeSearchDialog();
            Get.find<AllSearchController>().clearSearchController();
            if (AddressSessionHelper.hasValidActiveAddress()) {
              Scaffold.of(context).openDrawer();
            } else {
              AddressSessionHelper.openAddressPicker(mandatory: true);
            }
            },

            child: Padding( padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
              child: GetBuilder<LocationController>(builder: (locationController) {
                final hasAddress = AddressSessionHelper.hasValidActiveAddress();
                final address = locationController.getUserAddress();
                final addressText = hasAddress
                    ? (address?.address ?? '')
                    : 'select_your_location'.tr;
                final labelText = hasAddress
                    ? AddressSessionHelper.displayAddressLabelText(address)
                    : null;
                final icon = hasAddress
                    ? AddressSessionHelper.addressHeaderIcon(address)
                    : Icons.location_on;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                    Icon(icon, size: 20, color: Theme.of(context).textTheme.bodyLarge!.color),
                    const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                    if (labelText != null) ...[
                      Text(
                        labelText,
                        style: robotoSemiBold.copyWith(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                          fontSize: Dimensions.fontSizeExtraSmall,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          '·',
                          style: robotoRegular.copyWith(
                            color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.7),
                            fontSize: Dimensions.fontSizeExtraSmall,
                          ),
                        ),
                      ),
                    ],
                    Flexible(
                      child: Text(
                        addressText,
                        style: robotoRegular.copyWith(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                          fontSize: Dimensions.fontSizeExtraSmall,
                          fontStyle: hasAddress ? FontStyle.normal : FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      color: Get.isDarkMode ? light.cardColor : Theme.of(context).primaryColor,
                    ),
                  ],
                );
              }),
            ),
          ),
        ),

        MenuButtonWeb(title: 'home'.tr, onTap: () {
          _navigateWithAddress(RouteHelper.getMainRoute('home'), () {
            Get.toNamed(RouteHelper.getMainRoute('home'));
          });
        }),
        const SizedBox(width: 10),

        MenuButtonWeb( title: 'categories'.tr, onTap: (){
          _navigateWithAddress(RouteHelper.getCategoryProductRoute('', '', '0'), () {
            final categories = Get.find<CategoryController>().categoryList;
            if (categories != null && categories.isNotEmpty) {
              final first = categories.first;
              final slug = first.slug?.trim().isNotEmpty == true
                  ? first.slug!.trim()
                  : first.id?.trim() ?? '';
              if (slug.isNotEmpty) {
                Get.toNamed(RouteHelper.getCategoryProductRoute(
                  slug,
                  first.name ?? '',
                  '0',
                ));
              }
            }
          });
        }),
        const SizedBox(width: Dimensions.paddingSizeSmall),

        MenuButtonWeb( title: 'services'.tr, onTap: () {
          _navigateWithAddress(RouteHelper.allServiceScreenRoute('all_service'), () {
            Get.toNamed(RouteHelper.allServiceScreenRoute('all_service'));
          });
        }),

        SearchWidgetWeb(openSearchDialog : openSearchDialog),
        MenuButtonWebIcon( icon: Images.webCartIcon, isCart: true, onTap: () {
          _navigateWithAddress(RouteHelper.getCartRoute(), () {
            Get.toNamed(RouteHelper.getCartRoute());
          });
        }),

        const SizedBox(width: Dimensions.paddingSizeSmall),
        MenuButtonWebIcon( icon: Images.notification, isCart: false, onTap: () {
          _navigateWithAddress(RouteHelper.getNotificationRoute(), () {
            Get.toNamed(RouteHelper.getNotificationRoute());
          });
        }),

        const SizedBox(width: Dimensions.paddingSizeSmall),
        MenuButtonWebIcon( icon: Images.offerMenu, isCart: false, onTap: () {
          _navigateWithAddress(RouteHelper.getOffersRoute(), () {
            Get.toNamed(RouteHelper.getOffersRoute());
          });
        }),

        const SizedBox(width: Dimensions.paddingSizeSmall),
        MenuButtonWebIcon(icon: Images.webHomeIcon, onTap: (){
          _closeSearchDialog();
          Scaffold.of(context).openEndDrawer();
        }),

        const SizedBox(width: 10),
        CustomShakingWidget(
          key: signInShakeKey,
          shakeCount: 2,
          shakeOffset: 5,
          child: GetBuilder<AuthController>(builder: (authController){
            return InkWell( onTap: () {
              _closeSearchDialog();
              Get.find<AllSearchController>().clearSearchController();
              if(authController.isLoggedIn()){
                Get.toNamed(RouteHelper.getBookingScreenRoute(true));
              }else{
                if(!Get.currentRoute.contains(RouteHelper.signIn)) {
                  Get.toNamed(RouteHelper.getSignInRoute(redirectUrl: Get.currentRoute));

                }
              }},
              child: Container(padding: const EdgeInsets.symmetric( horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeSmall-2),
                decoration: BoxDecoration( color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(Dimensions.radiusSmall),),
                child: Row(children: [
                  authController.isLoggedIn() ?const SizedBox.shrink():Image.asset(Images.webSignInButton,width: 16.0,height: 16.0,),
                  const SizedBox(width: Dimensions.paddingSizeExtraSmall,),
                  Text(authController.isLoggedIn() ? 'my_bookings'.tr : 'sign_in'.tr, style: robotoRegular.copyWith(color: Colors.white)),
                ]),
              ),
            );
          }),
        ),
      ]),
    ));
  }

  @override
  Size get preferredSize => const Size(Dimensions.webMaxWidth, 70);
}

class MenuButtonWebIcon extends StatelessWidget {
  final String? icon;
  final bool isCart;
  final Function() onTap;
  const MenuButtonWebIcon({super.key, required this.icon, this.isCart = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell( onTap: onTap,
      child: Row(children: [ Stack (clipBehavior: Clip.none, children: [

        Image.asset( icon!, height: 16, width: 16, color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: .7)),

        isCart ? GetBuilder<CartController>(builder: (cartController) {
          return cartController.cartList.isNotEmpty ? Positioned( top: -7, right: -7,
            child: Container(
              padding: const EdgeInsets.all(2),
              height: 15, width: 15, alignment: Alignment.center,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Theme.of(context).colorScheme.primary),
              child: FittedBox(child: Text(
                cartController.cartList.length.toString(),
                style: robotoRegular.copyWith(fontSize: 12, color: light.cardColor),
              ),
              ),
            ),
          ) : const SizedBox();
        }) : const SizedBox()]),

        const SizedBox(width: Dimensions.paddingSizeExtraSmall),
      ]),
    );
  }
}

class MenuButtonWeb extends StatelessWidget {
  final String? title;
  final bool isCart;
  final Function() onTap;
  const MenuButtonWeb({super.key, required this.title, this.isCart = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextHover(
      builder: (hovered){
        return Container(
          decoration: BoxDecoration(
            color:hovered ? Theme.of(context).colorScheme.primary.withValues(alpha: .1) : Colors.transparent,
            borderRadius: const BorderRadius.all(Radius.circular(Dimensions.radiusDefault))
          ),
          child: InkWell(
            hoverColor: Colors.transparent,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical:Dimensions.paddingSizeEight, horizontal: Dimensions.paddingSizeEight),
              child: Text(title!, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall)),
            ),
          ),
        );
      },
    );
  }
}
