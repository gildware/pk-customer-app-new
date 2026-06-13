import 'package:get/get.dart';
import 'package:demandium/util/core_export.dart';

class BookingTrackHelper {
  static Future<String?> requestAccessToken({
    required String readableId,
    required String phone,
  }) async {
    final response = await Get.find<ApiClient>().postData(
      '${AppConstants.trackBooking}/$readableId/access-token',
      {'phone': phone},
    );

    final dynamic content = response.body is Map ? response.body['content'] : null;
    final token = content is Map ? content['track_token']?.toString() : null;

    if (response.statusCode == 200 && token != null && token.isNotEmpty) {
      return token;
    }

    return null;
  }
}
