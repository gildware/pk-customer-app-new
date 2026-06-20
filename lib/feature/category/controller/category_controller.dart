import 'package:demandium/api/local/cache_response.dart';
import 'package:demandium/feature/home/helper/mobile_app_home_api_helper.dart';
import 'package:demandium/feature/home/helper/mobile_app_home_helper.dart';
import 'package:demandium/helper/data_sync_helper.dart';
import 'package:get/get.dart';
import 'package:demandium/util/core_export.dart';
import 'package:demandium/common/models/category_types_model.dart';

class CategoryController extends GetxController implements GetxService {
  final CategoryRepo categoryRepo;
  CategoryController({required this.categoryRepo});

  static bool _categoryHasServices(CategoryModel category) =>
      (category.serviceCount ?? 0) > 0;

  List<CategoryModel>? _categoryList;
  final Map<String, List<CategoryModel>?> _curatedCategoriesBySection = {};
  List<CategoryModel>? _homeSubCategoryList;
  List<CategoryModel>? _subCategoryList;
  List<Service>? _searchProductList = [];
  List<CategoryModel>? _campaignBasedCategoryList ;
  int _subCategoryRequestId = 0;

  bool _isLoading = false;
  int? _pageSize;
  bool? _isSearching = false;
  final String _type = 'all';
  final String _searchText = '';

  List<CategoryModel>? get categoryList => _categoryList;
  List<CategoryModel>? curatedCategoriesFor(String sectionKey) => _curatedCategoriesBySection[sectionKey];

  List<CategoryModel>? categoriesForSection(String sectionKey) {
    if (MobileAppHomeHelper.usesManualData(sectionKey)) {
      return curatedCategoriesFor(sectionKey);
    }
    return _categoryList;
  }

  List<CategoryModel>? subCategoriesForSection(String sectionKey) {
    if (MobileAppHomeHelper.usesManualData(sectionKey)) {
      return curatedCategoriesFor(sectionKey);
    }
    if (MobileAppHomeHelper.section(sectionKey)?.isSubCategoryContent ?? false) {
      return _homeSubCategoryList;
    }
    return null;
  }

  bool subCategoriesLoadedForSection(String sectionKey) {
    final section = MobileAppHomeHelper.section(sectionKey);
    if (section == null || !section.isSubCategoryContent) {
      return false;
    }
    final list = subCategoriesForSection(sectionKey);
    if (list == null) {
      return false;
    }
    if (section.isManualData && list.isEmpty && section.categoryIds.isNotEmpty) {
      return false;
    }
    return true;
  }

  Future<void> ensureSubCategoriesForSection(String sectionKey) async {
    final section = MobileAppHomeHelper.section(sectionKey);
    if (section == null || !section.isSubCategoryContent) {
      return;
    }
    final limit = section.itemLimit ?? 10;
    if (section.isManualData) {
      final cached = curatedCategoriesFor(sectionKey);
      final shouldFetch = cached == null ||
          (cached.isEmpty && section.categoryIds.isNotEmpty);
      if (shouldFetch) {
        await loadCuratedCategories(sectionKey, reload: true, limit: limit);
      }
      return;
    }
    if (_homeSubCategoryList == null) {
      await getHomeSubCategoryList(true, limit: limit);
    }
  }

  Future<void> getHomeSubCategoryList(bool reload, {int limit = 8}) async {
    if (_homeSubCategoryList != null && !reload) {
      return;
    }
    await DataSyncHelper.fetchAndSyncData(
      fetchFromLocal: () => categoryRepo.getHomeSubCategoryList<CacheResponseData>(
        source: DataSourceEnum.local,
        limit: limit,
      ),
      fetchFromClient: () => categoryRepo.getHomeSubCategoryList(
        source: DataSourceEnum.client,
        limit: limit,
      ),
      onResponse: (data, source) {
        _homeSubCategoryList = MobileAppHomeApiHelper.extractContentDataMaps(data)
            .map((item) => CategoryModel.fromJson(item))
            .where((c) => c.isActive == true && _categoryHasServices(c))
            .toList();
        update();
      },
    );
  }

