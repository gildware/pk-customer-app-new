import 'dart:convert';
import 'package:demandium/api/local/cache_response.dart';
import 'package:demandium/common/models/api_response_model.dart';
import 'package:demandium/helper/db_helper.dart';
import 'package:demandium/helper/get_di.dart';
import 'package:demandium/util/core_export.dart';
import 'package:drift/drift.dart';
import 'package:get/get_connect/http/src/response/response.dart';



class DataSyncRepo {
  final ApiClient apiClient;
  final SharedPreferences? sharedPreferences;

  DataSyncRepo({required this.apiClient, required this.sharedPreferences});

  String _cacheKeyFor(String uri) {
    try {
      final addressJson = sharedPreferences?.getString(AppConstants.userAddress);
      if (addressJson != null) {
        final address = AddressModel.fromJson(jsonDecode(addressJson));
        final zoneId = address.zoneId?.trim();
        if (zoneId != null && zoneId.isNotEmpty) {
          return '$uri::zone:$zoneId';
        }
      }
    } catch (_) {}
    return uri;
  }

  Future<ApiResponseModel<T>> fetchData<T>(String uri, DataSourceEnum source, {dynamic body, ApiMethodType method = ApiMethodType.get} ) async {
    final cacheKey = _cacheKeyFor(uri);
    try {
      if (source == DataSourceEnum.local) {
        if (_isACachesDisable()) {
          return ApiResponseModel.withError("No local data found for $uri");
        }
        return await _fetchFromLocalCache<T>(cacheKey, uri);
      }
      return await _fetchFromClient<T>(cacheKey, uri, method: method, body: body);
    } catch (e) {
      debugPrint('DataSyncRepo: ===> $source $e ($uri)');

      return ApiResponseModel.withError(e);
    }
  }

  Future<ApiResponseModel<T>> _fetchFromClient<T>(String cacheKey, String uri, {dynamic body,ApiMethodType method = ApiMethodType.get}) async {
    final response = await _fetchResponseFromClient(uri, body: body, method: method);
    if (response.statusCode == 200) {
      try {
        final cacheData = CacheResponseCompanion(
          endPoint: Value(cacheKey),
          header: Value(jsonEncode(response.headers)),
          response: Value(jsonEncode(response.body)),
        );

        if (kIsWeb && _isWebCachesActive()) {
          _cacheResponseWeb(cacheKey, cacheData);
        }

        if (!kIsWeb && _isAppCachesActive()) {
          await DbHelper.insertOrUpdate(id: cacheKey, data: cacheData);
        }
      } catch (e) {
        debugPrint('DataSyncRepo: cache write skipped for $uri ($e)');
      }
    }

    return ApiResponseModel.withSuccess(response as T);
  }

  Future<Response> _fetchResponseFromClient (String uri,{dynamic body, ApiMethodType method = ApiMethodType.get}){
    if(method == ApiMethodType.get){
      return apiClient.getData(uri);
    }else{
      return apiClient.postData(uri, body);
    }
  }

  bool _isWebCachesActive()=> (AppConstants.cachesType == LocalCachesTypeEnum.all || AppConstants.cachesType == LocalCachesTypeEnum.web);
  bool _isAppCachesActive()=> (AppConstants.cachesType == LocalCachesTypeEnum.all || AppConstants.cachesType == LocalCachesTypeEnum.app);
  bool _isACachesDisable() => AppConstants.cachesType == LocalCachesTypeEnum.none;

  void _cacheResponseWeb(String uri, CacheResponseCompanion cacheData) {
    final cacheJson = CacheResponseData(
      id: 0,
      endPoint: cacheData.endPoint.value,
      header: cacheData.header.value,
      response: cacheData.response.value,
    ).toJson();
    sharedPreferences?.setString(uri, jsonEncode(cacheJson));
  }

  Future<ApiResponseModel<T>> _fetchFromLocalCache<T>(String cacheKey, String uri) async {
    try {
      CacheResponseData? cacheData;

      if (kIsWeb) {
        final cachedJson = sharedPreferences?.getString(cacheKey);
        if (cachedJson != null) {
          cacheData = CacheResponseData.fromJson(jsonDecode(cachedJson));
        }
      } else {
        cacheData = await database.getCacheResponseById(cacheKey);
      }

      if (cacheData != null && jsonDecode(cacheData.response) != null) {
        return ApiResponseModel.withSuccess(cacheData as T);
      }
    } catch (e) {
      debugPrint('DataSyncRepo: local cache read skipped for $uri ($e)');
    }

    return ApiResponseModel.withError("No local data found for $uri");
  }
}
