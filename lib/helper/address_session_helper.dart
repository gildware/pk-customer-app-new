import 'dart:async';

import 'package:demandium/common/widgets/address_selection_bottom_sheet.dart';
import 'package:demandium/feature/bottomNav/controller/bottom_nav_controller.dart';
import 'package:demandium/feature/home/controller/banner_controller.dart';
import 'package:demandium/feature/home/controller/campaign_controller.dart';
import 'package:demandium/feature/provider/controller/nearby_provider_controller.dart';
import 'package:demandium/feature/provider/controller/provider_booking_controller.dart';
import 'package:demandium/helper/db_helper.dart';
import 'package:get/get.dart';
import 'package:demandium/util/core_export.dart';
import 'package:uuid/uuid.dart';

/// Centralizes customer address validation, picker UX, and session-scoped home data.
class AddressSessionHelper {
  static bool _homeRefreshPending = false;
  static bool _homeRefreshInFlight = false;

  static bool get isHomeRefreshPending => _homeRefreshPending;

  static void markHomeRefreshPending() {
    _homeRefreshPending = true;
  }

  static bool _isMainHomeVisible() {
    if (!Get.isRegistered<BottomNavController>()) return false;
    if (Get.find<BottomNavController>().currentPage != BnbItem.homePage) {
      return false;
    }
    return Get.isDialogOpen != true && Get.isBottomSheetOpen != true;
  }

  static Future<void> performPendingHomeRefresh() async {
    if (!_homeRefreshPending || _homeRefreshInFlight) return;

    _homeRefreshPending = false;
    _homeRefreshInFlight = true;
    try {
      await resetHomeData();
      final reload = HomeScreen.reloadHomeContent;
      if (reload != null) {
        await reload(reload: true);
      } else {
        await HomeScreen.loadData(true);
      }
      if (Get.isRegistered<SplashController>()) {
        Get.find<SplashController>().update(['home_layout']);
      }
    } finally {
      _homeRefreshInFlight = false;
    }
  }

  static Future<void> performPendingHomeRefreshIfHomeVisible() async {
    if (!_homeRefreshPending || !_isMainHomeVisible()) return;
    await performPendingHomeRefresh();
  }

  /// Stored in [AddressModel.addressLabel] for unsaved session addresses.
  static const String currentLocationSourceLabel = 'current_location';
  static const String selectedFromMapSourceLabel = 'selected_from_map';

  static bool isSavedAddress(AddressModel? address) {
    final id = address?.id?.trim();
    return id != null && id.isNotEmpty && id != 'null';
  }

  static bool isCurrentLocationAddress(AddressModel? address) {
    final raw = address?.addressLabel?.trim().toLowerCase() ?? '';
    return raw == currentLocationSourceLabel;
  }

  static bool isSelectedFromMapAddress(AddressModel? address) {
    final raw = address?.addressLabel?.trim().toLowerCase() ?? '';
    return raw == selectedFromMapSourceLabel;
  }

  static String addressLabelKey(AddressModel? address) {
    final raw = address?.addressLabel?.trim().toLowerCase() ?? '';
    if (raw.contains('home')) return 'home';
    if (raw.contains('office')) return 'office';
    return 'others';
  }

  /// Translation key for the dashboard address header label.
  static String? displayAddressLabelKey(AddressModel? address) {
    if (address == null) return null;

    if (isCurrentLocationAddress(address)) {
      return 'header_current_location';
    }
    if (isSelectedFromMapAddress(address)) {
      return 'header_from_map';
    }

    if (!isSavedAddress(address)) return null;

    final raw = address.addressLabel?.trim();
    if (raw == null || raw.isEmpty) return null;
    return addressLabelKey(address);
  }

  static String _localizedLabel(String key, String fallback) {
    final translated = key.tr;
    return translated == key ? fallback : translated;
  }

  /// Resolved header label text (never returns a raw translation key).
  static String? displayAddressLabelText(AddressModel? address) {
    final key = displayAddressLabelKey(address);
    if (key == null) return null;

    switch (key) {
      case 'header_current_location':
        return _localizedLabel(key, 'Current Location');
      case 'header_from_map':
        return _localizedLabel(key, 'From Map');
      default:
        return key.tr;
    }
  }

  static IconData addressLabelIcon(AddressModel? address) {
    switch (addressLabelKey(address)) {
      case 'home':
        return Icons.home_filled;
      case 'office':
        return Icons.work;
      default:
        return Icons.widgets;
    }
  }

