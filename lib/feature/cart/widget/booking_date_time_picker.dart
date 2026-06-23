import 'package:demandium/common/widgets/time_picker_snipper.dart';
import 'package:demandium/helper/provider_availability_helper.dart';
import 'package:demandium/helper/validation_helper.dart';
import 'package:demandium/util/core_export.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

class BookingDateTimePicker extends StatefulWidget {
  final Future<bool> Function(String scheduleTime, DateTime selected)? onScheduleConfirmed;
  final ProviderData? providerToValidate;

  const BookingDateTimePicker({
    super.key,
    this.onScheduleConfirmed,
    this.providerToValidate,
  });

  static DateTime minimumScheduleTime() => CompanyAvailabilityHelper.minimumScheduleTime();

  static DateTime earliestCustomBookableDateTime() =>
      CompanyAvailabilityHelper.earliestCustomBookableDateTime();

  static DateTime? parseSelectedSchedule(ScheduleController scheduleController) {
    try {
      final date = scheduleController.selectedDate.trim();
      final timeRaw = scheduleController.selectedTime.trim();
      if (date.isEmpty || timeRaw.isEmpty) return null;

      final parts = timeRaw.split(':');
      if (parts.length < 2) return null;

      final hour = int.parse(parts[0].trim());
      final minute = int.parse(parts[1].trim());
      final second = parts.length > 2 ? int.parse(parts[2].trim()) : 0;
      final normalized =
          '$date ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:${second.toString().padLeft(2, '0')}';
      return DateConverter.dateTimeStringToDate(normalized);
    } catch (_) {
      return null;
    }
  }

  static bool isValidBookingDateTime(DateTime selected) {
    return !selected.isBefore(minimumScheduleTime());
  }

  @override
  State<BookingDateTimePicker> createState() => _BookingDateTimePickerState();
}

class _BookingDateTimePickerState extends State<BookingDateTimePicker> {
  late final DateRangePickerController _dateController;
  late DateTime _initialDateTime;

