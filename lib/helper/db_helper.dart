
import 'package:demandium/api/local/cache_response.dart';
import 'package:demandium/helper/get_di.dart';
import 'package:flutter/foundation.dart';

class DbHelper{
  static Future<void> insertOrUpdate({required String id, required CacheResponseCompanion data}) async {
    try {
      final response = await database.getCacheResponseById(id);

      if(response != null){
        await database.updateCacheResponse(id, data);
      }else{
        await database.insertCacheResponse(data);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('DbHelper.insertOrUpdate skipped ($e)');
      }
    }
  }

  static Future<void> deleteByEndPoint(String endPoint) async {
    try {
      await database.deleteCacheResponseByEndPoint(endPoint);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('DbHelper.deleteByEndPoint skipped ($e)');
      }
    }
  }

  static Future<void> clearAllCache() async {
    try {
      await database.clearCacheResponses();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('DbHelper.clearAllCache skipped ($e)');
      }
    }
  }

  /// Removes pre-zone cache keys (URI only) left from older app versions.
  static Future<void> clearLegacyUriOnlyCache() async {
    try {
      final entries = await database.getAllCacheResponses();
      for (final entry in entries) {
        if (!entry.endPoint.contains('::zone:')) {
          await database.deleteCacheResponseByEndPoint(entry.endPoint);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('DbHelper.clearLegacyUriOnlyCache skipped ($e)');
      }
    }
  }

  static Future<void> clearCacheOnZoneChange({String? previousZoneId, String? newZoneId}) async {
    try {
      final prev = previousZoneId?.trim() ?? '';
      final next = newZoneId?.trim() ?? '';

      if (prev.isNotEmpty && next.isNotEmpty && prev != next) {
        await clearAllCache();
        return;
      }

      if (next.isNotEmpty) {
        await clearLegacyUriOnlyCache();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('DbHelper.clearCacheOnZoneChange skipped ($e)');
      }
    }
  }
}
