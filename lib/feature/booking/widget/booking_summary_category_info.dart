import 'package:demandium/util/core_export.dart';
import 'package:get/get.dart';

class BookingSummaryCategoryInfo extends StatelessWidget {
  final BookingDetailsContent bookingDetails;

  const BookingSummaryCategoryInfo({super.key, required this.bookingDetails});

  @override
  Widget build(BuildContext context) {
    final categoryName = bookingDetails.category?.name;
    final subCategoryName = bookingDetails.subCategory?.name;

    if ((categoryName == null || categoryName.isEmpty) &&
        (subCategoryName == null || subCategoryName.isEmpty)) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeExtraSmall),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (categoryName != null && categoryName.isNotEmpty)
            _CategoryRow(label: 'category'.tr, value: categoryName),
          if (subCategoryName != null && subCategoryName.isNotEmpty)
            _CategoryRow(label: 'sub_category'.tr, value: subCategoryName),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final String label;
  final String value;

  const _CategoryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeExtraSmall),
      child: Row(
        children: [
          Text(
            '$label : ',
            style: robotoRegular.copyWith(
              fontSize: Dimensions.fontSizeSmall,
              color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: robotoRegular.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.8),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
