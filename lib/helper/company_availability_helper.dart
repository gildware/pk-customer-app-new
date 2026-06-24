import 'package:demandium/util/core_export.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class CompanyScheduleResolution {
  final DateTime schedule;
  final bool wasAdjusted;

  const CompanyScheduleResolution({
    required this.schedule,
    required this.wasAdjusted,
  });
}

class BookableDayTimeRange {
  final DateTime start;
  final DateTime end;

  const BookableDayTimeRange({
    required this.start,
    required this.end,
  });
}

class CompanyAvailabilityHelper {
  static CompanyServiceAvailability? _config() {
    if (!Get.isRegistered<SplashController>()) return null;
    return Get.find<SplashController>().configModel.content?.companyServiceAvailability;
  }

  static bool get isEnabled => _config()?.enabled == 1;

  static AdvanceBooking? _advanceBooking() {
    if (!Get.isRegistered<SplashController>()) return null;
    return Get.find<SplashController>().configModel.content?.advanceBooking;
  }

  static bool get isRestrictionEnabled {
    if (!Get.isRegistered<SplashController>()) return true;
    return Get.find<SplashController>().configModel.content?.scheduleBookingTimeRestriction == 1;
  }

  static Duration getMinimumLeadTimeDuration() {
    if (!isRestrictionEnabled) {
      return Duration.zero;
    }

    final advance = _advanceBooking();
    final value = advance?.advancedBookingRestrictionValue ?? 0;
    if (value <= 0) {
      return const Duration(hours: 2);
    }

    return _durationFromType(value, advance?.advancedBookingRestrictionType,
        fallback: const Duration(hours: 2));
  }

  static Duration getCartCheckoutLeniencyDuration() {
    if (!isRestrictionEnabled) {
      return Duration.zero;
    }

    final advance = _advanceBooking();
    final value = advance?.cartCheckoutLeniencyValue ?? 0;
    if (value <= 0) {
      return Duration.zero;
    }

    return _durationFromType(value, advance?.cartCheckoutLeniencyType);
  }

  /// Effective lead time for cart/checkout: restriction minus leniency.
  static Duration getEffectiveCartCheckoutLeadTimeDuration() {
    if (!isRestrictionEnabled) {
      return Duration.zero;
    }

    final restriction = getMinimumLeadTimeDuration();
    var leniency = getCartCheckoutLeniencyDuration();
    if (leniency > restriction) {
      leniency = restriction;
    }
    return restriction - leniency;
  }

  static Duration _durationFromType(int value, String? type,
      {Duration fallback = Duration.zero}) {
    switch (type) {
      case 'day':
        return Duration(days: value);
      case 'hour':
        return Duration(hours: value);
      case 'minute':
        return Duration(minutes: value);
      default:
        return value > 0 ? Duration(hours: value) : fallback;
    }
  }

  static int getMinimumLeadTimeHours() {
    final duration = getMinimumLeadTimeDuration();
    if (duration.inDays > 0) {
      return duration.inDays * 24;
    }
    return duration.inHours > 0 ? duration.inHours : 2;
  }

  static DateTime minimumScheduleTime() =>
      DateTime.now().add(getMinimumLeadTimeDuration());

  static DateTime minimumScheduleTimeForCartCheckout() =>
      DateTime.now().add(getEffectiveCartCheckoutLeadTimeDuration());

  /// Whether [day] has at least one bookable slot (restriction + company hours).
  static bool isDayBookableForCustom(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _bookableTimeRangeForDayUnchecked(
          normalizedDay,
          minimumScheduleTime(),
        ) !=
        null;
  }

  static bool isCustomBookingDaySelectable(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    final today = DateTime.now();
    final todayDay = DateTime(today.year, today.month, today.day);
    if (day.isBefore(todayDay)) return false;
    return isDayBookableForCustom(day);
  }

