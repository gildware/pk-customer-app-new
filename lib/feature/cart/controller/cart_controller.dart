
import 'package:demandium/api/local/cache_response.dart';
import 'package:demandium/helper/analytics/analytics_helper.dart';
import 'package:demandium/helper/validation_helper.dart';
import 'package:demandium/feature/cart/model/cart_additional_charge_line.dart';
import 'package:demandium/feature/cart/model/cart_service_info_model.dart';
import 'package:demandium/feature/cart/model/service_booking_step.dart';
import 'package:demandium/helper/data_sync_helper.dart';
import 'package:demandium/helper/provider_availability_helper.dart';
import 'package:get/get.dart';
import 'package:demandium/util/core_export.dart';
import 'package:intl/intl.dart';



class CartController extends GetxController implements GetxService {
  final CartRepo cartRepo;
  CartController({required this.cartRepo});

  List<CartModel> _cartList = [];
  List<CartModel> _initialCartList = [];
  bool _isLoading = false;
  bool _isCartLoading = false;
  double _amount = 0.0;
  final bool _isOthersInfoValid = false;
  bool _isButton = false;

  List<CartModel> get cartList => _cartList;
  List<CartModel> get initialCartList => _initialCartList;
  double get amount => _amount;
  bool get isLoading => _isLoading;
  bool get isCartLoading  => _isCartLoading ;
  bool get isOthersInfoValid => _isOthersInfoValid;

  bool get isButton => _isButton;


  List<ProviderData>? _providerList;
  List<ProviderData>? get  providerList=> _providerList;

  double _totalPrice = 0;
  double get totalPrice => _totalPrice;
  set updateTotalPrice(double price) => _totalPrice = price;

  double _walletBalance = 0.0;
  double get walletBalance => _walletBalance;


  double _referralAmount = 0.0;
  double get referralAmount => _referralAmount;

  double _additionalChargeTotal = 0.0;
  double get additionalChargeTotal => _additionalChargeTotal;

  List<CartAdditionalChargeLine> _additionalChargeLines = [];
  List<CartAdditionalChargeLine> get additionalChargeLines => _additionalChargeLines;

  double _bookingAmountWithoutCoupon = 0.0;
  double _couponAmount = 0.0;


  bool _walletPaymentStatus = false;
  bool get walletPaymentStatus => _walletPaymentStatus;

  ProviderData? _selectedProvider;
  ProviderData? get selectedProvider => _selectedProvider;

  CartServiceInfoModel? _cartServiceInfo;
  CartServiceInfoModel? get cartServiceInfo => _cartServiceInfo;
  bool get hasCartServiceInfo => _cartServiceInfo?.serviceAddressId != null && _cartServiceInfo?.serviceSchedule != null;

  ServiceBookingStep _bookingStep = ServiceBookingStep.variations;
  ServiceBookingStep get bookingStep => _bookingStep;

  AddressModel? _pendingBookingAddress;
  AddressModel? get pendingBookingAddress => _pendingBookingAddress;

  String? _pendingBookingSchedule;
  String? get pendingBookingSchedule => _pendingBookingSchedule;

  ProviderData? _pendingBookingProvider;
  ProviderData? get pendingBookingProvider => _pendingBookingProvider;

  List<ProviderData>? _filteredBookingProviders;
  List<ProviderData>? get filteredBookingProviders => _filteredBookingProviders;

  String subcategoryId ='';

  int selectedProviderIndex = -1;


  List<dynamic> _extractCartRows(dynamic cartPayload) {
    if (cartPayload == null) return [];
    if (cartPayload is List) return cartPayload;
    if (cartPayload is Map && cartPayload['data'] is List) {
      return cartPayload['data'] as List;
    }
    return [];
  }

  void _applyCartListPayload(dynamic data) {
    if (data == null || data is! Map) return;
    final content = data['content'];
    if (content == null || content is! Map) return;

    _cartList = [];
    for (final cart in _extractCartRows(content['cart'])) {
      if (cart is Map) {
        _cartList.add(CartModel.fromJson(Map<String, dynamic>.from(cart)));
      }
    }

    if (content['wallet_balance'] != null) {
      _walletBalance = double.tryParse(content['wallet_balance'].toString()) ?? 0;
    }
    if (content['total_cost'] != null) {
      _totalPrice = double.tryParse(content['total_cost'].toString()) ?? 0;
    }
    if (content['referral_amount'] != null) {
      _referralAmount = double.tryParse(content['referral_amount'].toString()) ?? 0;
    }

    _additionalChargeLines = [];
    _additionalChargeTotal = 0;
    if (content['additional_charges'] is Map) {
      final additionalCharges = Map<String, dynamic>.from(content['additional_charges'] as Map);
      _additionalChargeTotal = double.tryParse(additionalCharges['total']?.toString() ?? '') ?? 0;
      if (additionalCharges['lines'] is List) {
        for (final line in additionalCharges['lines'] as List) {
          if (line is Map) {
            _additionalChargeLines.add(
              CartAdditionalChargeLine.fromJson(Map<String, dynamic>.from(line)),
            );
          }
        }
      }
    }

    if (_cartList.isNotEmpty) {
      _selectedProvider = _cartList[0].provider;
      subcategoryId = _cartList[0].subCategoryId;
    } else {
      _selectedProvider = null;
    }

    if (content['cart_service_info'] != null) {
      _cartServiceInfo = CartServiceInfoModel.fromJson(
        Map<String, dynamic>.from(content['cart_service_info'] as Map),
      );
      _applyCartServiceInfoToCheckout();
    } else {
      _cartServiceInfo = null;
    }
  }

