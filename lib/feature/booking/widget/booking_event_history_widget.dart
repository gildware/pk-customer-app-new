import 'package:demandium/feature/booking/helper/booking_event_history_helper.dart';
import 'package:demandium/feature/booking/widget/booking_screen_shimmer.dart';
import 'package:demandium/feature/booking/widget/timeline/connectors.dart';
import 'package:demandium/feature/booking/widget/timeline/indicator_theme.dart';
import 'package:demandium/feature/booking/widget/timeline/indicators.dart';
import 'package:demandium/feature/booking/widget/timeline/timeline_theme.dart';
import 'package:demandium/feature/booking/widget/timeline/timeline_tile_builder.dart';
import 'package:demandium/feature/booking/widget/timeline/timelines.dart';
import 'package:get/get.dart';
import 'package:demandium/util/core_export.dart';

class BookingEventHistoryWidget extends StatelessWidget {
  final String? id;
  final bool isSubBooking;

  const BookingEventHistoryWidget({super.key, this.id, required this.isSubBooking});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        if (id == null) return;
        if (isSubBooking) {
          await Get.find<BookingDetailsController>().getSubBookingDetails(bookingId: id!);
        } else {
          await Get.find<BookingDetailsController>().getBookingDetails(bookingId: id!);
        }
      },
      child: GetBuilder<BookingDetailsController>(
        builder: (controller) {
          final booking = isSubBooking ? controller.subBookingDetailsContent : controller.bookingDetailsContent;
          if (booking == null) {
            return const SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: BookingScreenShimmer(),
            );
          }

          final events = BookingEventHistoryHelper.buildEvents(booking);
          if (events.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
              children: [
                Center(child: Text('no_history_entries_yet'.tr, style: robotoRegular)),
              ],
            );
          }

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            children: [
              Timeline.tileBuilder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                theme: TimelineThemeData(
                  nodePosition: 0,
                  indicatorTheme: const IndicatorThemeData(position: 0, size: 28.0),
                ),
                padding: EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: Get.find<LocalizationController>().isLtr ? 0 : 10,
                ),
                builder: TimelineTileBuilder.connected(
                  connectionDirection: ConnectionDirection.before,
                  itemCount: events.length,
                  contentsBuilder: (_, index) => _EventTile(event: events[index]),
                  connectorBuilder: (_, __, ___) => SolidLineConnector(color: Theme.of(context).colorScheme.primary),
                  indicatorBuilder: (_, index) => DotIndicator(
                    color: _indicatorColor(context, events[index].eventType),
                    child: Center(
                      child: Icon(
                        _indicatorIcon(events[index].eventType),
                        size: 14,
                        color: light.cardColor,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeExtraLarge),
            ],
          );
        },
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  final BookingTimelineEvent event;

  const _EventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 20, top: 4, right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event.title,
            style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault),
          ),
          const SizedBox(height: Dimensions.paddingSizeExtraSmall),
          Text(
            event.description,
            style: robotoRegular.copyWith(
              fontSize: Dimensions.fontSizeSmall,
              color: Theme.of(context).secondaryHeaderColor,
            ),
          ),
        ],
      ),
    );
  }
}

Color _indicatorColor(BuildContext context, BookingEventType type) {
  return switch (type) {
    BookingEventType.status => Theme.of(context).colorScheme.primary,
    BookingEventType.schedule => Colors.orange,
    BookingEventType.provider => Colors.blue,
    BookingEventType.service => Colors.teal,
    BookingEventType.payment => Colors.green,
    BookingEventType.other => Theme.of(context).colorScheme.primary,
  };
}

IconData _indicatorIcon(BookingEventType type) {
  return switch (type) {
    BookingEventType.status => Icons.sync,
    BookingEventType.schedule => Icons.calendar_today,
    BookingEventType.provider => Icons.person,
    BookingEventType.service => Icons.home_repair_service,
    BookingEventType.payment => Icons.payments,
    BookingEventType.other => Icons.history,
  };
}
