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

class CompanyAvailabilityHelper {
  static CompanyServiceAvailability? _config() {
    if (!Get.isRegistered<SplashController>()) return null;
    return Get.find<SplashController>().configModel.content?.companyServiceAvailability;
  }

  static bool get isEnabled => _config()?.enabled == 1;

  static int getMinimumLeadTimeHours() {
    final content = Get.isRegistered<SplashController>()
        ? Get.find<SplashController>().configModel.content
        : null;
    final advance = content?.advanceBooking;
    if (advance?.advancedBookingRestrictionType == 'hour' &&
        (advance?.advancedBookingRestrictionValue ?? 0) > 0) {
      return advance!.advancedBookingRestrictionValue!;
    }
    return 2;
  }

  static Duration getMinimumLeadTimeDuration() =>
      Duration(hours: getMinimumLeadTimeHours());

  static DateTime minimumScheduleTime() =>
      DateTime.now().add(getMinimumLeadTimeDuration());

  /// Whether [day] has at least one custom booking slot within company hours.
  static bool isDayBookableForCustom(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    final minimum = minimumScheduleTime();

    if (!isEnabled) {
      final dayEnd = DateTime(
        normalizedDay.year,
        normalizedDay.month,
        normalizedDay.day,
        23,
        59,
        59,
      );
      return !dayEnd.isBefore(minimum);
    }

    final config = _config();
    if (config == null) return true;

    if (_isWeekend(normalizedDay, config.weekends)) return false;

    final startTime = config.startTime;
    final endTime = config.endTime;
    if (startTime == null ||
        endTime == null ||
        startTime.isEmpty ||
        endTime.isEmpty ||
        _isInvalidSchedule(startTime, endTime)) {
      final dayEnd = DateTime(
        normalizedDay.year,
        normalizedDay.month,
        normalizedDay.day,
        23,
        59,
        59,
      );
      return !dayEnd.isBefore(minimum);
    }

    final dayStart = _serviceStartForDay(normalizedDay, startTime);
    final dayEnd = _applyTimeToDate(normalizedDay, endTime);
    final earliestOnDay = dayStart.isBefore(minimum) ? minimum : dayStart;

    return !earliestOnDay.isAfter(dayEnd) && isWithinCompanyHours(earliestOnDay);
  }

  static bool isCustomBookingDaySelectable(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    final today = DateTime.now();
    final todayDay = DateTime(today.year, today.month, today.day);
    if (day.isBefore(todayDay)) return false;
    return isDayBookableForCustom(day);
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
    final normalizedDay = DateTime(day.year, day.month, day.day);
    final minimum = minimumScheduleTime();

    if (!isEnabled) {
      if (_isSameCalendarDay(minimum, normalizedDay)) return minimum;
      return DateTime(
        normalizedDay.year,
        normalizedDay.month,
        normalizedDay.day,
        minimum.hour,
        minimum.minute,
        minimum.second,
      );
    }

    final config = _config();
    if (config == null) {
      return _isSameCalendarDay(minimum, normalizedDay)
          ? minimum
          : DateTime(
              normalizedDay.year,
              normalizedDay.month,
              normalizedDay.day,
              minimum.hour,
              minimum.minute,
              minimum.second,
            );
    }

    final startTime = config.startTime;
    final endTime = config.endTime;
    if (startTime == null ||
        endTime == null ||
        startTime.isEmpty ||
        endTime.isEmpty) {
      return _isSameCalendarDay(minimum, normalizedDay)
          ? minimum
          : _serviceStartForDay(normalizedDay, '09:00');
    }

    final dayStart = _serviceStartForDay(normalizedDay, startTime);
    final dayEnd = _applyTimeToDate(normalizedDay, endTime);
    final slot = dayStart.isBefore(minimum) ? minimum : dayStart;
    return slot.isAfter(dayEnd) ? dayStart : slot;
  }

  static bool _isSameCalendarDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
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
    if (!isEnabled || isWithinCompanyHours(candidate)) {
      return CompanyScheduleResolution(schedule: candidate, wasAdjusted: false);
    }

    return CompanyScheduleResolution(
      schedule: getNextAvailableSlot(candidate),
      wasAdjusted: true,
    );
  }

  /// Validates a custom schedule and adjusts to the next company slot when needed.
  static CompanyScheduleResolution resolveCustomSchedule(DateTime requested) {
    if (!isEnabled) {
      return CompanyScheduleResolution(schedule: requested, wasAdjusted: false);
    }

    final minimum = minimumScheduleTime();
    if (!requested.isBefore(minimum) && isWithinCompanyHours(requested)) {
      return CompanyScheduleResolution(schedule: requested, wasAdjusted: false);
    }

    final anchor = requested.isBefore(minimum) ? minimum : requested;
    return CompanyScheduleResolution(
      schedule: getNextAvailableSlot(anchor),
      wasAdjusted: true,
    );
  }

  /// Finds the next valid booking slot on or after [after].
  static DateTime getNextAvailableSlot(DateTime after) {
    final config = _config();
    if (config == null || config.enabled != 1) return after;

    final startTime = config.startTime;
    final endTime = config.endTime;
    if (startTime == null || endTime == null || startTime.isEmpty || endTime.isEmpty) {
      return after;
    }

    final minimum = minimumScheduleTime();

    for (var dayOffset = 0; dayOffset < 14; dayOffset++) {
      final day = DateTime(after.year, after.month, after.day).add(Duration(days: dayOffset));
      if (_isWeekend(day, config.weekends)) continue;

      final dayStart = _serviceStartForDay(day, startTime);
      final dayEnd = _applyTimeToDate(day, endTime);

      if (dayOffset == 0) {
        if (after.isBefore(dayStart)) {
          final slot = dayStart.isBefore(minimum) ? minimum : dayStart;
          if (isWithinCompanyHours(slot) && !slot.isBefore(minimum)) return slot;
          continue;
        }
        if (!after.isAfter(dayEnd) && isWithinCompanyHours(after)) {
          return after.isBefore(minimum) ? minimum : after;
        }
        continue;
      }

      final slot = dayStart.isBefore(minimum) ? minimum : dayStart;
      if (!slot.isBefore(minimum) && isWithinCompanyHours(slot)) return slot;
    }

    return after.isBefore(minimum) ? minimum : after;
  }

  static String? availabilityHoursNotice() {
    final config = _config();
    if (config == null || config.enabled != 1) return null;

    final start = _formatDisplayTime(config.startTime);
    final end = _formatDisplayTime(config.endTime);
    if (start == null || end == null) return null;

    final leadHours = getMinimumLeadTimeHours();
    return 'company_service_hours_notice'
        .trParams({'start': start, 'end': end, 'hours': '$leadHours'});
  }

  static String? outsideHoursMessage() {
    final config = _config();
    if (config == null || config.enabled != 1) return null;

    final start = _formatDisplayTime(config.startTime);
    final end = _formatDisplayTime(config.endTime);
    if (start == null || end == null) return null;

    return 'company_service_outside_hours_notice'.trParams({'start': start, 'end': end});
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
    final hours = getMinimumLeadTimeHours();
    return 'booking_minimum_lead_time_notice'.trParams({'hours': '$hours'});
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