  Future<void> getCartListFromServer({
    bool shouldUpdate = true,
    bool forceFromServer = false,
  }) async {
    if (forceFromServer) {
      await cartRepo.clearCartListCache();
      final clientResponse = await cartRepo.getCartListFromServer(source: DataSourceEnum.client);
      if (clientResponse.isSuccess &&
          clientResponse.response?.statusCode == 200 &&
          clientResponse.response?.body != null) {
        _applyCartListPayload(clientResponse.response!.body);
        if (shouldUpdate) update();
      }
      return;
    }

    DataSyncHelper.fetchAndSyncData(
      fetchFromLocal: () => cartRepo.getCartListFromServer<CacheResponseData>(source: DataSourceEnum.local),
      fetchFromClient: () => cartRepo.getCartListFromServer(source: DataSourceEnum.client),
      onResponse: (data, source) {
        _applyCartListPayload(data);
        if (shouldUpdate) update();
      },
    );
  }

  Future<void> removeCartFromServer(CartModel cart)async{
    _isLoading = true;
    Response response = await cartRepo.removeCartFromServer(cart.id);
    if(response.statusCode == 200){
      _cartList.remove(cart);
    }

    await getCartListFromServer(shouldUpdate: false, forceFromServer: true);
    _isLoading = false;
    update();
  }


  Future<void> removeAllCartItem()async{
    Response response = await cartRepo.removeAllCartFromServer();
    if(response.statusCode == 200){
      _isLoading = false;
      getCartListFromServer(shouldUpdate: false, forceFromServer: true);
    }
  }

  Future<void> updateCartQuantityToApi(String cartID, int quantity)async{
    _isCartLoading = true;
    update();


    Response response = await cartRepo.updateCartQuantity(cartID, quantity);
    if(response.statusCode == 200){
      _applyCartListPayload(response.body);
    }

    _isCartLoading = false;
    update();
  }

  Future<void> updateProvider(ProviderData? providerData)async{

    _isCartLoading = true;
    update();
    _selectedProvider = providerData;

    Response response = await cartRepo.updateProvider(providerData?.id ?? "");
    if(response.statusCode == 200){
      await getCartListFromServer();
      Get.find<ScheduleController>().buildSchedule(scheduleType: ScheduleType.asap);
    }else{

    }
    _isCartLoading = false;
    update();
  }


  void removeFromCartVariation(CartModel? cartModel) {
    if(cartModel == null) {
      _initialCartList = [];
    }else{
      _initialCartList.remove(cartModel);
      update();
    }
  }

  void removeFromCartList(int cartIndex) {
    _cartList[cartIndex].quantity = _cartList[cartIndex].quantity - 1;
    update();
  }

  void updateQuantity(int index, bool isIncrement) {
    if (isIncrement) {
      _initialCartList[index].quantity += 1;
      _totalPrice = _totalPrice + _initialCartList[index].totalCost;
    } else {
      if (_initialCartList[index].quantity > 0) {
        _initialCartList[index].quantity -= 1;
        _totalPrice = _totalPrice - _initialCartList[index].totalCost;
      }
    }
    _isButton = _isQuantity();
    update();
  }

 bool _isQuantity( ) {
    int count = 0;
    for (var cart in _initialCartList) {
      count += cart.quantity;
    }
    return count > 0;
  }



  void addDataToCart(){
    if(_cartList.isNotEmpty && _initialCartList.first.subCategoryId != _cartList.first.subCategoryId) {
      Get.back();
      Get.dialog(ConfirmationDialog(
        icon: Images.warning,
        title: "are_you_sure_to_reset".tr,
        description: 'you_have_service_from_other_sub_category'.tr,
        onYesPressed: () async {
          _initialCartList.removeWhere((cart) => cart.quantity < 1);
          _cartList = _initialCartList;

          update();
          onDemandToast("successfully_added_to_cart".tr,Colors.green);
          Get.back();
        },
      ));
    }else{
      update();
      onDemandToast("successfully_added_to_cart".tr,Colors.green);
      Get.back();
    }

  }