  /// Allowed booking window for [day], or null when the day cannot be booked.
  static BookableDayTimeRange? bookableTimeRangeForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    final today = DateTime.now();
    final todayDay = DateTime(today.year, today.month, today.day);
    if (normalizedDay.isBefore(todayDay)) {
      return null;
    }
    return _bookableTimeRangeForDayUnchecked(
      normalizedDay,
      minimumScheduleTime(),
    );
  }

  /// Allowed booking window for cart/checkout (lenient lead time).
  static BookableDayTimeRange? bookableTimeRangeForCartCheckoutDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    final today = DateTime.now();
    final todayDay = DateTime(today.year, today.month, today.day);
    if (normalizedDay.isBefore(todayDay)) {
      return null;
    }
    return _bookableTimeRangeForDayUnchecked(
      normalizedDay,
      minimumScheduleTimeForCartCheckout(),
    );
  }

  static BookableDayTimeRange? _bookableTimeRangeForDayUnchecked(
    DateTime normalizedDay,
    DateTime minimum,
  ) {
    final absoluteDayEnd = DateTime(
      normalizedDay.year,
      normalizedDay.month,
      normalizedDay.day,
      23,
      59,
      59,
    );

    if (!isEnabled) {
      final start = _isSameCalendarDay(minimum, normalizedDay)
          ? minimum
          : DateTime(normalizedDay.year, normalizedDay.month, normalizedDay.day);
      if (start.isAfter(absoluteDayEnd)) {
        return null;
      }
      return BookableDayTimeRange(start: start, end: absoluteDayEnd);
    }

    final config = _config();
    if (config == null) {
      final start = _isSameCalendarDay(minimum, normalizedDay)
          ? minimum
          : DateTime(normalizedDay.year, normalizedDay.month, normalizedDay.day);
      if (start.isAfter(absoluteDayEnd)) {
        return null;
      }
      return BookableDayTimeRange(start: start, end: absoluteDayEnd);
    }

    if (_isWeekend(normalizedDay, config.weekends)) {
      return null;
    }

    final startTime = config.startTime;
    final endTime = config.endTime;
    if (startTime == null ||
        endTime == null ||
        startTime.isEmpty ||
        endTime.isEmpty ||
        _isInvalidSchedule(startTime, endTime)) {
      final start = _isSameCalendarDay(minimum, normalizedDay)
          ? minimum
          : DateTime(normalizedDay.year, normalizedDay.month, normalizedDay.day);
      if (start.isAfter(absoluteDayEnd)) {
        return null;
      }
      return BookableDayTimeRange(start: start, end: absoluteDayEnd);
    }

    final dayStart = _serviceStartForDay(normalizedDay, startTime);
    final dayEnd = _applyTimeToDate(normalizedDay, endTime);
    final start = dayStart.isBefore(minimum) ? minimum : dayStart;
    if (start.isAfter(dayEnd)) {
      return null;
    }
    return BookableDayTimeRange(start: start, end: dayEnd);
  }

  static bool isSelectableBookingTime(DateTime dateTime) {
    final range = bookableTimeRangeForDay(dateTime);
    if (range == null) {
      return false;
    }
    final selected = _truncateToMinute(dateTime);
    final start = _truncateToMinute(range.start);
    final end = _truncateToMinute(range.end);
    return !selected.isBefore(start) && !selected.isAfter(end);
  }

  static bool isSelectableBookingTimeForCartCheckout(DateTime dateTime) {
    final range = bookableTimeRangeForCartCheckoutDay(dateTime);
    if (range == null) {
      return false;
    }
    final selected = _truncateToMinute(dateTime);
    final start = _truncateToMinute(range.start);
    final end = _truncateToMinute(range.end);
    return !selected.isBefore(start) && !selected.isAfter(end);
  }

  static DateTime clampToSelectableTime(DateTime dateTime) {
    final range = bookableTimeRangeForDay(dateTime);
    if (range == null) {
      return getNextAvailableSlot(dateTime);
    }
    final selected = _truncateToMinute(dateTime);
    final start = _truncateToMinute(range.start);
    final end = _truncateToMinute(range.end);
    if (selected.isBefore(start)) {
      return start;
    }
    if (selected.isAfter(end)) {
      return end;
    }
    return _truncateToMinute(dateTime);
  }

  /// First valid custom booking datetime on or after the minimum lead time.
  static DateTime earliestCustomBookableDateTime() {
    final minimum = minimumScheduleTime();
    final startDay = DateTime(minimum.year, minimum.month, minimum.day);

    for (var offset = 0; offset < 14; offset++) {
      final day = startDay.add(Duration(days: offset));
      if (!isCustomBookingDaySelectable(day)) continue;
      return defaultTimeForCustomDay(day);
    }

    return minimum;
  }

  /// Default time to offer when the customer picks [day] in the custom calendar.
  static DateTime defaultTimeForCustomDay(DateTime day) {
    final range = bookableTimeRangeForDay(day);
    if (range == null) {
      return _truncateToMinute(earliestCustomBookableDateTime());
    }
    return _truncateToMinute(range.start);
  }

  /// Keeps the current clock time when switching [selectedDay] if it is still
  /// bookable; otherwise clamps to the nearest valid slot for that day.
  static DateTime timeForSelectedDay(DateTime selectedDay, DateTime? currentSelection) {
    final day = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
    if (currentSelection == null) {
      return defaultTimeForCustomDay(day);
    }

    final candidate = DateTime(
      day.year,
      day.month,
      day.day,
      currentSelection.hour,
      currentSelection.minute,
    );
    if (isSelectableBookingTime(candidate)) {
      return candidate;
    }
    return clampToSelectableTime(candidate);
  }

  static bool _isSameCalendarDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static DateTime _truncateToMinute(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day, dateTime.hour, dateTime.minute);
  }

  static bool isWithinCompanyHours(DateTime dateTime) {
    final config = _config();
    if (config == null || config.enabled != 1) return true;

    final weekends = _normalizedWeekendKeys(config.weekends);
    final dayOfWeek = DateFormat('EEEE', 'en_US').format(dateTime).toLowerCase();
    if (weekends.contains(dayOfWeek)) return false;

    final startTime = config.startTime;
    final endTime = config.endTime;
    if (startTime == null ||
        endTime == null ||
        startTime.isEmpty ||
        endTime.isEmpty ||
        _isInvalidSchedule(startTime, endTime)) {
      return true;
    }

    return _isTimeWithinRange(dateTime, startTime, endTime);
  }

  /// Resolves ASAP schedule: applies lead time, then adjusts to company hours.
  static DateTime resolveAsapSchedule() => resolveAsapScheduleResolution().schedule;

  /// Validates ASAP lead time against company hours and adjusts when needed.
  static CompanyScheduleResolution resolveAsapScheduleResolution() {
    final candidate = minimumScheduleTime();
    if (isSelectableBookingTime(candidate)) {
      return CompanyScheduleResolution(schedule: candidate, wasAdjusted: false);
    }

    final adjusted = getNextAvailableSlot(candidate);
    return CompanyScheduleResolution(
      schedule: adjusted,
      wasAdjusted: adjusted != candidate,
    );
  }

  /// Validates a custom schedule against restriction time and company hours.
  static CompanyScheduleResolution resolveCustomSchedule(DateTime requested) {
    if (isSelectableBookingTime(requested)) {
      return CompanyScheduleResolution(schedule: requested, wasAdjusted: false);
    }

    final minimum = minimumScheduleTime();
    final anchor = requested.isBefore(minimum) ? minimum : requested;
    final adjusted = getNextAvailableSlot(anchor);

    return CompanyScheduleResolution(
      schedule: adjusted,
      wasAdjusted: adjusted != requested,
    );
  }

  /// Finds the next valid booking slot on or after [after].
  static DateTime getNextAvailableSlot(DateTime after) {
    final minimum = minimumScheduleTime();
    var anchor = after.isBefore(minimum) ? minimum : after;

    for (var dayOffset = 0; dayOffset < 14; dayOffset++) {
      final day = DateTime(anchor.year, anchor.month, anchor.day).add(Duration(days: dayOffset));
      final range = bookableTimeRangeForDay(day);
      if (range == null) {
        continue;
      }

      if (dayOffset == 0) {
        if (_truncateToMinute(anchor).isBefore(_truncateToMinute(range.start))) {
          return _truncateToMinute(range.start);
        }
        if (!_truncateToMinute(anchor).isAfter(_truncateToMinute(range.end))) {
          return _truncateToMinute(anchor);
        }
        continue;
      }

      return _truncateToMinute(range.start);
    }

    return anchor;
  }

  static String? availabilityHoursNotice() {
    final config = _config();
    if (config == null || config.enabled != 1) {
      if (!isRestrictionEnabled) return null;
      return minimumLeadTimeMessage();
    }

    final start = _formatDisplayTime(config.startTime);
    final end = _formatDisplayTime(config.endTime);
    if (start == null || end == null) return minimumLeadTimeMessage();

    if (!isRestrictionEnabled) {
      return 'company_service_hours_only_notice'
          .trParams({'start': start, 'end': end});
    }

    final advance = _advanceBooking();
    final value = advance?.advancedBookingRestrictionValue ?? 2;
    final type = advance?.advancedBookingRestrictionType;
    if (type == 'day') {
      return 'company_service_hours_with_days_notice'.trParams({
        'start': start,
        'end': end,
        'days': '$value',
      });
    }
    if (type == 'minute') {
      return 'company_service_hours_with_minutes_notice'.trParams({
        'start': start,
        'end': end,
        'minutes': '$value',
      });
    }

    return 'company_service_hours_notice'
        .trParams({'start': start, 'end': end, 'hours': '$value'});
  }

  static String? outsideHoursMessage() {
    final config = _config();
    if (config == null || config.enabled != 1) return null;

    final start = _formatDisplayTime(config.startTime);
    final end = _formatDisplayTime(config.endTime);
    if (start == null || end == null) return null;

    return 'company_service_outside_hours_notice'.trParams({'start': start, 'end': end});
  }

  /// Human-readable allowed booking window for [day] (includes lead time on today).
  static String allowedTimeRangeMessageForDay(DateTime day) {
    final range = bookableTimeRangeForDay(day);
    if (range == null) {
      return minimumLeadTimeMessage();
    }

    final start = DateFormat('h:mm a').format(_truncateToMinute(range.start));
    final end = DateFormat('h:mm a').format(_truncateToMinute(range.end));
    return 'select_time_between_allowed_range'.trParams({'start': start, 'end': end});
  }

  static String allowedTimeRangeMessageForCartCheckoutDay(DateTime day) {
    final range = bookableTimeRangeForCartCheckoutDay(day);
    if (range == null) {
      return minimumCartCheckoutLeadTimeMessage();
    }

    final start = DateFormat('h:mm a').format(_truncateToMinute(range.start));
    final end = DateFormat('h:mm a').format(_truncateToMinute(range.end));
    return 'select_time_between_allowed_range'.trParams({'start': start, 'end': end});
  }

  static String? outsideHoursRescheduledMessage(DateTime rescheduled) {
    final config = _config();
    if (config == null || config.enabled != 1) return null;

    final start = _formatDisplayTime(config.startTime);
    final end = _formatDisplayTime(config.endTime);
    if (start == null || end == null) return null;

    return 'company_service_outside_hours_rescheduled_notice'.trParams({
      'start': start,
      'end': end,
      'time': DateConverter.dateMonthYearTimeTwentyFourFormat(rescheduled),
    });
  }

  static String minimumLeadTimeMessage() {
    if (!isRestrictionEnabled) {
      return CompanyAvailabilityHelper.availabilityHoursNotice() ??
          'select_schedule_time'.tr;
    }

    final advance = _advanceBooking();
    final value = advance?.advancedBookingRestrictionValue ?? 2;
    final type = advance?.advancedBookingRestrictionType;
    if (type == 'day') {
      return 'booking_minimum_lead_time_days_notice'.trParams({'days': '$value'});
    }
    if (type == 'minute') {
      return 'booking_minimum_lead_time_minutes_notice'
          .trParams({'minutes': '$value'});
    }
    return 'booking_minimum_lead_time_notice'.trParams({'hours': '$value'});
  }

  static String minimumCartCheckoutLeadTimeMessage() {
    if (!isRestrictionEnabled) {
      return minimumLeadTimeMessage();
    }

    final effective = getEffectiveCartCheckoutLeadTimeDuration();
    if (effective.inDays > 0 && effective.inHours % 24 == 0) {
      final days = effective.inDays;
      return 'booking_minimum_lead_time_days_notice'.trParams({'days': '$days'});
    }
    if (effective.inHours > 0 && effective.inMinutes % 60 == 0) {
      return 'booking_minimum_lead_time_notice'
          .trParams({'hours': '${effective.inHours}'});
    }
    return 'booking_minimum_lead_time_minutes_notice'
        .trParams({'minutes': '${effective.inMinutes}'});
  }

  static String asapScheduleNotice(DateTime schedule) {
    return 'asap_scheduled_for_notice'.trParams({
      'time': DateConverter.dateMonthYearTimeTwentyFourFormat(schedule),
    });
  }

  static bool isAsapSchedule(DateTime parsed) {
    final now = DateTime.now();
    if (parsed.difference(now).inMinutes <= 5 &&
        parsed.isAfter(now.subtract(const Duration(minutes: 1)))) {
      return true;
    }
    final resolvedAsap = resolveAsapScheduleResolution().schedule;
    return parsed.difference(resolvedAsap).inMinutes.abs() <= 2;
  }

  static void notifyIfScheduleAdjusted(
    CompanyScheduleResolution resolution, {
    bool aboveOverlays = true,
    bool delay = false,
  }) {
    if (!resolution.wasAdjusted) return;

    void showNotice() {
      customSnackBar(
        outsideHoursRescheduledMessage(resolution.schedule) ??
            outsideHoursMessage() ??
            'company_service_outside_hours_notice'.tr,
        type: ToasterMessageType.info,
        aboveOverlays: aboveOverlays,
      );
    }

    if (delay) {
      WidgetsBinding.instance.addPostFrameCallback((_) => showNotice());
      return;
    }
    showNotice();
  }

  static List<String> _normalizedWeekendKeys(List<String>? weekends) {
    if (weekends == null || weekends.isEmpty) return const [];
    return weekends.map((d) => d.trim().toLowerCase()).where((d) => d.isNotEmpty).toList();
  }

  static bool _isWeekend(DateTime date, List<String>? weekends) {
    final normalized = _normalizedWeekendKeys(weekends);
    if (normalized.isEmpty) return false;
    final dayOfWeek = DateFormat('EEEE', 'en_US').format(date).toLowerCase();
    return normalized.contains(dayOfWeek);
  }

  static bool _isInvalidSchedule(String start, String end) {
    final startTime = _parseClockTime(start);
    final endTime = _parseClockTime(end);
    if (startTime == null || endTime == null) return true;
    return !startTime.isBefore(endTime);
  }

  static DateTime _clockBase(int hour, int minute, [int second = 0]) {
    return DateTime(1970, 1, 1, hour, minute, second);
  }

  static DateTime? _parseClockTime(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    const patterns = <String>[
      'HH:mm:ss',
      'HH:mm',
      'h:mm:ss a',
      'hh:mm:ss a',
      'h:mm a',
      'hh:mm a',
    ];

    for (final pattern in patterns) {
      try {
        final parsed = DateFormat(pattern).parse(trimmed);
        return _clockBase(parsed.hour, parsed.minute, parsed.second);
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  static bool _isTimeWithinRange(DateTime dateTime, String start, String end) {
    final startTime = _parseClockTime(start);
    final endTime = _parseClockTime(end);
    if (startTime == null || endTime == null) return true;

    final currentTime = _clockBase(dateTime.hour, dateTime.minute, dateTime.second);
    // Inclusive start, inclusive end (e.g. 09:00–18:00 allows booking at 6:00 PM).
    return !currentTime.isBefore(startTime) && !currentTime.isAfter(endTime);
  }

  static DateTime _applyTimeToDate(DateTime date, String time) {
    final parsed = _parseClockTime(time);
    if (parsed == null) return date;
    return DateTime(date.year, date.month, date.day, parsed.hour, parsed.minute, parsed.second);
  }

  /// Service start time on the given day.
  static DateTime _serviceStartForDay(DateTime day, String startTime) {
    return _applyTimeToDate(day, startTime);
  }

  static String? _formatDisplayTime(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final parsed = _parseClockTime(raw);
    if (parsed == null) return raw;
    return DateFormat('h:mm a').format(parsed);
  }
}