  static IconData addressHeaderIcon(AddressModel? address) {
    if (isCurrentLocationAddress(address)) {
      return Icons.my_location;
    }
    if (isSelectedFromMapAddress(address)) {
      return Icons.map_outlined;
    }
    if (!isSavedAddress(address)) {
      return Icons.location_on;
    }
    return addressLabelIcon(address);
  }

  static bool hasValidActiveAddress() {
    final address = Get.find<LocationController>().getUserAddress();
    if (address == null) return false;
    final lat = address.latitude?.trim();
    final lng = address.longitude?.trim();
    return lat != null && lat.isNotEmpty && lng != null && lng.isNotEmpty;
  }

  static bool isServiceableAddress(AddressModel? address) {
    if (address == null) return false;
    final zoneId = address.zoneId?.trim();
    if (zoneId == null || zoneId.isEmpty) return false;
    return (address.availableServiceCountInZone ?? 0) > 0;
  }

  /// Re-validates zone for the saved address. Clears local address when zone lookup fails.
  static Future<bool> validateAndRefreshActiveAddress() async {
    if (!hasValidActiveAddress()) return false;

    final locationController = Get.find<LocationController>();
    final synced = await locationController.refreshSavedAddressZone();
    if (!synced) {
      Get.find<AuthController>().authRepo.clearSharedAddress();
      locationController.clearSessionData();
      return false;
    }

    final address = locationController.getUserAddress();
    return address != null && (address.zoneId?.trim().isNotEmpty ?? false);
  }

  static Future<void> regenerateGuestId() async {
    final guestId = const Uuid().v1();
    await Get.find<SplashController>().setGuestId(guestId);
    try {
      await GuestSessionHelper.regenerateForGuest(guestId);
      await Get.find<ApiClient>().refreshGuestSessionHeaders();
    } catch (_) {}
  }

  static Future<void> resetHomeData() async {
    await DbHelper.clearAllCache();
    if (Get.isRegistered<ServiceController>()) {
      Get.find<ServiceController>().clearSessionData();
    }
    if (Get.isRegistered<BannerController>()) {
      Get.find<BannerController>().clearSessionData();
    }
    if (Get.isRegistered<CategoryController>()) {
      Get.find<CategoryController>().clearSessionData();
    }
    if (Get.isRegistered<CampaignController>()) {
      Get.find<CampaignController>().clearSessionData();
    }
    if (Get.isRegistered<ProviderBookingController>()) {
      Get.find<ProviderBookingController>().clearSessionData();
    }
    if (Get.isRegistered<NearbyProviderController>()) {
      Get.find<NearbyProviderController>().clearSessionData();
    }
    if (Get.isRegistered<SplashController>()) {
      Get.find<SplashController>().update(['home_layout']);
    }
  }

  static Future<void> openAddressPicker({
    bool mandatory = false,
    String? redirectRoute,
  }) async {
    final context = Get.context;
    if (context == null) {
      Get.offNamed(RouteHelper.getAccessLocationRoute('home'));
      return;
    }

    if (ResponsiveHelper.isDesktop(context)) {
      Get.toNamed(RouteHelper.getAccessLocationRoute('home'));
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: !mandatory,
      enableDrag: !mandatory,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (sheetContext) => PopScope(
        canPop: !mandatory,
        child: AddressSelectionBottomSheet(
          mandatory: mandatory,
          redirectRoute: redirectRoute,
        ),
      ),
    );
  }

  static Future<bool> applySelectedAddress(
    AddressModel address, {
    String? redirectRoute,
    bool canRoute = true,
    bool closeOverlays = true,
  }) async {
    final locationController = Get.find<LocationController>();

    if (address.latitude == null ||
        address.longitude == null ||
        address.latitude!.isEmpty ||
        address.longitude!.isEmpty) {
      return false;
    }

    final zoneResponse = await locationController.getZone(
      address.latitude!,
      address.longitude!,
      false,
    );

    address.availableServiceCountInZone = zoneResponse.totalServiceCount;
    if (zoneResponse.isSuccess && zoneResponse.zoneIds.isNotEmpty) {
      address.zoneId = zoneResponse.zoneIds;
    }

    if (!zoneResponse.isSuccess) {
      final message = (zoneResponse.message?.trim().isNotEmpty ?? false)
          ? zoneResponse.message!
          : '500'.tr;
      customSnackBar(message.tr, type: ToasterMessageType.error);
      return false;
    }

    if ((zoneResponse.totalServiceCount ?? 0) <= 0) {
      await locationController.saveUserAddress(address);
      if (closeOverlays && (Get.isDialogOpen == true || Get.isBottomSheetOpen == true)) {
        Get.back();
      }
      Get.offNamed(RouteHelper.getAreaNotServiceableRoute());
      return false;
    }

    if (closeOverlays && (Get.isDialogOpen == true || Get.isBottomSheetOpen == true)) {
      Get.back();
    }
    if (closeOverlays && Get.isBottomSheetOpen == true) {
      Get.back();
    }

    final route = redirectRoute ?? RouteHelper.getMainRoute('home');
    await locationController.saveAddressAndNavigate(
      address,
      false,
      route,
      canRoute,
      true,
      showDialog: 'false',
      resolvedZone: zoneResponse,
    );

    if (canRoute) {
      await resetHomeData();
      await HomeScreen.loadData(true);
    } else {
      markHomeRefreshPending();
      await performPendingHomeRefreshIfHomeVisible();
    }
    return true;
  }

