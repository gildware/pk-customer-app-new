import 'package:demandium/util/app_constants.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// Resolves [AppConstants.baseUrl] for the current runtime (e.g. Android emulator host).
class ApiUrlHelper {
  /// Android emulators cannot reach the host via 127.0.0.1; use 10.0.2.2 instead.
  static String resolveBaseUrl([String? base]) {
    final resolved = (base ?? AppConstants.baseUrl).trim();
    if (kDebugMode && GetPlatform.isAndroid && resolved.contains('127.0.0.1')) {
      return resolved.replaceFirst('127.0.0.1', '10.0.2.2');
    }
    return resolved;
  }
}
