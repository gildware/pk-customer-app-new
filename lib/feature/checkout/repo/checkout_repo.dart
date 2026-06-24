import 'dart:convert';
import 'package:demandium/util/core_export.dart';
import 'package:get/get.dart';


class CheckoutRepo extends GetxService {
  final ApiClient apiClient;
  CheckoutRepo({required this.apiClient});

  Future<Response> getPostDetails(String postId, String bidId) async {
    return await apiClient.getData('${AppConstants.getPostDetails}/$postId?post_bid_id=$bidId');
  }

  Future<Response> getOfflinePaymentMethod() async {
    Response response = await apiClient.getData(AppConstants.offlinePaymentUri);
    return response;
  }

  Future<Response> getDigitalPaymentResponse({String? transactionId}) async {
    String url = '${AppConstants.digitalPaymentResponse}?transaction_id=$transactionId';

    Future<String?> resolveAccessToken() async {
      final authController = Get.find<AuthController>();
      final splashController = Get.find<SplashController>();
      final subjectId = authController.isLoggedIn()
          ? Get.find<UserController>().userInfoModel?.id
          : splashController.getGuestId();

      if (subjectId == null || subjectId.isEmpty) {
        return null;
      }

      return PaymentAccessTokenHelper.forSubject(subjectId);
    }

    try {
      final accessToken = await resolveAccessToken();
      if (accessToken != null && accessToken.isNotEmpty) {
        url += '&access_token=${Uri.encodeComponent(accessToken)}';
      }
    } catch (e, stack) {
      ErrorLogger.record(e, stack, reason: 'CheckoutRepo.getDigitalPaymentResponse.token');
      if (!Get.find<AuthController>().isLoggedIn()) {
        await BookingAuthHelper.ensureGuestSessionIfNeeded();
        try {
          final accessToken = await resolveAccessToken();
          if (accessToken != null && accessToken.isNotEmpty) {
            url += '&access_token=${Uri.encodeComponent(accessToken)}';
          }
        } catch (_) {}
      }
    }

    return await apiClient.getData(url);
  }

  Future<Response?> checkExistingUser({required String phone}) async {
    return await apiClient.postData(
      AppConstants.checkExistingUser,
      {
        "phone": phone,
      },
    );
  }

  Future<Response?>submitOfflinePaymentData({required String bookingId, required String offlinePaymentId, required offlinePaymentInfo, required int isPartialPayment}) async {
    return await apiClient.postData(
      AppConstants.offlinePaymentDataStore,
      {
        "booking_id": bookingId,
        "offline_payment_id" : offlinePaymentId,
        "customer_information" : offlinePaymentInfo,
        "is_partial" : isPartialPayment,
      },
    );
  }

  Future<Response?> switchPaymentMethod({required String bookingId,  required String paymentMethod,  int isPartial = 0,  String? offlinePaymentId, String? offlinePaymentInfo}) async {
    return await apiClient.postData(
      AppConstants.switchPaymentMethod,
      {
        "booking_id": bookingId,
        "payment_method" : paymentMethod,
        "offline_payment_id" : offlinePaymentId,
        "customer_information" : offlinePaymentInfo,
        "is_partial" : isPartial
      },
    );
  }

  Future<Response> placeBookingRequest({
    required String paymentMethod, String? serviceAddressID, required AddressModel serviceAddress,String? schedule,
    required String zoneId, required int isPartial, required String serviceLocation,
    required String serviceType, String? bookingType, String? dates, SignUpBody? newUserInfo, String? paymentAmountType,
  }) async {
    String address = jsonEncode(serviceAddress);
    final body = <String, dynamic>{
      "payment_method" : paymentMethod,
      "zone_id" : zoneId,
      "service_schedule" : schedule,
      "service_address_id" : serviceAddressID,
      "guest_id" : Get.find<SplashController>().getGuestId(),
      "service_address" : address,
      "is_partial" : isPartial,
      "service_type": serviceType,
      "booking_type": bookingType,
      "dates": dates,
      "new_user_info": newUserInfo !=null ? jsonEncode(newUserInfo) : null,
      "service_location": serviceLocation
    };
    if (paymentAmountType != null && paymentAmountType.isNotEmpty) {
      body["payment_amount_type"] = paymentAmountType;
    }
    return await apiClient.postData(AppConstants.placeRequest, body);
  }
}
