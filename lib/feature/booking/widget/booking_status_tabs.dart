import 'package:get/get.dart';
import 'package:demandium/util/core_export.dart';

class ServiceRequestSectionMenu extends SliverPersistentHeaderDelegate {
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return GetBuilder<ServiceBookingController>(builder: (serviceBookingController) {
      return Container(
        margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(Dimensions.radiusLarge),
            bottomRight: Radius.circular(Dimensions.radiusLarge),
          ),
        ),
        child: Container(
          width: Dimensions.webMaxWidth,
          padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
          decoration: BoxDecoration(
            color: ResponsiveHelper.isDesktop(context) && Get.isDarkMode
                ? Theme.of(context).cardColor
                : ResponsiveHelper.isDesktop(context)
                    ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.07)
                    : Get.isDarkMode
                        ? Colors.transparent
                        : Theme.of(context).cardColor,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(Dimensions.radiusLarge),
              bottomRight: Radius.circular(Dimensions.radiusLarge),
            ),
          ),
          child: ResponsiveHelper.isDesktop(context)
              ? Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(),
                    Text(
                      'my_bookings'.tr,
                      style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeEight),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                        child: Row(
                          children: serviceBookingController.visibleBookingTabs.map((tab) {
                            final isSelected = serviceBookingController.selectedBookingStatus == tab;
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: InkWell(
                                onTap: () => serviceBookingController.updateBookingStatusTabs(tab),
                                child: BookingStatusTabItem(
                                  title: tab,
                                  isSelected: isSelected,
                                  bookingCount: serviceBookingController.bookingCount,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                )
              : const _MobileBookingStatusTabBar(),
        ),
      );
    });
  }

  @override
  double get maxExtent => ResponsiveHelper.isDesktop(Get.context!) ? 110 : 60;

  @override
  double get minExtent => ResponsiveHelper.isDesktop(Get.context!) ? 110 : 60;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}

class _MobileBookingStatusTabBar extends StatelessWidget {
  const _MobileBookingStatusTabBar();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ServiceBookingController>(builder: (controller) {
      final visibleTabs = controller.visibleBookingTabs;
      final scrollController = controller.bookingTabScrollController;
      if (scrollController == null || visibleTabs.isEmpty) {
        return const SizedBox(height: 46);
      }

      return SizedBox(
        height: 46,
        width: double.infinity,
        child: ListView.builder(
          key: const PageStorageKey('user_booking_tabs'),
          controller: scrollController,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
          itemCount: visibleTabs.length,
          itemBuilder: (context, index) {
            final tab = visibleTabs[index];
            return InkWell(
              onTap: () => controller.updateBookingStatusTabs(tab),
              child: AutoScrollTag(
                controller: scrollController,
                key: ValueKey(tab),
                index: index,
                highlightColor: Colors.transparent,
                child: BookingStatusTabItem(
                  title: tab,
                  isSelected: controller.selectedBookingStatus == tab,
                  bookingCount: controller.bookingCount,
                ),
              ),
            );
          },
        ),
      );
    });
  }
}
