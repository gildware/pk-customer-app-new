
import 'package:get/get.dart';
import 'package:demandium/util/core_export.dart';
import 'package:intl/intl.dart';

enum ScheduleType {asap, schedule}

class ScheduleController extends GetxController implements GetxService{

  final ScheduleRepo scheduleRepo;
  ScheduleController({required this.scheduleRepo});


  ServiceType _selectedServiceType = ServiceType.regular;
  ServiceType get selectedServiceType => _selectedServiceType;

  int _scheduleDaysCount = 1;
  int get scheduleDaysCount => _scheduleDaysCount;


  /// Regular Booking ///

  ScheduleType _selectedScheduleType = ScheduleType.asap;
  ScheduleType get selectedScheduleType => _selectedScheduleType;

  ScheduleType? _initialSelectedScheduleType;
  ScheduleType? get initialSelectedScheduleType => _initialSelectedScheduleType;

  String selectedDate = DateFormat('yyyy-MM-dd').format(_asapScheduleDateTime());
  String selectedTime = DateFormat('HH:mm:ss').format(_asapScheduleDateTime());

  String? scheduleTime;

  bool _scheduleAdjustedForAvailability = false;
  bool get scheduleAdjustedForAvailability => _scheduleAdjustedForAvailability;

  String? _scheduleAdjustmentNotice;
  String? get scheduleAdjustmentNotice => _scheduleAdjustmentNotice;


  /// Repeat Booking /////

  RepeatBookingType _selectedRepeatBookingType = RepeatBookingType.daily;
  RepeatBookingType get selectedRepeatBookingType => _selectedRepeatBookingType;

  // Daily Repeat Booking
  DateTimeRange? _pickedDailyRepeatBookingDateRange;
  DateTimeRange? get pickedDailyRepeatBookingDateRange => _pickedDailyRepeatBookingDateRange;
  set updateDailyRepeatBookingDateRange(DateTimeRange? dateRange) => _pickedDailyRepeatBookingDateRange = dateRange;

  TimeOfDay? _pickedDailyRepeatTime;
  TimeOfDay? get pickedDailyRepeatTime => _pickedDailyRepeatTime;
  set updatePickedDailyRepeatTime(TimeOfDay? time) => _pickedDailyRepeatTime = time;


  // Weekly Repeat Booking
  DateTimeRange? _finalPickedWeeklyRepeatBookingDateRange;
  DateTimeRange? get pickedWeeklyRepeatBookingDateRange => _finalPickedWeeklyRepeatBookingDateRange;

  DateTimeRange? _initialPickedWeeklyRepeatBookingDateRange;
  DateTimeRange? get initialPickedWeeklyRepeatBookingDateRange => _initialPickedWeeklyRepeatBookingDateRange;
  set updateInitialWeeklyRepeatBookingDateRange(DateTimeRange? dateRange) => _initialPickedWeeklyRepeatBookingDateRange = dateRange;

  TimeOfDay? _pickedWeeklyRepeatTime;
  TimeOfDay? get pickedWeeklyRepeatTime => _pickedWeeklyRepeatTime;
  set updatePickedWeeklyRepeatTime(TimeOfDay? time) => _pickedWeeklyRepeatTime = time;

  bool _isFinalRepeatWeeklyBooking = false;
  bool get isFinalRepeatWeeklyBooking => _isFinalRepeatWeeklyBooking;

  bool _isInitialRepeatWeeklyBooking = false;
  bool get isInitialRepeatWeeklyBooking => _isInitialRepeatWeeklyBooking;


  List<String> daysList = ['saturday', "sunday", "monday", "tuesday", "wednesday", "thursday", "friday"];
  List<bool> finalDaysCheckList = [false, false, false, false, false, false, false];
  List<bool> initialDaysCheckList = [false, false, false, false, false, false, false];


  // Custom Repeat Booking
  List<DateTime>  _pickedCustomRepeatBookingDateTimeList = [];
  List<DateTime>  get pickedCustomRepeatBookingDateTimeList => _pickedCustomRepeatBookingDateTimeList;

  List<DateTime>  _pickedInitialCustomRepeatBookingDateTimeList = [];
  List<DateTime>  get pickedInitialCustomRepeatBookingDateTimeList => _pickedInitialCustomRepeatBookingDateTimeList;
  set updateInitialCustomRepeatBookingDateRange(List<DateTime>  dateList) => _pickedInitialCustomRepeatBookingDateTimeList = dateList;



