import 'package:demandium/util/core_export.dart';
import 'package:intl/intl.dart';

enum ProviderLiveAvailability { available, onBreak, unavailable }

class ProviderAvailabilityHelper {
  static ProviderLiveAvailability getLiveAvailabilityStatus(ProviderData provider) {
    if (provider.serviceAvailability != 1 || provider.isActive != 1) {
      return ProviderLiveAvailability.unavailable;
    }
    if (!isWithinWorkingHours(provider, DateTime.now())) {
      return ProviderLiveAvailability.onBreak;
    }
    return ProviderLiveAvailability.available;
  }

  static bool isProviderAvailableNow(ProviderData provider) {
    return getLiveAvailabilityStatus(provider) == ProviderLiveAvailability.available;
  }

  static bool isProviderAvailableAtSchedule(ProviderData provider, DateTime scheduleDateTime) {
    if (provider.serviceAvailability != 1 || provider.isActive != 1) {
      return false;
    }
    if (provider.nextBookingEligibility == false) {
      return false;
    }

    return isWithinWorkingHours(provider, scheduleDateTime);
  }

  static bool isWithinWorkingHours(ProviderData provider, DateTime dateTime) {
    final weekends = _normalizedWeekendKeys(provider.weekends);
    final dayOfWeek = DateFormat('EEEE', 'en_US').format(dateTime).toLowerCase();
    if (weekends.contains(dayOfWeek)) {
      return false;
    }

    final startTime = provider.timeSchedule?.startTime;
    final endTime = provider.timeSchedule?.endTime;
    if (startTime == null || endTime == null || _isInvalidSchedule(startTime, endTime)) {
      return true;
    }

    return _isTimeWithinRange(dateTime, startTime, endTime);
  }

  static List<String> _normalizedWeekendKeys(List<String>? weekends) {
    if (weekends == null || weekends.isEmpty) {
      return const [];
    }
    return weekends.map((d) => d.trim().toLowerCase()).where((d) => d.isNotEmpty).toList();
  }

  static bool _isInvalidSchedule(String start, String end) {
    final startTime = _parseClockTime(start);
    final endTime = _parseClockTime(end);
    if (startTime == null || endTime == null) {
      return true;
    }
    return !startTime.isBefore(endTime);
  }

  /// Compare clock times on a shared base date (DateFormat.parse uses 1970-01-01).
  static DateTime _clockBase(int hour, int minute, [int second = 0]) {
    return DateTime(1970, 1, 1, hour, minute, second);
  }

  static DateTime? _parseClockTime(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }

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
    if (startTime == null || endTime == null) {
      return true;
    }

    final currentTime = _clockBase(dateTime.hour, dateTime.minute, dateTime.second);
    return !currentTime.isBefore(startTime) && !currentTime.isAfter(endTime);
  }

  static List<ProviderData> filterBySchedule(List<ProviderData> providers, DateTime scheduleDateTime) {
    return providers.where((p) => isProviderAvailableAtSchedule(p, scheduleDateTime)).toList();
  }
}