  Future<void> loadCuratedCategories(String sectionKey, {bool reload = false, int limit = 10}) async {
    if (reload) {
      _curatedCategoriesBySection.remove(sectionKey);
    }
    final cached = _curatedCategoriesBySection[sectionKey];
    if (!reload && cached != null) {
      final pickIds = MobileAppHomeHelper.section(sectionKey)?.categoryIds ?? const [];
      if (cached.isNotEmpty || pickIds.isEmpty) {
        return;
      }
    }
    await DataSyncHelper.fetchAndSyncData(
      fetchFromLocal: () => categoryRepo.getMobileAppHomeSectionCategories<CacheResponseData>(
        sectionKey: sectionKey,
        source: DataSourceEnum.local,
        limit: limit,
      ),
      fetchFromClient: () => categoryRepo.getMobileAppHomeSectionCategories(
        sectionKey: sectionKey,
        source: DataSourceEnum.client,
        limit: limit,
      ),
      onResponse: (data, source) {
        final section = MobileAppHomeHelper.section(sectionKey);
        final isSubCategorySection = section?.isSubCategoryContent ?? false;
        _curatedCategoriesBySection[sectionKey] = MobileAppHomeApiHelper.extractContentDataMaps(data)
            .map((item) => CategoryModel.fromJson(item))
            .where((c) {
              if (c.isActive == false) {
                return false;
              }
              if (isSubCategorySection) {
                return _categoryHasServices(c);
              }
              return true;
            })
            .toList();
        update();
      },
    );
  }
  List<CategoryModel>? get campaignBasedCategoryList => _campaignBasedCategoryList;
  List<CategoryModel>? get subCategoryList => _subCategoryList;
  List<Service>? get searchServiceList => _searchProductList;
  bool get isLoading => _isLoading;
  int? get pageSize => _pageSize;
  bool? get isSearching => _isSearching;
  String? get type => _type;
  String? get searchText => _searchText;


  Future<void> getCategoryList(bool reload ) async {

    if(_categoryList == null || reload){
      await DataSyncHelper.fetchAndSyncData(
        fetchFromLocal: ()=> categoryRepo.getCategoryList<CacheResponseData>( source: DataSourceEnum.local),
        fetchFromClient: ()=> categoryRepo.getCategoryList(source: DataSourceEnum.client),
        onResponse: (data, source) {

          _categoryList = [];
          data['content']['data'].forEach((category) {
            _categoryList!.add(CategoryModel.fromJson(category));
          });
          Get.find<AllSearchController>().insertCategoryCheckedList();
          update();
        },
      );
    }
  }


  Future<void> getSubCategoryList(String categorySlug, {bool shouldUpdate = true}) async {
    final requestId = ++_subCategoryRequestId;
    _subCategoryList = null;
    if(shouldUpdate){
      update();
    }
    Response response = await categoryRepo.getSubCategoryList(categorySlug);
    if (requestId != _subCategoryRequestId) {
      return;
    }
    if (response.statusCode == 200 && response.body['response_code'] == 'default_200') {
      _subCategoryList= [];
      response.body['content']['data'].forEach((category) {
        final model = CategoryModel.fromJson(category);
        _subCategoryList!.addIf(
          model.isActive == true && _categoryHasServices(model),
          model,
        );
      });
    } else {
      _subCategoryList= [];
    }
    update();
  }

  Future<void> getCampaignBasedCategoryList(String campaignID, bool isWithPagination) async {
    printLog("inside_campaign_based_category !");
    Response response = await categoryRepo.getItemsBasedOnCampaignId(campaignID: campaignID);

    if (response.body['response_code'] == 'default_200') {
      if(!isWithPagination){
        _campaignBasedCategoryList = [];
      }
      response.body['content']['data'].forEach((categoryTypesModel) {
        if(CategoryTypesModel.fromJson(categoryTypesModel).category != null){
          _campaignBasedCategoryList!.add(CategoryTypesModel.fromJson(categoryTypesModel).category!);
        }
      });
      _isLoading = false;
      Get.toNamed(RouteHelper.getCategoryRoute('fromCampaign',campaignID));
    } else {
      if(response.statusCode != 200){
        ApiChecker.checkApi(response);
      }else{
        customSnackBar('campaign_is_not_available_for_this_service'.tr, type: ToasterMessageType.info);
      }
    }
    update();
  }


  void toggleSearch() {
    _isSearching = !_isSearching!;
    _searchProductList = [];
    update();
  }
  void showBottomLoader() {
    _isLoading = true;
    update();
  }

  void applyHomeBundleCategories(dynamic rawContent) {
    _categoryList = [];
    for (final item in MobileAppHomeApiHelper.extractContentDataMaps({'content': rawContent})) {
      _categoryList!.add(CategoryModel.fromJson(item));
    }
    Get.find<AllSearchController>().insertCategoryCheckedList();
    update();
  }

  void applyHomeBundleSubCategories(dynamic rawContent) {
    _homeSubCategoryList = MobileAppHomeApiHelper.extractContentDataMaps({'content': rawContent})
        .map((item) => CategoryModel.fromJson(item))
        .where((c) => c.isActive == true && _categoryHasServices(c))
        .toList();
    update();
  }

  void applyHomeBundleCuratedCategories(String sectionKey, List<CategoryModel> categories) {
    _curatedCategoriesBySection[sectionKey] = categories;
    update();
  }

  void clearSessionData({bool notify = true}) {
    _categoryList = null;
    _curatedCategoriesBySection.clear();
    _homeSubCategoryList = null;
    _subCategoryList = null;
    _searchProductList = [];
    _campaignBasedCategoryList = null;
    if (notify) update();
  }
}
