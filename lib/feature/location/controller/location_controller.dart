import 'dart:convert';

import 'package:demandium/helper/address_session_helper.dart';
import 'package:demandium/helper/db_helper.dart';
import 'package:get/get.dart';
import 'package:demandium/util/core_export.dart';


enum Address {service, billing }
enum AddressLabel {home, office, others }
class LocationController extends GetxController implements GetxService {
  final LocationRepo locationRepo;
  LocationController({required this.locationRepo});

  void refreshUi({bool notify = true}) {
    if (!notify || isClosed) return;
    update();
  }

  Position _position = Position(longitude: 0, latitude: 0, timestamp: DateTime.now(), accuracy: 1, altitude: 1, heading: 1, speed: 1, speedAccuracy: 1, altitudeAccuracy: 1, headingAccuracy: 1);
  Position _pickPosition = Position(longitude: 0, latitude: 0, timestamp: DateTime.now(), accuracy: 1, altitude: 1, heading: 1, speed: 1, speedAccuracy: 1, altitudeAccuracy: 1, headingAccuracy: 1);
  bool _loading = false;
  AddressModel _address = AddressModel();
  AddressModel _pickAddress = AddressModel() ;
  final List<Marker> _markers = <Marker>[];
  List<AddressModel>? _addressList;
  final int _addressLabelIndex = 0;
  AddressModel? _selectedAddress;
  bool _isLoading = false;
  bool _inZone = false;
  String _zoneID = '';
  bool _buttonDisabled = true;
  bool _changeAddress = true;
  bool _isCameraMoving = false;
  GoogleMapController? _mapController;
  List<PredictionModel> _predictionList = [];
  PredictionModel? _firstPredictionModel;
  bool _skipNextPositionUpdate = false;
  Address _selectedAddressType = Address.service;
  AddressLabel _selectedAddressLabel = AddressLabel.home;
  TextEditingController searchController = TextEditingController();
  String  countryDialCode = CountryCode.fromCountryCode(Get.find<SplashController>().configModel.content?.countryCode ?? "BD").dialCode!;



  ServiceLocationType _selectedServiceLocationType = ServiceLocationType.customer;
  ServiceLocationType get selectedServiceLocationType => _selectedServiceLocationType;
  
  String? _newlyAddedAddressId;
  String? get newlyAddedAddressId => _newlyAddedAddressId;

  List<PredictionModel> get predictionList => _predictionList;
  PredictionModel? get firstPredictionModel => _firstPredictionModel;
  bool get isLoading => _isLoading;
  bool get loading => _loading;
  Position get position => _position;
  Position get pickPosition => _pickPosition;
  AddressModel get address => _address;
  AddressModel get pickAddress => _pickAddress;
  List<Marker> get markers => _markers;
  List<AddressModel>? get addressList => _addressList;
  int get addressLabelIndex => _addressLabelIndex;
  bool get inZone => _inZone;
  String get zoneID => _zoneID;
  bool get buttonDisabled => _buttonDisabled;
  bool get isCameraMoving => _isCameraMoving;
  GoogleMapController? get mapController => _mapController;

  ///address type like home , office , others
  Address get selectedAddressType => _selectedAddressType;
  AddressLabel get selectedAddressLabel => _selectedAddressLabel;
  AddressModel? get selectedAddress => _selectedAddress;
  double get minBottomSheetExtent => _minBottomSheetExtent;
  double get maxBottomSheetExtent => _maxBottomSheetExtent;

  set buttonDisabledOption(bool value) => _buttonDisabled = value;

  // Bottom Sheet State
  double _minBottomSheetExtent = 0.25;
  double _maxBottomSheetExtent = 0.85;

  void updateBottomSheetExtent(double min, double max, {bool notify = true}) {
    _minBottomSheetExtent = min;
    _maxBottomSheetExtent = max;
    if (notify) {
      refreshUi();
    }
  }



