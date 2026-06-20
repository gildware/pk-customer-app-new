class CartServiceInfoModel {
  String? id;
  String? customerId;
  String? zoneId;
  String? serviceAddressId;
  String? serviceSchedule;
  bool isAsapBooking = false;

  CartServiceInfoModel({
    this.id,
    this.customerId,
    this.zoneId,
    this.serviceAddressId,
    this.serviceSchedule,
    this.isAsapBooking = false,
  });

  static String? _asString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    if (text.isEmpty || text == 'null') return null;
    return text;
  }

  CartServiceInfoModel.fromJson(Map<String, dynamic> json) {
    id = _asString(json['id']);
    customerId = _asString(json['customer_id']);
    zoneId = _asString(json['zone_id']);
    serviceAddressId = _asString(json['service_address_id']);
    serviceSchedule = _asString(json['service_schedule']);
    isAsapBooking = false;
  }

  Map<String, dynamic> toJson() {
    return {
      'zone_id': zoneId,
      'service_address_id': serviceAddressId,
      'service_schedule': serviceSchedule,
    };
  }
}