  @override
  void initState() {
    super.initState();
    _dateController = DateRangePickerController();

    final scheduleController = Get.find<ScheduleController>();
    scheduleController.updateScheduleType(
      scheduleType: ScheduleType.schedule,
      shouldUpdate: false,
    );

    _initialDateTime = _resolveInitialCustomDateTime(scheduleController);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _dateController.selectedDate = _initialDateTime;
    });
  }

  DateTime _resolveInitialCustomDateTime(ScheduleController scheduleController) {
    final parsed = BookingDateTimePicker.parseSelectedSchedule(scheduleController);
    if (parsed != null && CompanyAvailabilityHelper.isCustomBookingDaySelectable(parsed)) {
      return parsed;
    }

    final earliest = BookingDateTimePicker.earliestCustomBookableDateTime();
    scheduleController.selectedDate = DateFormat('yyyy-MM-dd').format(earliest);
    scheduleController.selectedTime = DateFormat('HH:mm:ss').format(earliest);
    return earliest;
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (ResponsiveHelper.isDesktop(context)) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
        ),
        insetPadding: const EdgeInsets.all(30),
        child: _buildBody(context),
      );
    }
    return _buildBody(context);
  }

  Widget _buildBody(BuildContext context) {
    return Container(
      width: ResponsiveHelper.isDesktop(context)
          ? Dimensions.webMaxWidth / 2
          : Dimensions.webMaxWidth,
      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(Dimensions.radiusLarge),
        ),
      ),
      child: GetBuilder<ScheduleController>(builder: (scheduleController) {
        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'select_schedule_time'.tr,
                style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge),
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              Text(
                CompanyAvailabilityHelper.availabilityHoursNotice() ??
                    CompanyAvailabilityHelper.minimumLeadTimeMessage(),
                style: robotoRegular.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: Theme.of(context).hintColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Dimensions.paddingSizeDefault),
              _BookingDatePicker(
                dateRangePickerController: _dateController,
                initialSelectableDate: BookingDateTimePicker.earliestCustomBookableDateTime(),
              ),
              GetBuilder<ScheduleController>(
                builder: (scheduleController) => _BookingTimePicker(
                  key: ValueKey(scheduleController.selectedDate),
                  selectedDay: _parsePickerDay(scheduleController.selectedDate),
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeDefault),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      buttonText: 'cancel'.tr,
                      backgroundColor: Theme.of(context).disabledColor,
                      onPressed: () => Get.back(),
                    ),
                  ),
                  const SizedBox(width: Dimensions.paddingSizeSmall),
                  Expanded(
                    child: CustomButton(
                      buttonText: 'ok'.tr,
                      onPressed: () => _onConfirm(scheduleController),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }

  Future<void> _onConfirm(ScheduleController scheduleController) async {
    final selected = BookingDateTimePicker.parseSelectedSchedule(scheduleController);
    if (selected == null) {
      customSnackBar(
        'select_your_preferable_booking_time'.tr,
        type: ToasterMessageType.info,
        aboveOverlays: true,
      );
      return;
    }
    if (!BookingDateTimePicker.isValidBookingDateTime(selected)) {
      customSnackBar(
        CompanyAvailabilityHelper.minimumLeadTimeMessage(),
        type: ToasterMessageType.info,
        aboveOverlays: true,
      );
      return;
    }
    if (!CompanyAvailabilityHelper.isCustomBookingDaySelectable(selected)) {
      customSnackBar(
        CompanyAvailabilityHelper.outsideHoursMessage() ??
            'company_service_outside_hours_notice'.tr,
        type: ToasterMessageType.info,
        aboveOverlays: true,
      );
      return;
    }

    final resolution = scheduleController.applyCustomScheduleResolution(
      selected,
      notifyIfAdjusted: true,
    );
    final resolved = resolution.schedule;

    final provider = widget.providerToValidate;
    if (provider != null &&
        ValidationHelper.isValidUuid(provider.id) &&
        !ProviderAvailabilityHelper.isProviderAvailableAtSchedule(provider, resolved)) {
      customSnackBar(
        'your_selected_provider_is_unavailable_right_now'.tr,
        type: ToasterMessageType.info,
        aboveOverlays: true,
      );
      return;
    }

    scheduleController.updateScheduleType(
      scheduleType: ScheduleType.schedule,
      shouldUpdate: false,
    );
    scheduleController.buildSchedule(scheduleType: ScheduleType.schedule);
    scheduleController.update();

    final scheduleTime = scheduleController.scheduleTime;
    if (scheduleTime == null) {
      customSnackBar(
        'select_your_preferable_booking_time'.tr,
        type: ToasterMessageType.info,
        aboveOverlays: true,
      );
      return;
    }

    if (widget.onScheduleConfirmed != null) {
      final saved = await widget.onScheduleConfirmed!(scheduleTime, resolved);
      if (!saved) return;
      Get.back();
      return;
    }

    Get.find<CartController>().setPendingBookingSchedule(scheduleTime);
    Get.back();
  }

  DateTime? _parsePickerDay(String value) {
    if (value.isEmpty) return null;
    try {
      return DateFormat('yyyy-MM-dd').parse(value);
    } catch (_) {
      return null;
    }
  }
}

class _BookingDatePicker extends StatelessWidget {
  final DateRangePickerController dateRangePickerController;
  final DateTime initialSelectableDate;

  const _BookingDatePicker({
    required this.dateRangePickerController,
    required this.initialSelectableDate,
  });

  DateTime? _parseDate(String value) {
    if (value.isEmpty) return null;
    try {
      return DateFormat('yyyy-MM-dd').parse(value);
    } catch (_) {
      return null;
    }
  }

