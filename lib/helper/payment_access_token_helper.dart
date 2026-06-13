import 'package:demandium/util/core_export.dart';
import 'package:get/get.dart';

class PaymentAccessTokenHelper {
  static String? _cachedSubject;
  static String? _cachedToken;
  static DateTime? _cachedAt;

  static Future<String> forSubject(String subjectId) async {
    if (_cachedSubject == subjectId &&
        _cachedToken != null &&
        _cachedAt != null &&
        DateTime.now().difference(_cachedAt!) < const Duration(minutes: 50)) {
      return _cachedToken!;
    }

    final Map<String, String> body = {};
    if (!Get.find<AuthController>().isLoggedIn()) {
      body['guest_id'] = subjectId;
    }

    final response = await Get.find<ApiClient>().postData(
      '/api/v1/customer/payment/access-token',
      body,
    );

    final dynamic content = response.body is Map ? response.body['content'] : null;
    final token = content is Map ? content['access_token']?.toString() : null;

    if (response.statusCode == 200 && token != null && token.isNotEmpty) {
      _cachedSubject = subjectId;
      _cachedToken = token;
      _cachedAt = DateTime.now();
      return token;
    }

    throw Exception(response.statusText ?? 'Failed to get payment access token');
  }

  static void clearCache() {
    _cachedSubject = null;
    _cachedToken = null;
    _cachedAt = null;
  }
}
