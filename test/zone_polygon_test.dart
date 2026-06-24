import 'dart:convert';
import 'dart:io';

import 'package:demandium/feature/area/model/zone_model.dart';
import 'package:demandium/helper/map_bound_helper.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

Future<List<ZoneModel>> fetchZones(String baseUrl) async {
  final client = HttpClient();
  final req = await client.postUrl(Uri.parse(
    '$baseUrl/api/v1/customer/service/area-availability?offset=1&limit=200',
  ));
  req.headers.set('content-type', 'application/json');
  req.write('{}');
  final res = await req.close();
  final body = await res.transform(utf8.decoder).join();
  final json = jsonDecode(body) as Map<String, dynamic>;
  final zones = (json['content'] as Map)['data'] as List;
  return zones.map((zone) => ZoneModel.fromJson(zone as Map<String, dynamic>)).toList();
}

void assertPickable(String label, LatLng point, List<ZoneModel> zones, bool expected) {
  final operational = MapHelper.operationalZones(zones);
  final inside = MapHelper.isPointInsideOperationalZones(point, zones);
  final status = inside ? 'PICKABLE' : 'BLOCKED';
  final ok = inside == expected;
  print('${ok ? 'PASS' : 'FAIL'} | $label | $status | operationalZones=${operational.map((z) => z.name).join(', ')}');
  if (!ok) {
    throw StateError('$label expected ${expected ? 'pickable' : 'blocked'} but was $status');
  }
}

Future<void> main(List<String> args) async {
  final baseUrl = args.isNotEmpty ? args.first : 'https://dev.panunkaergar.com';
  print('Testing against $baseUrl\n');

  final zones = await fetchZones(baseUrl);
  print('Total zones: ${zones.length}');
  print('Operational zones: ${MapHelper.operationalZones(zones).map((z) => z.name).join(', ')}\n');

  if (baseUrl.contains('dev.panunkaergar.com')) {
    assertPickable('Tulip Garden (inside Srinagar)', const LatLng(34.1285, 74.8735), zones, true);
    assertPickable('Srinagar center', const LatLng(34.0837, 74.7973), zones, true);
    assertPickable('Pulwama (outside Srinagar polygon)', const LatLng(33.8740, 74.8997), zones, false);
    assertPickable('Tahab (outside Srinagar polygon)', const LatLng(33.72, 74.95), zones, false);
  } else {
    assertPickable('Srinagar center', const LatLng(34.0837, 74.7973), zones, true);
    assertPickable('Pulwama district leaf zone', const LatLng(33.8740, 74.8997), zones, true);
  }

  print('\nAll pick-map polygon checks passed.');
}
