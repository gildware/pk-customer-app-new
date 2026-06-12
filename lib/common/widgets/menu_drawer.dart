import 'package:demandium/util/core_export.dart';
import 'package:demandium/helper/mobile_app_icon_helper.dart';
import 'package:get/get.dart';


class MenuDrawer extends StatefulWidget {
  const MenuDrawer({super.key}) ;

  @override
  State<MenuDrawer> createState() => _MenuDrawerState();
}

class _MenuDrawerState  extends State<MenuDrawer> with SingleTickerProviderStateMixin {


  late final List<Menu> _menuList = [
    Menu(iconKey: 'profile', icon: Images.profileIcon, title: 'profile'.tr, onTap: () {
      Get.back();
      Get.toNamed(RouteHelper.getProfileRoute());
    }),
    Menu(iconKey: 'inbox', icon: Images.chatImage, title: 'inbox'.tr, onTap: () {
      Get.back();
      Get.toNamed(RouteHelper.getInboxScreenRoute());
    }),
    Menu(iconKey: 'language', icon: Images.translate, title: 'language'.tr, onTap: () {
      Get.back();
      Get.toNamed(RouteHelper.getLanguageScreen('menuDrawer'));
    }),
    Menu(iconKey: 'settings', icon: Images.settings, title: 'settings'.tr, onTap: () {
      Get.back();
      Get.toNamed(RouteHelper.getSettingRoute());
    }),
    Menu(iconKey: 'bookings', icon: Images.bookingsIcon, title:  Get.find<SplashController>().configModel.content?.guestCheckout == 0 || Get.find<AuthController>().isLoggedIn() ? 'bookings'.tr : "track_booking".tr, onTap: () {
      Get.back();

      Get.toNamed(!Get.find<AuthController>().isLoggedIn()
          && Get.find<SplashController>().configModel.content?.guestCheckout == 1
          ? RouteHelper.getTrackBookingRoute() :
      RouteHelper.getBookingScreenRoute(true),
      );
    }),

    if(Get.find<SplashController>().configModel.content?.biddingStatus==1)
    Menu(iconKey: 'custom_post', icon: Images.customPostIcon, title: 'my_posts'.tr, onTap: () {
      Get.back();
      Get.toNamed(RouteHelper.getMyPostScreen());
    }),

    Menu(iconKey: 'vouchers', icon: Images.voucherIcon, title: 'vouchers'.tr, onTap: () {
      Get.back();

      if(Get.find<LocationController>().getUserAddress() !=null ){
        Get.toNamed(RouteHelper.getVoucherRoute(fromPage: "menu"));
      }else{
        Get.toNamed(RouteHelper.getPickMapRoute( RouteHelper.voucherScreen , true, 'false', null, null,));
      }
    }),

    Menu(iconKey: 'my_favorite', icon: Images.myFavorite, title: 'my_favorite'.tr, onTap: () {
      Get.back();
      Get.toNamed(RouteHelper.getMyFavoriteScreen());
    }),

    if(Get.find<SplashController>().configModel.content!.walletStatus != 0 && Get.find<AuthController>().isLoggedIn())
    Menu(iconKey: 'wallet', icon: Images.walletMenu, title: 'my_wallet'.tr, onTap: () {
      Get.back();
      Get.toNamed(RouteHelper.getMyWalletScreen());
    }),
    if(Get.find<SplashController>().configModel.content!.loyaltyPointStatus != 0 && Get.find<AuthController>().isLoggedIn())
    Menu(iconKey: 'loyalty_point', icon: Images.myPoint, title: 'loyalty_point'.tr, onTap: () {
      Get.back();
      Get.toNamed(RouteHelper.getLoyaltyPointScreen());
    }),

    if(Get.find<SplashController>().configModel.content?.referEarnStatus==1)
      Menu(
        title:'refer_and_earn'.tr, iconKey: 'refer_and_earn', icon: Images.shareIcon, onTap: (){
          Get.back();
          Get.toNamed(RouteHelper.getReferAndEarnScreen());
      }),

    ...(Get.find<SplashController>()
        .configModel
        .content!
        .businessPages
        ?? [])
        .where((page) => HtmlType.isVisibleBusinessPage(page.pageKey, title: page.title))
        .map((page) => Menu(
      iconKey: _pageIconKey(page),
      icon: page.pageKey == HtmlType.aboutUs.value
          ? Images.aboutUs
          : page.pageKey == HtmlType.termsAndCondition.value
          ? Images.termsIcon : page.pageKey == HtmlType.privacyPolicy.value
          ? Images.privacyPolicyIcon : page.pageKey == HtmlType.cancellationPolicy.value
          ? Images.cancellationPolicy : page.pageKey == HtmlType.refundPolicy.value ? Images.refundPolicy : Images.othersPageIcon,
      title: _getPageTitle(page),
      onTap: () {
        Get.back();
        Get.toNamed(_getPageRoute(page));
      },
    )),

    Menu(iconKey: 'help_support', icon: Images.helpIcon, title: 'help_&_support'.tr, onTap: () {
      Get.back();
      Get.toNamed( RouteHelper.getSupportRoute());
    }),

    Menu(iconKey: 'service_area', icon: Images.areaMenuIcon, title: 'service_area'.tr, onTap: () {
      Get.back();
      Get.toNamed( RouteHelper.getServiceArea());
    }),

     Menu(iconKey: 'logout', icon: Images.logout, title:Get.find<AuthController>().isLoggedIn() ? 'logout'.tr : 'sign_in'.tr, onTap: () {
       Get.back();
       if(Get.find<AuthController>().isLoggedIn()) {
         Get.dialog(ConfirmationDialog(icon: Images.logoutIcon,
             title: 'are_you_sure_to_logout'.tr,
             description: "if_you_logged_out_your_cart_will_be_removed".tr,
             yesButtonColor: Theme.of(Get.context!).colorScheme.primary,
             onYesPressed: () async {
           await Get.find<AuthController>().logOut();
           await Get.find<AuthController>().clearSharedData();
           await Get.find<AuthController>().googleLogout();
           await Get.find<AuthController>().signOutWithFacebook();
           Get.offAllNamed(RouteHelper.getInitialRoute());
           customSnackBar("logged_out_successfully".tr, type : ToasterMessageType.success);
         }), useSafeArea: false);
       }else {
         Get.toNamed(RouteHelper.getSignInRoute(redirectUrl: Get.currentRoute));
       }
      }),
  ];

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


