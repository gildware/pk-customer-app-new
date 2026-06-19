import 'package:demandium/common/models/popup_menu_model.dart';
import 'package:demandium/feature/booking/model/booking_count.dart';
import 'package:demandium/helper/debounce_helper.dart';
import 'package:demandium/util/core_export.dart';
import 'package:demandium/feature/booking/model/service_availability_model.dart';
import 'package:demandium/feature/booking/widget/provider_available_bottom_sheet.dart';
import 'package:demandium/feature/booking/widget/service_unavailable_dialog.dart';
import 'package:get/get.dart';

class ServiceBookingController extends GetxController implements GetxService {
  final ServiceBookingRepo serviceBookingRepo;

  ServiceBookingController({required this.serviceBookingRepo});

  List<BookingModel>? _bookingList;

  List<BookingModel>? get bookingList => _bookingList;
  int _offset = 1;

  int? get offset => _offset;
  BookingContent? _bookingContent;

  BookingContent? get bookingContent => _bookingContent;

  int _bookingListPageSize = 0;
  final int _bookingListCurrentPage = 0;

  int get bookingListPageSize => _bookingListPageSize;

  int get bookingListCurrentPage => _bookingListCurrentPage;
  String _selectedBookingStatus = 'all';

  String get selectedBookingStatus => _selectedBookingStatus;

  List<String> get visibleBookingTabs => _bookingCount?.visibleTabs ?? const ['all'];

  int get selectedBookingTabIndex {
    final visible = visibleBookingTabs;
    if (visible.isEmpty) return 0;
    final idx = visible.indexOf(_selectedBookingStatus);
    return idx >= 0 ? idx : 0;
  }

  void _ensureSelectedTabVisible() {
    final visible = visibleBookingTabs;
    if (visible.isEmpty) return;
    if (!visible.contains(_selectedBookingStatus)) {
      _selectedBookingStatus = visible.first;
    }
  }

  bool _isNotAvailable = false;
  bool get isNotAvailable => _isNotAvailable;

  bool _isPriceChanged = false;
  bool get isPriceChanged => _isPriceChanged;

  ServiceAvailabilityModel? serviceAvailability;

  int _rebookIndex=-1;
  int get  selectedRebookIndex => _rebookIndex;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  ServiceType selectedServiceType = ServiceType.all;

  bool _isTabLoading = false;
  bool get isTabLoading => _isTabLoading;

  final DebounceHelper _debounceHelper = DebounceHelper(milliseconds: 300);

  AutoScrollController? bookingTabScrollController;

  BookingCount? _bookingCount;
  BookingCount? get bookingCount => _bookingCount;

  @override
  void onInit() {
    super.onInit();
    bookingTabScrollController = AutoScrollController(axis: Axis.horizontal);
  }

  @override
  void onClose() {
    bookingTabScrollController?.dispose();
    super.onClose();
  }

  Future<void> scrollBookingTabTo(int index) async {
    final controller = bookingTabScrollController;
    if (controller == null) return;
    if (index == selectedBookingTabIndex) return;
    await controller.scrollToIndex(
      index,
      preferPosition: AutoScrollPosition.begin,
      duration: Duration.zero,
    );
    await controller.highlight(index);
  }

  Future<void> refreshCurrentBookingTab() async {
    _bookingList = null;
    _isTabLoading = true;
    update();
    await getAllBookingService(
      offset: 1,
      bookingStatus: _selectedBookingStatus,
      isFromPagination: false,
      serviceType: selectedServiceType.name,
    );
  }

  void updateBookingStatusTabs(String bookingStatusTabs, {
    bool firstTimeCall = true, bool fromMenu = false,
  }) {

    if (_selectedBookingStatus == bookingStatusTabs) {
      return;
    }

    _selectedBookingStatus = bookingStatusTabs;
    update();

    if (firstTimeCall) {
      _isTabLoading = true;
      update();

      _debounceHelper.run(() {
        getAllBookingService(
          offset: 1,
          bookingStatus: _selectedBookingStatus,
          isFromPagination: false,
          serviceType: selectedServiceType.name,
        );
      });
    }
  }


  Future<void> getAllBookingService({required int offset, required String bookingStatus, required bool isFromPagination, bool fromMenu = false, required String serviceType}) async {
    _offset = offset;
    if (!isFromPagination) {
      _bookingList = null;
    }
    Response response = await serviceBookingRepo.getBookingList(offset: offset, bookingStatus: bookingStatus, serviceType: serviceType);
    if (response.statusCode == 200) {
      final content = response.body['content'];
      Map<String, dynamic> bookingsJson;
      if (content is Map && content['bookings'] != null) {
        if (content['bookings_count'] != null) {
          _bookingCount = BookingCount.fromJson(
            Map<String, dynamic>.from(content['bookings_count']),
          );
          _ensureSelectedTabVisible();
          if (_selectedBookingStatus != bookingStatus && !isFromPagination) {
            await getAllBookingService(
              offset: 1,
              bookingStatus: _selectedBookingStatus,
              isFromPagination: false,
              serviceType: serviceType,
            );
            return;
          }
        }
        bookingsJson = Map<String, dynamic>.from(content['bookings']);
      } else {
        bookingsJson = Map<String, dynamic>.from(content);
      }

      ServiceBookingList serviceBookingModel = ServiceBookingList.fromJson({
        ...Map<String, dynamic>.from(response.body),
        'content': bookingsJson,
      });
      if (!isFromPagination) {
        _bookingList = [];
      }
      for (var element in serviceBookingModel.content!.bookingModel!) {
        _bookingList!.add(element);
      }
      _bookingListPageSize = bookingsJson['last_page'];
      _bookingContent = serviceBookingModel.content!;
    } else {
      ApiChecker.checkApi(response);
    }

    _isTabLoading = false;
    update();
  }