  /// Returns false when navigation was redirected (e.g. non-serviceable screen).
  static Future<bool> ensureAddressBeforeContinue() async {
    if (!hasValidActiveAddress()) {
      return true;
    }

    final valid = await validateAndRefreshActiveAddress();
    if (!valid) {
      return true;
    }

    if (!isServiceableAddress(Get.find<LocationController>().getUserAddress())) {
      Get.offAllNamed(RouteHelper.getAreaNotServiceableRoute());
      return false;
    }

    return true;
  }

  /// Returns true when navigation was already handled (picker, home, or not-serviceable screen).
  static Future<bool> navigateAfterAuth({String? redirectRoute}) async {
    final locationController = Get.find<LocationController>();
    final route = redirectRoute ?? RouteHelper.getMainRoute('home');
    await locationController.getAddressList();

    if (hasValidActiveAddress()) {
      final valid = await validateAndRefreshActiveAddress();
      if (valid && isServiceableAddress(locationController.getUserAddress())) {
        await resetHomeData();
        markHomeRefreshPending();
        return false;
      }
      if (valid && !isServiceableAddress(locationController.getUserAddress())) {
        Get.offAllNamed(RouteHelper.getAreaNotServiceableRoute());
        return true;
      }
    }

    final savedAddresses = locationController.addressList;
    if (Get.find<AuthController>().isLoggedIn() &&
        savedAddresses != null &&
        savedAddresses.isNotEmpty) {
      if (savedAddresses.length == 1) {
        await applySelectedAddress(
          savedAddresses.first,
          redirectRoute: route,
          canRoute: true,
          closeOverlays: false,
        );
        return true;
      }

      final preferred = pickPreferredSavedAddress(savedAddresses);
      if (preferred != null && hasValidActiveAddress()) {
        await applySelectedAddress(
          preferred,
          redirectRoute: route,
          canRoute: true,
          closeOverlays: false,
        );
        return true;
      }
    }

    await openAddressPicker(mandatory: true, redirectRoute: route);
    return true;
  }

  /// Runs [whenReady] when a valid serviceable address exists; otherwise opens the picker or non-serviceable screen.
  static Future<void> requireAddressForNavigation({
    required String redirectRoute,
    required VoidCallback whenReady,
  }) async {
    if (!hasValidActiveAddress()) {
      await openAddressPicker(mandatory: true, redirectRoute: redirectRoute);
      return;
    }

    final valid = await validateAndRefreshActiveAddress();
    if (!valid) {
      await openAddressPicker(mandatory: true, redirectRoute: redirectRoute);
      return;
    }

    if (!isServiceableAddress(Get.find<LocationController>().getUserAddress())) {
      Get.toNamed(RouteHelper.getAreaNotServiceableRoute());
      return;
    }

    whenReady();
  }

  /// Prefer the saved address that matches the active local id, otherwise the first list item.
  static AddressModel? pickPreferredSavedAddress(List<AddressModel> addresses) {
    if (addresses.isEmpty) return null;
    final activeId = Get.find<LocationController>().getUserAddress()?.id;
    if (activeId != null) {
      for (final address in addresses) {
        if (address.id == activeId) return address;
      }
    }
    return addresses.first;
  }

  static Future<void> promptUseNewAddress(AddressModel address) async {
    if (!Get.context!.mounted) return;

    Get.dialog(
      ConfirmationDialog(
        icon: Images.mapLocation,
        title: 'use_this_address_for_services'.tr,
        description: address.address,
        onYesPressed: () async {
          Get.back();
          await applySelectedAddress(
            address,
            redirectRoute: null,
            canRoute: false,
            closeOverlays: false,
          );
          customSnackBar('new_address_added_successfully'.tr, type: ToasterMessageType.success);
        },
        onNoPressed: () {
          Get.back();
          customSnackBar('new_address_added_successfully'.tr, type: ToasterMessageType.success);
        },
      ),
      barrierDismissible: true,
    );
  }
}