  Future<bool> addMultipleCartToServer({
    bool fromServiceCenterDialog = true,
    required String providerId,
    bool showApiErrors = true,
  }) async {
    _isLoading = true;
    update();
    _replaceCartList();

    if (_cartList.isEmpty) {
      _isLoading = false;
      update();
      customSnackBar('select_at_least_one_variation'.tr, type: ToasterMessageType.info);
      return false;
    }

    bool success = false;

    if(_cartList.isNotEmpty &&
        _initialCartList.isNotEmpty &&
        _initialCartList.first.subCategoryId != _cartList.first.subCategoryId){
      Get.back();
      await Get.dialog(ConfirmationDialog(
        icon: Images.warning,
        title: "are_you_sure_to_reset".tr,
        description: 'you_have_service_from_other_sub_category'.tr,
        onNoPressed: (){
          Get.back();
        },
        onYesPressed: () async {
          Get.back();
          Get.dialog(const CustomLoader(), barrierDismissible: false,);
          await cartRepo.removeAllCartFromServer();
          bool allAdded = true;
          for (final item in _cartList) {
            final added = await addToCartApi(
              item,
              providerId: providerId,
              showApiErrors: showApiErrors,
            );
            if (!added) allAdded = false;
          }
          await getCartListFromServer();
          success = allAdded && _cartList.isNotEmpty;
          _isLoading = false;
          Get.back();
          if(fromServiceCenterDialog && success){
            customSnackBar("successfully_added_to_cart".tr,type : ToasterMessageType.success);
          }
        },
      ));
    }
    else{
      bool allAdded = true;
      for (final item in _cartList) {
        final added = await addToCartApi(
          item,
          providerId: providerId,
          showApiErrors: showApiErrors,
        );
        if (!added) allAdded = false;
      }
      await getCartListFromServer(shouldUpdate: false, forceFromServer: true);
      success = allAdded && _cartList.isNotEmpty;

      if(fromServiceCenterDialog){
        Get.back();
        if (success) {
          customSnackBar("successfully_added_to_cart".tr,type : ToasterMessageType.success);
        }
      }
    }
    _isLoading = false;
    update();
    return success;
  }

  bool _isCartAddSuccess(Response response) {
    return response.statusCode == 200 &&
        response.body is Map &&
        response.body['response_code']?.toString() == 'default_store_200';
  }

  Future<bool> addToCartApi(
    CartModel cartModel, {
    required String providerId,
    bool showApiErrors = true,
    Service? serviceOverride,
    String? zoneId,
    String? serviceAddressId,
    String? serviceSchedule,
  }) async {
    final service = serviceOverride ?? cartModel.service;
    final serviceId = service?.id ?? cartModel.serviceId;
    final categoryId = service?.categoryId ?? cartModel.categoryId;
    final subCategoryId = service?.subCategoryId ?? cartModel.subCategoryId;

    if (!ValidationHelper.isValidUuid(serviceId) ||
        !ValidationHelper.isValidUuid(categoryId) ||
        !ValidationHelper.isValidUuid(subCategoryId)) {
      if (showApiErrors) {
        customSnackBar('failed_to_add_to_cart'.tr, type: ToasterMessageType.error, aboveOverlays: true);
      }
      return false;
    }

    final guestId = Get.find<AuthController>().isLoggedIn()
        ? null
        : Get.find<SplashController>().getGuestId();

    final body = CartModelBody(
      serviceId: serviceId,
      categoryId: categoryId,
      variantKey: cartModel.variantKey,
      quantity: cartModel.quantity.toString(),
      subCategoryId: subCategoryId,
      providerId: ValidationHelper.isValidUuid(providerId) ? providerId : null,
      guestId: ValidationHelper.isValidUuid(guestId) ? guestId : null,
      zoneId: ValidationHelper.isValidUuid(zoneId) ? zoneId : null,
      serviceAddressId: ValidationHelper.isValidAddressId(serviceAddressId) ? serviceAddressId : null,
      serviceSchedule: serviceSchedule != null && serviceSchedule.isNotEmpty
          ? cartRepo.formatScheduleForApi(serviceSchedule)
          : null,
    );

    final response = await cartRepo.addToCartListToServer(body);

    if (_isCartAddSuccess(response)) {
      return true;
    }
    if (showApiErrors && response.body is Map) {
      ApiChecker.checkApi(response);
    }
    return false;
  }

