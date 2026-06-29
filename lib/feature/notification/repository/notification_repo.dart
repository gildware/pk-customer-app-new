import 'package:demandium/util/core_export.dart';
import 'package:get/get_connect/http/src/response/response.dart';

class NotificationRepo {
  final ApiClient apiClient;
  final SharedPreferences sharedPreferences;
  NotificationRepo({required this.apiClient, required this.sharedPreferences});

  Future<Response> getNotificationList(int offset) async {
    return await apiClient.getData('${AppConstants.notificationUri}?limit=10&offset=$offset');
  }

  Future<Response> getUnreadCount() async {
    return await apiClient.getData(AppConstants.notificationUnreadCountUri);
  }

  Future<Response> markAsRead(String notificationId) async {
    return await apiClient.putData(
      '${AppConstants.notificationUri}/$notificationId/read',
      {},
    );
  }

  Future<Response> markAllAsRead() async {
    return await apiClient.putData(AppConstants.notificationMarkAllReadUri, {});
  }
}