  void buildSchedule({bool shouldUpdate = true, required ScheduleType scheduleType, String? schedule}){

    if(schedule != null){
      _selectedScheduleType = ScheduleType.schedule;
      scheduleTime = schedule;
    }else if(_initialSelectedScheduleType == ScheduleType.asap){
      _selectedScheduleType = ScheduleType.asap;
      final resolution = CompanyAvailabilityHelper.resolveAsapScheduleResolution();
      _applyResolvedSchedule(resolution.schedule);
   }else{
      _selectedScheduleType = ScheduleType.schedule;
     scheduleTime = "$selectedDate $selectedTime";
   }
    if(shouldUpdate){
      update();
    }
  }

  void updateScheduleType({bool shouldUpdate = true, required ScheduleType scheduleType}){

    if(scheduleType == ScheduleType.asap){
      _initialSelectedScheduleType= ScheduleType.asap;
    }else{
      _initialSelectedScheduleType = ScheduleType.schedule;
    }
    if(shouldUpdate){
      update();
    }
  }

  DateTime? getSelectedDateTime(){
     if (_selectedScheduleType != ScheduleType.schedule || scheduleTime == null) {
       return null;
     }
     return DateConverter.tryParseScheduleDateTime(scheduleTime!);
  }

  String? checkValidityOfTimeRestriction( AdvanceBooking advanceBooking){
    final selected = DateConverter.tryParseScheduleDateTime('$selectedDate $selectedTime');
    if (selected == null) return 'select_schedule_time'.tr;

    Duration  difference = selected.difference(DateTime.now());

    if(advanceBooking.advancedBookingRestrictionType == "day" && difference.inDays < advanceBooking.advancedBookingRestrictionValue!){
      return "${'you_can_not_select_schedule_before'.tr} ${DateConverter.dateMonthYearTimeTwentyFourFormat(DateTime.now().add(Duration(days: advanceBooking.advancedBookingRestrictionValue!)))}";
    }else if (advanceBooking.advancedBookingRestrictionType == "hour" && difference.inHours < advanceBooking.advancedBookingRestrictionValue!){
      return "${'you_can_not_select_schedule_before'.tr} ${DateConverter.dateMonthYearTimeTwentyFourFormat(DateTime.now().add(Duration(hours: advanceBooking.advancedBookingRestrictionValue!)))}";
    }else if (advanceBooking.advancedBookingRestrictionType == "minute" && difference.inMinutes < advanceBooking.advancedBookingRestrictionValue!){
      return "${'you_can_not_select_schedule_before'.tr} ${DateConverter.dateMonthYearTimeTwentyFourFormat(DateTime.now().add(Duration(minutes: advanceBooking.advancedBookingRestrictionValue!)))}";
    }else{
      return null;
    }

  }

  void resetSchedule(){
    if(Get.find<SplashController>().configModel.content?.instantBooking == 1){
      _selectedScheduleType = ScheduleType.asap;
      _initialSelectedScheduleType = ScheduleType.asap;
      scheduleTime = _formatAsapScheduleTime();
    }else{
      _selectedScheduleType = ScheduleType.schedule;
      scheduleTime = null;
    }
  }

  /// Initializes the service booking schedule step with ASAP selected by default.
  void initBookingScheduleForFlow() {
    applyAsapScheduleResolution();
  }

  /// Rebuilds ASAP schedule from lead time + company availability rules.
  CompanyScheduleResolution applyAsapScheduleResolution({bool shouldUpdate = true}) {
    final resolution = CompanyAvailabilityHelper.resolveAsapScheduleResolution();
    _selectedScheduleType = ScheduleType.asap;
    _initialSelectedScheduleType = ScheduleType.asap;
    _applyResolvedSchedule(resolution.schedule);
    _scheduleAdjustedForAvailability = false;
    _scheduleAdjustmentNotice = null;
    if (shouldUpdate) {
      update();
    }
    return resolution;
  }

