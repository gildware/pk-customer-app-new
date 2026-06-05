import 'package:demandium/common/models/api_response_model.dart';
import 'package:demandium/common/repo/data_sync_repo.dart';
import 'package:demandium/util/core_export.dart';

class BannerRepo extends DataSyncRepo{
  BannerRepo({required super.apiClient, required SharedPreferences super.sharedPreferences});

  Future<ApiResponseModel<T>> getBannerList<T>({required DataSourceEnum source}) async {
    return await fetchData<T>(AppConstants.bannerUri, source);
  }

  Future<ApiResponseModel<T>> getMobileAppHomeSectionBanners<T>({
    required String sectionKey,
    required DataSourceEnum source,
    int limit = 10,
  }) async {
    return await fetchData<T>(
      '${AppConstants.mobileAppHomeSectionUri}$sectionKey/banners?limit=$limit&offset=1',
      source,
    );
  }

}