  /// Adds only the selected booking variations using the service's canonical IDs.
  Future<bool> addBookingCartItemsToServer({
    required Service service,
    String? providerId,
    String? zoneId,
    String? serviceAddressId,
    String? serviceSchedule,
    bool showApiErrors = true,
  }) async {
    final items = _initialCartList.where((cart) => cart.quantity > 0).toList();
    if (items.isEmpty) {
      if (showApiErrors) {
        customSnackBar('select_at_least_one_variation'.tr, type: ToasterMessageType.info, aboveOverlays: true);
      }
      return false;
    }

    if (!ValidationHelper.isValidUuid(service.id) ||
        !ValidationHelper.isValidUuid(service.categoryId) ||
        !ValidationHelper.isValidUuid(service.subCategoryId)) {
      if (showApiErrors) {
        customSnackBar('failed_to_add_to_cart'.tr, type: ToasterMessageType.error, aboveOverlays: true);
      }
      return false;
    }

    var addedCount = 0;
    for (final item in items) {
      final added = await addToCartApi(
        item,
        providerId: providerId ?? '',
        showApiErrors: showApiErrors,
        serviceOverride: service,
        zoneId: zoneId,
        serviceAddressId: serviceAddressId,
        serviceSchedule: serviceSchedule,
      );
      if (added) addedCount++;
    }

    if (addedCount > 0) {
      await getCartListFromServer(shouldUpdate: false, forceFromServer: true);
    }

    return addedCount == items.length;
  }

  String? _resolveZoneIdForBooking(AddressModel address) {
    if (ValidationHelper.isValidUuid(address.zoneId)) {
      return address.zoneId;
    }
    final saved = Get.find<LocationController>().getUserAddress();
    if (ValidationHelper.isValidUuid(saved?.zoneId)) {
      return saved!.zoneId;
    }
    final headerZone = Get.find<LocationController>().zoneID;
    if (ValidationHelper.isValidUuid(headerZone)) {
      return headerZone;
    }
    return null;
  }


  void removeAllAndAddToCart(CartModel cartModel) {
    _cartList = [];
    _cartList.add(cartModel);
    _amount = cartModel.discountedPrice.toDouble() * cartModel.quantity;
    update();
  }

  void setInitialCartList(Service service) {
    _totalPrice = 0;
    _initialCartList = [];
    for (final variation in service.bookableVariations) {
      _initialCartList.add(CartModel(
        service.id!,
        service.id!,
        service.categoryId!,
        service.subCategoryId!,
        variation.variantKey!,
        variation.price!,
        0,
        0,
        0,
        0,
        0,
        '',
        0,
        service.tax ?? 0,
        variation.price ?? 0,
        service,
      ));
    }
    _isButton = false;
  }

  List<CartModel> _replaceCartList() {
    _initialCartList.removeWhere((cart) => cart.quantity < 0);

    for (var initCart in _initialCartList) {
      _cartList.removeWhere((cart) => cart.id.contains(initCart.id) && cart.variantKey.contains(initCart.variantKey));
    }
    _cartList.addAll(_initialCartList);
    _cartList.removeWhere((element) => element.quantity == 0);

    return _cartList;
  }

  ({String? latitude, String? longitude}) _providerListOriginCoordinates() {
    final address = _pendingBookingAddress ??
        Get.find<LocationController>().selectedAddress ??
        Get.find<LocationController>().getUserAddress();
    final lat = address?.latitude?.trim();
    final lng = address?.longitude?.trim();
    if (lat != null &&
        lng != null &&
        lat.isNotEmpty &&
        lng.isNotEmpty &&
        lat != 'null' &&
        lng != 'null') {
      return (latitude: lat, longitude: lng);
    }
    return (latitude: null, longitude: null);
  }

  void _sortProvidersByDistance(List<ProviderData> providers) {
    providers.sort((a, b) {
      if (a.distance == null && b.distance == null) return 0;
      if (a.distance == null) return 1;
      if (b.distance == null) return -1;
      return a.distance!.compareTo(b.distance!);
    });
  }

  Future<void> getProviderBasedOnSubcategory(String subcategoryId,bool reload) async {

    if(reload || _providerList == null){
      _providerList = null;
    }
    final origin = _providerListOriginCoordinates();
    Response response = await cartRepo.getProviderBasedOnSubcategory(
      subcategoryId,
      originLatitude: origin.latitude,
      originLongitude: origin.longitude,
    );
    if (response.statusCode == 200) {
      _providerList = [];
      List<dynamic> list =  response.body['content'];

      for (var element in list) {
        providerList!.add(ProviderData.fromJson(element));
      }
      _sortProvidersByDistance(_providerList!);

      if(_selectedProvider != null && _providerList != null && _providerList!.isNotEmpty){
        for(int i = 0 ; i <_providerList!.length ; i ++ ){
          if(_selectedProvider?.id == _providerList![i].id){
            selectedProviderIndex =i;
          }
        }
      }else{
        selectedProviderIndex = -1;
      }
    } else {
      _providerList = [];
    }
    update();
  }

