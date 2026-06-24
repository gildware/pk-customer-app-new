import 'package:demandium/theme/time_picker_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

Future<TimeOfDay?> showCustomTimePicker({TimeOfDay? initialTime}) async {
  final context = Get.context;
  if (context == null) return null;

  final brightness = Theme.of(context).brightness;
  final baseScheme = Theme.of(context).colorScheme;

  return showTimePicker(
    context: context,
    initialTime: initialTime ?? TimeOfDay.fromDateTime(DateTime.now()),
    builder: (pickerContext, child) {
      return Theme(
        data: Theme.of(pickerContext).copyWith(
          timePickerTheme: AppTimePickerTheme.forBrightness(brightness),
          colorScheme: AppTimePickerTheme.colorSchemeFor(brightness, baseScheme),
        ),
        child: MediaQuery(
          data: MediaQuery.of(pickerContext).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        ),
      );
    },
  );
}
