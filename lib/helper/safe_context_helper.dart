import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SafeContext {
  static BuildContext? get overlayOrContext => Get.overlayContext ?? Get.context;

  static bool get isAvailable {
    final context = overlayOrContext;
    return context != null && context.mounted;
  }

  static void whenAvailable(void Function(BuildContext context) action) {
    final context = overlayOrContext;
    if (context == null || !context.mounted) return;
    action(context);
  }
}
