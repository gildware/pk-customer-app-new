import 'package:demandium/common/widgets/custom_pop_widget.dart';
import 'package:demandium/util/core_export.dart';
import 'package:get/get.dart';
import 'package:demandium/common/widgets/address_selection_drawer.dart';

class MyFavoriteScreen extends StatefulWidget {
  final String? fromPage;
  final bool embedInBottomNav;
  const MyFavoriteScreen({super.key, this.fromPage, this.embedInBottomNav = false}) ;

  @override
  State<MyFavoriteScreen> createState() => _MyFavoriteScreenState();
}

class _MyFavoriteScreenState extends State<MyFavoriteScreen> with SingleTickerProviderStateMixin {

  TabController? tabController;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    await Get.find<LocationController>().refreshSavedAddressZone();
    Get.find<MyFavoriteController>().getFavoriteServiceList(1, true);
    Get.find<MyFavoriteController>().getProviderList(1, true);
  }


  Widget _buildBody() {
    return GetBuilder<MyFavoriteController>(builder: (_) {
      if (ResponsiveHelper.isDesktop(context)) {
        return Center(
          child: SizedBox(
            width: Dimensions.webMaxWidth,
            child: Column(
              children: [
                FavoriteTabBarView(tabController: tabController),
                SizedBox(
                  height: Get.height * 0.8,
                  child: TabBarView(
                    controller: tabController,
                    children: const [
                      FavoriteServiceListView(),
                      FavoriteProviderListView(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return Column(
        children: [
          FavoriteTabBarView(tabController: tabController),
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: const [
                FavoriteServiceListView(),
                FavoriteProviderListView(),
              ],
            ),
          ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final Widget screen = Scaffold(
      drawer: ResponsiveHelper.isDesktop(context) ? const AddressSelectionDrawer() : null,
      endDrawer: ResponsiveHelper.isDesktop(context) ? const MenuDrawer() : null,
      appBar: widget.embedInBottomNav
          ? CustomAppBar(
              title: 'favourites'.tr,
              isBackButtonExist: false,
            )
          : CustomAppBar(
              title: 'my_favorite'.tr,
              onBackPressed: () {
                if (widget.fromPage == 'fromNotification') {
                  Get.offAllNamed(RouteHelper.getInitialRoute());
                } else if (Navigator.canPop(context)) {
                  Get.back();
                } else {
                  Get.offAllNamed(RouteHelper.getInitialRoute());
                }
              },
            ),
      body: widget.embedInBottomNav
          ? _buildBody()
          : FooterBaseView(
              isScrollView: ResponsiveHelper.isDesktop(context),
              child: _buildBody(),
            ),
    );

    if (widget.embedInBottomNav) {
      return screen;
    }
    return CustomPopWidget(child: screen);
  }
}
