import 'package:demandium/api/local/cache_response.dart';
import 'package:demandium/common/enums/enums.dart';
import 'package:demandium/feature/home/helper/mobile_app_home_api_helper.dart';
import 'package:demandium/feature/home/helper/mobile_app_home_helper.dart';
import 'package:demandium/feature/home/repository/home_bundle_repo.dart';
import 'package:demandium/helper/data_sync_helper.dart';
import 'package:get/get.dart';
import 'package:demandium/util/core_export.dart';

class HomeBundleHelper {
  static bool _bundleApplied = false;

  static bool get bundleApplied => _bundleApplied;

  static Future<bool> loadAndApply({required bool reload}) async {
    if (!reload && _bundleApplied) {
      return true;
    }

    var applied = false;
    await DataSyncHelper.fetchAndSyncData(
      fetchFromLocal: () => Get.find<HomeBundleRepo>().getHomeBundle<CacheResponseData>(
        source: DataSourceEnum.local,
      ),
      fetchFromClient: () => Get.find<HomeBundleRepo>().getHomeBundle(
        source: DataSourceEnum.client,
      ),
      onResponse: (data, source) {
        final content = data['content'];
        if (content is Map) {
          _apply(Map<String, dynamic>.from(content));
          applied = true;
          _bundleApplied = true;
        }
      },
      suppressErrorWhenLocalSucceeded: true,
    );
    return applied;
  }

  static void reset() {
    _bundleApplied = false;
  }

  static void _apply(Map<String, dynamic> content) {
    if (content['banners'] != null) {
      Get.find<BannerController>().applyHomeBundleBanners(content['banners']);
    }
    if (content['categories'] != null) {
      Get.find<CategoryController>().applyHomeBundleCategories(content['categories']);
    }
    if (content['popular_services'] != null) {
      Get.find<ServiceController>().applyHomeBundlePopularServices(content['popular_services']);
    }
    if (content['trending_services'] != null) {
      Get.find<ServiceController>().applyHomeBundleTrendingServices(content['trending_services']);
    }
    if (content['recommended_services'] != null) {
      Get.find<ServiceController>().applyHomeBundleRecommendedServices(content['recommended_services']);
    }
    if (content['recommended_search'] != null) {
      Get.find<ServiceController>().applyHomeBundleRecommendedSearch(content['recommended_search']);
    }
    if (content['featured_categories'] != null) {
      Get.find<ServiceController>().applyHomeBundleFeaturedCategories(content['featured_categories']);
    }
    if (content['recently_viewed_services'] != null) {
      Get.find<ServiceController>().applyHomeBundleRecentlyViewed(content['recently_viewed_services']);
    }
    if (content['sub_categories'] != null) {
      Get.find<CategoryController>().applyHomeBundleSubCategories(content['sub_categories']);
    }
    if (content['providers'] != null) {
      Get.find<ProviderBookingController>().applyHomeBundleProviders(content['providers']);
    }
    if (content['nearby_providers'] != null) {
      Get.find<NearbyProviderController>().applyHomeBundleProviders(content['nearby_providers']);
    }
    if (content['campaigns'] != null) {
      Get.find<CampaignController>().applyHomeBundleCampaigns(content['campaigns']);
    }
    if (content['advertisements'] != null) {
      Get.find<AdvertisementController>().applyHomeBundleAdvertisements(content['advertisements']);
    }
    if (content['offline_payment_methods'] != null) {
      Get.find<CheckOutController>().applyHomeBundleOfflineMethods(content['offline_payment_methods']);
    }

    final curated = content['curated_sections'];
    if (curated is Map) {
      _applyCuratedSections(Map<String, dynamic>.from(curated));
    }
  }

  static void _applyCuratedSections(Map<String, dynamic> sections) {
    for (final entry in sections.entries) {
      final key = entry.key;
      final raw = entry.value;
      if (raw == null) continue;

      final section = MobileAppHomeHelper.section(key);
      if (section == null) continue;

      final wrapped = {'content': raw is Map ? raw : {'data': raw}};

      if (section.isServiceContent) {
        final services = MobileAppHomeApiHelper.extractContentDataMaps(wrapped)
            .map((item) => Service.fromJson(item))
            .toList();
        Get.find<ServiceController>().applyHomeBundleCuratedServices(key, services);
      } else if (section.isProviderContent) {
        final providers = ProviderModel.fromJson(wrapped).content?.data ?? [];
        if (section.key == 'nearby_providers') {
          Get.find<NearbyProviderController>().applyHomeBundleCuratedProviders(key, providers);
        } else {
          Get.find<ProviderBookingController>().applyHomeBundleCuratedProviders(key, providers);
        }
      } else if (section.isBannerContent) {
        final banners = MobileAppHomeApiHelper.extractContentDataMaps(wrapped)
            .map((item) => BannerModel.fromJson(item))
            .toList();
        Get.find<BannerController>().applyHomeBundleCuratedBanners(key, banners);
      } else if (section.isCategoryContent || section.isSubCategoryContent) {
        final categories = MobileAppHomeApiHelper.extractContentDataMaps(wrapped)
            .map((item) => CategoryModel.fromJson(item))
            .toList();
        Get.find<CategoryController>().applyHomeBundleCuratedCategories(key, categories);
      } else if (key == 'feathered_categories') {
        final categories = MobileAppHomeApiHelper.extractContentDataMaps(wrapped)
            .map((item) => CategoryData.fromJson(item))
            .where((c) => c.servicesByCategory != null && c.servicesByCategory!.isNotEmpty)
            .toList();
        Get.find<ServiceController>().applyHomeBundleCuratedFeatheredCategories(key, categories);
      }
    }
  }
}
