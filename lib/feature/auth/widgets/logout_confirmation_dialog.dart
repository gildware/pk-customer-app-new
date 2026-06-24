import 'package:get/get.dart';
import 'package:demandium/util/core_export.dart';

class LogoutConfirmationDialog extends StatelessWidget {
  const LogoutConfirmationDialog({super.key});

  static void show() {
    Get.dialog(const LogoutConfirmationDialog(), useSafeArea: false);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AuthController>(builder: (authController) {
      return ConfirmationDialog(
        icon: Images.logoutIcon,
        title: 'are_you_sure_to_logout'.tr,
        description: 'if_you_logged_out_your_cart_will_be_removed'.tr,
        yesButtonColor: Theme.of(context).colorScheme.primary,
        isLoading: authController.isLogoutLoading,
        onYesPressed: () => authController.performLogout(),
      );
    });
  }
}