  static const _initialDelayTime = Duration(milliseconds: 200);
  static const _itemSlideTime = Duration(milliseconds: 250);
  static const _staggerTime = Duration(milliseconds: 50);
  static const _buttonDelayTime = Duration(milliseconds: 150);
  static const _buttonTime = Duration(milliseconds: 500);
  final _animationDuration = _initialDelayTime + (_staggerTime * 7) + _buttonDelayTime + _buttonTime;

  late AnimationController _staggeredController;
  final List<Interval> _itemSlideIntervals = [];

  @override
  void initState() {
    super.initState();

    _createAnimationIntervals();
    _staggeredController = AnimationController(
      vsync: this,
      duration: _animationDuration,
    )..forward();
  }

  void _createAnimationIntervals() {
    for (var i = 0; i < _menuList.length; ++i) {
      final startTime = _initialDelayTime + (_staggerTime * i);
      final endTime = startTime + _itemSlideTime;
      _itemSlideIntervals.add(
        Interval(
          startTime.inMilliseconds / _animationDuration.inMilliseconds,
          endTime.inMilliseconds / _animationDuration.inMilliseconds,
        ),
      );
    }
  }

  @override
  void dispose() {
    _staggeredController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveHelper.isDesktop(context) ? _buildContent() : const SizedBox();
  }

  Widget _buildContent(){
    return Align(alignment:Get.find<LocalizationController>().isLtr? Alignment.topRight : Alignment.topLeft, child: Container(
      width: 300,
      decoration: BoxDecoration(borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30)), color: Theme.of(context).cardColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [

          Container(
            padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeLarge, horizontal: 25),
            margin: const EdgeInsets.only(right: 30),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(bottomRight: Radius.circular(Dimensions.radiusExtraLarge)),
              color: Theme.of(context).primaryColor,
            ),
            alignment: Alignment.centerLeft,
            child: Text('menu'.tr, style: robotoBold.copyWith(fontSize: 20, color: Colors.white)),
          ),

          Expanded(
            child: ListView.builder(
              itemCount: _menuList.length,
              physics: const AlwaysScrollableScrollPhysics(),
              shrinkWrap: true,
              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
              itemBuilder: (context, index) {
                return AnimatedBuilder(
                  animation: _staggeredController,
                  builder: (context, child) {
                    final animationPercent = Curves.easeOut.transform(
                      _itemSlideIntervals[index].transform(_staggeredController.value),
                    );
                    final opacity = animationPercent;
                    final slideDistance = (1.0 - animationPercent) * 150;

                    return Opacity(
                      opacity: opacity,
                      child: Transform.translate(
                        offset: Offset(slideDistance, 0),
                        child: child,
                      ),
                    );
                  },
                  child: InkWell(
                    onTap: _menuList[index].onTap as void Function()?,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeExtraSmall),
                      child: Row(children: [

                        Container(
                          height: 60, width: 60, alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
                            color: Theme.of(context).primaryColor,
                          ),
                          child: MobileAppIconHelper.icon(
                            key: _menuList[index].iconKey ?? '',
                            fallbackAsset: _menuList[index].icon!,
                            height: 30,
                            width: 30,
                          ),
                        ),
                        const SizedBox(width: Dimensions.paddingSizeSmall),

                        Expanded(child: Text(_menuList[index].title ?? '', style: robotoMedium, overflow: TextOverflow.ellipsis, maxLines: 1)),

                      ]),
                    ),
                  ),
                );
              },
            ),
          ),

        ],
      ),
    ));
  }
}



class Menu {
  String? iconKey;
  String? icon;
  String? title;
  Function onTap;

  Menu({this.iconKey, required this.icon, required this.title, required this.onTap});
}