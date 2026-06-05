import 'package:demandium/feature/home/helper/mobile_app_home_helper.dart';
import 'package:demandium/feature/home/widget/customer_home_sections.dart';
import 'package:get/get.dart';
import 'package:demandium/util/core_export.dart';
import 'package:demandium/common/widgets/address_selection_drawer.dart';


class HomeScreen extends StatefulWidget {
  static Future<void> _safeLoad(Future<void> future) {
    return future.catchError((error, stack) {
      if (kDebugMode) {
        debugPrint('HomeScreen.loadData: $error');
      }
    });
  }

  static Future<void> loadData(bool reload, {int availableServiceCount = 1}) async {
    if (Get.isRegistered<SplashController>()) {
      await _safeLoad(Get.find<SplashController>().getConfigData());
    }

    if(availableServiceCount==0){
      await _safeLoad(Get.find<BannerController>().getBannerList(reload));
    }else{
      await Future.wait([
        _safeLoad(Get.find<ServiceController>().getRecommendedSearchList()),
        _safeLoad(Get.find<BannerController>().getBannerList(reload)),
        _safeLoad(Get.find<AdvertisementController>().getAdvertisementList(reload)),
        _safeLoad(Get.find<CategoryController>().getCategoryList(reload)),
        if (_needsDefaultHomeSubCategories())
          _safeLoad(Get.find<CategoryController>().getHomeSubCategoryList(
            reload,
            limit: _defaultHomeSubCategoryLimit(),
          )),
        _safeLoad(Get.find<ServiceController>().getPopularServiceList(1,reload)),
        _safeLoad(Get.find<ServiceController>().getTrendingServiceList(1,reload)),
        _safeLoad(Get.find<ProviderBookingController>().getProviderList(1,reload)),
        _safeLoad(Get.find<NearbyProviderController>().getProviderList(1,reload)),
        _safeLoad(Get.find<CampaignController>().getCampaignList(reload)),
        _safeLoad(Get.find<ServiceController>().getRecommendedServiceList(1, reload)),
        _safeLoad(Get.find<CheckOutController>().getOfflinePaymentMethod(false, shouldUpdate: false)),
        _safeLoad(Get.find<ServiceController>().getFeatherCategoryList(reload)),
        if(Get.find<AuthController>().isLoggedIn()) _safeLoad(Get.find<AuthController>().updateToken()),
        if(Get.find<AuthController>().isLoggedIn()) _safeLoad(Get.find<ServiceController>().getRecentlyViewedServiceList(1,reload)),
      ]);

      await _safeLoad(_loadCuratedHomeSections(reload));

      Get.find<BookingDetailsController>().manageDialog();
    }
  }

  static bool _needsDefaultHomeSubCategories() {
    return MobileAppHomeHelper.orderedEnabledSections().any(
      (s) => s.isSubCategoryContent && !s.isManualData,
    );
  }

  static int _defaultHomeSubCategoryLimit() {
    for (final section in MobileAppHomeHelper.orderedEnabledSections()) {
      if (section.isSubCategoryContent && !section.isManualData) {
        return section.itemLimit ?? 8;
      }
    }
    return 8;
  }

  static Future<void> _loadCuratedHomeSections(bool reload) async {
    if (!MobileAppHomeHelper.usesRemoteConfig) {
      if (_needsDefaultHomeSubCategories()) {
        await Get.find<CategoryController>().getHomeSubCategoryList(
          reload,
          limit: _defaultHomeSubCategoryLimit(),
        );
      }
      return;
    }
    final futures = <Future<void>>[];
    for (final section in MobileAppHomeHelper.manualSections()) {
      final limit = section.itemLimit ?? 10;
      if (section.isServiceContent) {
        futures.add(Get.find<ServiceController>().loadCuratedServices(
          section.key,
          reload: reload,
          limit: limit,
        ));
      } else if (section.isProviderContent) {
        if (section.key == 'nearby_providers') {
          futures.add(Get.find<NearbyProviderController>().loadCuratedProviders(
            section.key,
            reload: reload,
            limit: limit,
          ));
        } else {
          futures.add(Get.find<ProviderBookingController>().loadCuratedProviders(
            section.key,
            reload: reload,
            limit: limit,
          ));
        }
      } else if (section.isBannerContent) {
        futures.add(Get.find<BannerController>().loadCuratedBanners(
          section.key,
          reload: reload,
          limit: limit,
        ));
      } else if (section.key == 'feathered_categories') {
        futures.add(Get.find<ServiceController>().loadCuratedFeatheredCategories(
          section.key,
          reload: reload,
          limit: limit,
        ));
      } else if (section.isCategoryContent || section.isSubCategoryContent) {
        futures.add(Get.find<CategoryController>().loadCuratedCategories(
          section.key,
          reload: true,
          limit: limit,
        ));
      }
    }
    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
  }

  final AddressModel? addressModel;
  final bool showServiceNotAvailableDialog;
  const HomeScreen({super.key, this.addressModel, required this.showServiceNotAvailableDialog}) ;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  AddressModel? _previousAddress;
  int _availableServiceCount = 0;
  bool _homeDataLoaded = false;
  bool _zoneRefreshInFlight = false;
  bool _homeLoadInFlight = false;

  @override
  bool get wantKeepAlive => true;

  int _serviceCountFromAddress() {
    return Get.find<LocationController>().getUserAddress()?.availableServiceCountInZone ?? 0;
  }

  int get _displayServiceCount {
    final fromAddress = _serviceCountFromAddress();
    if (fromAddress > 0) return fromAddress;
    return _availableServiceCount;
  }

