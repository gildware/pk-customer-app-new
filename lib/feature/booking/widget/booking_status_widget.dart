import 'package:demandium/helper/booking_status_variant_colors.dart';
import 'package:demandium/util/core_export.dart';
import 'package:get/get.dart';

class BookingStatusButtonWidget extends StatelessWidget {
  final String? bookingStatus;
  final String? displayKey;
  final String? badgeVariant;

  const BookingStatusButtonWidget({
    super.key,
    this.bookingStatus,
    this.displayKey,
    this.badgeVariant,
  });

  String get _labelKey {
    if (displayKey != null && displayKey!.isNotEmpty) {
      return displayKey!;
    }
    return bookingStatus ?? '';
  }

  @override
  Widget build(BuildContext context) {
    if (_labelKey.isEmpty) {
      return const SizedBox.shrink();
    }

    final variant = BookingStatusVariantColors.resolveBadgeVariant(
      badgeVariant: badgeVariant,
      rawStatus: bookingStatus,
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: Dimensions.paddingSizeTine,
        horizontal: Dimensions.paddingSizeEight,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        color: BookingStatusVariantColors.softBadgeBackground(variant),
      ),
      child: Text(
        _labelKey.tr,
        style: robotoMedium.copyWith(
          fontWeight: FontWeight.w500,
          fontSize: Dimensions.fontSizeSmall,
          color: BookingStatusVariantColors.softBadgeForeground(variant),
        ),
      ),
    );
  }
}
