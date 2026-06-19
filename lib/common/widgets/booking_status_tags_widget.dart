import 'package:demandium/common/model/booking_status_ui_model.dart';
import 'package:demandium/helper/booking_status_variant_colors.dart';
import 'package:demandium/util/core_export.dart';
import 'package:get/get.dart';

Color bookingStatusBadgeBackgroundColor(
  BuildContext context, {
  required String? rawStatus,
  required String? badgeVariant,
}) {
  final variant = BookingStatusVariantColors.resolveBadgeVariant(
    badgeVariant: badgeVariant,
    rawStatus: rawStatus,
  );
  return BookingStatusVariantColors.softBadgeBackground(variant);
}

Color bookingStatusBadgeTextColor(
  BuildContext context, {
  required String? rawStatus,
  required String? badgeVariant,
}) {
  final variant = BookingStatusVariantColors.resolveBadgeVariant(
    badgeVariant: badgeVariant,
    rawStatus: rawStatus,
  );
  return BookingStatusVariantColors.softBadgeForeground(variant);
}

Color bookingStatusTagBackgroundColor(BuildContext context, String variant) {
  return BookingStatusVariantColors.solidTagBackground(variant);
}

Color bookingStatusTagTextColor(BuildContext context, String variant) {
  return BookingStatusVariantColors.solidTagForeground(variant);
}

class BookingStatusBadge extends StatelessWidget {
  final String? rawStatus;
  final String? displayKey;
  final String? badgeVariant;

  const BookingStatusBadge({
    super.key,
    required this.rawStatus,
    this.displayKey,
    this.badgeVariant,
  });

  String get _labelKey {
    if (displayKey != null && displayKey!.isNotEmpty) {
      return displayKey!;
    }
    return rawStatus ?? '';
  }

  @override
  Widget build(BuildContext context) {
    if (_labelKey.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeSmall,
        vertical: Dimensions.paddingSizeExtraSmall,
      ),
      decoration: BoxDecoration(
        color: bookingStatusBadgeBackgroundColor(
          context,
          rawStatus: rawStatus,
          badgeVariant: badgeVariant,
        ),
        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
      ),
      child: Text(
        _labelKey.tr,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: robotoMedium.copyWith(
          fontSize: Dimensions.fontSizeSmall,
          color: bookingStatusBadgeTextColor(
            context,
            rawStatus: rawStatus,
            badgeVariant: badgeVariant,
          ),
        ),
      ),
    );
  }
}

class BookingStatusTagChip extends StatelessWidget {
  final BookingStatusTag tag;

  const BookingStatusTagChip({super.key, required this.tag});

  @override
  Widget build(BuildContext context) {
    final hasBorder = BookingStatusVariantColors.solidTagHasBorder(tag.variant);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeSmall,
        vertical: Dimensions.paddingSizeExtraSmall,
      ),
      decoration: BoxDecoration(
        color: bookingStatusTagBackgroundColor(context, tag.variant),
        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
        border: hasBorder
            ? Border.all(color: BookingStatusVariantColors.borderLight)
            : null,
      ),
      child: Text(
        tag.label.tr,
        style: robotoMedium.copyWith(
          fontSize: Dimensions.fontSizeExtraSmall,
          color: bookingStatusTagTextColor(context, tag.variant),
        ),
      ),
    );
  }
}

class BookingStatusTagsScrollRow extends StatelessWidget {
  final List<BookingStatusTag> tags;
  final double spacing;

  const BookingStatusTagsScrollRow({
    super.key,
    required this.tags,
    this.spacing = Dimensions.paddingSizeExtraSmall,
  });

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < tags.length; i++) ...[
            if (i > 0) SizedBox(width: spacing),
            BookingStatusTagChip(tag: tags[i]),
          ],
        ],
      ),
    );
  }
}

class BookingStatusTagsWrap extends StatelessWidget {
  final List<BookingStatusTag> tags;
  final double spacing;
  final double runSpacing;

  const BookingStatusTagsWrap({
    super.key,
    required this.tags,
    this.spacing = Dimensions.paddingSizeExtraSmall,
    this.runSpacing = Dimensions.paddingSizeExtraSmall,
  });

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: tags.map((tag) => BookingStatusTagChip(tag: tag)).toList(),
    );
  }
}

class BookingStatusAndTagsRow extends StatelessWidget {
  final String? rawStatus;
  final BookingStatusUiFields? ui;
  final MainAxisAlignment alignment;
  final bool compact;

  const BookingStatusAndTagsRow({
    super.key,
    required this.rawStatus,
    this.ui,
    this.alignment = MainAxisAlignment.start,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final tags = ui?.tags ?? const <BookingStatusTag>[];

    if (compact) {
      return Wrap(
        spacing: Dimensions.paddingSizeExtraSmall,
        runSpacing: Dimensions.paddingSizeExtraSmall,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: alignment == MainAxisAlignment.end
            ? WrapAlignment.end
            : WrapAlignment.start,
        children: [
          BookingStatusBadge(
            rawStatus: rawStatus,
            displayKey: ui?.displayKey,
            badgeVariant: ui?.badgeVariant,
          ),
          ...tags.map((tag) => BookingStatusTagChip(tag: tag)),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        BookingStatusBadge(
          rawStatus: rawStatus,
          displayKey: ui?.displayKey,
          badgeVariant: ui?.badgeVariant,
        ),
        if (tags.isNotEmpty) ...[
          const SizedBox(height: Dimensions.paddingSizeExtraSmall),
          SizedBox(
            width: double.infinity,
            child: BookingStatusTagsWrap(tags: tags),
          ),
        ],
      ],
    );
  }
}
