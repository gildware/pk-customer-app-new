import 'package:demandium/api/local/cache_response.dart';
import 'package:demandium/feature/home/helper/mobile_app_home_api_helper.dart';
import 'package:demandium/feature/home/helper/mobile_app_home_helper.dart';
import 'package:demandium/helper/data_sync_helper.dart';
import 'package:get/get.dart';
import 'package:demandium/util/core_export.dart';
import 'package:demandium/feature/home/model/campaign_model.dart';

class CampaignController extends GetxController implements GetxService {
  final CampaignRepo campaignRepo;
  CampaignController({required this.campaignRepo});

  List<CampaignData>? _campaignList ;
  final Map<String, List<CampaignData>?> _curatedCampaignsBySection = {};
  List<Service>? _itemCampaignList;
  int? _currentIndex = 0;
  bool? _isLoading = false;

  List<CampaignData>? get campaignList => _campaignList;
  List<CampaignData>? curatedCampaignsFor(String sectionKey) => _curatedCampaignsBySection[sectionKey];
  List<Service>? get itemCampaignList => _itemCampaignList;
  int? get currentIndex => _currentIndex;
  bool? get isLoading => _isLoading;

  Future<void> getCampaignList(bool reload) async {
    if(_campaignList == null || reload){

      await DataSyncHelper.fetchAndSyncData(
        fetchFromLocal: ()=>campaignRepo.getCampaignList<CacheResponseData>( source: DataSourceEnum.local),
        fetchFromClient: ()=> campaignRepo.getCampaignList(source: DataSourceEnum.client),
        onResponse: (data, source) {
          _campaignList = [];
          data['content']['data'].forEach((campaign) {
            _campaignList!.add(CampaignData.fromJson(campaign));
          });
          update();
        },
      );
    }
  }

  List<CampaignData>? campaignsForSection(String sectionKey) {
    if (MobileAppHomeHelper.usesManualData(sectionKey)) {
      return curatedCampaignsFor(sectionKey);
    }
    return _campaignList;
  }

  Future<void> loadCuratedCampaigns(String sectionKey, {bool reload = false, int limit = 10}) async {
    final cached = _curatedCampaignsBySection[sectionKey];
    if (!reload && cached != null) {
      final pickIds = MobileAppHomeHelper.section(sectionKey)?.campaignIds ?? const [];
      if (cached.isNotEmpty || pickIds.isEmpty) {
        return;
      }
    }
    await DataSyncHelper.fetchAndSyncData(
      fetchFromLocal: () => campaignRepo.getMobileAppHomeSectionCampaigns<CacheResponseData>(
        sectionKey: sectionKey,
        source: DataSourceEnum.local,
        limit: limit,
      ),
      fetchFromClient: () => campaignRepo.getMobileAppHomeSectionCampaigns(
        sectionKey: sectionKey,
        source: DataSourceEnum.client,
        limit: limit,
      ),
      onResponse: (data, source) {
        _curatedCampaignsBySection[sectionKey] = MobileAppHomeApiHelper.extractContentDataMaps(data)
            .map((item) => CampaignData.fromJson(item))
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

  Future<void> navigateFromCampaign(String campaignID,String discountType)async {
    printLog("discountType:$discountType");
    _isLoading = true;
    update();
    if(discountType == 'category'){
      Get.find<CategoryController>().getCampaignBasedCategoryList(campaignID,false);
    }else if(discountType == 'mixed'){
      Get.find<ServiceController>().getMixedCampaignList(campaignID,false);
    }else{
      Get.find<ServiceController>().getCampaignBasedServiceList(campaignID,true);
    }
    _isLoading = false;
    update();
  }

  void applyHomeBundleCampaigns(dynamic rawContent) {
    _campaignList = [];
    final list = rawContent is Map ? rawContent['data'] : null;
    if (list is List) {
      for (final campaign in list) {
        if (campaign is Map<String, dynamic>) {
          _campaignList!.add(CampaignData.fromJson(campaign));
        }
      }
    }
    update();
  }

  void applyHomeBundleCuratedCampaigns(String sectionKey, List<CampaignData> campaigns) {
    _curatedCampaignsBySection[sectionKey] = campaigns;
    update();
  }

  void clearSessionData({bool notify = true}) {
    _campaignList = null;
    _curatedCampaignsBySection.clear();
    _itemCampaignList = null;
    _currentIndex = 0;
    if (notify) update();
  }
}