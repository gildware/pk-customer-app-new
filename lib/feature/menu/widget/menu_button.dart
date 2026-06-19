import 'package:get/get.dart';
import 'package:demandium/util/core_export.dart';
import 'package:demandium/helper/mobile_app_icon_helper.dart';


class MenuButton extends StatelessWidget {
  final MenuModel menu;
  const MenuButton({super.key, required this.menu, });

  @override
  Widget build(BuildContext context) {

    int count = ResponsiveHelper.isTab(context) ? 6 : 4;
    double size = ((context.width > Dimensions.webMaxWidth ? Dimensions.webMaxWidth : context.width)/count)-Dimensions.paddingSizeDefault;
    final boxSize = size - (size * 0.25);
    final iconSize = (boxSize - (Dimensions.paddingSizeDefault * 2)).clamp(22.0, 36.0);

    return Stack(
      children: [
        Column(children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(Dimensions.paddingSizeExtraSmall)),
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            ),
            height: boxSize,
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
            alignment: Alignment.center,
            child: MobileAppIconHelper.icon(
              iconKey: menu.iconKey ?? '',
              fallbackAsset: menu.icon!,
              width: iconSize,
              height: iconSize,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeEight),
          Text(menu.title!, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall), textAlign: TextAlign.center),
        ]),
        Positioned.fill(child: RippleButton(onTap: () async {
          if(menu.isLogout) {
            Get.back();
            if(Get.find<AuthController>().isLoggedIn()) {
              Get.dialog(ConfirmationDialog(
                  icon: Images.logoutIcon,
                  title: 'are_you_sure_to_logout'.tr,
                  description: "if_you_logged_out_your_cart_will_be_removed".tr,
                  onYesPressed: () async {
                    await Get.find<AuthController>().logOut();
                    await Get.find<AuthController>().clearSharedData();
                    await Get.find<AuthController>().googleLogout();
                    await Get.find<AuthController>().signOutWithFacebook();
                    Get.offAllNamed(RouteHelper.getInitialRoute());
              }), useSafeArea: false);
            }else {
              Get.toNamed(RouteHelper.getSignInRoute());
            }
          }
          else if (menu.iconKey == 'become_provider') {
            await ProviderAppLauncher.open();
          }
          else if(menu.route!.startsWith('http')) {
            if(await canLaunchUrlString(menu.route!)) {
          launchUrlString(menu.route!, mode: LaunchMode.externalApplication);}
          } else {
            if(menu.route!.contains('/language')){
              Get.back();
              Get.bottomSheet(const ChooseLanguageBottomSheet(), backgroundColor: Colors.transparent, isScrollControlled: true);
            } else {
              Get.offNamed(menu.route!);
            }
          }
        }))
      ],
    );
  }
}