  Future<void> rebook(String bookingId, {bool isBack = false}) async {
    _isLoading = true;
    update();
    Response response = await serviceBookingRepo.addRebookToServer(bookingId);
    _isLoading = false;
    update();
    if (response.statusCode == 200) {
      if(isBack){
        Get.back();
      }
      await Get.find<LocationController>().refreshSavedAddressZone();
      Get.find<CartController>().getCartListFromServer(shouldUpdate: true);
      customSnackBar(response.body['message'], type : ToasterMessageType.success);
    }
  }


  Future<void> checkRebookAvailability(String bookingId) async {
    _isPriceChanged = false;
    _isNotAvailable = false;
    _isLoading = true;
    update();

    Get.dialog(const CustomLoader(), barrierDismissible: true);

    Response response = await serviceBookingRepo.rebookCheck(bookingId);

    Get.back();
    _isLoading = false;
    update();
    if(response.statusCode != 200) {
      ApiChecker.checkApi(response);
      return;
    }

    final body = response.body;
    if (body is! Map) {
      customSnackBar('failed_to_add_to_cart'.tr, type: ToasterMessageType.error);
      return;
    }

    try {
      serviceAvailability = ServiceAvailabilityModel.fromJson(Map<String, dynamic>.from(body));
    } catch (_) {
      customSnackBar('failed_to_add_to_cart'.tr, type: ToasterMessageType.error);
      return;
    }

    final content = serviceAvailability?.content;
    final services = content?.services ?? [];
    if (content == null || services.isEmpty) {
      customSnackBar('no_service_available'.tr, type: ToasterMessageType.info);
      return;
    }

    for (final service in services) {
      if (!_isPriceChanged && service.isPriceChanged == 1) {
        _isPriceChanged = true;
      }
      if (!_isNotAvailable && service.isAvailable == 0) {
        _isNotAvailable = true;
      }
    }
    update();

    if(content.isProviderAvailable == 1 && !_isNotAvailable && !_isPriceChanged) {
      await rebook(bookingId);
    } else if (content.isProviderAvailable == 0) {
      if (ResponsiveHelper.isDesktop(Get.context)) {
         Get.dialog(Center(child: RebookWarningBottomSheet(bookingId: bookingId)));
      } else {
        Get.bottomSheet(RebookWarningBottomSheet(bookingId: bookingId), backgroundColor: Colors.transparent, isScrollControlled: true);
      }
    } else if (_isNotAvailable || _isPriceChanged) {
      if (ResponsiveHelper.isDesktop(Get.context)) {
        Get.dialog(Center(child: ServiceUnavailableDialog(bookingId: bookingId, isPriceChanged: _isPriceChanged, isNotAvailable: _isNotAvailable, isAllNotAvailable: checkAllServiceAvailable(services),)));
      } else {
        Get.bottomSheet(ServiceUnavailableDialog(bookingId: bookingId, isPriceChanged: _isPriceChanged, isNotAvailable: _isNotAvailable, isAllNotAvailable: checkAllServiceAvailable(services)), backgroundColor: Colors.transparent, isScrollControlled: true);
      }
    }
  }


    Future<void> checkCartSubcategory(String bookingId, String subcategoryId) async {
      if(Get.find<CartController>().cartList.isNotEmpty) {
        List<CartModel> cartList =  Get.find<CartController>().cartList;
        if(cartList[0].subCategoryId != subcategoryId) {
          Get.dialog(ConfirmationDialog(
            icon: Images.warning,
            title: "are_you_sure_to_reset".tr,
            description: 'you_have_service_from_other_sub_category'.tr,
            onYesPressed: () async {
              Get.find<CartController>().removeAllCartItem();
              checkRebookAvailability(bookingId);
              Get.back();
            },
          ));
        }else {
          await checkRebookAvailability(bookingId);
        }
      } else {
        await checkRebookAvailability(bookingId);
      }
    }

  void updateRebookIndex (int index) {
    _rebookIndex = index;
    update();
  }


  bool checkAllServiceAvailable (List<Services>? services) {
    bool available = true;
    for (int i = 0; i< services!.length; i++) {
      if(available && services[i].isAvailable == 1) {
        available = false;
      }
    }
    return available;
  }

  void updateSelectedServiceType({ServiceType? type}){
    if(type!=null){
      selectedServiceType = type;
      update();
      getAllBookingService(offset: 1, bookingStatus: _selectedBookingStatus, isFromPagination: false, serviceType: type.name);
    }else{
      selectedServiceType = ServiceType.all;
    }
  }

  List<PopupMenuModel> getPopupMenuList({required String status, bool isRepeatBooking = false, RepeatBooking? ongoingRepeatBooking, required bool isCustomizeBooking}) {
    if (status == "pending") {
      return [
        PopupMenuModel(title: "booking_details", icon: Icons.remove_red_eye_sharp),
        PopupMenuModel(title: "download_invoice", icon: Icons.file_download_outlined),
        PopupMenuModel(title: "cancel", icon: Icons.cancel_outlined),
      ];
    } else if (status == "accepted" || status == "ongoing" || status == "on_hold") {
      return [
        PopupMenuModel(title: "booking_details", icon: Icons.remove_red_eye_sharp),
        PopupMenuModel(title: "download_invoice", icon: Icons.file_download_outlined),
      ];
    }
    else if (status == "canceled"|| status == "completed" || status == "refunded") {
      return [
        PopupMenuModel(title: "booking_details", icon: Icons.remove_red_eye_sharp),
        PopupMenuModel(title: "download_invoice", icon: Icons.file_download_outlined),
      ];
    }
    return [];
  }

}
