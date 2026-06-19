import 'package:demandium/feature/home/helper/mobile_app_home_helper.dart';
import 'package:demandium/feature/home/widget/curated_provider_horizontal_view.dart';
import 'package:demandium/feature/home/widget/home_sub_category_view.dart';
import 'package:demandium/feature/home/widget/nearby_provider_listview.dart';
import 'package:get/get.dart';
import 'package:demandium/util/core_export.dart';

/// Builds customer home sections from admin [mobile_app_home] config.
class CustomerHomeSections {
  /// Slivers in admin sort order (search uses [HomeSearchWidget] pinned header).
  static List<Widget> buildHomeSlivers({
    required BuildContext context,
    required int availableServiceCount,
    required bool isAvailableProvider,
    required int? providerBooking,
    required bool isLtr,
    required ServiceController serviceController,
    required ProviderBookingController providerController,
  }) {
    final splash = Get.find<SplashController>().configModel.content;
    final directBooking = splash?.directProviderBooking == 1;
    final biddingOn = splash?.biddingStatus == 1;
    final isLoggedIn = Get.find<AuthController>().isLoggedIn();

    final sections = MobileAppHomeHelper.orderedEnabledSections(excludeSearch: false);
    final slivers = <Widget>[
      const SliverToBoxAdapter(child: SizedBox(height: Dimensions.paddingSizeSmall)),
    ];

    final columnChildren = <Widget>[];

    void flushColumn() {
      if (columnChildren.isEmpty) return;
      slivers.add(
        SliverToBoxAdapter(
          child: Center(
            child: SizedBox(
              width: Dimensions.webMaxWidth,
              child: Column(children: List.from(columnChildren)),
            ),
          ),
        ),
      );
      columnChildren.clear();
    }

    for (final section in sections) {
      if (section.key == 'search') {
        flushColumn();
        slivers.add(const HomeSearchWidget());
        continue;
      }

      final widget = _buildSection(
        context: context,
        section: section,
        availableServiceCount: availableServiceCount,
        directBooking: directBooking,
        biddingOn: biddingOn,
        isLoggedIn: isLoggedIn,
        isAvailableProvider: isAvailableProvider,
        providerBooking: providerBooking,
        isLtr: isLtr,
        serviceController: serviceController,
        providerController: providerController,
      );
      if (widget != null) {
        columnChildren.add(widget);
      }
    }

    flushColumn();

    if (slivers.length <= 1) {
      slivers.add(
        SliverToBoxAdapter(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * .6,
            child: const ServiceNotAvailableScreen(),
          ),
        ),
      );
    }

