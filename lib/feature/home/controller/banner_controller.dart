import 'package:demandium/api/local/cache_response.dart';
import 'package:demandium/feature/home/helper/mobile_app_home_api_helper.dart';
import 'package:demandium/feature/home/helper/mobile_app_home_helper.dart';
import 'package:demandium/helper/data_sync_helper.dart';
import 'package:get/get.dart';
import 'package:demandium/util/core_export.dart';

class BannerController extends GetxController implements GetxService {
  final BannerRepo bannerRepo;
  BannerController({required this.bannerRepo});

  List<BannerModel>? _banners;
  final Map<String, List<BannerModel>?> _curatedBannersBySection = {};
  List<BannerModel>? get banners => _banners;
  List<BannerModel>? curatedBannersFor(String sectionKey) => _curatedBannersBySection[sectionKey];

  int? _currentIndex = 0;
  int? get currentIndex => _currentIndex;

  Future<void> getBannerList(bool reload) async {


    if(_banners == null || reload){
      await DataSyncHelper.fetchAndSyncData(
        fetchFromLocal: ()=> bannerRepo.getBannerList<CacheResponseData>( source: DataSourceEnum.local),
        fetchFromClient: ()=> bannerRepo.getBannerList(source: DataSourceEnum.client),
        onResponse: (data, source) {
          _banners = [];
          final dynamic bannerList = data['content']?['data'];
          if (bannerList is List) {
            for (final banner in bannerList) {
              if (banner is Map<String, dynamic>) {
                _banners!.add(BannerModel.fromJson(banner));
              }
            }
          }
          update();
        },
      );
    }

  }

  List<BannerModel>? bannersForSection(String sectionKey) {
    if (MobileAppHomeHelper.usesManualData(sectionKey)) {
      return curatedBannersFor(sectionKey);
    }
    return _banners;
  }

  Future<void> loadCuratedBanners(String sectionKey, {bool reload = false, int limit = 10}) async {
    final cached = _curatedBannersBySection[sectionKey];
    if (!reload && cached != null) {
      final pickIds = MobileAppHomeHelper.section(sectionKey)?.bannerIds ?? const [];
      if (cached.isNotEmpty || pickIds.isEmpty) {
        return;
      }
    }
    await DataSyncHelper.fetchAndSyncData(
      fetchFromLocal: () => bannerRepo.getMobileAppHomeSectionBanners<CacheResponseData>(
        sectionKey: sectionKey,
        source: DataSourceEnum.local,
        limit: limit,
      ),
      fetchFromClient: () => bannerRepo.getMobileAppHomeSectionBanners(
        sectionKey: sectionKey,
        source: DataSourceEnum.client,
        limit: limit,
      ),
      onResponse: (data, source) {
        _curatedBannersBySection[sectionKey] = MobileAppHomeApiHelper.extractContentDataMaps(data)
            .map((item) => BannerModel.fromJson(item))
            .toList();
        update();
      },
    );
  }

  void setCurrentIndex(int index, bool notify) {
    _currentIndex = index;
    if(notify) {
      update();
    }
  }


  Future<void> navigateFromBanner(String resourceType, String bannerID, String link, String resourceID, {String categoryName = '', String? serviceSlug})async {
    switch (resourceType){
      case 'category':
        Get.toNamed(RouteHelper.subCategoryScreenRoute(categoryName,bannerID,0));
        break;

      case 'link':
        if (await canLaunchUrl(Uri.parse(link))) {
          await launchUrl(Uri.parse(link));
        } else {
          throw 'Could not launch $link';
        }
        break;
      case 'service':
        if (serviceSlug != null && serviceSlug.isNotEmpty) {
          Get.toNamed(RouteHelper.getServiceRoute(serviceSlug));
        } else {
          customSnackBar('no_service_available'.tr, type: ToasterMessageType.info);
        }
        break;
      default:
    }
  }

  void applyHomeBundleBanners(dynamic rawContent) {
    _banners = [];
    for (final item in MobileAppHomeApiHelper.extractContentDataMaps({'content': rawContent})) {
      _banners!.add(BannerModel.fromJson(item));
    }
    update();
  }

  void applyHomeBundleCuratedBanners(String sectionKey, List<BannerModel> banners) {
    _curatedBannersBySection[sectionKey] = banners;
    update();
  }

  void clearSessionData({bool notify = true}) {
    _banners = null;
    _curatedBannersBySection.clear();
    _currentIndex = 0;
    if (notify) update();
  }
}
