import 'package:get/get.dart';
import 'package:demandium/util/core_export.dart';

class AiChatRepo {
  final ApiClient apiClient;
  AiChatRepo({required this.apiClient});

  Future<Response> getConversation() async {
    return apiClient.getData(AppConstants.mobileAiChatConversation);
  }

  Future<Response> sendMessage(String message) async {
    return apiClient.postData(
      AppConstants.mobileAiChatSend,
      {'message': message},
      timeoutSeconds: 120,
    );
  }

  Future<Response> clearConversation() async {
    return apiClient.postData(AppConstants.mobileAiChatClear, {});
  }

  Future<Response> bookingAction(Map<String, dynamic> body) async {
    return apiClient.postData(
      AppConstants.mobileAiChatBookingAction,
      body,
      timeoutSeconds: 120,
    );
  }

  Future<Response> quickIntent(String intent, {String? query}) async {
    final body = <String, dynamic>{'intent': intent};
    if (query != null && query.isNotEmpty) body['query'] = query;
    return apiClient.postData(
      AppConstants.mobileAiChatQuickIntent,
      body,
      timeoutSeconds: 120,
    );
  }
}
