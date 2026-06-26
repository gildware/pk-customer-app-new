import 'package:demandium/common/widgets/custom_pop_widget.dart';
import 'package:demandium/feature/auth/widgets/logout_confirmation_dialog.dart';
import 'package:get/get.dart';
import 'package:demandium/feature/profile/model/profile_cart_item_model.dart';
import 'package:demandium/util/core_export.dart';
import 'package:demandium/common/widgets/address_selection_drawer.dart';

class ProfileScreen extends StatefulWidget{
  const ProfileScreen({super.key}) ;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  @override
  void initState() {
    super.initState();
    if(Get.find<AuthController>().isLoggedIn()){
      Get.find<UserController>().getUserInfo(reload: false);
    }
  }
  @override
  Widget build(BuildContext context) {

    bool pickedAddress = AddressSessionHelper.hasValidActiveAddress();

    final profileCartModelList = [
      ProfileCardItemModel(
        'my_address'.tr,
        'my_address',
        RouteHelper.getAddressRoute('fromProfileScreen'),
      ),
      ProfileCardItemModel(
        'notifications'.tr,
        'notifications',
        pickedAddress
            ? RouteHelper.getNotificationRoute()
            : RouteHelper.getPickMapRoute(
                RouteHelper.notification, true, 'false', null, null),
      ),
      if (!Get.find<AuthController>().isLoggedIn())
        ProfileCardItemModel(
          'sign_in'.tr,
          'sign_in',
          RouteHelper.getSignInRoute(redirectUrl: RouteHelper.profile),
        ),
      if (Get.find<AuthController>().isLoggedIn())
        ProfileCardItemModel(
          'suggest_new_service'.tr,
          'suggest_new_service',
          pickedAddress
              ? RouteHelper.getNewSuggestedServiceScreen()
              : RouteHelper.getPickMapRoute(
                  RouteHelper.suggestService, true, 'false', null, null),
        ),
      if (Get.find<AuthController>().isLoggedIn())
        ProfileCardItemModel(
          'delete_account'.tr,
          'delete_account',
          'delete_account',
        ),
      if (Get.find<AuthController>().isLoggedIn())
        ProfileCardItemModel(
          'logout'.tr,
          'logout',
          'sign_out',
        ),
    ];

    return CustomPopWidget(
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        drawer: ResponsiveHelper.isDesktop(context) ? const AddressSelectionDrawer() : null,

        endDrawer:ResponsiveHelper.isDesktop(context) ? const MenuDrawer() : null,
        appBar: CustomAppBar(
          title: 'profile'.tr,
          centerTitle: true,
          bgColor: Theme.of(context).primaryColor,
          isBackButtonExist: true,
          onBackPressed: (){
            if(Navigator.canPop(context)){
              Get.back();
            }else{
              Get.offAllNamed(RouteHelper.getMainRoute("home"));
            }
          },
        ),

        body: GetBuilder<UserController>(
          builder: (userController) {
            return userController.userInfoModel == null  && Get.find<AuthController>().isLoggedIn() ?
            const Center(child: CircularProgressIndicator()) :
            FooterBaseView(
              child: WebShadowWrap(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ProfileHeader(userInfoModel: userController.userInfoModel,),
                    const SizedBox(height: Dimensions.paddingSizeLarge),
                    GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: ResponsiveHelper.isMobile(context) ? 1 : 2,
                        childAspectRatio: 6,
                        crossAxisSpacing: Dimensions.paddingSizeExtraLarge,
                        mainAxisSpacing: Dimensions.paddingSizeSmall,
                      ),
                      itemCount: profileCartModelList.length,
                      itemBuilder: (context, index) {
                        return ProfileCardItem(
                          title: profileCartModelList[index].title,
                          iconKey: profileCartModelList[index].iconKey,
                          onTap: () {
                            if(profileCartModelList[index].routeName == 'sign_out'){
                              if(
                              Get.find<AuthController>().isLoggedIn()) {
                                LogoutConfirmationDialog.show();
                              }else {
                                Get.toNamed(RouteHelper.getSignInRoute());
                              }
                            }else if(profileCartModelList[index].routeName == 'delete_account'){
                              Get.dialog(
                                  ConfirmationDialog(
                                      icon: Images.deleteProfile,
                                      title: 'are_you_sure_to_delete_your_account'.tr,
                                      description: 'it_will_remove_your_all_information'.tr,
                                      yesButtonText: 'delete',
                                      noButtonText: 'cancel',
                                      onYesPressed: () => userController.removeUser()),
                                  useSafeArea: false
                              );
                            }
                            else{
                              Get.toNamed(profileCartModelList[index].routeName);
                            }
                          },
                        );
                      },
                    ),

                    const SizedBox(height:Dimensions.paddingSizeDefault,)
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

