import 'package:demandium/common/models/api_response_model.dart';
import 'package:demandium/common/repo/data_sync_repo.dart';
import 'package:get/get.dart';
import 'package:get/get_connect/http/src/response/response.dart';
import 'package:demandium/util/core_export.dart';

class UserRepo extends DataSyncRepo{
  UserRepo({required super.apiClient, required SharedPreferences super.sharedPreferences});

  Future<ApiResponseModel<T>> getUserInfo<T> ({required DataSourceEnum source}) async {
    return await fetchData<T>(AppConstants.customerInfoUri, source);
  }

  Future<ApiResponseModel<T>> getCategoryList<T>({required DataSourceEnum source}) async {
    return await fetchData<T>('${AppConstants.categoryUrl}?limit=100&offset=1', source);
  }

  Future<Response> updateProfile(UserInfoModel userInfoModel, XFile? data) async {
    Map<String, String> body = {};
    body.addAll(<String, String>{
      '_method': 'put',
      'first_name': userInfoModel.fName!,
      'last_name': userInfoModel.lName!,
      'email': userInfoModel.email!,
      'phone': userInfoModel.phone!,
      'password': userInfoModel.password ?? "",
      'confirm_password': userInfoModel.confirmPassword ??"",
    });
    return await apiClient.postMultipartData(AppConstants.updateProfileUri, body,data != null ? [MultipartBody('profile_image', data)]:[]);
  }

  Future<Response> changePassword({
    required String identity,
    required String identityType,
    required String otp,
    required String password,
    required String confirmPassword,
    int isFirebaseOtp = 0,
  }) async {
    return await apiClient.putData(AppConstants.resetPasswordUri, {
      '_method': 'put',
      'identity': identity,
      'identity_type': identityType,
      'otp': otp,
      'password': password,
      'confirm_password': confirmPassword,
      'is_firebase_otp': isFirebaseOtp,
    });
  }

  Future<Response> deleteUser() async {
    return await apiClient.deleteData(AppConstants.customerRemove);
  }

}