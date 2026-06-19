class BookingStatusTag {
  final String key;
  final String label;
  final String variant;

  const BookingStatusTag({
    required this.key,
    required this.label,
    required this.variant,
  });

  factory BookingStatusTag.fromJson(Map<String, dynamic> json) {
    return BookingStatusTag(
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      variant: json['variant']?.toString() ?? 'secondary',
    );
  }
}

class BookingStatusUiFields {
  final String? displayKey;
  final String? badgeVariant;
  final List<BookingStatusTag> tags;

  const BookingStatusUiFields({
    this.displayKey,
    this.badgeVariant,
    this.tags = const [],
  });

  factory BookingStatusUiFields.fromJson(Map<String, dynamic> json) {
    final rawTags = json['booking_status_tags'];
    final parsedTags = <BookingStatusTag>[];
    if (rawTags is List) {
      for (final item in rawTags) {
        if (item is Map<String, dynamic>) {
          parsedTags.add(BookingStatusTag.fromJson(item));
        } else if (item is Map) {
          parsedTags.add(BookingStatusTag.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    return BookingStatusUiFields(
      displayKey: json['booking_status_display_key']?.toString(),
      badgeVariant: json['booking_status_badge_variant']?.toString(),
      tags: parsedTags,
    );
  }
}
