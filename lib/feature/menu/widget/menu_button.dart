import 'package:get/get.dart';
import 'package:demandium/feature/auth/widgets/logout_confirmation_dialog.dart';
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
              color: context.adaptivePrimaryColor.withValues(alpha: 0.1),
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
          Text(menu.title!, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: context.onSurfaceText), textAlign: TextAlign.center),
        ]),
        Positioned.fill(child: RippleButton(onTap: () async {
          if(menu.isLogout) {
            closeOverlayThen(() {
              if(Get.find<AuthController>().isLoggedIn()) {
                LogoutConfirmationDialog.show();
              } else {
                Get.toNamed(RouteHelper.getSignInRoute());
              }
            });
            return;
          }

          if (menu.iconKey == 'become_provider') {
            closeOverlayThen(() async {
              await ProviderAppLauncher.open();
            });
            return;
          }

          if(menu.route!.startsWith('http')) {
            closeOverlayThen(() async {
              if(await canLaunchUrlString(menu.route!)) {
                launchUrlString(menu.route!, mode: LaunchMode.externalApplication);
              }
            });
            return;
          }

          closeOverlayThen(() {
            if(menu.route!.contains('/language')){
              Get.bottomSheet(const ChooseLanguageBottomSheet(), backgroundColor: Colors.transparent, isScrollControlled: true);
            } else {
              Get.offNamed(menu.route!);
            }
          });
        }))
      ],
    );
  }
}

