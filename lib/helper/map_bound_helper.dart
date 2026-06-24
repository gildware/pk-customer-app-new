import 'dart:collection';

import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:demandium/feature/location/controller/location_controller.dart';
import 'package:demandium/feature/splash/controller/splash_controller.dart';
import 'package:demandium/feature/address/model/address_model.dart';
import 'package:demandium/feature/provider/model/provider_model.dart';
import 'package:demandium/feature/area/model/zone_model.dart';

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

  static List<LatLng> latLngListFromZone(ZoneModel zone) {
    final coordinates = zone.formattedCoordinates;
    if (coordinates == null || coordinates.isEmpty) {
      return [];
    }
    return coordinates
        .where((c) => c.latitude != null && c.longitude != null)
        .map((c) => LatLng(c.latitude!, c.longitude!))
        .toList();
  }

  /// Zones drawn on a huge area (e.g. "All over the World") must not define pickable service area.
  static bool isCatchAllZone(ZoneModel zone) {
    final polygon = latLngListFromZone(zone);
    if (polygon.length < 3) {
      return true;
    }
    final bounds = boundsFromLatLngList(polygon);
    final latSpan = (bounds.northeast.latitude - bounds.southwest.latitude).abs();
    final lngSpan = (bounds.northeast.longitude - bounds.southwest.longitude).abs();
    return latSpan > 10 || lngSpan > 10;
  }

  /// Leaf / local zones used for map shading and pick validation (excludes parent + world zones).
  static List<ZoneModel> operationalZones(List<ZoneModel> zones) {
    if (zones.isEmpty) {
      return zones;
    }

    final parentIds = zones
        .map((zone) => zone.id)
        .whereType<String>()
        .where((id) => zones.any((other) => other.id != id && other.parentId == id))
        .toSet();

    final operational = zones.where((zone) {
      if (isCatchAllZone(zone)) {
        return false;
      }
      final zoneId = zone.id;
      if (zoneId != null && parentIds.contains(zoneId)) {
        return false;
      }
      return latLngListFromZone(zone).length >= 3;
    }).toList();

    return operational.isEmpty
        ? zones.where((zone) => !isCatchAllZone(zone) && latLngListFromZone(zone).length >= 3).toList()
        : operational;
  }

  static bool isPointInsideOperationalZones(LatLng point, List<ZoneModel> zones) {
    return isPointInsideAnyZone(point, operationalZones(zones));
  }

  static Set<Polygon> polygonsFromZones(List<ZoneModel> zones) {
    final polygonList = <Polygon>[];
    final drawableZones = operationalZones(zones);
    for (int index = 0; index < drawableZones.length; index++) {
      final points = latLngListFromZone(drawableZones[index]);
      if (points.length < 3) {
        continue;
      }
      polygonList.add(
        Polygon(
          polygonId: PolygonId('zone_$index'),
          points: points,
          strokeWidth: 2,
          strokeColor: Get.theme.colorScheme.primary,
          fillColor: Get.theme.colorScheme.primary.withValues(alpha: .2),
        ),
      );
    }
    return HashSet<Polygon>.of(polygonList);
  }

  static bool isPointInsidePolygon(LatLng point, List<LatLng> polygon) {
    if (polygon.length < 3) {
      return false;
    }

    bool inside = false;
    for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      final latI = polygon[i].latitude;
      final lngI = polygon[i].longitude;
      final latJ = polygon[j].latitude;
      final lngJ = polygon[j].longitude;

      final intersects = ((latI > point.latitude) != (latJ > point.latitude)) &&
          (point.longitude <
              (lngJ - lngI) * (point.latitude - latI) / (latJ - latI + 0.0) + lngI);
      if (intersects) {
        inside = !inside;
      }
    }
    return inside;
  }

  static bool isPointInsideAnyZone(LatLng point, List<ZoneModel> zones) {
    for (final zone in zones) {
      final polygon = latLngListFromZone(zone);
      if (isPointInsidePolygon(point, polygon)) {
        return true;
      }
    }
    return false;
  }

  static List<List<LatLng>> polygonsFromZoneModels(List<ZoneModel> zones) {
    return operationalZones(zones)
        .map(latLngListFromZone)
        .where((polygon) => polygon.length >= 3)
        .toList();
  }

}