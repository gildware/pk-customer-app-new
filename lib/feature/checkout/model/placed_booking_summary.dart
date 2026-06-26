class PlacedBookingSummary {
  final String readableId;
  final String serviceName;
  final String? bookingId;

  const PlacedBookingSummary({
    required this.readableId,
    required this.serviceName,
    this.bookingId,
  });
}
