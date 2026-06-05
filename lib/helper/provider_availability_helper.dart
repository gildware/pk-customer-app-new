import 'package:demandium/util/core_export.dart';
import 'package:intl/intl.dart';

class ProviderAvailabilityHelper {
  static bool isProviderAvailableAtSchedule(ProviderData provider, DateTime scheduleDateTime) {
    if (provider.serviceAvailability != 1 || provider.isActive != 1) {
      return false;
    }
    if (provider.nextBookingEligibility == false) {
      return false;
    }

    final weekends = provider.weekends ?? [];
    final dayOfWeek = DateConverter.dateToWeek(scheduleDateTime).toLowerCase();
    if (weekends.contains(dayOfWeek)) {
      return false;
    }

    final timeSchedule = provider.timeSchedule;
    if (timeSchedule?.startTime == null || timeSchedule?.endTime == null) {
      return true;
    }

    final scheduleTime = DateConverter.convertStringTimeToDate(scheduleDateTime);
    return _isUnderTime(scheduleTime, timeSchedule!.startTime!, timeSchedule.endTime!);
  }

  static bool _isUnderTime(String current, String start, String end) {
    try {
      final currentTime = DateFormat('HH:mm:ss').parse(current);
      final startTime = DateFormat('HH:mm:ss').parse(start);
      final endTime = DateFormat('HH:mm:ss').parse(end);
      return !currentTime.isBefore(startTime) && !currentTime.isAfter(endTime);
    } catch (_) {
      return false;
    }
  }

  static List<ProviderData> filterBySchedule(List<ProviderData> providers, DateTime scheduleDateTime) {
    return providers.where((p) => isProviderAvailableAtSchedule(p, scheduleDateTime)).toList();
  }
}
