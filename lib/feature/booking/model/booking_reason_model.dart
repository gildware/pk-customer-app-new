class BookingReasonModel {
  final int? id;
  final String? name;
  final String? description;

  BookingReasonModel({this.id, this.name, this.description});

  factory BookingReasonModel.fromJson(Map<String, dynamic> json) {
    return BookingReasonModel(
      id: int.tryParse(json['id']?.toString() ?? ''),
      name: json['name']?.toString(),
      description: json['description']?.toString(),
    );
  }
}
