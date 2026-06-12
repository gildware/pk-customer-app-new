import 'dart:ui';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class ErrorLogger {
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (kIsWeb || _initialized) return;
    _initialized = true;

    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode);

    final defaultOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      defaultOnError?.call(details);
      record(
        details.exception,
        details.stack,
        reason: details.context?.toString(),
        fatal: true,
      );
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      record(error, stack, fatal: true);
      return true;
    };
  }

  static void record(
    Object error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) {
    if (kDebugMode) {
      debugPrint('ErrorLogger${reason != null ? ' ($reason)' : ''}: $error');
      if (stack != null) debugPrint(stack.toString());
    }
    if (kIsWeb) return;
    try {
      FirebaseCrashlytics.instance.recordError(
        error,
        stack ?? StackTrace.current,
        reason: reason,
        fatal: fatal,
      );
    } catch (_) {}
  }

  static void log(String message) {
    if (kDebugMode) debugPrint('ErrorLogger: $message');
    if (kIsWeb) return;
    try {
      FirebaseCrashlytics.instance.log(message);
    } catch (_) {}
  }
}
