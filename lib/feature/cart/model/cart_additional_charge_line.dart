class CartAdditionalChargeLine {
  final String id;
  final String name;
  final double amount;

  CartAdditionalChargeLine({
    required this.id,
    required this.name,
    required this.amount,
  });

  factory CartAdditionalChargeLine.fromJson(Map<String, dynamic> json) {
    return CartAdditionalChargeLine(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '') ?? 0,
    );
  }
}
