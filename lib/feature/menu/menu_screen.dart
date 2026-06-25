import 'package:get/get.dart';
import 'package:demandium/util/core_export.dart';


class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {

  @override
  void initState() {
    super.initState();
    Get.find<BottomNavController>().updateMenuPageIndex(0);
  }

  @override
  Widget build(BuildContext context) {
    bool isLoggedIn = Get.find<AuthController>().isLoggedIn();
    ConfigModel configModel  = Get.find<SplashController>().configModel;
    double ratio =  ResponsiveHelper.isTab(context) ? 1.1 : 1.2;

    final List<MenuModel> menuList = [
      MenuModel(iconKey: 'profile', icon: Images.profileIcon, title: 'profile'.tr, route: RouteHelper.getProfileRoute()),
      MenuModel(iconKey: 'inbox', icon: Images.chatImage, title: 'inbox'.tr, route:RouteHelper.getInboxScreenRoute()),
      if (AppConstants.enableLanguageSelection)
        MenuModel(iconKey: 'language', icon: Images.translate, title: 'language'.tr, route: RouteHelper.getLanguageScreen('fromSettingsPage')),
      MenuModel(iconKey: 'settings', icon: Images.settings, title: 'settings'.tr, route: RouteHelper.getSettingRoute()),

      // Bidding/post menu — hidden unless enabled via admin (Mobile App Management → App Features).
      if(configModel.content?.biddingStatus == 1)
        MenuModel(
          iconKey: 'custom_post',
          icon: Images.customPostIcon,
          title: 'my_posts'.tr,
          route: RouteHelper.getMyPostScreen(),
        ),
      if(configModel.content!.walletStatus != 0 && isLoggedIn)
        MenuModel(iconKey: 'wallet', icon: Images.walletMenu, title: 'my_wallet'.tr, route: RouteHelper.getMyWalletScreen()),
      if(configModel.content!.loyaltyPointStatus != 0 && isLoggedIn)
        MenuModel(iconKey: 'loyalty_point', icon: Images.myPoint, title: 'loyalty_point'.tr, route: RouteHelper.getLoyaltyPointScreen()),

      if(Get.find<SplashController>().configModel.content?.referEarnStatus == 1)
        MenuModel(
          title:'refer_and_earn'.tr,
          iconKey: 'refer_and_earn',
          icon: Images.shareIcon,
          route: RouteHelper.getReferAndEarnScreen(),
        ),
      MenuModel(iconKey: 'service_area', icon: Images.areaMenuIcon, title: 'service_area'.tr, route: RouteHelper.getServiceArea()),

      MenuModel(iconKey: 'help_support', icon: Images.helpIcon, title: 'help_&_support'.tr, route: RouteHelper.getSupportRoute()),

      ...(configModel
          .content!
          .businessPages
          ?? [])
          .where((page) => HtmlType.isVisibleBusinessPage(page.pageKey, title: page.title))
          .map((page) => MenuModel(
        iconKey: _pageIconKey(page),
        icon: page.pageKey == HtmlType.aboutUs.value
            ? Images.aboutUs
            : page.pageKey == HtmlType.termsAndCondition.value
            ? Images.termsIcon : page.pageKey == HtmlType.privacyPolicy.value
            ? Images.privacyPolicyIcon : page.pageKey == HtmlType.cancellationPolicy.value
            ? Images.cancellationPolicy : page.pageKey == HtmlType.refundPolicy.value ? Images.refundPolicy : Images.othersPageIcon, // Or choose icon based on page
        title: _getPageTitle(page),
        route: _getPageRoute(page),
      )),

    ];
    menuList.add(MenuModel(iconKey: 'logout', icon: Images.logout, title: isLoggedIn ? 'logout'.tr : 'sign_in'.tr, route: '', isLogout: true));

    int menuCountInSinglePage = ResponsiveHelper.isTab(context) && menuList.length > 17 ? 18
        : ResponsiveHelper.isTab(context) && menuList.length < 18 ? menuList.length
        : ResponsiveHelper.isMobile(context) && menuList.length > 11 ? 12
        : menuList.length ;

    int totalPageSize = (menuList.length/ menuCountInSinglePage).ceil();

    return PointerInterceptor(
      child: GetBuilder<BottomNavController>(builder: (bottomNavController){
        return Container(
          width: Dimensions.webMaxWidth,
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            color: Theme.of(context).cardColor,
          ),
          child: SafeArea(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              InkWell(
                onTap: () => Get.back(),
                child: Icon(Icons.keyboard_arrow_down_rounded, size: 30, color: context.adaptivePrimaryColor),
              ),
              const SizedBox(height: Dimensions.paddingSizeExtraSmall),

              ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: Get.height * 0.15,
                  maxHeight: Get.height * 0.4
                ),
                child: PageView.builder(
                  onPageChanged: (value) {
                    bottomNavController.updateMenuPageIndex(value, shouldUpdate: true);
                  },
                  itemCount: totalPageSize,
                  itemBuilder: (context, index) => GridView.builder(
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount:  ResponsiveHelper.isMobile(context) ? 4 : 6,
                      childAspectRatio: (1/ratio),
                      crossAxisSpacing: Dimensions.paddingSizeExtraSmall, mainAxisSpacing: Dimensions.paddingSizeExtraSmall,
                    ),
                    itemCount: totalPageSize == 1 || (bottomNavController.currentMenuPageIndex + 1 < totalPageSize) ? menuCountInSinglePage : (menuList.length - (menuCountInSinglePage * (totalPageSize-1))),
                    itemBuilder: (context, index) {
                      return MenuButton(menu: menuList[( menuCountInSinglePage* bottomNavController.currentMenuPageIndex) + index]);
                    },
                  ),
                ),
              ),

              if(totalPageSize > 1) SizedBox(
                height: 15,
                child: Row(mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate( totalPageSize, (index) => PagerDot(index: index, currentIndex: bottomNavController.currentMenuPageIndex)
                  ),
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall,),

              Text("${'app_version'.tr} ${AppConstants.appVersion}", style: robotoMedium.copyWith(
                color: Get.isDarkMode ? Theme.of(context).hintColor : Theme.of(context).colorScheme.primary,
              )),
              SizedBox(height: ResponsiveHelper.isMobile(context) ? Dimensions.paddingSizeDefault : 0),

            ]),
          ),
        );
      }),
    );
  }

  String _pageIconKey(BusinessPage page) {
    if (page.pageKey == HtmlType.aboutUs.value) return 'about_us';
    if (page.pageKey == HtmlType.termsAndCondition.value) return 'terms';
    if (page.pageKey == HtmlType.privacyPolicy.value) return 'privacy_policy';
    if (page.pageKey == HtmlType.cancellationPolicy.value) return 'cancellation_policy';
    if (page.pageKey == HtmlType.refundPolicy.value) return 'refund_policy';
    return 'other_pages';
  }

  String _getPageTitle(BusinessPage page) {
    return page.pageKey == HtmlType.aboutUs.value
          ? 'about_us'.tr
          : page.pageKey == HtmlType.termsAndCondition.value
          ? 'terms_and_conditions'.tr : page.pageKey == HtmlType.privacyPolicy.value
          ? 'privacy_policy'.tr : page.pageKey == HtmlType.cancellationPolicy.value
          ? 'cancellation_policy'.tr : page.pageKey == HtmlType.refundPolicy.value ? 'refund_policy'.tr : page.title ?? '';
  }

  String _getPageRoute(BusinessPage page) {
    return page.pageKey == HtmlType.aboutUs.value
        ? RouteHelper.getAboutUsRoute()
        : page.pageKey == HtmlType.termsAndCondition.value
        ? RouteHelper.getTermsAndConditionsRoute()
        : page.pageKey == HtmlType.privacyPolicy.value
        ? RouteHelper.getPrivacyPolicyRoute()
        : page.pageKey == HtmlType.cancellationPolicy.value
        ? RouteHelper.getCancellationPolicyRoute()
        : page.pageKey == HtmlType.refundPolicy.value
        ? RouteHelper.getRefundPolicyRoute()
        : ''; // No route for custom pages - only standard HTML types are supported
  }
}
