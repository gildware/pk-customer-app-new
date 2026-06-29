import 'package:demandium/util/core_export.dart';
import 'package:get/get.dart';


class BookingDetailsRepo{
  final SharedPreferences sharedPreferences;
  final ApiClient apiClient;
  BookingDetailsRepo({required this.sharedPreferences,required this.apiClient});


  Future<Response> getBookingDetails({required String bookingID})async{
    return await apiClient.getData("${AppConstants.bookingDetails}/$bookingID");
  }

  Future<Response> getSubBookingDetails({required String bookingID})async{
    return await apiClient.getData("${AppConstants.subBookingDetails}/$bookingID");
  }

  Future<Response> trackBookingDetails({required String bookingID, required String phoneNUmber})async{
    final trackToken = await BookingTrackHelper.requestAccessToken(
      readableId: bookingID,
      phone: phoneNUmber,
    );
    if (trackToken == null) {
      return const Response(statusCode: 404, statusText: 'Booking not found');
    }
    return await apiClient.postData("${AppConstants.trackBooking}/$bookingID",{
      "phone": phoneNUmber,
      "track_token": trackToken,
    });
  }


  Future<Response> bookingCancel({
    required String bookingID,
    required int customerCancellationReasonId,
    String? statusChangeRemarks,
    String? refundMethod,
  }) async {
    return await apiClient.postData('${AppConstants.bookingCancel}/$bookingID', {
      "booking_status": "canceled",
      "booking_customer_cancellation_reason_id": customerCancellationReasonId,
      if (statusChangeRemarks != null && statusChangeRemarks.isNotEmpty)
        "status_change_remarks": statusChangeRemarks,
      if (refundMethod != null && refundMethod.isNotEmpty) "refund_method": refundMethod,
      "_method": "put",
    });
  }

  Future<Response> subBookingCancel({
    required String bookingID,
    required int customerCancellationReasonId,
    String? statusChangeRemarks,
  }) async {
    return await apiClient.postData('${AppConstants.subBookingCancel}/$bookingID', {
      "booking_customer_cancellation_reason_id": customerCancellationReasonId,
      if (statusChangeRemarks != null && statusChangeRemarks.isNotEmpty)
        "status_change_remarks": statusChangeRemarks,
    });
  }

  Future<Response> getCustomerCancellationReasons() async {
    return await apiClient.getData(AppConstants.customerCancellationReasonsUrl);
  }

  Future<void> setLastIncompleteOfflineBookingId(String bookingId) async {
    await sharedPreferences.setString(AppConstants.lastIncompleteOfflineBookingId, bookingId);
  }

  String getLastIncompleteOfflineBookingId() {
    return sharedPreferences.getString(AppConstants.lastIncompleteOfflineBookingId) ?? "";
  }

}