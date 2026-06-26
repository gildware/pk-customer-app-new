import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

bool _navigationLocked = false;

/// Defers [action] until after the current frame so Navigator is not locked.
void runAfterFrame(void Function() action) {
  SchedulerBinding.instance.addPostFrameCallback((_) {
    action();
  });
}

/// Ignores rapid repeat navigation while a route change is in progress.
void safeNavigate(void Function() action) {
  if (_navigationLocked) {
    return;
  }

  runAfterFrame(() {
    if (_navigationLocked) {
      return;
    }
    _navigationLocked = true;
    try {
      action();
    } finally {
      Future.delayed(const Duration(milliseconds: 350), () {
        _navigationLocked = false;
      });
    }
  });
}

/// Closes an open overlay route first, then runs [action] on the next frame.
void closeOverlayThen(void Function() action) {
  if (Get.isBottomSheetOpen == true || Get.isDialogOpen == true) {
    Get.back();
  }
  safeNavigate(action);
}

/// Closes the current overlay (drawer, sheet, or dialog), then navigates safely.
void closeRouteThen(void Function() action) {
  if (Get.key.currentState?.canPop() ?? false) {
    Get.back();
  }
  safeNavigate(action);
}
