import 'package:demandium/common/models/api_response_model.dart';
import 'package:demandium/common/repo/data_sync_repo.dart';
import 'package:demandium/helper/db_helper.dart';
import 'package:demandium/helper/validation_helper.dart';
import 'package:demandium/util/core_export.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class CartRepo extends DataSyncRepo{
  CartRepo({required super.apiClient, required SharedPreferences super.sharedPreferences});

  Future<Response> addToCartListToServer(CartModelBody cartModel) async {
    return await apiClient.postData(AppConstants.addToCart, cartModel.toJson());
  }

  String cartListUri() =>
      '${AppConstants.getCartList}&&guest_id=${Get.find<SplashController>().getGuestId()}';

  Future<ApiResponseModel<T>> getCartListFromServer<T>({required DataSourceEnum source}) async {
    return await fetchData<T>(cartListUri(), source);
  }

  Future<void> clearCartListCache() async {
    final uri = cartListUri();
    if (kIsWeb) {
      await sharedPreferences?.remove(uri);
    } else {
      await DbHelper.deleteByEndPoint(uri);
    }
  }

  Future<Response> removeCartFromServer(String cartID) async {
    return await apiClient.postData("${AppConstants.removeCartItem}$cartID?guest_id=${Get.find<SplashController>().getGuestId()}", {
      "_method" : "delete"
    });
  }

  Future<Response> removeAllCartFromServer() async {
    return await apiClient.postData("${AppConstants.removeAllCartItem}?guest_id=${Get.find<SplashController>().getGuestId()}",
        {
          "_method" : "delete"
        }
    );
  }

  Future<Response> updateCartQuantity(String cartID, int quantity)async{
    return await apiClient.postData("${AppConstants.updateCartQuantity}$cartID?guest_id=${Get.find<SplashController>().getGuestId()}",
        {
          'quantity': quantity,
          "_method": "put"
        }
    );
  }

  Future<Response> updateCartItemSchedule(String cartId, String serviceSchedule) async {
    final body = <String, dynamic>{
      'service_schedule': formatScheduleForApi(serviceSchedule),
    };
    final guestId = Get.find<SplashController>().getGuestId();
    if (!Get.find<AuthController>().isLoggedIn() && ValidationHelper.isValidUuid(guestId)) {
      body['guest_id'] = guestId;
    }
    return await apiClient.putData(
      '${AppConstants.updateCartSchedule}$cartId?guest_id=$guestId',
      body,
    );
  }

  Future<Response> updateProvider(String providerId)async {
    return await apiClient.postData(AppConstants.updateCartProvider,
      { 'provider_id': providerId,
        "_method":"put",
        "guest_id": Get.find<SplashController>().getGuestId()
      });
  }

  Future<Response> getProviderBasedOnSubcategory(
    String subcategoryId, {
    String? zoneId,
    String? originLatitude,
    String? originLongitude,
  }) async {
    final headers = zoneId != null && zoneId.isNotEmpty
        ? {AppConstants.zoneId: zoneId}
        : null;
    final query = StringBuffer(
      "${AppConstants.getProviderBasedOnSubcategory}?sub_category_id=$subcategoryId",
    );
    if (originLatitude != null &&
        originLongitude != null &&
        originLatitude.isNotEmpty &&
        originLongitude.isNotEmpty) {
      query.write('&origin_latitude=$originLatitude&origin_longitude=$originLongitude');
    }
    return await apiClient.getData(
      query.toString(),
      headers: headers,
    );
  }

  Future<Response> updateCartOtherInfo({
    required String zoneId,
    required String serviceAddressId,
    required String serviceSchedule,
  }) async {
    final addressId = int.tryParse(serviceAddressId.trim()) ?? serviceAddressId;
    final Map<String, dynamic> body = {
      'zone_id': zoneId,
      'service_address_id': addressId,
      'service_schedule': _formatScheduleForApi(serviceSchedule),
    };

    final isLoggedIn = Get.find<AuthController>().isLoggedIn();
    final guestId = Get.find<SplashController>().getGuestId();
    if (!isLoggedIn && ValidationHelper.isValidUuid(guestId)) {
      body['guest_id'] = guestId;
    }

    return await apiClient.postData(AppConstants.otherInfo, body);
  }

  String formatScheduleForApi(String schedule) {
    try {
      final parsed = DateConverter.dateTimeStringToDate(schedule);
      return DateFormat('yyyy-MM-dd HH:mm:ss').format(parsed);
    } catch (_) {
      return schedule;
    }
  }

  String _formatScheduleForApi(String schedule) => formatScheduleForApi(schedule);

  Future<Response> addRebookToServer(String bookingId) async {
    return await apiClient.postData(AppConstants.rebookApi, {'booking_id' : bookingId, 'guest_id' : Get.find<SplashController>().getGuestId()} );
  }


}