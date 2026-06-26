import 'package:demandium/common/widgets/custom_pop_widget.dart';
import 'package:get/get.dart';
import 'package:demandium/util/core_export.dart';
import 'package:demandium/common/widgets/address_selection_drawer.dart';

class ServiceDetailsScreen extends StatefulWidget {
  final String? serviceID;
  final String? fromPage;
  const ServiceDetailsScreen({super.key, this.serviceID,this.fromPage="others"}) ;

  @override
  State<ServiceDetailsScreen> createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {

  final scaffoldState = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    if(widget.serviceID != null){
      Get.find<ServiceDetailsController>().getServiceDetails(widget.serviceID!, fromPage: widget.fromPage == "search_page" ? "search_page" : "");
      if(Get.find<AuthController>().isLoggedIn()){
        Get.find<ServiceController>().getRecentlyViewedServiceList(1,true,);
      }
    }
    super.initState();
    Get.find<ServiceTabController>().updateServicePageCurrentState(ServiceTabControllerState.serviceOverview);
  }

  void _onServiceTabSelected(int index, bool hasFaqs) {
    final tabController = Get.find<ServiceTabController>();
    tabController.controller?.index = index;
    if (index == 0) {
      tabController.updateServicePageCurrentState(ServiceTabControllerState.serviceOverview);
    } else if (hasFaqs && index == 1) {
      tabController.updateServicePageCurrentState(ServiceTabControllerState.faq);
    } else {
      tabController.updateServicePageCurrentState(ServiceTabControllerState.review);
    }
  }

