import 'package:demandium/common/widgets/time_picker_widget.dart';
import 'package:demandium/util/core_export.dart';
import 'package:get/get.dart';

class ScheduleTimePicker extends StatelessWidget {
  const ScheduleTimePicker({super.key});

  TimeOfDay? _selectedTime(ScheduleController scheduleController) {
    final parsed = DateConverter.tryParseScheduleDateTime(
      '${scheduleController.selectedDate} ${scheduleController.selectedTime}',
    );
    if (parsed == null) return null;
    return TimeOfDay(hour: parsed.hour, minute: parsed.minute);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      child: Row(
        children: [
          Text(
            'time'.tr,
            style: robotoBold.copyWith(
              fontSize: Dimensions.fontSizeLarge,
              color: Get.isDarkMode
                  ? Theme.of(context).textTheme.bodyMedium?.color
                  : Theme.of(Get.context!).colorScheme.primary,
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeLarge),
          GetBuilder<ScheduleController>(builder: (scheduleController) {
            return Expanded(
              child: AppTimePickerWidget(
                key: ValueKey(
                  '${scheduleController.selectedDate}_${scheduleController.selectedTime}',
                ),
                time: _selectedTime(scheduleController),
                placeholder: 'pick_time'.tr,
                onTimeChanged: (time) {
                  scheduleController.selectedTime =
                      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
                  scheduleController.updateScheduleType(scheduleType: ScheduleType.schedule);
                  scheduleController.update();
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}
