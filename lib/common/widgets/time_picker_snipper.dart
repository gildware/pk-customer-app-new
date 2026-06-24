import 'package:demandium/util/core_export.dart';
import 'dart:math';

class ItemScrollPhysics extends ScrollPhysics {
  final double? itemHeight;
  final double targetPixelsLimit;

  const ItemScrollPhysics({
    super.parent,
    this.itemHeight,
    this.targetPixelsLimit = 3.0,
  })  : assert(itemHeight != null && itemHeight > 0);

  @override
  ItemScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return ItemScrollPhysics(
        parent: buildParent(ancestor), itemHeight: itemHeight);
  }

  double _getItem(ScrollPosition position) {
    double maxScrollItem =
    (position.maxScrollExtent / itemHeight!).floorToDouble();
    return min(max(0, position.pixels / itemHeight!), maxScrollItem);
  }

  double _getPixels(ScrollPosition position, double item) {
    return item * itemHeight!;
  }

  double _getTargetPixels(
      ScrollPosition position, Tolerance tolerance, double velocity) {
    double item = _getItem(position);
    if (velocity < -tolerance.velocity) {
      item -= targetPixelsLimit;
    } else if (velocity > tolerance.velocity) {
      item += targetPixelsLimit;
    }
    return _getPixels(position, item.roundToDouble());
  }

  @override
  Simulation? createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    Tolerance tolerance = const Tolerance();
    final double target =
    _getTargetPixels(position as ScrollPosition, tolerance, velocity);
    if (target != position.pixels) {
      return ScrollSpringSimulation(spring, position.pixels, target, velocity,
          tolerance: tolerance);
    }
    return null;
  }

  @override
  bool get allowImplicitScrolling => false;
}

typedef SelectedIndexCallback = void Function(int);
typedef TimePickerCallback = void Function(DateTime);

enum _SpinnerColumn { hour, minute, second }



class TimePickerSpinner extends StatefulWidget {
  final DateTime? time;
  final int minutesInterval;
  final int secondsInterval;
  final bool is24HourMode;
  final bool isShowSeconds;
  final TextStyle? highlightedTextStyle;
  final TextStyle? normalTextStyle;
  final TextStyle? disabledTextStyle;
  final double? itemHeight;
  final double? itemWidth;
  final AlignmentGeometry? alignment;
  final double? spacing;
  final bool isForce2Digits;
  final DateTime? minSelectableTime;
  final DateTime? maxSelectableTime;
  final bool restrictToAllowedRange;
  final TimePickerCallback? onTimeChange;

  const TimePickerSpinner(
      {super.key,
        this.time,
        this.minutesInterval = 1,
        this.secondsInterval = 1,
        this.is24HourMode = true,
        this.isShowSeconds = false,
        this.highlightedTextStyle,
        this.normalTextStyle,
        this.disabledTextStyle,
        this.itemHeight,
        this.itemWidth,
        this.alignment,
        this.spacing,
        this.isForce2Digits = false,
        this.minSelectableTime,
        this.maxSelectableTime,
        this.restrictToAllowedRange = true,
        this.onTimeChange})
      ;

  @override
  TimePickerSpinnerState createState() => TimePickerSpinnerState();
}

class TimePickerSpinnerState extends State<TimePickerSpinner> {
  late ScrollController hourController;
  late ScrollController minuteController;
  late ScrollController secondController;
  late ScrollController apController;
  int currentSelectedHourIndex = -1;
  int currentSelectedMinuteIndex = -1;
  int currentSelectedSecondIndex = -1;
  int currentSelectedAPIndex = -1;
  DateTime? currentTime;
  bool isHourScrolling = false;
  bool isMinuteScrolling = false;
  bool isSecondsScrolling = false;
  bool isAPScrolling = false;

