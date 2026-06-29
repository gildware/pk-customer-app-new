import 'package:demandium/common/models/popup_menu_model.dart';
import 'package:demandium/feature/booking/model/booking_reason_model.dart';
import 'package:demandium/feature/checkout/widget/payment_section/incomplete_offline_payment_dialog.dart';
import 'package:demandium/feature/home/widget/referal_welcome_dialog.dart';
import 'package:demandium/helper/booking_helper.dart';
import 'package:demandium/util/core_export.dart';
import 'package:get/get.dart';


enum BookingDetailsTabs {bookingDetails, payments, history, serviceLog}
class BookingDetailsController extends GetxController implements GetxService{
  BookingDetailsRepo bookingDetailsRepo;
  BookingDetailsController({required this.bookingDetailsRepo});

  BookingDetailsTabs _selectedDetailsTabs = BookingDetailsTabs.bookingDetails;
  BookingDetailsTabs get selectedBookingStatus =>_selectedDetailsTabs;


  final bookingIdController = TextEditingController();
  final phoneController = TextEditingController();

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  bool _isCancelling = false;
  bool get isCancelling => _isCancelling;

  List<BookingReasonModel> _customerCancellationReasons = [];
  List<BookingReasonModel> get customerCancellationReasons => _customerCancellationReasons;

  bool _isLoadingCancellationReasons = false;
  bool get isLoadingCancellationReasons => _isLoadingCancellationReasons;

  Future<List<BookingReasonModel>>? _customerCancellationReasonsRequest;

  BookingDetailsContent? _bookingDetailsContent;
  BookingDetailsContent? get bookingDetailsContent => _bookingDetailsContent;

  BookingDetailsContent? _subBookingDetailsContent;
  BookingDetailsContent? get subBookingDetailsContent => _subBookingDetailsContent;

  DigitalPaymentMethod? _selectedDigitalPaymentMethod;
  DigitalPaymentMethod ? get selectedDigitalPaymentMethod => _selectedDigitalPaymentMethod;


  void updateBookingStatusTabs(BookingDetailsTabs bookingDetailsTabs){
    _selectedDetailsTabs = bookingDetailsTabs;
    update();
  }


  Future<bool> bookingCancel({
    required String bookingId,
    required int customerCancellationReasonId,
    String? statusChangeRemarks,
    String? refundMethod,
    bool fromListScreen = false,
  }) async {
    _isCancelling = true;
    update();
    Response? response = await bookingDetailsRepo.bookingCancel(
      bookingID: bookingId,
      customerCancellationReasonId: customerCancellationReasonId,
      statusChangeRemarks: statusChangeRemarks,
      refundMethod: refundMethod,
    );
    if (response.statusCode == 200) {
      final responseCode = response.body['response_code']?.toString() ?? '';
      if (responseCode == 'status_update_success_200' || responseCode == 'booking_already_canceled_200') {
        _isCancelling = false;
        if (responseCode == 'status_update_success_200') {
          customSnackBar('booking_cancelled_successfully'.tr, type: ToasterMessageType.success);
        }
        if (fromListScreen) {
          Get.find<ServiceBookingController>().refreshCurrentBookingTab();
        } else {
          await getBookingDetails(bookingId: bookingId, reload: false);
          Get.find<ServiceBookingController>().refreshCurrentBookingTab();
        }
        update();
        return true;
      }
      if (responseCode == 'booking_already_accepted_200'
          || responseCode == 'booking_already_ongoing_200'
          || responseCode == 'booking_already_completed_200') {
        customSnackBar(response.body['message'] ?? '');
        await getBookingDetails(bookingId: bookingId);
        _isCancelling = false;
      } else if (responseCode != 'status_update_success_200' && responseCode != 'booking_already_canceled_200') {
        _isCancelling = false;
        ApiChecker.checkApi(response);
      }
    } else {
      _isCancelling = false;
      ApiChecker.checkApi(response);
    }
    update();
    return false;
  }

