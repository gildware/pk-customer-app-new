class PaymentResponseModel {
  String? responseCode;
  String? message;
  PaymentResponseModelContent? content;

  PaymentResponseModel({this.responseCode, this.message, this.content});

  PaymentResponseModel.fromJson(Map<String, dynamic> json) {
    responseCode = json['response_code'];
    message = json['message'];
    content =
    json['content'] != null ?  PaymentResponseModelContent.fromJson(json['content']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['response_code'] = responseCode;
    data['message'] = message;
    if (content != null) {
      data['content'] = content!.toJson();
    }
    return data;
  }
}

class PaymentResponseModelContent {
  String? bookingId;
  List<String> bookingIds = [];
  List<String> readableIds = [];
  String? bookingRepeatId;
  String? newUserPhone;
  String? loginToken;

  PaymentResponseModelContent({
    this.bookingId,
    List<String>? bookingIds,
    List<String>? readableIds,
    this.bookingRepeatId,
    this.newUserPhone,
    this.loginToken,
  })  : bookingIds = bookingIds ?? const [],
        readableIds = readableIds ?? const [];

  PaymentResponseModelContent.fromJson(Map<String, dynamic> json) {
    bookingId = json['booking_id']?.toString();
    bookingIds = _parseStringList(json['booking_ids']);
    if (bookingIds.isEmpty && bookingId != null && bookingId!.isNotEmpty) {
      bookingIds = [bookingId!];
    }
    readableIds = _parseStringList(json['readable_ids']);
    bookingRepeatId = json['booking_repeat_id'];
    newUserPhone = json['new_user_phone'];
    loginToken = json['login_token'];
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is! List) return [];
    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['booking_id'] = bookingId;
    data['booking_ids'] = bookingIds;
    data['readable_ids'] = readableIds;
    data['booking_repeat_id'] = bookingRepeatId;
    data['new_user_phone'] = newUserPhone;
    data['login_token'] = loginToken;
    return data;
  }
}