  Widget _buildServiceHeader(BuildContext context, Service service, Discount discount, double lowestPrice) {
    return Stack(children: [
      Column(children: [
        ClipRRect(
          borderRadius: BorderRadius.all((!ResponsiveHelper.isMobile(context) && !ResponsiveHelper.isTab(context)) ?  const Radius.circular(8): const Radius.circular(0.0)),
          child: Stack(
            children: [
              Center(
                child: SizedBox(
                  width: Dimensions.webMaxWidth,
                  height: ResponsiveHelper.isDesktop(context) ? 280:150,
                  child: CustomImage(
                    image: service.coverImageFullPath ?? "",
                    placeholder: Images.servicePlaceholder,
                  ),
                ),
              ),
              Center(
                child: Container(
                  width: Dimensions.webMaxWidth,
                  height: ResponsiveHelper.isDesktop(context) ? 280:150,
                  decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6)
                  ),
                ),
              ),
              Container(
                width: Dimensions.webMaxWidth,
                height: ResponsiveHelper.isDesktop(context) ? 280:150,
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
                child: Center(child: Text(service.name ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeExtraLarge, color: Colors.white))),
              ),
            ],
          ),
        ),
        const SizedBox(height: 120,)
      ]),
      Positioned(
        bottom: -2, left: Dimensions.paddingSizeSmall, right: Dimensions.paddingSizeSmall,
        child: ServiceInformationCard(discount: discount,service: service,lowestPrice: lowestPrice,),
      ),
    ]);
  }

  Widget _buildActiveTabContent(ServiceTabController tabController, Service service, ServiceDetailsController serviceController) {
    switch (tabController.servicePageCurrentState) {
      case ServiceTabControllerState.serviceOverview:
        return ServiceOverview(description: service.description!);
      case ServiceTabControllerState.faq:
        return const ServiceDetailsFaqSection();
      case ServiceTabControllerState.review:
        if (tabController.reviewList != null) {
          return ServiceDetailsReview(
            serviceID: serviceController.service!.id!,
            listScrollController: _scrollController,
          );
        }
        return const EmptyReviewWidget();
    }
  }

  Widget _buildMobileBody(BuildContext context, Service service, Discount discount, double lowestPrice, ServiceDetailsController serviceController) {
    final hasFaqs = service.faqs != null && service.faqs!.isNotEmpty;

    return GetBuilder<ServiceTabController>(
      initState: (state){
        Get.find<ServiceTabController>().getServiceReview(serviceController.service!.id!,1);
      },
      builder: (serviceTabController) {
        if (serviceTabController.controller == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: _buildServiceHeader(context, service, discount, lowestPrice),
            ),
            SliverPersistentHeader(
              pinned: true,
              floating: false,
              delegate: _ServiceDetailsTabBarDelegate(
                tabController: serviceTabController.controller!,
                tabs: serviceTabController.serviceDetailsTabs(serviceController.service),
                onTabSelected: (index) => _onServiceTabSelected(index, hasFaqs),
              ),
            ),
            SliverToBoxAdapter(
              child: _buildActiveTabContent(serviceTabController, service, serviceController),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDesktopBody(BuildContext context, Service service, Discount discount, double lowestPrice, ServiceDetailsController serviceController) {
    return Column(children: [

      if(!ResponsiveHelper.isMobile(context) && !ResponsiveHelper.isTab(context))
        const SizedBox(height: Dimensions.paddingSizeDefault),

      _buildServiceHeader(context, service, discount, lowestPrice),

      GetBuilder<ServiceTabController>(
        init: Get.find<ServiceTabController>(),
        builder: (serviceTabController) {
          return Container(
            color:Theme.of(context).scaffoldBackgroundColor,
            child: Center(
              child: Container(
                width: Get.width / 3,
                color: Get.isDarkMode?Theme.of(context).scaffoldBackgroundColor:Theme.of(context).cardColor,
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                child: DecoratedTabBar(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Get.isDarkMode
                            ? Theme.of(context).dividerColor
                            : Theme.of(context).colorScheme.primary.withValues(alpha: .3),
                        width: 1.0,
                      ),
                    ),
                  ),
                  tabBar: TabBar(
                      padding: const EdgeInsets.only(top: Dimensions.paddingSizeMini),
                      unselectedLabelColor: context.tabUnselectedColor,
                      controller: serviceTabController.controller,
                      labelColor: context.tabSelectedColor,
                      labelStyle: robotoBold.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                      ),
                      indicatorColor: context.tabIndicatorColor,
                      indicatorPadding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
                      labelPadding: const EdgeInsets.only(bottom: Dimensions.paddingSizeExtraSmall),
                      indicatorWeight: 2,
                      tabs: serviceTabController.serviceDetailsTabs(serviceController.service)
                  ),
                ),
              ),
            ),
          );
        },
      ),

      GetBuilder<ServiceTabController>(
        initState: (state){
          Get.find<ServiceTabController>().getServiceReview(serviceController.service!.id!,1);
        },
        builder: (controller){
          return SizedBox(
            height: 500,
            child: TabBarView(
              controller: controller.controller,
              children: [
                SingleChildScrollView(child: ServiceOverview(description:service.description!)),
                if(Get.find<ServiceDetailsController>().service!.faqs!.isNotEmpty)
                  const SingleChildScrollView(child: ServiceDetailsFaqSection()),
                if(controller.reviewList != null)
                  SingleChildScrollView(
                    child: ServiceDetailsReview(serviceID: serviceController.service!.id!,),
                  )
                else
                  const EmptyReviewWidget()
              ],
            ),
          );
        },
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return CustomPopWidget(
      child: Scaffold(
        key: scaffoldState,
        drawer: ResponsiveHelper.isDesktop(context) ? const AddressSelectionDrawer() : null,

        endDrawer:ResponsiveHelper.isDesktop(context) ? const MenuDrawer():null,
        appBar: CustomAppBar(centerTitle: false, title: 'service_details'.tr,showCart: true,),
        body: GetBuilder<ServiceDetailsController>(
          builder: (serviceController) {
            if(serviceController.service != null || widget.serviceID == null){
              if(serviceController.service != null && serviceController.service!.id != null &&  widget.serviceID != null){
                Service? service = serviceController.service;
                Discount discount = PriceConverter.discountCalculation(service!);
                final double lowestPrice = service.resolveLowestPrice().toDouble();
                return  FooterBaseView(
                  isScrollView: ResponsiveHelper.isMobile(context) ? false: true,
                  child: SizedBox(
                    width: Dimensions.webMaxWidth,
                    child: ResponsiveHelper.isMobile(context)
                        ? _buildMobileBody(context, service, discount, lowestPrice, serviceController)
                        : _buildDesktopBody(context, service, discount, lowestPrice, serviceController),
                  ),
                );
              }else{
                return NoDataScreen(text: 'no_service_available'.tr,type: NoDataType.service,);
              }
            }else{
              return const ServiceDetailsShimmerWidget();
            }
          },
        ),
      ),
    );
  }
}

class _ServiceDetailsTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  final List<Widget> tabs;
  final ValueChanged<int> onTabSelected;

  _ServiceDetailsTabBarDelegate({
    required this.tabController,
    required this.tabs,
    required this.onTabSelected,
  });

  @override
  double get minExtent => 48;

  @override
  double get maxExtent => 48;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: DecoratedTabBar(
        decoration: BoxDecoration(
          color: Get.isDarkMode ? Theme.of(context).scaffoldBackgroundColor : Theme.of(context).cardColor,
          border: Border(
            bottom: BorderSide(
              color: Get.isDarkMode
                  ? Theme.of(context).dividerColor
                  : Theme.of(context).colorScheme.primary.withValues(alpha: .3),
              width: 1.0,
            ),
          ),
        ),
        tabBar: TabBar(
          padding: const EdgeInsets.only(top: Dimensions.paddingSizeMini),
          unselectedLabelColor: context.tabUnselectedColor,
          controller: tabController,
          labelColor: context.tabSelectedColor,
          labelStyle: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall),
          indicatorColor: context.tabIndicatorColor,
          indicatorPadding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
          labelPadding: const EdgeInsets.only(bottom: Dimensions.paddingSizeExtraSmall),
          indicatorWeight: 2,
          onTap: onTabSelected,
          tabs: tabs,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _ServiceDetailsTabBarDelegate oldDelegate) {
    return oldDelegate.tabController != tabController || oldDelegate.tabs != tabs;
  }
}
