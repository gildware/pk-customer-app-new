import 'dart:convert';
import 'package:demandium/api/local/cache_response.dart';
import 'package:demandium/common/models/api_response_model.dart';
import 'package:demandium/helper/silent_api_context.dart';
import 'package:demandium/util/core_export.dart';
import 'package:get/get.dart';


class DataSyncHelper {
  /// Generic method to fetch data from local and remote sources
  static Future<void> fetchAndSyncData({
    required Future<ApiResponseModel<CacheResponseData>> Function() fetchFromLocal,
    required Future<ApiResponseModel<Response>> Function() fetchFromClient,
    required Function(dynamic, DataSourceEnum source) onResponse,
    bool suppressErrorWhenLocalSucceeded = false,
  }) async {

    // Step 1: Try to load from the local source
    final localResponse = await fetchFromLocal();
    final loadedFromLocal = localResponse.isSuccess;

    if (loadedFromLocal) {
      try {
        onResponse(jsonDecode(localResponse.response!.response), DataSourceEnum.local);
      } catch (e, stack) {
        ErrorLogger.record(e, stack, reason: 'DataSyncHelper local onResponse');
      }
    }

    // Step 2: Try to load from the client (remote) source and update if successful
    final clientResponse = await fetchFromClient();
    if (clientResponse.isSuccess && clientResponse.response?.statusCode == 200) {
      try {
        onResponse(clientResponse.response?.body, DataSourceEnum.client);
      } catch (e, stack) {
        ErrorLogger.record(e, stack, reason: 'DataSyncHelper client onResponse');
      }
    } else if ((!suppressErrorWhenLocalSucceeded || !loadedFromLocal) &&
        !SilentApiContext.isActive) {
      if(clientResponse.response?.statusCode != 429){
        ApiChecker.checkApi(Response(
          body: clientResponse.response?.body,
          statusCode: clientResponse.response?.statusCode,
          statusText: clientResponse.response?.statusText,
        ));
      }
    }

  }
}