  Future<bool> subBookingCancel({
    required String subBookingId,
    required int customerCancellationReasonId,
    String? statusChangeRemarks,
  }) async {
    _isCancelling = true;
    update();
    Response? response = await bookingDetailsRepo.subBookingCancel(
      bookingID: subBookingId,
      customerCancellationReasonId: customerCancellationReasonId,
      statusChangeRemarks: statusChangeRemarks,
    );
    if(response.statusCode == 200 ){
      _isCancelling = false;

      await getSubBookingDetails(bookingId: subBookingId);
      if(_bookingDetailsContent != null){
        getBookingDetails(bookingId: _bookingDetailsContent?.id ?? "", reload : false );
      }
      customSnackBar('booking_cancelled_successfully'.tr, type : ToasterMessageType.success);
      update();
      return true;
    } else{
      _isCancelling = false;
      ApiChecker.checkApi(response);
    }
    update();
    return false;
  }

  Future<List<BookingReasonModel>> getCustomerCancellationReasons({bool forceReload = false}) async {
    if (_customerCancellationReasons.isNotEmpty && !forceReload) {
      return _customerCancellationReasons;
    }

    if (_customerCancellationReasonsRequest != null && !forceReload) {
      return _customerCancellationReasonsRequest!;
    }

    _isLoadingCancellationReasons = true;
    update();

    _customerCancellationReasonsRequest = _fetchCustomerCancellationReasons();
    try {
      return await _customerCancellationReasonsRequest!;
    } finally {
      _customerCancellationReasonsRequest = null;
    }
  }

  Future<List<BookingReasonModel>> _fetchCustomerCancellationReasons() async {
    try {
      final response = await bookingDetailsRepo.getCustomerCancellationReasons();
      if (response.statusCode == 200) {
        final raw = response.body['content'];
        if (raw is List) {
          _customerCancellationReasons = raw
              .whereType<Map>()
              .map((item) => BookingReasonModel.fromJson(Map<String, dynamic>.from(item)))
              .toList();
        } else {
          _customerCancellationReasons = [];
        }
      } else {
        _customerCancellationReasons = [];
      }
    } catch (_) {
      _customerCancellationReasons = [];
    }

    _isLoadingCancellationReasons = false;
    update();
    return _customerCancellationReasons;
  }

  Future<void> getBookingDetails({required String bookingId, bool reload = true})async{
    if(reload){
      _bookingDetailsContent = null;
    }
    Response response = await bookingDetailsRepo.getBookingDetails(bookingID: bookingId);
    if(response.statusCode == 200){
      _bookingDetailsContent = BookingDetailsContent.fromJson(response.body['content']);
      update();
    } else {
      ApiChecker.checkApi(response);
    }
  }

  Future<void> getSubBookingDetails({required String bookingId})async{

    _subBookingDetailsContent = null;
    Response response = await bookingDetailsRepo.getSubBookingDetails(bookingID: bookingId);
    if(response.statusCode == 200){
      _subBookingDetailsContent = BookingDetailsContent.fromJson(response.body['content']);

    } else {
      ApiChecker.checkApi(response);
    }
    update();

  }


  Future<void> trackBookingDetails(String bookingReadableId, String phone, {bool reload = false}) async {
    if(reload){
      _isLoading = true;
      update();
    }
    if( reload || _bookingDetailsContent == null){

      Response response = await bookingDetailsRepo.trackBookingDetails(bookingID: bookingReadableId, phoneNUmber: phone);
      if(response.statusCode == 200){
        _bookingDetailsContent = BookingDetailsContent.fromJson(response.body['content']);
        update();
      }else{
        _bookingDetailsContent = null;
        _isLoading = false;
        update();
      }
    }
    if(reload){
      _isLoading = false;
      update();
    }

  }

  void updateSelectedDigitalPayment({DigitalPaymentMethod? value, bool shouldUpdate = true}){
    _selectedDigitalPaymentMethod = value;
    if(shouldUpdate){
      update();
    }
  }

  void resetBookingDetailsValue({bool shouldUpdate = false, bool resetBookingDetails = false}){
    _selectedDetailsTabs = BookingDetailsTabs.bookingDetails;
    _subBookingDetailsContent = null;
    if(resetBookingDetails){
      _bookingDetailsContent = null;
    }
  }