  TextStyle defaultHighlightTextStyle =
  const TextStyle(fontSize: 32, color: Colors.black);
  TextStyle defaultNormalTextStyle =
  const TextStyle(fontSize: 32, color: Colors.black54);
  double defaultItemHeight = 60;
  double defaultItemWidth = 45;
  double defaultSpacing = 20;
  AlignmentGeometry defaultAlignment = Alignment.centerRight;

  TextStyle? _getHighlightedTextStyle() {
    return widget.highlightedTextStyle ?? defaultHighlightTextStyle;
  }

  TextStyle? _getNormalTextStyle() {
    return widget.normalTextStyle ?? defaultNormalTextStyle;
  }

  TextStyle? _getDisabledTextStyle() {
    return widget.disabledTextStyle ??
        _getNormalTextStyle()?.copyWith(
          color: (_getNormalTextStyle()?.color ?? Colors.black54).withValues(alpha: 0.25),
        );
  }

  DateTime _dateOnSameDay(int hour, int minute, [int second = 0]) {
    return DateTime(
      currentTime!.year,
      currentTime!.month,
      currentTime!.day,
      hour,
      minute,
      second,
    );
  }

  bool _isSelectable(DateTime value) {
    if (!widget.restrictToAllowedRange) {
      return true;
    }
    final min = widget.minSelectableTime;
    final max = widget.maxSelectableTime;
    if (min != null && value.isBefore(min)) {
      return false;
    }
    if (max != null && value.isAfter(max)) {
      return false;
    }
    return true;
  }

  bool _isHourIndexSelectable(int index, int max, int interval) {
    for (var minute = 0; minute < 60; minute += widget.minutesInterval) {
      final candidate = _dateTimeForSpinnerIndex(
        hourIndex: index,
        minuteIndex: currentSelectedMinuteIndex,
        secondIndex: currentSelectedSecondIndex,
        hourMax: max,
        minuteOverride: minute,
      );
      if (_isSelectable(candidate)) {
        return true;
      }
    }
    return false;
  }

  bool _isMinuteIndexSelectable(int index, int max, int interval) {
    final candidate = _dateTimeForSpinnerIndex(
      hourIndex: currentSelectedHourIndex,
      minuteIndex: index,
      secondIndex: currentSelectedSecondIndex,
      hourMax: _getHourCount(),
      minuteMax: max,
    );
    return _isSelectable(candidate);
  }

  DateTime _dateTimeForSpinnerIndex({
    required int hourIndex,
    required int minuteIndex,
    required int secondIndex,
    required int hourMax,
    int? minuteMax,
    int? minuteOverride,
  }) {
    final savedHourIndex = currentSelectedHourIndex;
    final savedMinuteIndex = currentSelectedMinuteIndex;
    final savedSecondIndex = currentSelectedSecondIndex;

    currentSelectedHourIndex = hourIndex;
    currentSelectedMinuteIndex = minuteIndex;
    currentSelectedSecondIndex = secondIndex;

    if (minuteOverride != null) {
      final minute = minuteOverride;
      int hour = hourIndex - hourMax;
      if (!widget.is24HourMode && currentSelectedAPIndex == 2) {
        hour += 12;
      }
      final result = _dateOnSameDay(hour, minute);
      currentSelectedHourIndex = savedHourIndex;
      currentSelectedMinuteIndex = savedMinuteIndex;
      currentSelectedSecondIndex = savedSecondIndex;
      return result;
    }

    final result = getDateTime();
    currentSelectedHourIndex = savedHourIndex;
    currentSelectedMinuteIndex = savedMinuteIndex;
    currentSelectedSecondIndex = savedSecondIndex;
    return result;
  }

  DateTime _clampToSelectable(DateTime value) {
    if (!widget.restrictToAllowedRange) {
      return value;
    }
    var clamped = value;
    final min = widget.minSelectableTime;
    final max = widget.maxSelectableTime;
    if (min != null && clamped.isBefore(min)) {
      clamped = min;
    }
    if (max != null && clamped.isAfter(max)) {
      clamped = max;
    }
    return clamped;
  }

