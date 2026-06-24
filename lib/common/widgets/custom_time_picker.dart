import 'package:demandium/common/widgets/time_picker_widget.dart';
import 'package:demandium/util/core_export.dart';
import 'package:get/get.dart';

class CustomTimePicker extends StatelessWidget {
  final TimeOfDay? time;
  final Function(TimeOfDay) onTimeChanged;
  final bool isExpandedRow;

  const CustomTimePicker({
    super.key,
    this.time,
    required this.onTimeChanged,
    this.isExpandedRow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: isExpandedRow ? 50 : 35,
          child: AppTimePickerWidget(
            time: time,
            placeholder: 'time_hint'.tr,
            expanded: isExpandedRow,
            onTimeChanged: onTimeChanged,
          ),
        ),
      ],
    );
  }
}
