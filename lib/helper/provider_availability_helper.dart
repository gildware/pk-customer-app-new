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
    final weekends = provider.weekends ?? [];
    final dayOfWeek = DateConverter.dateToWeek(dateTime).toLowerCase();
    if (weekends.contains(dayOfWeek)) {
      return false;
    }

    final startTime = provider.timeSchedule?.startTime;
    final endTime = provider.timeSchedule?.endTime;
    if (startTime == null || endTime == null || _isInvalidSchedule(startTime, endTime)) {
      return true;
    }

    final scheduleTime = DateConverter.convertStringTimeToDate(dateTime);
    return _isUnderTime(scheduleTime, startTime, endTime);
  }

  static bool _isInvalidSchedule(String start, String end) {
    try {
      final startTime = DateFormat('HH:mm:ss').parse(_normalizeTime(start));
      final endTime = DateFormat('HH:mm:ss').parse(_normalizeTime(end));
      return !startTime.isBefore(endTime);
    } catch (_) {
      return true;
    }
  }

  static String _normalizeTime(String time) {
    return time.length == 5 ? '$time:00' : time;
  }

  static bool _isUnderTime(String current, String start, String end) {
    try {
      final currentTime = DateFormat('HH:mm:ss').parse(_normalizeTime(current));
      final startTime = DateFormat('HH:mm:ss').parse(_normalizeTime(start));
      final endTime = DateFormat('HH:mm:ss').parse(_normalizeTime(end));
      return !currentTime.isBefore(startTime) && !currentTime.isAfter(endTime);
    } catch (_) {
      return false;
    }
  }

  static List<ProviderData> filterBySchedule(List<ProviderData> providers, DateTime scheduleDateTime) {
    return providers.where((p) => isProviderAvailableAtSchedule(p, scheduleDateTime)).toList();
  }
}