  Future<AddressModel> getCurrentLocation(bool fromAddress, {bool deviceCurrentLocation = false, GoogleMapController? mapController, LatLng? defaultLatLng, bool notify = true, bool isFromCheckout = false}) async {
    _loading = true;
    if(notify) {
      refreshUi();
    }
    AddressModel addressModel;
    Position myPosition;
    try {
      await Geolocator.requestPermission();
      Position newLocalData = await Geolocator.getCurrentPosition();
      if(getUserAddress() != null && !deviceCurrentLocation){
        myPosition =  Position(
          latitude: double.tryParse(getUserAddress()!.latitude!) ?? 0,
          longitude: double.tryParse(getUserAddress()!.longitude!) ?? 0,
          timestamp: DateTime.now(), accuracy: 1, altitude: 1, heading: 1, speed: 1, speedAccuracy: 1,
          altitudeAccuracy: 1, headingAccuracy: 1,
        );
      }else if(defaultLatLng !=null){

        myPosition =  Position(
            latitude:defaultLatLng.latitude,
            longitude:defaultLatLng.longitude,
            timestamp: DateTime.now(), accuracy: 1, altitude: 1, heading: 1, speed: 1, speedAccuracy: 1,
            altitudeAccuracy: 1, headingAccuracy: 1
        );
      }else{
        myPosition = newLocalData;
      }
    }catch(e) {
      if(defaultLatLng != null){
        myPosition = Position(
            latitude:defaultLatLng.latitude,
            longitude:defaultLatLng.longitude,
            timestamp: DateTime.now(), accuracy: 1, altitude: 1, heading: 1, speed: 1, speedAccuracy: 1,  altitudeAccuracy: 1, headingAccuracy: 1
        );
      }else{
        myPosition = Position(
            latitude:  Get.find<SplashController>().configModel.content?.defaultLocation?.latitude ?? 23.0000,
            longitude: Get.find<SplashController>().configModel.content?.defaultLocation?.longitude ?? 90.0000,
            timestamp: DateTime.now(), accuracy: 1, altitude: 1, heading: 1, speed: 1, speedAccuracy: 1,  altitudeAccuracy: 1, headingAccuracy: 1
        );
      }

    }
    if(fromAddress) {
      _position = myPosition;
    }else {
      _pickPosition = myPosition;
    }
    if (mapController != null) {

      mapController.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(myPosition.latitude, myPosition.longitude), zoom: 16),
      ));
    }
    AddressModel address = await getAddressFromGeocode(LatLng(myPosition.latitude, myPosition.longitude));


    ZoneResponseModel responseModel = await getZone(myPosition.latitude.toString(), myPosition.longitude.toString(), true, isLoading: fromAddress);

    print('--------------res-----> ${responseModel.zoneIds} || ${getUserAddress()?.zoneId}');

    print('--------address----> $fromAddress');


    if(isFromCheckout){
      if(responseModel.zoneIds == getUserAddress()?.zoneId){
        _buttonDisabled = false;
        print('--------------false-----');

      }else{
        print('--------------ture-----');
        _buttonDisabled = true;
      }
    }else{
      _buttonDisabled = !responseModel.isSuccess;
    }

    String? firstName;

    if( Get.find<AuthController>().isLoggedIn() && Get.find<UserController>().userInfoModel?.phone!=null && Get.find<UserController>().userInfoModel?.fName !=null){
      firstName = "${Get.find<UserController>().userInfoModel?.fName} ";
    }
    addressModel = AddressModel(
        latitude: myPosition.latitude.toString(), longitude: myPosition.longitude.toString(), addressType: 'others',
        zoneId: responseModel.isSuccess ? responseModel.zoneIds : '',
        address: address.address ?? "",
        country: address.country ?? "",
        house: address.house ?? "",
        street: address.street ?? "",
        city: address.city ?? "",
        zipCode: address.zipCode ?? "",
        addressLabel: deviceCurrentLocation
            ? AddressSessionHelper.currentLocationSourceLabel
            : AddressLabel.home.name,
        availableServiceCountInZone: responseModel.totalServiceCount,
        contactPersonNumber: firstName !=null? Get.find<UserController>().userInfoModel?.phone ?? "" : "",
        contactPersonName: firstName!=null ? "$firstName${Get.find<UserController>().userInfoModel?.lName ?? "" }" : ""
    );

    fromAddress ? _address = addressModel : _pickAddress = addressModel;
    _loading = false;
    refreshUi();
    return addressModel;
  }

  Future<ZoneResponseModel> getZone(String lat, String long, bool markerLoad, {bool isLoading = false}) async {
    
    if(!isLoading){
      _isLoading = true;
      refreshUi();
    }
    ZoneResponseModel responseModel;
    Response response = await locationRepo.getZone(lat, long);

    int totalServiceCountInZone = 0;
    final body = response.body;
    final content = body is Map ? body['content'] : null;
    final zone = content is Map ? content['zone'] : null;
    if(response.statusCode == 200 && body is Map && zone != null && zone['id'] != null) {
      _inZone = true;
      _zoneID = zone['id'].toString();

      if(body['content']['available_services_count'] !=null){
        totalServiceCountInZone = int.tryParse(body['content']['available_services_count'].toString()) ?? 0;
      }
      responseModel = ZoneResponseModel(true, '',_zoneID, totalServiceCountInZone);
    }else {
      _inZone = false;
      final message = body is Map ? (body['message']?.toString() ?? '') : (response.statusText ?? '');
      responseModel = ZoneResponseModel(false, message, '',totalServiceCountInZone);
    }
    if(!isLoading){
      _isLoading = false;
      refreshUi();
    }
    return responseModel;
  }

  Future<void> updatePosition(CameraPosition position, bool fromAddress, {bool formCheckout = false}) async {
    if (_skipNextPositionUpdate) {
      _skipNextPositionUpdate = false;
      return;
    }

    _loading = true;
    update();

    try {
      if (fromAddress) {
        _position = Position(
          latitude: position.target.latitude,
          longitude: position.target.longitude,
          timestamp: DateTime.now(),
          heading: 1,
          accuracy: 1,
          altitude: 1,
          speedAccuracy: 1,
          speed: 1,
          altitudeAccuracy: 1,
          headingAccuracy: 1,
        );
      } else {
        _pickPosition = Position(
          latitude: position.target.latitude,
          longitude: position.target.longitude,
          timestamp: DateTime.now(),
          heading: 1,
          accuracy: 1,
          altitude: 1,
          speedAccuracy: 1,
          speed: 1,
          altitudeAccuracy: 1,
          headingAccuracy: 1,
        );
      }

      final zoneResponse = await getZone(
        position.target.latitude.toString(),
        position.target.longitude.toString(),
        true,
        isLoading: true,
      );

      if (formCheckout && !zoneResponse.zoneIds.contains(getUserAddress()?.zoneId ?? '')) {
        _buttonDisabled = true;
      } else {
        _buttonDisabled = !zoneResponse.isSuccess;
      }

      if (_changeAddress) {
        final address = await getAddressFromGeocode(
          LatLng(position.target.latitude, position.target.longitude),
        );
        if (fromAddress) {
          _address = address;
        } else {
          _pickAddress = address;
        }
      } else {
        _changeAddress = true;
      }
    } catch (e) {
      if (kDebugMode) {
        print('updatePosition error: $e');
      }
      _buttonDisabled = true;
    } finally {
      _loading = false;
      if (!isClosed) {
        update();
      }
    }
  }

  Future<void> resolvePickMapPosition(
    LatLng latLng, {
    bool fromAddress = false,
    bool formCheckout = false,
  }) async {
    await updatePosition(
      CameraPosition(target: latLng, zoom: 16),
      fromAddress,
      formCheckout: formCheckout,
    );
  }

  Future<ResponseModel> deleteUserAddressByID(AddressModel address) async {
    ResponseModel responseModel ;
    Response response = await locationRepo.removeAddressByID(address.id!);
    if (response.statusCode == 200 && response.body['response_code']=="default_delete_200") {
      await getAddressList();

      if(address.id == _selectedAddress?.id) {
        _selectedAddress = null;
      }
      responseModel = ResponseModel(true, response.body['message']);
    } else {
      responseModel = ResponseModel(false, response.body['message']??response.statusText);
    }
    refreshUi();
    return responseModel;
  }

  Future<void> getAddressList({bool fromCheckout = false, bool showErrorSnackBar = true}) async {
    Response response = await locationRepo.getAllAddress();
    if (response.statusCode == 200) {
      _addressList = <AddressModel>[];
      final content = response.body is Map ? response.body['content'] : null;
      final data = content is Map ? content['data'] : null;
      if (data is List) {
        for (final address in data) {
          _addressList!.add(AddressModel.fromJson(address));
        }
      }
    } else if (showErrorSnackBar) {
      ApiChecker.checkApi(response);
    }
    if(_addressList != null && _addressList!.isNotEmpty){
      for(var element in _addressList!){
        if(element.id == getUserAddress()?.id){
          _addressList?.remove(element);
          _addressList?.insert(0, element);
        }
      }
    }
   // _isLoading = false;

    refreshUi();
  }

  Future<void> addAddress(
    AddressModel addressModel, {
    bool fromAddAddressScreen = false,
    bool fromCheckout = false,
  }) async {
    _isLoading = true;
    refreshUi();
    Response response = await locationRepo.addAddress(addressModel);
    final body = response.body;
    if (body is Map && body["response_code"] == "default_store_200") {
      _newlyAddedAddressId = body["content"]["id"]?.toString();

      await getAddressList();

      Future.delayed(const Duration(seconds: 3), () {
        _newlyAddedAddressId = null;
        refreshUi();
      });

      final saved = AddressModel.fromJson(body["content"]);

      if (fromAddAddressScreen) {
        Get.back();
        if (fromCheckout) {
          updateSelectedAddress(saved);
          customSnackBar('new_address_added_successfully'.tr, type: ToasterMessageType.success);
        } else {
          await AddressSessionHelper.promptUseNewAddress(saved);
        }
      } else {
        await saveUserAddress(saved);
      }
    } else {
      String message = '500'.tr;
      if (body is Map && body['message'] != null) {
        message = body['message'].toString();
      } else if (response.statusText != null && response.statusText!.isNotEmpty) {
        message = response.statusText!;
      }
      if (message == 'out_of_coverage' || message.contains('out_of_coverage')) {
        message = 'service_not_available_in_this_area'.tr;
      }
      customSnackBar(message.tr, type: ToasterMessageType.error);
    }
    _isLoading = false;
    refreshUi();
  }

  Future<ResponseModel> updateAddress(AddressModel addressModel, String addressId) async {
    _isLoading = true;
    refreshUi();
    Response response = await locationRepo.updateAddress(addressModel, addressId);
    ResponseModel responseModel;
    if (response.statusCode == 200) {
      await getAddressList(showErrorSnackBar: false);
      final body = response.body;
      final successMessage = body is Map
          ? (body['message']?.toString() ?? body['response_code']?.toString() ?? 'default_update_200')
          : 'default_update_200';
      responseModel = ResponseModel(true, successMessage);
    } else {
      String message = '500'.tr;
      final body = response.body;
      if (body is Map && body['message'] != null) {
        message = body['message'].toString();
      } else if (body is Map && body['errors'] is List && (body['errors'] as List).isNotEmpty) {
        message = body['errors'][0]['message']?.toString() ?? message;
      } else if (response.statusText != null && response.statusText!.isNotEmpty) {
        message = response.statusText!;
      }
      responseModel = ResponseModel(false, message.tr);
    }
    _isLoading = false;
    refreshUi();
    return responseModel;
  }


  Future<bool> saveUserAddress(AddressModel address) async {
    String userAddress = jsonEncode(address.toJson());
    return await locationRepo.saveUserAddress(userAddress, address.zoneId);
  }

  /// Re-resolves zone from saved coordinates, updates zoneId, service count, and API headers.
  Future<bool> refreshSavedAddressZone() async {
    final address = getUserAddress();
    if (address?.latitude == null ||
        address?.longitude == null ||
        address!.latitude!.isEmpty ||
        address.longitude!.isEmpty) {
      return false;
    }

    final previousZoneId = address.zoneId?.trim();

    final zoneResponse = await getZone(
      address.latitude.toString(),
      address.longitude.toString(),
      false,
      isLoading: true,
    );

    if (!zoneResponse.isSuccess) {
      address.availableServiceCountInZone = 0;
      await saveUserAddress(address);
      return false;
    }
    if (zoneResponse.isSuccess && zoneResponse.zoneIds.isNotEmpty) {
      address.zoneId = zoneResponse.zoneIds;
    }
    address.availableServiceCountInZone = zoneResponse.totalServiceCount;
    await saveUserAddress(address);
    await DbHelper.clearCacheOnZoneChange(
      previousZoneId: previousZoneId,
      newZoneId: address.zoneId?.trim(),
    );
    return zoneResponse.isSuccess;
  }


  AddressModel? getUserAddress() {
    AddressModel? addressModelUser;
    try {
      addressModelUser = AddressModel.fromJson(jsonDecode(locationRepo.getUserAddress()!));
      //_selectedAddress = addressModelUser;
    }catch(e){
      return addressModelUser;
    }
    return addressModelUser;
  }

  ///
  Future<void> saveAddressAndNavigate(
    AddressModel address,
    bool fromSignUp,
    String? route,
    bool canRoute,
    bool isServiceAvailable, {
    bool fromAddressDialog = false,
    String? showDialog,
    ZoneResponseModel? resolvedZone,
  }) async {
    final ZoneResponseModel responseModel = resolvedZone ?? await getZone(
      address.latitude.toString(),
      address.longitude.toString(),
      true,
    );

    if (!responseModel.isSuccess || responseModel.zoneIds.trim().isEmpty) {
      final message = (responseModel.message?.trim().isNotEmpty ?? false)
          ? responseModel.message!
          : 'service_not_available_in_this_area'.tr;
      customSnackBar(message.tr, type: ToasterMessageType.error);
      return;
    }

    AddressModel? previousAddress = getUserAddress();
    if(previousAddress != null) {
      setZoneContinue('true');
    }

    address.availableServiceCountInZone = responseModel.totalServiceCount;

    if(!fromAddressDialog && (getUserAddress() != null && getUserAddress()!.zoneId != null)? !responseModel.zoneIds.contains(getUserAddress()!.zoneId.toString()) : true && Get.find<CartController>().cartList.isNotEmpty) {
      Get.dialog(ConfirmationDialog(
        icon: Images.warning, title: 'are_you_sure_to_reset'.tr, description: 'if_you_change_location'.tr,
        onYesPressed: () {
          Get.back();
          _setZoneData(address, fromSignUp, route, canRoute,true, responseModel.zoneIds, previousAddress, isServiceAvailable, showDialog: showDialog);
        },
        onNoPressed: () {
          Get.back();
          Get.back();
        },
      ));
    }else {
      _setZoneData(address, fromSignUp, route, canRoute,false, responseModel.zoneIds, previousAddress, isServiceAvailable, showDialog: showDialog);
    }
  }

  void _setZoneData(AddressModel address, bool fromSignUp, String? route, bool canRoute,bool shouldCartDelete, String? zoneIds, AddressModel? previousAddress, bool? isServiceAvailable, {String? showDialog}) {
    if(zoneIds != null && zoneIds.trim().isNotEmpty){
      address.zoneId = zoneIds;
      autoNavigate(address, fromSignUp, route, canRoute, previousAddress,isServiceAvailable, shouldCartDelete: shouldCartDelete, showDialog: showDialog);
    }

  }

  void autoNavigate(AddressModel address, bool fromSignUp, String? route, bool canRoute, AddressModel? previousAddress, bool? isServiceAvailable, {bool shouldCartDelete = false,  String? showDialog}) async {
    if(GetPlatform.isAndroid && !GetPlatform.isWeb){
      if(getUserAddress() != null){
        if (getUserAddress()!.zoneId != address.zoneId) {
          FirebaseMessaging.instance.unsubscribeFromTopic('zone_${getUserAddress()!.zoneId}_customer');
          FirebaseMessaging.instance.subscribeToTopic('zone_${address.zoneId}_customer');
        }
      }
      else {
        FirebaseMessaging.instance.subscribeToTopic('zone_${address.zoneId}_customer');
      }
    }
    await saveUserAddress(address);

    if (shouldCartDelete) {
      await Get.find<CartController>().removeAllCartItem();
    }

    if (!canRoute) {
      return;
    }

    HomeScreen.loadData(true);
    if (route != null && route != "" && route != "home") {
      Get.offAllNamed(route);
    } else {
      Get.offAllNamed(RouteHelper.getMainRoute('home', previousAddress: previousAddress, showServiceNotAvailableDialog: showDialog));
    }
  }

  Future<AddressModel> setLocation(String placeID, String address, GoogleMapController? mapController) async {
    _loading = true;
    refreshUi();

    LatLng latLng = const LatLng(0, 0);

    AddressModel addressModel = AddressModel();
    addressModel.address = address;

    Response response = await locationRepo.getPlaceDetails(placeID);

    if(response.statusCode == 200) {
      PlaceDetailsModel placeDetails = PlaceDetailsModel.fromJson(response.body);
      latLng = LatLng(placeDetails.content?.location?.latitude ?? 0, placeDetails.content?.location?.longitude  ?? 0);

      addressModel.latitude = latLng.latitude.toString();
      addressModel.longitude = latLng.longitude.toString();

      if (placeDetails.content?.formattedAddress?.isNotEmpty ?? false) {
        addressModel.address = placeDetails.content!.formattedAddress!;
      }

      placeDetails.content?.addressComponents?.forEach((element) {
        if(element.types !=null){
          if(element.types!.contains("country")){
            addressModel.country = element.longName ?? "";
          }
          if(element.types!.contains("locality") && element.types!.contains("political")){
            addressModel.city = element.longName ?? "";
          }
          if(element.types!.contains("street_number")) {
            addressModel.house = element.longName ?? "";
          }
          if(element.types!.contains("route")){
            addressModel.street = element.longName ?? "";
          }
          if(element.types!.contains("postal_code")){
            addressModel.zipCode = element.longName ?? "";
          }
        }
      });

    }

    _pickPosition = Position(
      latitude: latLng.latitude, longitude: latLng.longitude,
      timestamp: DateTime.now(), accuracy: 1, altitude: 1, heading: 1, speed: 1, speedAccuracy: 1,
        altitudeAccuracy: 1, headingAccuracy: 1
    );

    addressModel.addressLabel = AddressSessionHelper.selectedFromMapSourceLabel;
    _pickAddress = addressModel;
    _changeAddress = false;

    if (Get.currentRoute?.contains(RouteHelper.addAddress) ?? false) {
      _position = _pickPosition;
      _address = addressModel;
      final zoneResponse = await getZone(
        latLng.latitude.toString(),
        latLng.longitude.toString(),
        true,
      );
      _buttonDisabled = !zoneResponse.isSuccess;
    }

    if (mapController != null) {
      mapController.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: latLng, zoom: 17)));
    }
    _loading = false;
    refreshUi();

    return addressModel;
  }

  void disableButton() {
    _buttonDisabled = true;
    update();
  }

  void setAddAddressData() {
    _position = _pickPosition;
    _address = _pickAddress;
    _skipNextPositionUpdate = true;
    _buttonDisabled = false;
    refreshUi();
  }

  void setUpdateAddress(AddressModel address, {bool shouldUpdate = true}){
    final latitude = double.tryParse(address.latitude?.toString() ?? '') ?? 0;
    final longitude = double.tryParse(address.longitude?.toString() ?? '') ?? 0;
    _position = Position(
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
      altitude: 1,
      heading: 1,
      speed: 1,
      speedAccuracy: 1,
      floor: 1,
      accuracy: 1,
      altitudeAccuracy: 1,
      headingAccuracy: 1,
    );
    _address.address = address.address ?? '';
    if (address.zoneId != null && address.zoneId!.trim().isNotEmpty) {
      _zoneID = address.zoneId!.trim();
      _inZone = true;
    }
    _skipNextPositionUpdate = true;
    refreshUi(notify: shouldUpdate);
  }

  void updateAddressType(Address address, {bool shouldUpdate = true}){
    _selectedAddressType = address;
    refreshUi(notify: shouldUpdate);
  }

  void updateAddressLabel({AddressLabel? addressLabel, String addressLabelString = '', bool shouldUpdate = true}){
    if(addressLabel == null) {
      _selectedAddressLabel = _getAddressLabel(addressLabelString);
    }else{
      _selectedAddressLabel = addressLabel;
    }
    refreshUi(notify: shouldUpdate);
  }

  AddressLabel _getAddressLabel(String addressLabel) {
    late AddressLabel label;
    if(AddressLabel.home.name.contains(addressLabel)) {
      label = AddressLabel.home;
    }else if(AddressLabel.office.name.contains(addressLabel)){
      label = AddressLabel.office;
    }else{
      label = AddressLabel.others;
    }

    return label;
  }


  ///set address index to select address from address list
  Future<bool> setAddressIndex(AddressModel address,{bool fromAddressScreen = true}) async {
    bool isSuccess = false;
    if(fromAddressScreen){
      ZoneResponseModel selectedZone = await  getZone('${address.latitude}', '${address.longitude}', false);
      if(selectedZone.zoneIds.contains(getUserAddress()?.zoneId??"")) {
        _selectedAddress = address;

        refreshUi();
        isSuccess = true;
      }else{
        isSuccess = false;
      }
    }else{
      _selectedAddress = address;
      refreshUi();
      isSuccess = true;
    }
    return isSuccess;
  }

  void resetAddress({bool clearMapController = true, bool notify = true}) {
    _address = AddressModel();
    _changeAddress = true;
    _loading = false;
    if (clearMapController) {
      _mapController = null;
    }
    if (notify) {
      refreshUi();
    }
  }

  /// Clears in-memory address state when the customer session ends or switches.
  void clearSessionData({bool notify = true}) {
    _addressList = null;
    _selectedAddress = null;
    _newlyAddedAddressId = null;
    _inZone = false;
    _zoneID = '';
    resetAddress(clearMapController: true, notify: false);
    if (notify) {
      refreshUi();
    }
  }

  void clearMapController() {
    _mapController = null;
  }

  void setPickData() {
    _pickPosition = _position;
    _pickAddress = _address;
    _changeAddress = true;
    _skipNextPositionUpdate = false;
  }

  void setMapController(GoogleMapController mapController) {
    _mapController = mapController;
  }

  Future<AddressModel> getAddressFromGeocode(LatLng latLng) async {
    Response response = await locationRepo.getAddressFromGeocode(latLng);
    AddressFormat addressFormat;
    AddressModel address = AddressModel(
      address: 'Unknown Location Found'
    );
    if(response.statusCode == 200 && response.body['content']['status'] == 'OK') {

      addressFormat = AddressFormat.fromJson( response.body['content']['results'][0]);

      addressFormat.addressComponents?.forEach((element) {

        if(element.types !=null){
          if(element.types!.contains("country")){
            address.country = element.longName ?? "";
          }
          if(element.types!.contains("locality") && element.types!.contains("political")){
            address.city = element.longName ?? "";
          }
          if(element.types!.contains("street_number")) {
            address.house = element.longName ?? "";
          }
          if(element.types!.contains("route")){
            address.street = element.longName ?? "";
          }

          if(element.types!.contains("postal_code")){
            address.zipCode = element.longName ?? "";
          }
        }
      });
      address.address = addressFormat.formattedAddress ?? "";
    }
    return address;
  }

  Future<List<PredictionModel>> searchLocation(BuildContext context, String text) async {

    _firstPredictionModel = null;

    if (text.isNotEmpty) {
      Response response = await locationRepo.searchLocation(text);
      if (response.statusCode == 200 && response.body['response_code'] == 'default_200') {
        _predictionList = [];
        final suggestions = response.body['content']?['suggestions'];
        if (suggestions is List) {
          try {
            for (final prediction in suggestions) {
              _predictionList.add(PredictionModel.fromJson(prediction));
            }
          } catch (_) {
            _predictionList = [];
          }
        }

        if (_predictionList.isNotEmpty) {
          _firstPredictionModel = _predictionList.first;
        }
      }
    }
    return _predictionList;
  }

  void setPlaceMark({
    AddressModel? addressModel,
    String? address,
    String? house,
    String? floor,
    String? city,
    String? country,
    String? landmark,
    String? zipCode,
    String? street,
  }) {
    if (addressModel != null) {
      _address = addressModel;
    }

    if (address != null) {
      _address.address = address;
    } else if (house != null) {
      _address.house = house;
    } else if (floor != null) {
      _address.floor = floor;
    } else if (city != null) {
      _address.city = city;
    } else if (country != null) {
      _address.country = country;
    } else if (landmark != null) {
      _address.landmark = landmark;
    } else if (zipCode != null) {
      _address.zipCode = zipCode;
    } else if (street != null) {
      _address.street = street;
    }
  }

  void updateSelectedAddress(AddressModel? addressModel, {bool shouldUpdate = true} ) {
    _selectedAddress =  addressModel;

    if(shouldUpdate){
      refreshUi();
    }
  }

  Future<void> updatePostInformation(String postId,String addressId) async {
    Response response = await locationRepo.changePostServiceAddress(postId,addressId);

    if(response.statusCode==200 && response.body['response_code']=="default_update_200"){
      customSnackBar("service_schedule_updated_successfully".tr,type : ToasterMessageType.success);
    }
  }

  Future<void>  setZoneContinue(String isContinue) async {
    await  locationRepo.setZoneContinue(isContinue);
  }

  String getZoneContinue() {
    return locationRepo.getZoneContinue();
  }

  void mapBound(GoogleMapController controller, List<Coordinates>? coordinates) async {
    List<LatLng> latLongList = [];

    if (coordinates != null) {
      for (int subIndex = 0; subIndex < coordinates.length; subIndex++) {
        latLongList.add(LatLng(coordinates[subIndex].latitude!, coordinates[subIndex].longitude!));
      }
    }

    await controller.getVisibleRegion();
    Future.delayed(const Duration(milliseconds: 100), () {
      controller.animateCamera(CameraUpdate.newLatLngBounds(
        MapHelper.boundsFromLatLngList(latLongList),
        100.5,
      ));
    });

    refreshUi();
  }

  void updateCameraMovingStatus(bool status){
    _isCameraMoving = status;
    refreshUi();
  }

  void updateSelectedServiceLocationType ({ServiceLocationType? type, bool shouldUpdate = true}){
    if(type !=null){
      _selectedServiceLocationType = type;
      if(shouldUpdate){
        refreshUi();
      }
    }else{
      _selectedServiceLocationType = ServiceLocationType.customer;
    }
  }


}