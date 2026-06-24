import 'package:demandium/util/core_export.dart';
import 'package:get/get.dart';

class CartBookingDisplayHelper {
  static AddressModel? resolveAddressForCartItem(CartModel cart) {
    if (cart.serviceAddress != null) {
      return AddressHelper.ensureContactPerson(cart.serviceAddress!);
    }

    final addressId = cart.serviceAddressId;
    if (addressId == null || addressId.isEmpty) return null;

    final locationController = Get.find<LocationController>();
    for (final address in locationController.addressList ?? []) {
      if (address.id?.toString() == addressId) {
        return AddressHelper.ensureContactPerson(address);
      }
    }

    final selected = locationController.selectedAddress;
    if (selected?.id?.toString() == addressId) {
      return AddressHelper.ensureContactPerson(selected!);
    }

    return null;
  }

  static String? resolveItemOwnSchedule(CartModel cart) {
    final itemSchedule = cart.serviceSchedule?.trim();
    if (itemSchedule == null || itemSchedule.isEmpty) return null;
    return itemSchedule;
  }

  static String? resolveRawScheduleForCartItem(CartModel cart) {
    final own = resolveItemOwnSchedule(cart);
    if (own != null) return own;

    final fallback = Get.find<CartController>().cartServiceInfo?.serviceSchedule?.trim();
    if (fallback != null && fallback.isNotEmpty) return fallback;

    return null;
  }

  static String formatAsapWithDateTime(DateTime parsed) {
    return '${'ASAP'.tr} (${DateConverter.dateMonthYearTimeTwentyFourFormat(parsed)})';
  }

  static bool isAsapBookingSchedule(String raw, DateTime parsed) {
    if (Get.isRegistered<CartController>()) {
      final info = Get.find<CartController>().cartServiceInfo;
      final storedSchedule = info?.serviceSchedule?.trim();
      if (info?.isAsapBooking == true &&
          storedSchedule != null &&
          storedSchedule.isNotEmpty &&
          storedSchedule == raw.trim()) {
        return true;
      }
    }
    return isAsapSchedule(parsed);
  }

  static bool isAsapSchedule(DateTime parsed) {
    return CompanyAvailabilityHelper.isAsapSchedule(parsed);
  }

  static bool isCartItemScheduleInPast(CartModel cart) {
    final raw = resolveRawScheduleForCartItem(cart);
    if (raw == null || raw.isEmpty) return false;

    final parsed = DateConverter.tryParseScheduleDateTime(raw);
    if (parsed == null) return false;
    if (isAsapSchedule(parsed)) return false;

    return parsed.isBefore(DateTime.now());
  }

  static bool isCartItemScheduleBelowRestriction(CartModel cart) {
    final raw = resolveRawScheduleForCartItem(cart);
    if (raw == null || raw.isEmpty) return false;

    final parsed = DateConverter.tryParseScheduleDateTime(raw);
    if (parsed == null) return false;
    if (isAsapSchedule(parsed)) return false;

    return !CompanyAvailabilityHelper.isSelectableBookingTimeForCartCheckout(parsed);
  }

  static bool isCartItemScheduleInvalid(CartModel cart) {
    return isCartItemScheduleInPast(cart) || isCartItemScheduleBelowRestriction(cart);
  }

  static String invalidScheduleMessageForCartItem(CartModel cart) {
    final raw = resolveRawScheduleForCartItem(cart);
    final parsed = raw != null ? DateConverter.tryParseScheduleDateTime(raw) : null;
    if (parsed != null && !isAsapSchedule(parsed)) {
      if (parsed.isBefore(DateTime.now())) {
        return 'cart_schedule_past_message'.tr;
      }
      if (!CompanyAvailabilityHelper.isSelectableBookingTimeForCartCheckout(parsed)) {
        if (!CompanyAvailabilityHelper.isWithinCompanyHours(parsed)) {
          return CompanyAvailabilityHelper.outsideHoursMessage() ??
              'company_service_outside_hours_notice'.tr;
        }
        final day = DateTime(parsed.year, parsed.month, parsed.day);
        return CompanyAvailabilityHelper.allowedTimeRangeMessageForCartCheckoutDay(day);
      }
    }
    return CompanyAvailabilityHelper.minimumCartCheckoutLeadTimeMessage();
  }

  static bool hasPastScheduleCartItems(Iterable<CartModel> cartItems) {
    return hasInvalidScheduleCartItems(cartItems);
  }

  static bool hasInvalidScheduleCartItems(Iterable<CartModel> cartItems) {
    for (final cart in cartItems) {
      if (isCartItemScheduleInvalid(cart)) return true;
    }
    return false;
  }

  static String? resolveScheduleLabelForCartItem(CartModel cart) {
    final raw = resolveRawScheduleForCartItem(cart);
    if (raw == null || raw.isEmpty) return null;
    return _formatSchedule(raw);
  }

  static String? _formatSchedule(String raw) {
    final parsed = DateConverter.tryParseScheduleDateTime(raw);
    if (parsed == null) return raw;

    if (isAsapBookingSchedule(raw, parsed)) {
      return formatAsapWithDateTime(parsed);
    }
    return DateConverter.dateOrdinalMonthYearTimeFormat(parsed);
  }

  static String? validateCartItemsForCheckout(Iterable<CartModel> cartItems) {
    for (final cart in cartItems) {
      final raw = resolveRawScheduleForCartItem(cart);
      if (raw == null || raw.isEmpty) {
        return 'select_your_preferable_booking_time'.tr;
      }
      final parsed = DateConverter.tryParseScheduleDateTime(raw);
      if (parsed != null &&
          !isAsapSchedule(parsed) &&
          !CompanyAvailabilityHelper.isSelectableBookingTimeForCartCheckout(parsed)) {
        if (!CompanyAvailabilityHelper.isWithinCompanyHours(parsed)) {
          final resolution = CompanyAvailabilityHelper.resolveCustomSchedule(parsed);
          return CompanyAvailabilityHelper.outsideHoursRescheduledMessage(resolution.schedule) ??
              CompanyAvailabilityHelper.outsideHoursMessage() ??
              'company_service_outside_hours_notice'.tr;
        }
        final day = DateTime(parsed.year, parsed.month, parsed.day);
        return CompanyAvailabilityHelper.allowedTimeRangeMessageForCartCheckoutDay(day);
      }
      if (parsed != null &&
          !isAsapSchedule(parsed) &&
          parsed.isBefore(DateTime.now())) {
        return 'cart_schedule_past_message'.tr;
      }
      final address = resolveAddressForCartItem(cart);
      if (address == null || (address.address?.trim().isEmpty ?? true)) {
        return 'add_address_first'.tr;
      }
      if (!AddressHelper.hasValidContactPerson(address)) {
        return 'please_input_contact_person_name_and_phone_number'.tr;
      }
    }
    return null;
  }

  static String? addressSubtitle(AddressModel? address) {
    if (address == null) return null;
    final parts = <String>[];
    if (address.addressLabel != null && address.addressLabel!.isNotEmpty) {
      parts.add(address.addressLabel!);
    }
    if (AddressHelper.hasValidContactPerson(address)) {
      parts.add('${address.contactPersonName} · ${address.contactPersonNumber}');
    }
    return parts.isEmpty ? null : parts.join(' · ');
  }
}