  void updateProviderSelectedIndex(int index){
    selectedProviderIndex = index;
    if (index >= 0 && _filteredBookingProviders != null && index < _filteredBookingProviders!.length) {
      _pendingBookingProvider = _filteredBookingProviders![index];
    } else if (index == -1) {
      _pendingBookingProvider = null;
    }
    update();
  }

  void resetBookingFlow({bool shouldUpdate = true}) {
    _bookingStep = ServiceBookingStep.variations;
    _pendingBookingAddress = null;
    _pendingBookingSchedule = null;
    _pendingBookingProvider = null;
    _filteredBookingProviders = null;
    selectedProviderIndex = -1;
    if (shouldUpdate) update();
  }

  void setBookingStep(ServiceBookingStep step) {
    _bookingStep = step;
    if (step == ServiceBookingStep.schedule) {
      final scheduleController = Get.find<ScheduleController>();
      scheduleController.initBookingScheduleForFlow();
      scheduleController.updateSelectedBookingType(type: ServiceType.regular);
      _pendingBookingSchedule = scheduleController.scheduleTime;
    }
    update();
  }

  void setPendingBookingAddress(AddressModel address) {
    _pendingBookingAddress = address;
    update();
  }

  void setPendingBookingSchedule(String schedule) {
    _pendingBookingSchedule = schedule;
  }

  void setPendingBookingProvider(ProviderData? provider) {
    _pendingBookingProvider = provider;
    update();
  }

  Future<void> loadProvidersForBooking(String subcategoryId) async {
    final zoneId = _pendingBookingAddress?.zoneId ?? '';
    final origin = _providerListOriginCoordinates();
    _isLoading = true;
    update();
    Response response = await cartRepo.getProviderBasedOnSubcategory(
      subcategoryId,
      zoneId: zoneId,
      originLatitude: origin.latitude,
      originLongitude: origin.longitude,
    );
    List<ProviderData> allProviders = [];
    if (response.statusCode == 200) {
      for (var element in response.body['content']) {
        allProviders.add(ProviderData.fromJson(element));
      }
      _sortProvidersByDistance(allProviders);
    }
    if (_pendingBookingSchedule != null && allProviders.isNotEmpty) {
      final scheduleDate = DateFormat('yyyy-MM-dd HH:mm:ss').parse(_pendingBookingSchedule!);
      final filtered = ProviderAvailabilityHelper.filterBySchedule(allProviders, scheduleDate);
      _filteredBookingProviders = filtered.isNotEmpty ? filtered : allProviders;
    } else {
      _filteredBookingProviders = allProviders;
    }
    if (_filteredBookingProviders != null && _filteredBookingProviders!.isNotEmpty) {
      _sortProvidersByDistance(_filteredBookingProviders!);
    }
    selectedProviderIndex = -1;
    _pendingBookingProvider = null;
    _isLoading = false;
    update();
  }

  void _syncPendingBookingAddress() {
    if (_pendingBookingAddress != null) return;

    final locationController = Get.find<LocationController>();
    if (locationController.selectedAddress != null) {
      _pendingBookingAddress = locationController.selectedAddress;
      return;
    }

    final addresses = locationController.addressList;
    if (addresses != null && addresses.isNotEmpty) {
      _pendingBookingAddress = addresses.first;
      return;
    }

    final saved = locationController.getUserAddress();
    if (saved != null) {
      _pendingBookingAddress = saved;
    }
  }

  void _syncPendingBookingScheduleFromController() {
    if (_pendingBookingSchedule != null && _pendingBookingSchedule!.isNotEmpty) {
      return;
    }
    final scheduleController = Get.find<ScheduleController>();
    if (scheduleController.scheduleTime != null &&
        scheduleController.scheduleTime!.isNotEmpty) {
      _pendingBookingSchedule = scheduleController.scheduleTime;
      return;
    }
    scheduleController.buildSchedule(
      shouldUpdate: false,
      scheduleType: ScheduleType.asap,
    );
    _pendingBookingSchedule = scheduleController.scheduleTime;
  }

  void _persistBookingCartServiceInfo({
    required String zoneId,
    required String addressId,
    required String schedule,
  }) {
    _cartServiceInfo = CartServiceInfoModel(
      zoneId: zoneId,
      serviceAddressId: addressId,
      serviceSchedule: schedule,
    );
  }

