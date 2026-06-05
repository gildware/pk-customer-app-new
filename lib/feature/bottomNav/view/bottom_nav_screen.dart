import 'package:demandium/util/core_export.dart';
import 'package:get/get.dart';

class BottomNavScreen extends StatefulWidget {
  final AddressModel ? previousAddress;
  final bool showServiceNotAvailableDialog;
  final int pageIndex;
  const  BottomNavScreen({super.key, required this.pageIndex, this.previousAddress, required this.showServiceNotAvailableDialog});

  @override
  State<BottomNavScreen> createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends State<BottomNavScreen> {
  bool _canExit = GetPlatform.isWeb ? true : false;

  @override
  void initState() {
    super.initState();
    final nav = Get.find<BottomNavController>();
    switch (widget.pageIndex) {
      case 1:
        nav.changePage(BnbItem.bookings, shouldUpdate: false);
        break;
      case 2:
        nav.changePage(BnbItem.biddings, shouldUpdate: false);
        break;
      case 3:
        if (AppConstants.enableAiChat) {
          nav.changePage(BnbItem.aiChat, shouldUpdate: false);
        } else {
          nav.changePage(BnbItem.homePage, shouldUpdate: false);
        }
        break;
      case 4:
        nav.changePage(BnbItem.more, shouldUpdate: false);
        break;
      default:
        nav.changePage(BnbItem.homePage, shouldUpdate: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    final isUserLoggedIn = Get.find<AuthController>().isLoggedIn();

    return PopScope(
      canPop: ResponsiveHelper.isDesktop(context),
      onPopInvokedWithResult: (_, _) {
        if (Get.find<BottomNavController>().currentPage != BnbItem.homePage) {
          Get.find<BottomNavController>().changePage(BnbItem.homePage);
        } else {
          if (_canExit) {
            if(!GetPlatform.isWeb) {
              SystemNavigator.pop();
            }
          } else {
            customSnackBar('back_press_again_to_exit'.tr, type : ToasterMessageType.info);
            _canExit = true;
            Timer(const Duration(seconds: 2), () {
              _canExit = false;
            });
          }
        }
      },

      child: Scaffold(
        // AI chat center FAB — disabled (see AppConstants.enableAiChat).
        floatingActionButton: AppConstants.enableAiChat
            && !ResponsiveHelper.isDesktop(context)
            && MediaQuery.of(context).viewInsets.bottom == 0
            ? GetBuilder<BottomNavController>(
                builder: (navController) {
                  final isAiChat = navController.currentPage == BnbItem.aiChat;
                  return InkWell(
                    onTap: () {
                      if (!isUserLoggedIn) {
                        Get.toNamed(RouteHelper.getSignInRoute(redirectUrl: RouteHelper.home));
                      } else {
                        navController.changePage(BnbItem.aiChat);
                      }
                    },
                    child: Container(
                      height: 70,
                      width: 70,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isAiChat ? null : Get.isDarkMode ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.secondary,
                        shape: BoxShape.circle,
                        gradient: isAiChat ? const LinearGradient(
                          colors: [Color(0xFFFBBB00), Color(0xFFFF833D)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ) : null,
                      ),
                      child: Icon(
                        Icons.auto_awesome,
                        color: Get.isDarkMode ? Theme.of(context).primaryColorLight : Colors.white,
                        size: 35,
                      ),
                    ),
                  );
                },
              )
            : null,

        floatingActionButtonLocation: AppConstants.enableAiChat
            ? FloatingActionButtonLocation.miniCenterDocked
            : null,

        bottomNavigationBar: ResponsiveHelper.isDesktop(context) ? const SizedBox() : Container(
          padding: EdgeInsets.only(
            top: Dimensions.paddingSizeDefault,
            bottom: padding.bottom > 15 ? 0 : Dimensions.paddingSizeDefault,
          ),
          color:Get.isDarkMode ? Theme.of(context).cardColor.withValues(alpha: .5) : Theme.of(context).primaryColor,
          child: SafeArea(
            child: Padding( padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall),
              child: Row(children: [

                _bnbItem(
                  icon: Images.home, bnbItem: BnbItem.homePage, context: context,
                  onTap: () => Get.find<BottomNavController>().changePage(BnbItem.homePage),
                ),

                _bnbItem(
                  icon: Images.bookings, bnbItem: BnbItem.bookings, context: context,
                  onTap: () {
                    if (!isUserLoggedIn && Get.find<SplashController>().configModel.content?.guestCheckout == 1) {
                      Get.toNamed(RouteHelper.getTrackBookingRoute());
                    } else if(!isUserLoggedIn){
                      Get.toNamed(RouteHelper.getBookingScreenRoute(true));
                    } else {
                      Get.find<BottomNavController>().changePage(BnbItem.bookings);
                    }
                  },
                ),

                // AI chat nav slot — disabled (see AppConstants.enableAiChat).
                if (AppConstants.enableAiChat)
                  _bnbItem(
                    icon: '', bnbItem: BnbItem.aiChat, context: context,
                    onTap: () {},
                  ),

                _bnbItem(
                  icon: Images.customPostIcon,
                  bnbItem: BnbItem.biddings,
                  context: context,
                  onTap: () {
                    if (!isUserLoggedIn) {
                      Get.toNamed(RouteHelper.getSignInRoute(redirectUrl: RouteHelper.home));
                    } else {
                      Get.find<BottomNavController>().changePage(BnbItem.biddings);
                    }
                  },
                ),

                _bnbItem(
                  icon: Images.menu, bnbItem: BnbItem.more, context: context,
                  onTap: () => Get.bottomSheet(const MenuScreen(),
                    backgroundColor: Colors.transparent, isScrollControlled: true,
                  ),
                ),
              ]),
            ),
          ),
        ),

        body: GetBuilder<BottomNavController>(builder: (navController){
          return _bottomNavigationBody(widget.previousAddress, widget.showServiceNotAvailableDialog);
        }),

      ),
    );
  }

  Widget _bnbItem({
    required String icon,
    required BnbItem bnbItem,
    required GestureTapCallback onTap,
    required BuildContext context,
  }) {
    return GetBuilder<BottomNavController>(builder: (bottomNavController){
      final isSelected = bottomNavController.currentPage == bnbItem;
      final isCenterFab = bnbItem == BnbItem.aiChat;
      return Expanded(
        child: InkWell(
          onTap: isCenterFab ? null : onTap,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
            isCenterFab
                ? const SizedBox(width: 20, height: 20)
                : Image.asset(icon, width: 18, height: 18,
                    color: isSelected ? Colors.white : Colors.white60,
                  ),
            const SizedBox(height: Dimensions.paddingSizeExtraSmall),
            if (!isCenterFab)
              Text(_labelFor(bnbItem).tr,
                style: robotoRegular.copyWith( fontSize: Dimensions.fontSizeSmall,
                  color: isSelected ? Colors.white : Colors.white60,
                ),
              ),
          ]),
        ),
      );
    });
  }