  Future<void> _loadHomeContent({bool reload = false}) async {
    if (_homeLoadInFlight) return;

    final count = _serviceCountFromAddress();
    // Before zone count is known, load sections once so home is not blank.
    final effectiveCount = count > 0 ? count : (!_homeDataLoaded ? 1 : 0);

    if (!reload && _homeDataLoaded && count == _availableServiceCount) {
      return;
    }

    _homeLoadInFlight = true;
    _availableServiceCount = count;
    try {
      await HomeScreen.loadData(reload, availableServiceCount: effectiveCount);
      _homeDataLoaded = true;
    } catch (error, stack) {
      _homeDataLoaded = true;
      if (kDebugMode) {
        debugPrint('HomeScreen._loadHomeContent: $error\n$stack');
      }
    } finally {
      _homeLoadInFlight = false;
      if (mounted) {
        setState(() {});
        if (Get.isRegistered<SplashController>()) {
          Get.find<SplashController>().update(['home_layout']);
        }
      }
    }
  }

  Future<void> _refreshZoneCountInBackground() async {
    if (_zoneRefreshInFlight) return;
    _zoneRefreshInFlight = true;
    try {
      final locationController = Get.find<LocationController>();
      final address = locationController.getUserAddress();
      if (address?.latitude == null ||
          address?.longitude == null ||
          address!.latitude!.isEmpty ||
          address.longitude!.isEmpty) {
        return;
      }

      final zoneResponse = await locationController.getZone(
        address.latitude.toString(),
        address.longitude.toString(),
        false,
        isLoading: true,
      );
      address.availableServiceCountInZone = zoneResponse.totalServiceCount;
      await locationController.saveUserAddress(address);

      if (!mounted) return;
      final newCount = zoneResponse.totalServiceCount;
      if (newCount != _availableServiceCount || !_homeDataLoaded) {
        await _loadHomeContent(reload: _homeDataLoaded);
      } else if (mounted) {
        setState(() => _availableServiceCount = newCount ?? 0);
      }
    } finally {
      _zoneRefreshInFlight = false;
    }
  }

  @override
  void initState() {
    super.initState();

    Get.find<LocalizationController>().filterLanguage(shouldUpdate: false);
    if(Get.find<AuthController>().isLoggedIn()) {
      Get.find<UserController>().getUserInfo();
      Get.find<LocationController>().getAddressList();
    }

    _availableServiceCount = _serviceCountFromAddress();
    _previousAddress = widget.addressModel;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _loadHomeContent();
      if (!mounted) return;
      await _refreshZoneCountInBackground();
    });

    if (_previousAddress != null && _displayServiceCount == 0 && widget.showServiceNotAvailableDialog) {
      Future.delayed(const Duration(microseconds: 1000), () {
        if (!mounted) return;
        Get.dialog(
          ServiceNotAvailableDialog(
            address: _previousAddress,
            forCard: false,
            showButton: true,
            onBackPressed: () {
              Get.back();
              Get.find<LocationController>().setZoneContinue('false');
            },
          )
        );
      });
    }
  }

  PreferredSizeWidget homeAppBar({GlobalKey<CustomShakingWidgetState>? signInShakeKey}){
    if(ResponsiveHelper.isDesktop(context)){
      return WebMenuBar(signInShakeKey: signInShakeKey,);
    }else{
      return const AddressAppBar(backButton: false);
    }
  }
  final ScrollController scrollController = ScrollController();
  final signInShakeKey = GlobalKey<CustomShakingWidgetState>();

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final availableServiceCount = _displayServiceCount;

    return Scaffold(
      appBar: homeAppBar(signInShakeKey: signInShakeKey),
      drawer: ResponsiveHelper.isDesktop(context) ? const AddressSelectionDrawer() : null,
      endDrawer:ResponsiveHelper.isDesktop(context) ? const MenuDrawer() : null,
      body: ResponsiveHelper.isDesktop(context) ? WebHomeScreen(scrollController: scrollController, availableServiceCount: availableServiceCount, signInShakeKey : signInShakeKey,) : SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _refreshZoneCountInBackground();
            await _loadHomeContent(reload: true);
          },
          child: GestureDetector(
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: GetBuilder<SplashController>(
              id: 'home_layout',
              builder: (splashController) {
                return GetBuilder<ProviderBookingController>(builder: (providerController) {
                  return GetBuilder<ServiceController>(builder: (serviceController) {
                    return GetBuilder<CategoryController>(builder: (categoryController) {
                    final bool isAvailableProvider = providerController.providerList != null && providerController.providerList!.isNotEmpty;
                    final int? providerBooking = splashController.configModel.content?.directProviderBooking;
                    final bool isLtr = Get.find<LocalizationController>().isLtr;

                    final slivers = CustomerHomeSections.buildHomeSlivers(
                      context: context,
                      availableServiceCount: availableServiceCount,
                      isAvailableProvider: isAvailableProvider,
                      providerBooking: providerBooking,
                      isLtr: isLtr,
                      serviceController: serviceController,
                      providerController: providerController,
                    );

                    if (!_homeDataLoaded) {
                      slivers.insert(
                        1,
                        const SliverToBoxAdapter(child: _HomeInitialLoadingView()),
                      );
                    }

                    return CustomScrollView(
                      controller: scrollController,
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: ClampingScrollPhysics(),
                      ),
                      slivers: slivers,
                    );
                    });
                  });
                });
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeInitialLoadingView extends StatelessWidget {
  const _HomeInitialLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
      child: Column(
        children: [
          PopularServiceShimmer(enabled: true),
          SizedBox(height: Dimensions.paddingSizeLarge),
          PopularServiceShimmer(enabled: true),
        ],
      ),
    );
  }
}
