import 'package:demandium/util/core_export.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

class CustomDatePicker extends StatelessWidget {
  final DateRangePickerController dateRangePickerController;
  const CustomDatePicker({super.key, required this.dateRangePickerController}) ;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final calendarMinDate = DateTime(today.year, today.month, today.day);

    return SizedBox(
      height: 300, width: 500,
      child: GetBuilder<ScheduleController>(builder: (scheduleController){
        return SfDateRangePicker(
          backgroundColor: Theme.of(context).cardColor,
          controller: dateRangePickerController,
         showNavigationArrow: true,
          minDate: calendarMinDate,
          selectableDayPredicate: CompanyAvailabilityHelper.isCustomBookingDaySelectable,
          onSelectionChanged: (DateRangePickerSelectionChangedArgs args){
            if(args.value !=null){
              final selectedDay = args.value as DateTime;
              scheduleController.selectedDate =  DateFormat('yyyy-MM-dd').format(selectedDay);
              final currentSelection = DateConverter.tryParseScheduleDateTime(
                '${scheduleController.selectedDate} ${scheduleController.selectedTime}',
              );
              final resolvedTime = CompanyAvailabilityHelper.timeForSelectedDay(
                selectedDay,
                currentSelection,
              );
              scheduleController.selectedTime =
                  DateFormat('HH:mm:ss').format(resolvedTime);
              scheduleController.updateScheduleType(scheduleType: ScheduleType.schedule);
              scheduleController.update();
            }
          },
          initialSelectedDate: scheduleController.getSelectedDateTime(),
          selectionMode: DateRangePickerSelectionMode.single,
          selectionShape: DateRangePickerSelectionShape.rectangle,
          viewSpacing: 10,
          todayHighlightColor: Get.isDarkMode ? Theme.of(context).textTheme.bodyMedium?.color : null,
          selectionTextStyle: TextStyle(color:  Get.isDarkMode ? Theme.of(context).textTheme.bodyMedium?.color : null),
          headerHeight: 50,
          toggleDaySelection: true,
          enablePastDates: false,
          headerStyle: DateRangePickerHeaderStyle(
            backgroundColor: Theme.of(context).cardColor,
            textAlign: TextAlign.center,
            textStyle: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge,
              color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: 0.8),
            ),
          ),
        );
      }),
    );
  }
}