  /// Resolves a custom schedule against company availability rules.
  CompanyScheduleResolution applyCustomScheduleResolution(
    DateTime requested, {
    bool notifyIfAdjusted = false,
    bool shouldUpdate = true,
    bool delayNotification = false,
  }) {
    final resolution = CompanyAvailabilityHelper.resolveCustomSchedule(requested);
    _selectedScheduleType = ScheduleType.schedule;
    _initialSelectedScheduleType = ScheduleType.schedule;
    _storeScheduleResolution(resolution);
    if (shouldUpdate) {
      update();
    }
    if (notifyIfAdjusted) {
      CompanyAvailabilityHelper.notifyIfScheduleAdjusted(
        resolution,
        delay: delayNotification,
      );
    }
    return resolution;
  }

  void _storeScheduleResolution(CompanyScheduleResolution resolution) {
    _applyResolvedSchedule(resolution.schedule);
    _scheduleAdjustedForAvailability = resolution.wasAdjusted;
    _scheduleAdjustmentNotice = resolution.wasAdjusted
        ? CompanyAvailabilityHelper.outsideHoursRescheduledMessage(resolution.schedule)
        : null;
  }

  void clearScheduleAdjustmentNotice() {
    _scheduleAdjustedForAvailability = false;
    _scheduleAdjustmentNotice = null;
  }

  void _applyResolvedSchedule(DateTime schedule) {
    scheduleTime = '${DateFormat('yyyy-MM-dd').format(schedule)} ${DateFormat('HH:mm:ss').format(schedule)}';
    selectedDate = DateFormat('yyyy-MM-dd').format(schedule);
    selectedTime = DateFormat('HH:mm:ss').format(schedule);
  }


  void setInitialScheduleValue(){
    if(_selectedScheduleType == ScheduleType.asap){
      _initialSelectedScheduleType = ScheduleType.asap;
    }
  }

  void updateSelectedDate(String? date){
    if(date!=null){
      scheduleTime = date;
    }else{
     scheduleTime = null;
    }
  }

  Future<void> updatePostInformation(String postId,String scheduleTime) async {
    Response response = await scheduleRepo.changePostScheduleTime(postId,scheduleTime);

    if(response.statusCode==200 && response.body['response_code']=="default_update_200"){
      customSnackBar("service_schedule_updated_successfully".tr,type : ToasterMessageType.success);
    }
  }

  void removeInitialPickedCustomRepeatBookingDate ({required int index}){
    _pickedInitialCustomRepeatBookingDateTimeList.removeAt(index);
  }

  void removePickedCustomRepeatBookingDate ({required int index}){
    _pickedCustomRepeatBookingDateTimeList.removeAt(index);
  }


  void updateSelectedRepeatBookingType({RepeatBookingType? type}){
    if(type !=null){
      _selectedRepeatBookingType = type;
      update();
    }else{
      _selectedRepeatBookingType = RepeatBookingType.daily;
    }
  }

  void toggleDaysCheckedValue(int index) {
    initialDaysCheckList[index] = !initialDaysCheckList[index];
    update();
  }

  void updateWeeklyRepeatBookingStatus({bool shouldUpdate = true}){
    _initialPickedWeeklyRepeatBookingDateRange = null;
    _isInitialRepeatWeeklyBooking = !_isInitialRepeatWeeklyBooking;
    if(shouldUpdate){
      update();
    }
  }

  void updateSelectedBookingType ({ServiceType? type}){
    if(type !=null){
      _selectedServiceType = type;
      update();
    }else{
      _selectedServiceType = ServiceType.regular;
    }
  }

  List<String> getWeeklyPickedDays() {
    List<String> pickedDays = [];
    for (int index = 0; index < finalDaysCheckList.length; index++) {
      if (finalDaysCheckList[index]) {
        pickedDays.add(daysList[index]);
      }
    }
    return pickedDays;
  }

  List<String> getInitialWeeklyPickedDays() {
    List<String> pickedDays = [];
    for (int index = 0; index < initialDaysCheckList.length; index++) {
      if (initialDaysCheckList[index]) {
        pickedDays.add(daysList[index]);
      }
    }
    return pickedDays;
  }


  void updateCustomRepeatBookingDateTime({required int index, required DateTime dateTime}){
    pickedInitialCustomRepeatBookingDateTimeList[index] = dateTime;
    update();
  }