  DateTime _initialSelectableDate(
    ScheduleController scheduleController,
    DateTime fallbackDate,
  ) {
    final parsed = _parseDate(scheduleController.selectedDate);
    if (parsed != null && CompanyAvailabilityHelper.isCustomBookingDaySelectable(parsed)) {
      return parsed;
    }
    return fallbackDate;
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final calendarMinDate = DateTime(today.year, today.month, today.day);

    return SizedBox(
      height: 300,
      child: GetBuilder<ScheduleController>(builder: (scheduleController) {
        return SfDateRangePicker(
          backgroundColor: Theme.of(context).cardColor,
          controller: dateRangePickerController,
          showNavigationArrow: true,
          minDate: calendarMinDate,
          selectableDayPredicate: CompanyAvailabilityHelper.isCustomBookingDaySelectable,
          onSelectionChanged: (DateRangePickerSelectionChangedArgs args) {
            if (args.value is DateTime) {
              final selectedDay = args.value as DateTime;
              scheduleController.selectedDate =
                  DateFormat('yyyy-MM-dd').format(selectedDay);
              final defaultTime =
                  CompanyAvailabilityHelper.defaultTimeForCustomDay(selectedDay);
              scheduleController.selectedTime = DateFormat('HH:mm:ss').format(defaultTime);
              scheduleController.updateScheduleType(
                scheduleType: ScheduleType.schedule,
                shouldUpdate: false,
              );
              scheduleController.update();
            }
          },
          initialSelectedDate: _initialSelectableDate(scheduleController, initialSelectableDate),
          selectionMode: DateRangePickerSelectionMode.single,
          selectionShape: DateRangePickerSelectionShape.rectangle,
          enablePastDates: false,
          headerStyle: DateRangePickerHeaderStyle(
            backgroundColor: Theme.of(context).cardColor,
            textAlign: TextAlign.center,
            textStyle: robotoMedium.copyWith(
              fontSize: Dimensions.fontSizeLarge,
              color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: 0.8),
            ),
          ),
        );
      }),
    );
  }
}

class _BookingTimePicker extends StatefulWidget {
  final DateTime? selectedDay;
  const _BookingTimePicker({super.key, required this.selectedDay});

  @override
  State<_BookingTimePicker> createState() => _BookingTimePickerState();
}

class _BookingTimePickerState extends State<_BookingTimePicker> {
  DateTime _resolvePickerTime(ScheduleController scheduleController) {
    final parsed = BookingDateTimePicker.parseSelectedSchedule(scheduleController);
    if (parsed != null) return parsed;

    final day = widget.selectedDay ?? DateTime.now();
    return CompanyAvailabilityHelper.defaultTimeForCustomDay(day);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ScheduleController>(builder: (scheduleController) {
      final pickerTime = _resolvePickerTime(scheduleController);
      return Padding(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      child: Row(
        children: [
          Text(
            'time'.tr,
            style: robotoBold.copyWith(
              fontSize: Dimensions.fontSizeLarge,
              color: Get.isDarkMode
                  ? Theme.of(context).textTheme.bodyMedium?.color
                  : Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeLarge),
          Expanded(
            child: TimePickerSpinner(
              time: pickerTime,
              is24HourMode: Get.find<SplashController>().configModel.content?.timeFormat == '24',
              normalTextStyle: robotoRegular.copyWith(
                color: Theme.of(context).hintColor,
                fontSize: Dimensions.fontSizeSmall,
              ),
              highlightedTextStyle: robotoMedium.copyWith(
                fontSize: Dimensions.fontSizeLarge,
                color: Get.isDarkMode
                    ? Theme.of(context).textTheme.bodyMedium?.color
                    : Theme.of(context).colorScheme.primary,
              ),
              spacing: Dimensions.paddingSizeDefault,
              itemHeight: Dimensions.fontSizeLarge + 2,
              itemWidth: 50,
              alignment: Alignment.topCenter,
              isForce2Digits: true,
              onTimeChange: (time) {
                Get.find<ScheduleController>().selectedTime =
                    DateFormat('HH:mm:ss').format(time);
              },
            ),
          ),
        ],
      ),
    );
    });
  }
}
