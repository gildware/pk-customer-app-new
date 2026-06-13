import 'package:demandium/util/core_export.dart';
import 'package:get/get.dart';

class BookingInvoiceHelper {
  static Future<String> customerInvoiceUrl({
    required String bookingId,
    required String lang,
    String variant = 'regular',
  }) async {
    final response = await Get.find<ApiClient>().getData(
      '/api/v1/customer/booking/$bookingId/invoice-url?lang=$lang&variant=$variant',
    );

    final dynamic content = response.body is Map ? response.body['content'] : null;
    final url = content is Map ? content['url']?.toString() : null;

    if (response.statusCode == 200 && url != null && url.isNotEmpty) {
      return url;
    }

    throw Exception(response.statusText ?? 'Failed to get invoice URL');
  }
}
