import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:demandium/feature/location/controller/location_controller.dart';
import 'package:demandium/feature/splash/controller/splash_controller.dart';
import 'package:demandium/feature/address/model/address_model.dart';
import 'package:demandium/feature/provider/model/provider_model.dart';

class MapHelper {
  /// Resolves a valid map camera target (never 0,0 unless that is intentional).
  static LatLng resolveMapTarget({
    required bool usePickPosition,
    LatLng? fallback,
  }) {
    final locationController = Get.find<LocationController>();
    final position = usePickPosition ? locationController.pickPosition : locationController.position;

    if (position.latitude != 0 || position.longitude != 0) {
      return LatLng(position.latitude, position.longitude);
    }

    if (fallback != null && (fallback.latitude != 0 || fallback.longitude != 0)) {
      return fallback;
    }

    final userAddress = locationController.getUserAddress();
    final userLat = double.tryParse(userAddress?.latitude ?? '');
    final userLng = double.tryParse(userAddress?.longitude ?? '');
    if (userLat != null && userLng != null && (userLat != 0 || userLng != 0)) {
      return LatLng(userLat, userLng);
    }

    final defaultLocation = Get.find<SplashController>().configModel.content?.defaultLocation;
    return LatLng(
      defaultLocation?.latitude ?? 23.0,
      defaultLocation?.longitude ?? 90.0,
    );
  }

  static bool isValidLatLng(LatLng latLng) {
    return latLng.latitude != 0 || latLng.longitude != 0;
  }

  static LatLngBounds boundsFromLatLngList(List<LatLng> list) {
    double? x0, x1, y0, y1;
    for (LatLng latLng in list) {
      if (x0 == null) {
        x0 = x1 = latLng.latitude;
        y0 = y1 = latLng.longitude;
      } else {
        if (latLng.latitude > x1!) x1 = latLng.latitude;
        if (latLng.latitude < x0) x0 = latLng.latitude;
        if (latLng.longitude > y1!) y1 = latLng.longitude;
        if (latLng.longitude < y0!) y0 = latLng.longitude;
      }
    }
    return LatLngBounds(northeast: LatLng(x1 ?? 0, y1 ?? 0), southwest: LatLng(x0 ?? 0, y0 ?? 0));
  }

  static double getDistanceBetweenUserCurrentLocationAndProvider(AddressModel userCurrentAddress, ProviderData providerModel){

    double userLat = double.tryParse(userCurrentAddress.latitude ?? "0.00") ?? 0.0 ;
    double userLon = double.tryParse(userCurrentAddress.longitude ?? "0.00") ?? 0.0 ;

    double providerLat = providerModel.coordinates?.latitude ?? 0.0 ;
    double providerLon = providerModel.coordinates?.longitude ?? 0.0 ;

    return  Geolocator.distanceBetween(userLat, userLon, providerLat, providerLon)/1000;
  }


}