  void _safeJumpTo(ScrollController controller, double offset) {
    if (!controller.hasClients) {
      return;
    }
    controller.jumpTo(offset);
  }

  void _syncControllersToTime(DateTime time, {bool deferIfNeeded = false}) {
    void apply() {
      currentTime = time;
      currentSelectedHourIndex =
          (time.hour % (widget.is24HourMode ? 24 : 12)) + _getHourCount();
      _safeJumpTo(
        hourController,
        (currentSelectedHourIndex - 1) * _getItemHeight()!,
      );

      currentSelectedMinuteIndex =
          (time.minute / widget.minutesInterval).floor() +
              (isLoop(_getMinuteCount()) ? _getMinuteCount() : 1);
      _safeJumpTo(
        minuteController,
        (currentSelectedMinuteIndex - 1) * _getItemHeight()!,
      );

      currentSelectedSecondIndex =
          (time.second / widget.secondsInterval).floor() +
              (isLoop(_getSecondCount()) ? _getSecondCount() : 1);
      _safeJumpTo(
        secondController,
        (currentSelectedSecondIndex - 1) * _getItemHeight()!,
      );

      if (!widget.is24HourMode) {
        currentSelectedAPIndex = time.hour >= 12 ? 2 : 1;
        _safeJumpTo(
          apController,
          (currentSelectedAPIndex - 1) * _getItemHeight()!,
        );
      }
    }

    if (deferIfNeeded &&
        (!hourController.hasClients || !minuteController.hasClients)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        apply();
      });
      return;
    }

    apply();
  }

  bool _isSamePickerTime(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day &&
        a.hour == b.hour &&
        a.minute == b.minute;
  }

  void _finalizeTimeSelection() {
    final current = getDateTime();
    final clamped = _clampToSelectable(current);
    if (clamped != current) {
      _syncControllersToTime(clamped, deferIfNeeded: true);
    }
    widget.onTimeChange?.call(clamped);
  }

  @override
  void didUpdateWidget(covariant TimePickerSpinner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.restrictToAllowedRange) {
      return;
    }

    final incoming = widget.time ?? currentTime ?? DateTime.now();
    final clamped = _clampToSelectable(incoming);
    final dayChanged = currentTime != null &&
        !_isSamePickerTime(
          DateTime(currentTime!.year, currentTime!.month, currentTime!.day),
          DateTime(clamped.year, clamped.month, clamped.day),
        );
    final timeChanged = !_isSamePickerTime(currentTime, clamped);

    if (currentTime == null ||
        dayChanged ||
        timeChanged ||
        oldWidget.minSelectableTime != widget.minSelectableTime ||
        oldWidget.maxSelectableTime != widget.maxSelectableTime) {
      _syncControllersToTime(clamped, deferIfNeeded: true);
    }
  }

  int _getHourCount() {
    return widget.is24HourMode ? 24 : 12;
  }

  int _getMinuteCount() {
    return (60 / widget.minutesInterval).floor();
  }

  int _getSecondCount() {
    return (60 / widget.secondsInterval).floor();
  }

  double? _getItemHeight() {
    return widget.itemHeight ?? defaultItemHeight;
  }

  double? _getItemWidth() {
    return widget.itemWidth ?? defaultItemWidth;
  }

  double? _getSpacing() {
    return widget.spacing ?? defaultSpacing;
  }

  AlignmentGeometry? _getAlignment() {
    return widget.alignment ?? defaultAlignment;
  }

  bool isLoop(int value) {
    return value > 10;
  }

  DateTime getDateTime() {
    int hour = currentSelectedHourIndex - _getHourCount();
    if (!widget.is24HourMode && currentSelectedAPIndex == 2) hour += 12;
    int minute = (currentSelectedMinuteIndex -
        (isLoop(_getMinuteCount()) ? _getMinuteCount() : 1)) *
        widget.minutesInterval;
    int second = (currentSelectedSecondIndex -
        (isLoop(_getSecondCount()) ? _getSecondCount() : 1)) *
        widget.secondsInterval;
    return DateTime(currentTime!.year, currentTime!.month, currentTime!.day,
        hour, minute, second);
  }

  @override
  void initState() {
    final initial = _clampToSelectable(widget.time ?? DateTime.now());
    currentTime = initial;

    currentSelectedHourIndex =
        (currentTime!.hour % (widget.is24HourMode ? 24 : 12)) + _getHourCount();
    hourController = ScrollController(
        initialScrollOffset:
        (currentSelectedHourIndex - 1) * _getItemHeight()!);

    currentSelectedMinuteIndex =
        (currentTime!.minute / widget.minutesInterval).floor() +
            (isLoop(_getMinuteCount()) ? _getMinuteCount() : 1);
    minuteController = ScrollController(
        initialScrollOffset:
        (currentSelectedMinuteIndex - 1) * _getItemHeight()!);

    currentSelectedSecondIndex =
        (currentTime!.second / widget.secondsInterval).floor() +
            (isLoop(_getSecondCount()) ? _getSecondCount() : 1);
    secondController = ScrollController(
        initialScrollOffset:
        (currentSelectedSecondIndex - 1) * _getItemHeight()!);

    currentSelectedAPIndex = currentTime!.hour >= 12 ? 2 : 1;
    apController = ScrollController(
        initialScrollOffset: (currentSelectedAPIndex - 1) * _getItemHeight()!);

    super.initState();
  }

  @override
  void dispose() {
    hourController.dispose();
    minuteController.dispose();
    secondController.dispose();
    apController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> contents = [
      SizedBox(
        width: _getItemWidth(),
        height: _getItemHeight()! * 2.9,
        child: spinner(
          hourController,
          _getHourCount(),
          currentSelectedHourIndex,
          isHourScrolling,
          1, (index) {
            currentSelectedHourIndex = index;
            isHourScrolling = true;
          }, () => isHourScrolling = false,
          _SpinnerColumn.hour,
        ),
      ),
       Padding(padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
        child: Text(':',style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge),),
      ),
      SizedBox(
        width: _getItemWidth(),
        height: _getItemHeight()! * 2.9,
        child: spinner(
          minuteController,
          _getMinuteCount(),
          currentSelectedMinuteIndex,
          isMinuteScrolling,
          widget.minutesInterval,
              (index) {
            currentSelectedMinuteIndex = index;
            isMinuteScrolling = true;
          },
              () => isMinuteScrolling = false,
          _SpinnerColumn.minute,
        ),
      ),
    ];

    if (widget.isShowSeconds) {
      contents.add(spacer());
      contents.add(SizedBox(
        width: _getItemWidth(),
        height: _getItemHeight()! * 2.9,
        child: spinner(
          secondController,
          _getSecondCount(),
          currentSelectedSecondIndex,
          isSecondsScrolling,
          widget.secondsInterval,
              (index) {
            currentSelectedSecondIndex = index;
            isSecondsScrolling = true;
          },
              () => isSecondsScrolling = false,
          _SpinnerColumn.second,
        ),
      ));
    }

    if (!widget.is24HourMode) {
      contents.add(const SizedBox(width: Dimensions.paddingSizeSmall,));
      contents.add(SizedBox(
        width: _getItemWidth()! * 1.2,
        height: _getItemHeight()! * 3,
        child: apSpinner(),
      ));
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: contents,
    );
  }

  Widget spacer() {
    return SizedBox(
      width: _getSpacing(),
      height: _getItemHeight()! * 3,
    );
  }

  Widget spinner(
      ScrollController controller,
      int max,
      int selectedIndex,
      bool isScrolling,
      int interval,
      SelectedIndexCallback onUpdateSelectedIndex,
      VoidCallback onScrollEnd,
      _SpinnerColumn column) {

    Widget spinner = NotificationListener<ScrollNotification>(
      onNotification: (scrollNotification) {
        if (scrollNotification is UserScrollNotification) {
          if (scrollNotification.direction.toString() ==
              "ScrollDirection.idle") {
            if (isLoop(max)) {
              int segment = (selectedIndex / max).floor();
              if (segment == 0) {
                onUpdateSelectedIndex(selectedIndex + max);
                if (controller.hasClients) {
                  controller
                      .jumpTo(controller.offset + (max * _getItemHeight()!));
                }
              } else if (segment == 2) {
                onUpdateSelectedIndex(selectedIndex - max);
                if (controller.hasClients) {
                  controller
                      .jumpTo(controller.offset - (max * _getItemHeight()!));
                }
              }
            }
            setState(() {
              onScrollEnd();
              _finalizeTimeSelection();
            });
          }
        } else if (scrollNotification is ScrollUpdateNotification) {
          setState(() {
            onUpdateSelectedIndex(
                (controller.offset / _getItemHeight()!).round() + 1);
          });
        }
        return true;
      },
      child: Container(
        decoration: BoxDecoration(
            color: Theme.of(context).hintColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault)
        ),
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: ListView.builder(
            itemBuilder: (context, index) {
              String text = '';
              if (isLoop(max)) {
                text = ((index % max) * interval).toString();
              } else if (index != 0 && index != max + 1) {
                text = (((index - 1) % max) * interval).toString();
              }
              if (!widget.is24HourMode &&
                  controller == hourController &&
                  text == '0') {
                text = '12';
              }
              if (widget.isForce2Digits && text != '') {
                text = text.padLeft(2, '0');
              }
              final isSelectable = switch (column) {
                _SpinnerColumn.hour => _isHourIndexSelectable(index, max, interval),
                _SpinnerColumn.minute => _isMinuteIndexSelectable(index, max, interval),
                _SpinnerColumn.second => true,
              };
              return Container(
                height: _getItemHeight(),
                alignment: _getAlignment(),
                child: Center(
                  child: Text(
                    text,
                    style: selectedIndex == index
                        ? _getHighlightedTextStyle()
                        : isSelectable
                            ? _getNormalTextStyle()
                            : _getDisabledTextStyle(),
                  ),
                ),
              );
            },
            controller: controller,
            itemCount: isLoop(max) ? max * 3 : max + 2,
            physics: ItemScrollPhysics(itemHeight: _getItemHeight(),targetPixelsLimit: 0),
            padding: EdgeInsets.zero,
          ),
        ),
      ),
    );

    return Stack(
      children: <Widget>[
        Positioned.fill(child: spinner),
        isScrolling
            ? Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0),
            ))
            : Container()
      ],
    );
  }

  Widget apSpinner() {
    Widget spinner = NotificationListener<ScrollNotification>(
      onNotification: (scrollNotification) {
        if (scrollNotification is UserScrollNotification) {
          if (scrollNotification.direction.toString() == "ScrollDirection.idle") {
            isAPScrolling = false;
            _finalizeTimeSelection();
          }
        } else if (scrollNotification is ScrollUpdateNotification) {
          setState(() {
            currentSelectedAPIndex = (apController.offset / _getItemHeight()!).round() + 1;
            isAPScrolling = true;
          });
        }
        return true;
      },
      child: ListView.builder(
        itemBuilder: (context, index) {
          String text = index == 1 ? 'am' : (index == 2 ? 'pm' : '');
          return Container(
            height: _getItemHeight(),
            alignment: Alignment.center,
            child: Text(
              text,
              style: currentSelectedAPIndex == index ? _getHighlightedTextStyle() : _getNormalTextStyle(),
            ),
          );
        },
        controller: apController,
        itemCount: 4,
        physics: ItemScrollPhysics(
          itemHeight: _getItemHeight(),
          targetPixelsLimit: 1,
        ),
      ),
    );

    return Stack(
      children: <Widget>[
        Positioned.fill(child: spinner),
        isAPScrolling ? Positioned.fill(child: Container()) : Container()
      ],
    );
  }
}