  void resetScheduleData({RepeatBookingType? repeatBookingType, bool shouldUpdate = true}){

    if(repeatBookingType == RepeatBookingType.daily){
      _finalPickedWeeklyRepeatBookingDateRange = null;
      _pickedCustomRepeatBookingDateTimeList = [];
      _pickedDailyRepeatTime = null;
      _pickedWeeklyRepeatTime = null;
      finalDaysCheckList = [false, false, false, false, false, false, false];
      _isFinalRepeatWeeklyBooking = false;

    }else if(repeatBookingType == RepeatBookingType.weekly){
      _pickedDailyRepeatBookingDateRange = null;
      _pickedCustomRepeatBookingDateTimeList = [];
      _pickedDailyRepeatTime = null;
    }else if (repeatBookingType == RepeatBookingType.custom){
      _pickedDailyRepeatBookingDateRange = null;
      _finalPickedWeeklyRepeatBookingDateRange = null;
      _pickedDailyRepeatTime = null;
      _pickedWeeklyRepeatTime = null;
      finalDaysCheckList = [false, false, false, false, false, false, false];
      _isFinalRepeatWeeklyBooking = false;
    }else{
      _pickedDailyRepeatBookingDateRange = null;
      _finalPickedWeeklyRepeatBookingDateRange = null;
      _pickedCustomRepeatBookingDateTimeList = [];
      _pickedDailyRepeatTime = null;
      _selectedRepeatBookingType = RepeatBookingType.daily;
      _isFinalRepeatWeeklyBooking = false;
      finalDaysCheckList = [false, false, false, false, false, false, false];
    }

    calculateScheduleCountDays(serviceType: repeatBookingType == null ? ServiceType.regular : ServiceType.repeat, repeatBookingType: repeatBookingType ?? RepeatBookingType.daily);

    if(shouldUpdate){
      update();
    }
  }

  void initWeeklySelectedSchedule({bool isFirst = true}){
    if(isFirst){
      _isInitialRepeatWeeklyBooking =  _isFinalRepeatWeeklyBooking;
      initialDaysCheckList.clear();
      initialDaysCheckList.addAll(finalDaysCheckList);
      _initialPickedWeeklyRepeatBookingDateRange = _finalPickedWeeklyRepeatBookingDateRange;
    }else{
      _isFinalRepeatWeeklyBooking = _isInitialRepeatWeeklyBooking;
      finalDaysCheckList.clear();
      finalDaysCheckList.addAll(initialDaysCheckList);
      _finalPickedWeeklyRepeatBookingDateRange = _initialPickedWeeklyRepeatBookingDateRange;
      update();
    }
  }

  void initCustomSelectedSchedule({bool isFirst = true}){
    if(isFirst){
     _pickedInitialCustomRepeatBookingDateTimeList.clear();
     _pickedInitialCustomRepeatBookingDateTimeList.addAll(_pickedCustomRepeatBookingDateTimeList);
    }else{
      _pickedCustomRepeatBookingDateTimeList.clear();
      _pickedCustomRepeatBookingDateTimeList.addAll(_pickedInitialCustomRepeatBookingDateTimeList);
      update();
    }
  }

  static DateTime _asapScheduleDateTime() => CompanyAvailabilityHelper.resolveAsapSchedule();

  static String _formatAsapScheduleTime() {
    final asap = _asapScheduleDateTime();
    return '${DateFormat('yyyy-MM-dd').format(asap)} ${DateFormat('HH:mm:ss').format(asap)}';
  }

  void calculateScheduleCountDays ({ServiceType? serviceType, required RepeatBookingType repeatBookingType}){

    if(selectedServiceType == ServiceType.regular || serviceType == ServiceType.regular){
      _scheduleDaysCount = 1;
    }else{
      if(repeatBookingType == RepeatBookingType.daily){
        _scheduleDaysCount = CheckoutHelper.calculateDaysCountBetweenDateRange(_pickedDailyRepeatBookingDateRange);
      } else if(repeatBookingType == RepeatBookingType.weekly){
        _scheduleDaysCount = CheckoutHelper.calculateDaysCountBetweenDateRangeWithSpecificSelectedDay(_finalPickedWeeklyRepeatBookingDateRange, getWeeklyPickedDays());
      } else{
        _scheduleDaysCount = _pickedCustomRepeatBookingDateTimeList.length;
      }
    }
  }

}