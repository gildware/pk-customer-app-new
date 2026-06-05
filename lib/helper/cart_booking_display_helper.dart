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

  static bool isAsapSchedule(DateTime parsed) {
    final now = DateTime.now();
    return parsed.difference(now).inMinutes <= 5 &&
        parsed.isAfter(now.subtract(const Duration(minutes: 1)));
  }

  static bool isCartItemScheduleInPast(CartModel cart) {
    final raw = resolveRawScheduleForCartItem(cart);
    if (raw == null || raw.isEmpty) return false;

    final parsed = DateConverter.tryParseScheduleDateTime(raw);
    if (parsed == null) return false;
    if (isAsapSchedule(parsed)) return false;

    return parsed.isBefore(DateTime.now());
  }

  static bool hasPastScheduleCartItems(Iterable<CartModel> cartItems) {
    for (final cart in cartItems) {
      if (isCartItemScheduleInPast(cart)) return true;
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

    final now = DateTime.now();
    if (parsed.difference(now).inMinutes <= 5 &&
        parsed.isAfter(now.subtract(const Duration(minutes: 1)))) {
      return 'ASAP'.tr;
    }
    return DateConverter.dateOrdinalMonthYearTimeFormat(parsed);
  }

  static String? validateCartItemsForCheckout(Iterable<CartModel> cartItems) {
    for (final cart in cartItems) {
      final raw = resolveRawScheduleForCartItem(cart);
      if (raw == null || raw.isEmpty) {
        return 'select_your_preferable_booking_time';
      }
      final parsed = DateConverter.tryParseScheduleDateTime(raw);
      if (parsed != null &&
          !isAsapSchedule(parsed) &&
          parsed.isBefore(DateTime.now().add(const Duration(hours: 2)))) {
        return 'booking_minimum_two_hours_notice';
      }
      final address = resolveAddressForCartItem(cart);
      if (address == null || (address.address?.trim().isEmpty ?? true)) {
        return 'add_address_first';
      }
      if (!AddressHelper.hasValidContactPerson(address)) {
        return 'please_input_contact_person_name_and_phone_number';
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
