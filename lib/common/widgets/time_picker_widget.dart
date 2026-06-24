import 'package:demandium/common/widgets/show_custom_time_picker.dart';
import 'package:demandium/util/core_export.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class AppTimePickerWidget extends StatefulWidget {
  final TimeOfDay? time;
  final String placeholder;
  final ValueChanged<TimeOfDay> onTimeChanged;
  final bool expanded;

  const AppTimePickerWidget({
    super.key,
    this.time,
    this.placeholder = '',
    required this.onTimeChanged,
    this.expanded = true,
  });

  static String format12Hour(TimeOfDay time) {
    final dateTime = DateTime(1970, 1, 1, time.hour, time.minute);
    return DateFormat('h:mm a').format(dateTime);
  }

  @override
  State<AppTimePickerWidget> createState() => _AppTimePickerWidgetState();
}

class _AppTimePickerWidgetState extends State<AppTimePickerWidget> {
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _selectedTime = widget.time;
  }

  @override
  void didUpdateWidget(covariant AppTimePickerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.time != oldWidget.time) {
      _selectedTime = widget.time;
    }
  }

  @override
  Widget build(BuildContext context) {
    final placeholder = widget.placeholder.isNotEmpty ? widget.placeholder : 'pick_time'.tr;

    return InkWell(
      onTap: () async {
        final picked = await showCustomTimePicker(initialTime: _selectedTime);
        if (picked == null) return;
        setState(() => _selectedTime = picked);
        widget.onTimeChanged(picked);
      },
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
          border: Border.all(
            color: Theme.of(context).textTheme.bodySmall!.color!.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _selectedTime != null
                    ? AppTimePickerWidget.format12Hour(_selectedTime!)
                    : placeholder,
                style: robotoRegular.copyWith(
                  color: _selectedTime != null ? null : Theme.of(context).hintColor,
                ),
                maxLines: 1,
              ),
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Icon(
              Icons.access_time,
              size: 20,
              color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