    return slivers;
  }

  static Widget? _buildSection({
    required BuildContext context,
    required HomeSectionConfig section,
    required int availableServiceCount,
    required bool directBooking,
    required bool biddingOn,
    required bool isLoggedIn,
    required bool isAvailableProvider,
    required int? providerBooking,
    required bool isLtr,
    required ServiceController serviceController,
    required ProviderBookingController providerController,
  }) {
    if (availableServiceCount <= 0 && section.key != 'banners') {
      return null;
    }

    switch (section.key) {
      case 'banners':
        return const BannerView(sectionKey: 'banners');

      case 'categories':
        return const Padding(
          padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
          child: CategoryView(sectionKey: 'categories'),
        );

      case 'highlight_providers':
        if (MobileAppHomeHelper.usesManualData('highlight_providers')) {
          final curated = Get.find<ProviderBookingController>().providersForHomeSection('highlight_providers');
          if (curated != null && curated.isEmpty) return null;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
            child: CuratedProviderHorizontalView(
              sectionKey: 'highlight_providers',
              height: isLtr ? 190 : 205,
              titleOverride: MobileAppHomeHelper.sectionTitle('highlight_providers', 'highlight_providers'),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
          child: HighlightProviderWidget(
            titleOverride: MobileAppHomeHelper.sectionTitle('highlight_providers', 'highlight_for_you'),
          ),
        );

      case 'popular_services':
        return Column(
          children: [
            const SizedBox(height: Dimensions.paddingSizeLarge),
            HorizontalScrollServiceView(
              fromPage: 'popular_services',
              serviceList: serviceController.servicesForHomeSection('popular_services'),
              titleOverride: MobileAppHomeHelper.sectionTitle('popular_services', 'popular_services'),
            ),
          ],
        );

      case 'campaigns':
        return const CampaignView(sectionKey: 'campaigns');

      case 'recommended_services':
        if (MobileAppHomeHelper.usesManualData('recommended_services')) {
          return Column(
            children: [
              const SizedBox(height: Dimensions.paddingSizeLarge),
              HorizontalScrollServiceView(
                fromPage: 'recommended_services',
                serviceList: serviceController.servicesForHomeSection('recommended_services'),
                titleOverride: MobileAppHomeHelper.sectionTitle('recommended_services', 'recommended_for_you'),
              ),
            ],
          );
        }
        return Column(
          children: [
            const SizedBox(height: Dimensions.paddingSizeLarge),
            RecommendedServiceView(
              height: isLtr ? 210 : 225,
              titleOverride: MobileAppHomeHelper.sectionTitle('recommended_services', 'recommended_for_you'),
            ),
          ],
        );

      case 'nearby_providers':
        if (providerBooking != 1) {
          return null;
        }
        if (MobileAppHomeHelper.usesManualData('nearby_providers')) {
          final nearby = Get.find<NearbyProviderController>();
          final list = nearby.providersForHomeSection('nearby_providers');
          if (list != null && list.isEmpty) return null;
          return Column(
            children: [
              const SizedBox(height: Dimensions.paddingSizeLarge),
              CuratedProviderHorizontalView(
                sectionKey: 'nearby_providers',
                height: isLtr ? 190 : 205,
                titleOverride: MobileAppHomeHelper.sectionTitle('nearby_providers', 'providers_near_you'),
              ),
            ],
          );
        }
        if (!(isAvailableProvider || providerController.providerList == null)) {
          return null;
        }
        return Column(
          children: [
            SizedBox(height: (isAvailableProvider || providerController.providerList == null) ? Dimensions.paddingSizeLarge : 0),
            NearbyProviderListview(
              height: isLtr ? 190 : 205,
              titleOverride: MobileAppHomeHelper.sectionTitle('nearby_providers', 'providers_near_you'),
            ),
          ],
        );

      case 'explore_provider_card':
        if (providerBooking != 1 || !(isAvailableProvider || providerController.providerList == null)) {
          return null;
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeLarge),
          child: SizedBox(
            height: 160,
            child: ExploreProviderCard(showShimmer: providerController.providerList == null),
          ),
        );

      case 'recommended_providers':
        if (!directBooking) return null;
        if (MobileAppHomeHelper.usesManualData('recommended_providers')) {
          return CuratedProviderHorizontalView(
            sectionKey: 'recommended_providers',
            height: 220,
            titleOverride: MobileAppHomeHelper.sectionTitle('recommended_providers', 'recommended_experts_for_you'),
          );
        }
        return HomeRecommendProvider(
          height: 220,
          titleOverride: MobileAppHomeHelper.sectionTitle('recommended_providers', 'recommended_experts_for_you'),
        );

      case 'create_post':
        if (!biddingOn) return null;
        return const Padding(
          padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeLarge),
          child: HomeCreatePostView(showShimmer: false),
        );

      case 'recently_viewed':
        if (!isLoggedIn && !MobileAppHomeHelper.usesManualData('recently_viewed')) return null;
        return HorizontalScrollServiceView(
          fromPage: 'recently_view_services',
          serviceList: serviceController.servicesForHomeSection('recently_viewed'),
          titleOverride: MobileAppHomeHelper.sectionTitle('recently_viewed', 'recently_view_services'),
        );

      case 'trending_services':
        return HorizontalScrollServiceView(
          fromPage: 'trending_services',
          serviceList: serviceController.servicesForHomeSection('trending_services'),
          titleOverride: MobileAppHomeHelper.sectionTitle('trending_services', 'trending_services'),
        );

      case 'feathered_categories':
        return const FeatheredCategoryView();

      default:
        if (!MobileAppHomeHelper.isCustomSection(section.key)) {
          return null;
        }
        if (section.isSubCategoryContent) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
            child: HomeSubCategoryView(sectionKey: section.key),
          );
        }
        if (section.isServiceContent) {
          return Column(
            children: [
              const SizedBox(height: Dimensions.paddingSizeLarge),
              HorizontalScrollServiceView(
                fromPage: section.key,
                serviceList: serviceController.servicesForHomeSection(section.key),
                titleOverride: MobileAppHomeHelper.sectionTitle(section.key, section.key),
              ),
            ],
          );
        }
        if (section.isProviderContent && directBooking) {
          return CuratedProviderHorizontalView(
            sectionKey: section.key,
            height: isLtr ? 190 : 205,
            titleOverride: MobileAppHomeHelper.sectionTitle(section.key, section.key),
          );
        }
        if (section.isBannerContent) {
          return BannerView(sectionKey: section.key);
        }
        if (section.isCampaignContent) {
          return CampaignView(sectionKey: section.key);
        }
        if (section.isCategoryContent) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
            child: CategoryView(sectionKey: section.key),
          );
        }
        return null;
    }
  }
}