  void resetTrackingData({bool shouldUpdate = true}){
    bookingIdController.clear();
    phoneController.clear();
    _bookingDetailsContent = null;

    if(shouldUpdate){
      update();
    }
  }

  void manageDialog(){
    final context = Get.context;
    if (context == null) {
      return;
    }

    var userData = Get.find<UserController>().userInfoModel;
    if(Get.find<AuthController>().isLoggedIn() && userData !=null && userData.lastIncompleteOfflineBooking != null && getLastIncompleteOfflineBookingId() != userData.lastIncompleteOfflineBooking?.id){
     if(Get.isDialogOpen == false){
       if(ResponsiveHelper.isDesktop(context)){
         Get.dialog(Center(child: IncompleteOfflinePaymentDialog(booking: Get.find<UserController>().userInfoModel?.lastIncompleteOfflineBooking,))).then((value){
           setLastIncompleteOfflineBookingId(userData.lastIncompleteOfflineBooking?.id ?? "");
         });
       }else{
         showModalBottomSheet(context: context,
           builder: (_){
             return  IncompleteOfflinePaymentDialog(booking: Get.find<UserController>().userInfoModel?.lastIncompleteOfflineBooking,);
           },
           backgroundColor: Colors.transparent,
         ).then((value){
           setLastIncompleteOfflineBookingId(userData.lastIncompleteOfflineBooking?.id ?? "");
         });
       }
     }
    }

    if(Get.find<ServiceController>().allService !=null && Get.find<ServiceController>().allService!.isNotEmpty && (Get.currentRoute.contains(RouteHelper.home) || Get.currentRoute.contains("/?page=home"))){
      if(Get.find<UserController>().showReferWelcomeDialog() && Get.find<AuthController>().getIsShowReferralBottomSheet() == true){
        Future.delayed(const Duration(microseconds: 500), () {
          showModalBottomSheet(
            isDismissible: false,
            context: context,
            useRootNavigator: true,
            isScrollControlled: true,
            builder: (context) => const ReferWelcomeDialog(),
            backgroundColor: Colors.transparent,
          );
        });
      }
    }
  }

  Future<void>  setLastIncompleteOfflineBookingId(String bookingId) async {
    await  bookingDetailsRepo.setLastIncompleteOfflineBookingId(bookingId);
  }

  String getLastIncompleteOfflineBookingId() {
    return bookingDetailsRepo.getLastIncompleteOfflineBookingId();
  }

  List<PopupMenuModel> getPopupMenuList(BookingDetailsContent? booking) {
    final status = booking?.bookingStatus ?? '';
    if (status == "pending") {
      return [
        PopupMenuModel(title: "download_invoice", icon: Icons.file_download_outlined),
        PopupMenuModel(title: "cancel", icon: Icons.cancel_outlined),
      ];
    } else if(status == "completed"){
      return [
        PopupMenuModel(title: "download_invoice", icon: Icons.file_download_outlined),
        if (booking != null && BookingHelper.canLeaveReview(booking))
          PopupMenuModel(title: "review", icon: Icons.reviews_outlined),
      ];
    }
    return [];
  }

  List<PopupMenuModel> getPServiceLogMenuList({required String status,  bool nextService = false}) {

    if (status == "pending") {
      return [
        PopupMenuModel(title: "download_invoice", icon: Icons.file_download_outlined),

      ];
    } else if (status == "accepted") {
      return [
        if(nextService) PopupMenuModel(title: "booking_details", icon: Icons.remove_red_eye),
        PopupMenuModel(title: "download_invoice", icon: Icons.file_download_outlined),
        if(!nextService) PopupMenuModel(title: "cancel", icon: Icons.cancel_outlined),
      ];
    }

    else if (status == "ongoing" || status == "completed" || status == "canceled") {
      return [
        PopupMenuModel(title: "booking_details", icon: Icons.remove_red_eye),
        PopupMenuModel(title: "download_invoice", icon: Icons.file_download_outlined),

      ];
    }
    return [];
  }

}