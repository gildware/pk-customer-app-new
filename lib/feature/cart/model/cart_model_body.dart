class CartModelBody {
  String? serviceId;
  String? categoryId;
  String? variantKey;
  String? quantity;
  String? subCategoryId;
  String? providerId;
  String? guestId;
  String? zoneId;
  String? serviceAddressId;
  String? serviceSchedule;

  CartModelBody({
    this.serviceId,
    this.categoryId,
    this.variantKey,
    this.quantity,
    this.subCategoryId,
    this.providerId,
    this.guestId,
    this.zoneId,
    this.serviceAddressId,
    this.serviceSchedule,
  });

  CartModelBody.fromJson(Map<String, dynamic> json) {
    serviceId = json['service_id'];
    categoryId = json['category_id'];
    variantKey = json['variant_key'];
    quantity = json['quantity'];
    subCategoryId = json['sub_category_id'];
    providerId = json['provider_id'];
    guestId = json['guest_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['service_id'] = serviceId;
    data['category_id'] = categoryId;
    data['variant_key'] = variantKey;
    data['quantity'] = quantity;
    data['sub_category_id'] = subCategoryId;
    if (providerId != null && providerId!.isNotEmpty) {
      data['provider_id'] = providerId;
    }
    if (guestId != null && guestId!.isNotEmpty) {
      data['guest_id'] = guestId;
    }
    if (zoneId != null && zoneId!.isNotEmpty) {
      data['zone_id'] = zoneId;
    }
    if (serviceAddressId != null && serviceAddressId!.isNotEmpty) {
      final parsedId = int.tryParse(serviceAddressId!) ?? serviceAddressId;
      data['service_address_id'] = parsedId;
    }
    if (serviceSchedule != null && serviceSchedule!.isNotEmpty) {
      data['service_schedule'] = serviceSchedule;
    }
    return data;
  }
}