  Future<void> completeBookingAndAddToCart({required Service service, required VoidCallback onSuccess}) async {
    _syncPendingBookingAddress();
    var address = _pendingBookingAddress;
    if (address != null) {
      address = AddressHelper.ensureContactPerson(address);
      _pendingBookingAddress = address;
    }
    final addressId = address?.id?.trim();
    if (address == null) {
      customSnackBar('add_address_first'.tr, type: ToasterMessageType.info, aboveOverlays: true);
      return;
    }
    if (!ValidationHelper.isValidAddressId(addressId)) {
      customSnackBar('add_address_first'.tr, type: ToasterMessageType.info, aboveOverlays: true);
      return;
    }
    if (!AddressHelper.hasValidContactPerson(address)) {
      customSnackBar(
        'please_input_contact_person_name_and_phone_number'.tr,
        type: ToasterMessageType.info,
        aboveOverlays: true,
      );
      return;
    }
    _syncPendingBookingScheduleFromController();
    if (_pendingBookingSchedule == null || _pendingBookingSchedule!.isEmpty) {
      customSnackBar('select_your_preferable_booking_time'.tr, type: ToasterMessageType.info, aboveOverlays: true);
      return;
    }

    final zoneId = _resolveZoneIdForBooking(address);
    if (!ValidationHelper.isValidUuid(zoneId)) {
      customSnackBar('service_not_available_in_this_area'.tr, type: ToasterMessageType.info, aboveOverlays: true);
      return;
    }

    _isLoading = true;
    update();

    var otherInfoSaved = false;
    try {
      cartRepo.apiClient.updateHeader(
        cartRepo.apiClient.token,
        zoneId,
        Get.find<LocalizationController>().locale.languageCode,
        Get.find<SplashController>().getGuestId(),
      );

      final providerId = _pendingBookingProvider?.id;
    final formattedSchedule = cartRepo.formatScheduleForApi(_pendingBookingSchedule!);
    final cartAdded = await addBookingCartItemsToServer(
      service: service,
      providerId: providerId,
      zoneId: zoneId,
      serviceAddressId: addressId,
      serviceSchedule: formattedSchedule,
      showApiErrors: true,
    );

      if (!cartAdded) return;

      final otherInfoResponse = await cartRepo.updateCartOtherInfo(
        zoneId: zoneId!,
        serviceAddressId: addressId!,
        serviceSchedule: formattedSchedule,
      );

      otherInfoSaved = otherInfoResponse.statusCode == 200 &&
          otherInfoResponse.body is Map &&
          (otherInfoResponse.body['response_code']?.toString() == 'default_update_200' ||
              otherInfoResponse.body['response_code']?.toString() == 'default_store_200');

    _persistBookingCartServiceInfo(
        zoneId: zoneId!,
        addressId: addressId!,
        schedule: formattedSchedule,
      );

      final locationController = Get.find<LocationController>();
      locationController.updateSelectedAddress(address, shouldUpdate: false);
      await locationController.saveUserAddress(address);
      final scheduleController = Get.find<ScheduleController>();
      if (scheduleController.selectedScheduleType == ScheduleType.asap) {
        scheduleController.buildSchedule(shouldUpdate: false, scheduleType: ScheduleType.asap);
      } else {
        scheduleController.buildSchedule(
          shouldUpdate: false,
          scheduleType: ScheduleType.schedule,
          schedule: _pendingBookingSchedule,
        );
      }
      await getCartListFromServer(shouldUpdate: false, forceFromServer: true);

      try {
        for (CartModel item in _initialCartList) {
          if (item.quantity > 0) {
            AnalyticsHelper.logAddToCart(
              itemId: service.id!,
              itemName: service.name!,
              price: item.price.toDouble(),
              quantity: item.quantity,
              currency: Get.find<SplashController>().configModel.content?.currencyCode ?? '\$',
            );
          }
        }
      } catch (_) {}

      resetBookingFlow(shouldUpdate: false);
      Get.back();
      _showAddedToCartDialog(bookingDetailsSaved: otherInfoSaved);
      onSuccess();
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('completeBookingAndAddToCart failed: $e\n$stack');
      }
      customSnackBar('failed_to_add_to_cart'.tr, type: ToasterMessageType.error, aboveOverlays: true);
    } finally {
      _isLoading = false;
      update();
    }
  }

  void _showAddedToCartDialog({required bool bookingDetailsSaved}) {
    Future.delayed(const Duration(milliseconds: 400), () {
      final context = Get.overlayContext ?? Get.context;
      if (context == null) return;

      Get.dialog(
        ConfirmationDialog(
          icon: Images.cart,
          title: 'item_added_to_cart'.tr,
          description: 'item_added_to_cart_message'.tr,
          yesButtonText: 'go_to_cart',
          noButtonText: 'continue_shopping',
          yesButtonColor: Theme.of(context).colorScheme.primary,
          onNoPressed: () => Get.back(),
          onYesPressed: () {
            Get.back();
            Get.toNamed(RouteHelper.getCartRoute());
          },
        ),
        barrierDismissible: true,
      );
    });
  }

  void _applyCartServiceInfoToCheckout() {
    if (_cartServiceInfo == null) return;
    final locationController = Get.find<LocationController>();
    final scheduleController = Get.find<ScheduleController>();

    if (_cartServiceInfo!.serviceSchedule != null) {
      scheduleController.buildSchedule(
        shouldUpdate: false,
        scheduleType: ScheduleType.schedule,
        schedule: _cartServiceInfo!.serviceSchedule,
      );
    }

    if (_cartServiceInfo!.serviceAddressId != null && locationController.addressList != null) {
      for (final address in locationController.addressList!) {
        if (address.id?.toString() == _cartServiceInfo!.serviceAddressId) {
          final enriched = AddressHelper.ensureContactPerson(address);
          locationController.updateSelectedAddress(enriched, shouldUpdate: false);
          break;
        }
      }
    }
  }

  Future<void> syncCheckoutFromCartServiceInfo() async {
    if (!hasCartServiceInfo) return;
    final locationController = Get.find<LocationController>();
    if (locationController.addressList == null) {
      if (Get.find<AuthController>().isLoggedIn()) {
        await locationController.getAddressList();
      } else {
        final saved = locationController.getUserAddress();
        if (saved != null) {
          locationController.updateSelectedAddress(saved, shouldUpdate: false);
        }
      }
    }
    _applyCartServiceInfoToCheckout();
    update();
  }

  void updatePreselectedProvider(ProviderData? providerData, {bool shouldUpdate = true}){
   _selectedProvider = providerData;

   if(shouldUpdate){
     update();
   }

  }


  void updateWalletPaymentStatus(bool status, {bool shouldUpdate = true}){
    _walletPaymentStatus = status;

    if(shouldUpdate){
      update();
    }
  }

  void updateBookingAmountWithoutCoupon(){
    _couponAmount = CheckoutHelper.calculateDiscount(cartList: _cartList, discountType: DiscountType.coupon);
    _bookingAmountWithoutCoupon =CheckoutHelper.calculateTotalAmountWithoutCoupon(cartList: _cartList);
  }


  bool isOpenPartialPaymentPopup = true;




  Future<void> openWalletPaymentConfirmDialog() async {
    bool initialCheck;
    bool checkAfterUsingCoupon;

    if(_bookingAmountWithoutCoupon > walletBalance){
      initialCheck = true;
    }else{
      initialCheck = false;
    }
    if(_bookingAmountWithoutCoupon > (walletBalance + _couponAmount)){
      checkAfterUsingCoupon =  true;
    }else{
      checkAfterUsingCoupon = false;
    }

    if(initialCheck != checkAfterUsingCoupon && walletPaymentStatus && isOpenPartialPaymentPopup){
      showGeneralDialog(barrierColor: Colors.black.withValues(alpha: 0.5),
        transitionBuilder: (context, a1, a2, widget) {
          return Transform.scale(
            scale: a1.value,
            child: Opacity(
              opacity: a1.value,
              child: Center(
                child: Padding( padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                  child: Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                        color: Theme.of(context).cardColor
                    ),

                    child: Stack(
                      alignment: Alignment.topRight,
                      clipBehavior: Clip.none,
                      children: [
                        const WalletPaymentConfirmDialog(),
                        IconButton(
                          padding: const EdgeInsets.all(0),
                          onPressed: (){
                            Get.back();
                            updateWalletPaymentStatus(false);
                          },
                          icon :  const Icon(Icons.cancel),color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 200),
        barrierDismissible: false,
        barrierLabel: '',
        context: Get.context!,
        pageBuilder: (context, animation1, animation2){
          return Container();
        },
      );
    }
  }


  void showMinimumAndMaximumOrderValueToaster() {
    ConfigModel configModel = Get.find<SplashController>().configModel;

    Get.closeAllSnackbars();

    if(configModel.content!.minBookingAmount !=0 && configModel.content!.minBookingAmount! > _totalPrice && _cartList.isNotEmpty){
      customSnackBar("message",
        customWidget: Row(children: [
          Icon(Icons.circle, color: Colors.white.withValues(alpha: 0.8),size: 16,),
          Text("  ${'minimum_booking_amount'.tr} ${PriceConverter.convertPrice(Get.find<SplashController>().configModel.content!.minBookingAmount!)}",
            style: robotoRegular.copyWith(color: Colors.white),
          ),
        ],),
      );
    }else{
      if(configModel.content!.maxBookingAmount !=0 && configModel.content!.maxBookingAmount! < _totalPrice &&  _cartList.isNotEmpty){
        customSnackBar("message",
          customWidget: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start,children: [
                Icon(Icons.warning_outlined, color: Theme.of(Get.context!).cardColor.withValues(alpha: 0.6),size: 16,),
                const SizedBox(width: Dimensions.paddingSizeExtraSmall,),
                Flexible(child: Text(" ${'maximum_order_amount_exceed'.tr} ""(${'${'maximum_order_amount'.tr}'
                    ' ${PriceConverter.convertPrice(Get.find<SplashController>().configModel.content!.maxBookingAmount!)}'}) ${"admin_will_verify_this_order".tr}",
                  style: robotoRegular.copyWith(color: Colors.white),
                )),
              ],),
            ],
          ),
        );
      }
    }
  }

  Future<void> rebook(String bookingId) async{
    cartRepo.addRebookToServer(bookingId);
  }

  String maskNumberWithoutCountryCode(String phoneNumber) {
    if (phoneNumber.length <= 6) {
      return phoneNumber;
    }
    String maskedNumber = phoneNumber.substring(0, phoneNumber.length - 6); // Keep initial digits

    maskedNumber += '***';
    maskedNumber += phoneNumber.substring(phoneNumber.length - 3);
    return maskedNumber;
  }

  bool checkProviderUnavailability(){
    return _cartList.isNotEmpty &&  _cartList[0].provider !=null &&
        (_cartList[0].provider?.serviceAvailability == 0 || _cartList[0].provider?.isActive== 0 || _cartList[0].provider?.nextBookingEligibility == false);
  }

  bool get hasPastScheduleCartItems =>
      CartBookingDisplayHelper.hasPastScheduleCartItems(_cartList);

  String? _resolveCartZoneId() {
    if (ValidationHelper.isValidUuid(_cartServiceInfo?.zoneId)) {
      return _cartServiceInfo!.zoneId;
    }
    for (final item in _cartList) {
      if (ValidationHelper.isValidUuid(item.zoneId)) {
        return item.zoneId;
      }
    }
    final locationController = Get.find<LocationController>();
    final address = locationController.selectedAddress ?? locationController.getUserAddress();
    if (address != null) {
      final zoneId = _resolveZoneIdForBooking(address);
      if (ValidationHelper.isValidUuid(zoneId)) return zoneId;
    }
    final headerZone = locationController.zoneID;
    if (ValidationHelper.isValidUuid(headerZone)) return headerZone;
    return null;
  }

  bool isProviderAvailableForCartSchedule(ProviderData? provider, DateTime scheduleDateTime) {
    if (provider == null || !ValidationHelper.isValidUuid(provider.id)) {
      return true;
    }
    return ProviderAvailabilityHelper.isProviderAvailableAtSchedule(provider, scheduleDateTime);
  }

  Future<bool> updateCartItemBookingSchedule({
    required String cartId,
    required String scheduleTime,
    required DateTime selectedDateTime,
    ProviderData? provider,
    String? zoneId,
  }) async {
    if (selectedDateTime.isBefore(DateTime.now().add(const Duration(hours: 2)))) {
      customSnackBar('booking_minimum_two_hours_notice'.tr, type: ToasterMessageType.info, aboveOverlays: true);
      return false;
    }
    if (!isProviderAvailableForCartSchedule(provider, selectedDateTime)) {
      customSnackBar(
        'your_selected_provider_is_unavailable_right_now'.tr,
        type: ToasterMessageType.info,
        aboveOverlays: true,
      );
      return false;
    }

    final resolvedZoneId = ValidationHelper.isValidUuid(zoneId) ? zoneId : _resolveCartZoneId();

    _isCartLoading = true;
    update();

    try {
      if (ValidationHelper.isValidUuid(resolvedZoneId)) {
        cartRepo.apiClient.updateHeader(
          cartRepo.apiClient.token,
          resolvedZoneId,
          Get.find<LocalizationController>().locale.languageCode,
          Get.find<SplashController>().getGuestId(),
        );
      }

      final formattedSchedule = cartRepo.formatScheduleForApi(scheduleTime);
      final response = await cartRepo.updateCartItemSchedule(cartId, formattedSchedule);

      if (response.statusCode == 200 && response.body is Map) {
        _applyCartListPayload(response.body);
        await getCartListFromServer(shouldUpdate: false, forceFromServer: true);
        customSnackBar('service_schedule_updated_successfully'.tr, type: ToasterMessageType.success);
        return true;
      }

      if (response.body is Map) {
        ApiChecker.checkApi(response);
      } else {
        customSnackBar('failed_to_update_schedule'.tr, type: ToasterMessageType.error, aboveOverlays: true);
      }
      return false;
    } catch (_) {
      customSnackBar('failed_to_update_schedule'.tr, type: ToasterMessageType.error, aboveOverlays: true);
      return false;
    } finally {
      _isCartLoading = false;
      update();
    }
  }

  String? checkScheduleBookingAvailability(){

    if(Get.find<SplashController>().configModel.content?.scheduleBooking == 0){
      return 'schedule_booking_currently_unavailable'.tr ;
    }else if(_cartList.isNotEmpty &&  _cartList[0].provider != null && ( _cartList[0].provider?.scheduleBookingEligibility == false)){
      return 'schedule_booking_currently_unavailable_for_this_provider'.tr ;
    }else{
      return null;
    }
  }


}
