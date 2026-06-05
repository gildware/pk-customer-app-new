import 'package:demandium/common/widgets/custom_pop_widget.dart';
import 'package:demandium/feature/provider/widgets/provider_details_shimmer.dart';
import 'package:demandium/util/core_export.dart';
import 'package:get/get.dart';
import 'package:demandium/common/widgets/address_selection_drawer.dart';


class ProviderDetailsScreen extends StatefulWidget {
  final String providerId;
  const ProviderDetailsScreen({super.key,required this.providerId}) ;


  @override
  ProviderDetailsScreenState createState() => ProviderDetailsScreenState();
}

class ProviderDetailsScreenState extends State<ProviderDetailsScreen> with TickerProviderStateMixin {
  late TabController _profileTabController;
  TabController? _serviceTabController;
  final GlobalKey<NestedScrollViewState> _nestedScrollKey = GlobalKey<NestedScrollViewState>();
  int _lastProfileTabIndex = 0;

  @override
  void initState() {
    super.initState();

    _profileTabController = TabController(length: 3, vsync: this);
    _profileTabController.addListener(_onProfileTabChanged);

    final providerBookingController = Get.find<ProviderBookingController>();

    providerBookingController.updateTabBarPinned(false);

    providerBookingController.getProviderDetailsData(widget.providerId, true).then((value){
      _initServiceTabController();
      Get.find<CartController>().updatePreselectedProvider(null);
      if (mounted) setState(() {});
    });
  }

  void _onProfileTabChanged() {
    if (_profileTabController.indexIsChanging) return;

    final index = _profileTabController.index;
    if (index == 0 && _lastProfileTabIndex != 0) {
      _resetServicesTabScroll();
    }
    _lastProfileTabIndex = index;
  }

  void _resetServicesTabScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final inner = _nestedScrollKey.currentState?.innerController;
      if (inner != null && inner.hasClients) {
        inner.jumpTo(inner.position.minScrollExtent);
      }
    });
  }

  void _initServiceTabController() {
    _serviceTabController?.dispose();
    final count = Get.find<ProviderBookingController>().categoryItemList.length;
    if (count > 0) {
      _serviceTabController = TabController(length: count, vsync: this);
    } else {
      _serviceTabController = null;
    }
  }

  @override
  void dispose() {
    _profileTabController.removeListener(_onProfileTabChanged);
    _profileTabController.dispose();
    _serviceTabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return CustomPopWidget(
      child: Scaffold(
        drawer: ResponsiveHelper.isDesktop(context) ? const AddressSelectionDrawer() : null,

        endDrawer:ResponsiveHelper.isDesktop(context) ? const MenuDrawer():null,
        appBar: const AnimatedCustomAppBar(),
        body: GetBuilder<ProviderBookingController>(
          builder: (providerBookingController){
            if(providerBookingController.providerDetailsContent!= null){

              if(providerBookingController.providerDetailsContent?.provider == null) {
                return NoDataScreen(text: 'no_data_found'.tr, type: NoDataType.provider);
              }

              return Column(children: [

                Expanded(
                  child: SizedBox(
                    width: Dimensions.webMaxWidth,
                    child: NestedScrollView(
                      key: _nestedScrollKey,
                      floatHeaderSlivers: true,
                      headerSliverBuilder: (context, innerBoxIsScrolled) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          providerBookingController.updateTabBarPinned(innerBoxIsScrolled);
                        });

                        return [
                          if(providerBookingController.providerDetailsContent?.provider?.serviceAvailability == 0)
                            SliverToBoxAdapter(
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                                  border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.error)),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: Dimensions.paddingSizeDefault,
                                  horizontal: Dimensions.paddingSizeLarge,
                                ),
                                child: Center(
                                  child: Text(
                                    'provider_is_currently_unavailable'.tr,
                                    style: robotoMedium,
                                  ),
                                ),
                              ),
                            ),

                          SliverToBoxAdapter(
                            child: _ProviderProfileHeader(
                              providerId: widget.providerId,
                              onReviewsTap: () {
                                if (_profileTabController.length > 2) {
                                  _profileTabController.animateTo(2);
                                }
                              },
                            ),
                          ),

                          SliverOverlapAbsorber(
                            handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                            sliver: SliverPersistentHeader(
                              pinned: true,
                              delegate: _ProviderProfileTabBarDelegate(
                                tabController: _profileTabController,
                              ),
                            ),
                          ),
                        ];
                      },
                      body: TabBarView(
                        controller: _profileTabController,
                        children: [
                          _KeepAliveTabChild(
                            child: _ProviderServicesTab(
                              providerId: widget.providerId,
                              serviceTabController: _serviceTabController,
                            ),
                          ),
                          const _KeepAliveTabChild(
                            child: _ProviderShowcaseTab(),
                          ),
                          _KeepAliveTabChild(
                            child: ProviderReviewBody(
                              providerId: widget.providerId,
                              embeddedInProfileTab: true,
                              useNestedScroll: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                if(ResponsiveHelper.isDesktop(context)) const FooterView(),

              ]);

            }else{
              return const FooterBaseView(child: ProviderDetailsShimmer());
            }
          },
        ),
      ),
    );
  }
}

