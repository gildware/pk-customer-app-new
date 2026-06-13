import 'package:demandium/common/enums/enums.dart';
import 'package:demandium/common/models/api_response_model.dart';
import 'package:demandium/common/repo/data_sync_repo.dart';
import 'package:demandium/util/app_constants.dart';

class HomeBundleRepo extends DataSyncRepo {
  HomeBundleRepo({required super.apiClient, required super.sharedPreferences});

  Future<ApiResponseModel<T>> getHomeBundle<T>({required DataSourceEnum source}) async {
    return fetchData<T>(AppConstants.homeBundleUri, source);
  }
}
