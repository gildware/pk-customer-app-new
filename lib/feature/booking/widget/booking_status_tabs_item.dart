import 'package:demandium/feature/booking/model/booking_count.dart';
import 'package:demandium/feature/booking/widget/booking_filter_tab_chip.dart';
import 'package:demandium/util/core_export.dart';

class BookingStatusTabItem extends StatelessWidget {
  const BookingStatusTabItem({
    super.key,
    required this.title,
    required this.isSelected,
    this.bookingCount,
  });

  final String title;
  final bool isSelected;
  final BookingCount? bookingCount;

  @override
  Widget build(BuildContext context) {
    return BookingFilterTabChip(
      tab: title,
      isSelected: isSelected,
      bookingCount: bookingCount,
    );
  }
}