class _KeepAliveTabChild extends StatefulWidget {
  final Widget child;
  const _KeepAliveTabChild({required this.child});

  @override
  State<_KeepAliveTabChild> createState() => _KeepAliveTabChildState();
}

class _KeepAliveTabChildState extends State<_KeepAliveTabChild> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

class _ProviderProfileHeader extends StatelessWidget {
  final String providerId;
  final VoidCallback? onReviewsTap;

  const _ProviderProfileHeader({
    required this.providerId,
    this.onReviewsTap,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProviderBookingController>(
      builder: (providerBookingController) {
        return Column(
          children: [
            if(!ResponsiveHelper.isDesktop(context))
              CustomImage(
                image: providerBookingController.providerDetailsContent?.provider?.coverImageFullPath ?? '',
                placeholder: Images.placeholder,
                width: context.width,
                height: context.width / 3,
              ),
            ProviderDetailsTopCard(
              providerId: providerId,
              onReviewsTap: onReviewsTap,
            ),
          ],
        );
      },
    );
  }
}

class _ProviderProfileTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;

  _ProviderProfileTabBarDelegate({required this.tabController});

  @override
  double get minExtent => 45;

  @override
  double get maxExtent => 45;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      height: 45,
      width: Dimensions.webMaxWidth,
      color: Theme.of(context).cardColor,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.0),
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
              width: 0.5,
            ),
          ),
        ),
        child: TabBar(
          controller: tabController,
          indicatorColor: Theme.of(context).colorScheme.primary,
          labelColor: Get.isDarkMode
              ? Theme.of(context).textTheme.bodyLarge?.color
              : Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
          unselectedLabelStyle: robotoRegular,
          tabs: [
            Tab(text: 'services'.tr),
            Tab(text: 'work_showcase'.tr),
            Tab(text: 'reviews'.tr),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _ProviderProfileTabBarDelegate oldDelegate) {
    return oldDelegate.tabController != tabController;
  }
}

class _ProviderShowcaseTab extends StatelessWidget {
  const _ProviderShowcaseTab();

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return CustomScrollView(
          key: const PageStorageKey<String>('provider_showcase_tab'),
          slivers: [
            SliverOverlapInjector(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            ),
            SliverToBoxAdapter(
              child: ProviderShowcaseSection(showTitle: false),
            ),
          ],
        );
      },
    );
  }
}

class _ProviderServicesTab extends StatelessWidget {
  final String providerId;
  final TabController? serviceTabController;

  const _ProviderServicesTab({
    required this.providerId,
    required this.serviceTabController,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProviderBookingController>(
      builder: (providerBookingController) {
        if (providerBookingController.categoryItemList.isEmpty) {
          return Builder(
            builder: (context) {
              return CustomScrollView(
                key: const PageStorageKey<String>('provider_services_empty'),
                slivers: [
                  SliverOverlapInjector(
                    handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                  ),
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: NoDataScreen(text: 'no_subscribed_subcategories_available'.tr),
                    ),
                  ),
                ],
              );
            },
          );
        }

        if (serviceTabController == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return VerticalScrollableTabView(
          useNestedScroll: true,
          tabController: serviceTabController!,
          listItemData: providerBookingController.categoryItemList,
          verticalScrollPosition: VerticalScrollPosition.begin,
          eachItemChild: (object, index) {
            final category = object as CategoryModelItem;
            return CategorySection(
              category: category,
              providerData: providerBookingController.providerDetailsContent?.provider,
            );
          },
          slivers: [
            SliverAppBar(
              automaticallyImplyLeading: false,
              backgroundColor: Colors.transparent,
              pinned: true,
              leading: const SizedBox(),
              actions: const [SizedBox()],
              expandedHeight: 0,
              elevation: 0,
              flexibleSpace: const SizedBox(),
              toolbarHeight: 0,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(45),
                child: Container(
                  height: 45,
                  width: Dimensions.webMaxWidth,
                  color: Theme.of(context).cardColor,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.0),
                      border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4), width: 0.5),),
                    ),
                    child: TabBar(
                      isScrollable: true,
                      controller: serviceTabController!,
                      indicatorColor: Theme.of(context).colorScheme.primary,
                      labelColor: Get.isDarkMode ? Theme.of(context).textTheme.bodyLarge?.color : Theme.of(context).colorScheme.primary,
                      unselectedLabelColor: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                      unselectedLabelStyle: robotoRegular,
                      tabs: providerBookingController.categoryItemList.map((e) => Tab(
                        text: e.title,
                      )).toList(),
                      onTap: (index) {
                        VerticalScrollableTabBarStatus.setIndex(index);
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class AnimatedCustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final double height;

  const AnimatedCustomAppBar({super.key, this.height = kToolbarHeight});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProviderBookingController>();

    return ValueListenableBuilder<bool>(
      valueListenable: controller.isTabBarPinnedNotifier,
      builder: (context, isPinned, child) {
        return CustomAppBar(
          title: isPinned
              ? controller.providerDetailsContent?.provider?.companyName ?? "provider_details".tr
              : "provider_details".tr,
          showCart: true,
        );
      },
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);
}
