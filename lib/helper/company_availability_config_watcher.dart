import 'dart:convert';

import 'package:demandium/util/core_export.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Keeps company service hours and booking restriction settings in sync with admin.
class CompanyAvailabilityConfigWatcher extends GetxService with WidgetsBindingObserver {
  Timer? _timer;
  bool _isForeground = true;
  bool _isRunning = false;
  String? _lastSignature;

  static const String bookingConfigUpdateId = 'booking_config';
  static const Duration pollInterval = Duration(seconds: 15);

  void start() {
    if (!GetPlatform.isMobile || _isRunning) {
      return;
    }
    _isRunning = true;
    WidgetsBinding.instance.addObserver(this);
    _timer?.cancel();
    _lastSignature = _buildSignature();
    _timer = Timer.periodic(pollInterval, (_) => unawaited(_poll()));
    unawaited(_poll(force: true));
  }

  void stop() {
    if (!_isRunning) {
      return;
    }
    _isRunning = false;
    _timer?.cancel();
    _timer = null;
    WidgetsBinding.instance.removeObserver(this);
    _lastSignature = null;
  }

  Future<void> refreshNow() => _poll(force: true);

  /// Called after [SplashController.refreshConfigFromServer] updates the in-memory config.
  Future<void> onConfigRefreshed() async {
    final current = _buildSignature();
    final changed = _lastSignature == null || _lastSignature != current;
    _lastSignature = current;

    if (changed && Get.isRegistered<SplashController>()) {
      Get.find<SplashController>().update([bookingConfigUpdateId]);
      _applyScheduleAdjustments();
    }

    _refreshCartAndCheckoutUi();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isForeground = state == AppLifecycleState.resumed;
    if (_isForeground) {
      unawaited(_poll(force: true));
    }
  }

  Future<void> _poll({bool force = false}) async {
    if (!_isForeground || !Get.isRegistered<SplashController>()) {
      return;
    }

    final refreshed = await Get.find<SplashController>().refreshConfigFromServer();
    if (!refreshed) {
      _refreshCartAndCheckoutUi();
    }
  }

  String? _buildSignature() {
    final content = Get.find<SplashController>().configModel.content;
    final availability = content?.companyServiceAvailability;
    final advance = content?.advanceBooking;

    return jsonEncode({
      'enabled': availability?.enabled,
      'start_time': availability?.startTime,
      'end_time': availability?.endTime,
      'weekends': availability?.weekends,
      'restriction_value': advance?.advancedBookingRestrictionValue,
      'restriction_type': advance?.advancedBookingRestrictionType,
      'leniency_value': advance?.cartCheckoutLeniencyValue,
      'leniency_type': advance?.cartCheckoutLeniencyType,
      'schedule_booking_time_restriction': content?.scheduleBookingTimeRestriction,
    });
  }

  void _refreshCartAndCheckoutUi() {
    if (Get.isRegistered<CartController>()) {
      Get.find<CartController>().update();
    }
    if (Get.isRegistered<CheckOutController>()) {
      Get.find<CheckOutController>().update();
    }
  }

  void _applyScheduleAdjustments() {
    if (!Get.isRegistered<ScheduleController>()) {
      return;
    }

    final scheduleController = Get.find<ScheduleController>();
    final previousSchedule = scheduleController.scheduleTime;

    if (scheduleController.selectedScheduleType == ScheduleType.asap ||
        scheduleController.initialSelectedScheduleType == ScheduleType.asap) {
      scheduleController.applyAsapScheduleResolution(shouldUpdate: true);

      if (Get.isRegistered<CartController>()) {
        final cartController = Get.find<CartController>();
        if (cartController.pendingBookingSchedule != null &&
            scheduleController.scheduleTime != null) {
          cartController.setPendingBookingSchedule(scheduleController.scheduleTime!);
        }
      }

      if (previousSchedule != null &&
          scheduleController.scheduleTime != null &&
          previousSchedule != scheduleController.scheduleTime) {
        CompanyAvailabilityHelper.notifyIfScheduleAdjusted(
          CompanyScheduleResolution(
            schedule: CompanyAvailabilityHelper.resolveAsapSchedule(),
            wasAdjusted: true,
          ),
          delay: true,
        );
      }
      return;
    }

    final selected = DateConverter.tryParseScheduleDateTime(
      '${scheduleController.selectedDate} ${scheduleController.selectedTime}',
    );
    if (selected == null) {
      scheduleController.update();
      return;
    }

    final resolution = scheduleController.applyCustomScheduleResolution(
      selected,
      notifyIfAdjusted: true,
      shouldUpdate: true,
      delayNotification: true,
    );

    if (Get.isRegistered<CartController>()) {
      final cartController = Get.find<CartController>();
      if (cartController.pendingBookingSchedule != null) {
        cartController.setPendingBookingSchedule(
          DateFormat('yyyy-MM-dd HH:mm:ss').format(resolution.schedule),
        );
      }
    }
  }
}
