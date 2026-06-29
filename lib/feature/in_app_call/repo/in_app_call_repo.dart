import 'package:demandium/util/core_export.dart';
import 'package:get/get_connect/http/src/response/response.dart';

class InAppCallRepo {
  final ApiClient apiClient;

  InAppCallRepo({required this.apiClient});

  Future<Response> getConfig() async {
    return apiClient.getData(AppConstants.inAppCallConfig);
  }

  Future<Response> getPendingIncoming() async {
    return apiClient.getData(AppConstants.inAppCallPending);
  }

  Future<Response> getHistory(int offset, {int limit = 20, String? channelId}) async {
    var url = '${AppConstants.inAppCallHistory}?offset=$offset&limit=$limit';
    if (channelId != null && channelId.isNotEmpty) {
      url = '$url&channel_id=$channelId';
    }
    return apiClient.getData(url);
  }

  Future<Response> initiate(String channelId) async {
    return apiClient.postData(AppConstants.inAppCallInitiate, {
      'channel_id': channelId,
    });
  }

  Future<Response> show(String callId) async {
    return apiClient.getData('${AppConstants.inAppCallBase}/$callId');
  }

  Future<Response> accept(String callId) async {
    return apiClient.postData('${AppConstants.inAppCallBase}/$callId/accept', {});
  }

  Future<Response> decline(String callId) async {
    return apiClient.postData('${AppConstants.inAppCallBase}/$callId/decline', {});
  }

  Future<Response> cancel(String callId) async {
    return apiClient.postData('${AppConstants.inAppCallBase}/$callId/cancel', {});
  }

  Future<Response> end(String callId) async {
    return apiClient.postData('${AppConstants.inAppCallBase}/$callId/end', {});
  }

  Future<Response> missed(String callId) async {
    return apiClient.postData('${AppConstants.inAppCallBase}/$callId/missed', {});
  }

  Future<Response> postSignal(String callId, String signalType, Map<String, dynamic> payload) async {
    return apiClient.postData('${AppConstants.inAppCallBase}/$callId/signals', {
      'signal_type': signalType,
      'payload': payload,
    });
  }

  Future<Response> listSignals(String callId, {String? after}) async {
    var url = '${AppConstants.inAppCallBase}/$callId/signals';
    if (after != null && after.isNotEmpty) {
      url = '$url?after=$after';
    }
    return apiClient.getData(url);
  }
}