  String _labelFor(BnbItem item) {
    switch (item) {
      case BnbItem.homePage:
        return 'home';
      case BnbItem.bookings:
        return 'bookings';
      case BnbItem.biddings:
        return 'biddings';
      case BnbItem.aiChat:
        return 'ai_chat';
      case BnbItem.more:
        return 'more';
    }
  }

  int _bottomNavStackIndex(BnbItem currentPage, bool isLoggedIn) {
    switch (currentPage) {
      case BnbItem.homePage:
        return 0;
      case BnbItem.bookings:
        return isLoggedIn ? 1 : 0;
      case BnbItem.biddings:
        return isLoggedIn ? 2 : 0;
      case BnbItem.aiChat:
        return AppConstants.enableAiChat ? 3 : 0;
      case BnbItem.more:
        return 0;
    }
  }

  Widget _bottomNavigationBody(AddressModel? previousAddress, bool showServiceNotAvailableDialog) {
    PriceConverter.getCurrency();
    final isLoggedIn = Get.find<AuthController>().isLoggedIn();
    final currentPage = Get.find<BottomNavController>().currentPage;

    return IndexedStack(
      index: _bottomNavStackIndex(currentPage, isLoggedIn),
      sizing: StackFit.expand,
      children: [
        HomeScreen(
          addressModel: previousAddress,
          showServiceNotAvailableDialog: showServiceNotAvailableDialog,
        ),
        if (isLoggedIn) const BookingListScreen() else const SizedBox.shrink(),
        if (isLoggedIn) const AllPostScreen(embedInBottomNav: true) else const SizedBox.shrink(),
        // AI chat screen — disabled (see AppConstants.enableAiChat).
        if (AppConstants.enableAiChat) const AiChatScreen(embedInBottomNav: true),
      ],
    );
  }
}
