import 'package:demandium/common/widgets/custom_pop_widget.dart';
import 'package:get/get.dart';
import 'package:demandium/util/core_export.dart';
import 'package:demandium/common/widgets/address_selection_drawer.dart';
import 'package:demandium/feature/address/widget/address_form_bottom_sheet.dart';
import 'package:demandium/feature/address/widget/contact_info_section.dart';
import 'package:demandium/feature/address/widget/address_details_section.dart';
import 'package:demandium/feature/address/widget/address_map_section.dart';
class AddAddressScreen extends StatefulWidget {
  final bool fromCheckout;
  final AddressModel? address;
  const AddAddressScreen({super.key, required this.fromCheckout, this.address});

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final TextEditingController _contactPersonNameController = TextEditingController();
  final TextEditingController _contactPersonNumberController = TextEditingController();
  final TextEditingController _serviceAddressController = TextEditingController();
  final TextEditingController _houseController = TextEditingController();
  final TextEditingController _floorController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _zipController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();

  final FocusNode _nameNode = FocusNode();
  final FocusNode _numberNode = FocusNode();
  final FocusNode _serviceAddressNode = FocusNode();
  final FocusNode _houseNode = FocusNode();
  final FocusNode _floorNode = FocusNode();
  final FocusNode _landmarkNode = FocusNode();
  final FocusNode _cityNode = FocusNode();
  final FocusNode _zipNode = FocusNode();
  final FocusNode _streetNode = FocusNode();

  LatLng? _initialPosition;
  final GlobalKey<FormState> addressFormKey = GlobalKey<FormState>();
  final Completer<GoogleMapController> _controller = Completer();

  CameraPosition? _cameraPosition;

  // ValueNotifier to communicate bottom sheet extent without rebuilding
  final ValueNotifier<double> _bottomSheetExtent = ValueNotifier<double>(0.25);

  bool _showDetailsStep = false;

  @override
  void initState() {
    super.initState();
    final locationController = Get.find<LocationController>();
    if (widget.address != null) {
      _initialPosition = LatLng(
        double.tryParse(widget.address!.latitude ?? '') ?? 0,
        double.tryParse(widget.address!.longitude ?? '') ?? 0,
      );
      setControllerData();
    } else {
      locationController.resetAddress(notify: false);
      locationController.updateAddressLabel(addressLabelString: 'home'.tr, shouldUpdate: false);
      Get.find<LocationController>().countryDialCode = CountryCode.fromCountryCode(Get.find<SplashController>().configModel.content?.countryCode ?? "BD").dialCode!;
      _prefillDefaultContactInfo();
      if (Get.find<AuthController>().isLoggedIn()) {
        final userController = Get.find<UserController>();
        if (userController.userInfoModel == null) {
          userController.getUserInfo(reload: false).then((_) {
            if (mounted) {
              setState(_prefillDefaultContactInfo);
            }
          });
        }
      }

      _initialPosition = LatLng(
        double.tryParse(locationController.getUserAddress()?.latitude ?? '') ??
            (Get.find<SplashController>().configModel.content?.defaultLocation?.latitude ?? 23.0000),
        double.tryParse(locationController.getUserAddress()?.longitude ?? '') ??
            (Get.find<SplashController>().configModel.content?.defaultLocation?.longitude ?? 90.0000),
      );

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final address = await locationController.getCurrentLocation(
          true,
          mapController: locationController.mapController,
          defaultLatLng: _initialPosition,
        );
        if (!mounted) {
          return;
        }
        _serviceAddressController.text = address.address ?? '';
        _cityController.text = address.city ?? '';
        _landmarkController.text = address.landmark ?? '';
        _streetController.text = address.street ?? '';
        _zipController.text = address.zipCode ?? '';
        _houseController.text = address.house ?? '';
        _floorController.text = address.floor ?? '';
        _prefillDefaultContactInfo();
      });
    }
  }

  void _prefillDefaultContactInfo() {
    if (widget.address != null) return;

    final user = Get.find<UserController>().userInfoModel;
    final locationController = Get.find<LocationController>();

    if (_contactPersonNameController.text.trim().isEmpty) {
      final nameParts = <String>[];
      if (user?.fName != null && user!.fName!.trim().isNotEmpty) {
        nameParts.add(user.fName!.trim());
      }
      if (user?.lName != null && user!.lName!.trim().isNotEmpty) {
        nameParts.add(user.lName!.trim());
      }
      if (nameParts.isNotEmpty) {
        _contactPersonNameController.text = nameParts.join(' ');
      }
    }

    if (_contactPersonNumberController.text.trim().isEmpty && user?.phone != null) {
      final dialCode = Get.find<UserController>().countryDialCode;
      if (dialCode.isNotEmpty) {
        locationController.countryDialCode = dialCode;
      }
      final localNumber = PhoneVerificationHelper.isPhoneValid(user!.phone!, fromAuthPage: false);
      if (localNumber.isNotEmpty) {
        _contactPersonNumberController.text = localNumber;
      }
    }
  }

  String _defaultCountryName() => '';

  void _syncFieldsFromLocationController() {
    final address = Get.find<LocationController>().address;
    _serviceAddressController.text = address.address ?? '';
    _cityController.text = address.city ?? '';
    _landmarkController.text = address.landmark ?? '';
    _streetController.text = address.street ?? '';
    _zipController.text = address.zipCode ?? '';
    _houseController.text = address.house ?? '';
    _floorController.text = address.floor ?? '';
  }

  Future<void> _openPickMapScreen() async {
    final picked = await Get.toNamed<bool>(
      RouteHelper.getPickMapRoute(
        'add-address',
        false,
        '${widget.fromCheckout}',
        null,
        null,
      ),
      arguments: PickMapScreen(
        fromAddAddress: true,
        fromSignUp: false,
        googleMapController: Get.find<LocationController>().mapController,
        route: null,
        canRoute: false,
        formCheckout: widget.fromCheckout,
        zone: null,
      ),
    );
    if (picked == true && mounted) {
      _syncFieldsFromLocationController();
    }
  }

  Future<void> setControllerData() async {
    final address = widget.address;
    if (address == null) return;

    _serviceAddressController.text = address.address ?? "";
    _contactPersonNameController.text = address.contactPersonName ?? '';

    String numberAfterValidation = PhoneVerificationHelper.isPhoneValid(
        address.contactPersonNumber ?? Get.find<UserController>().userInfoModel?.phone ?? "", fromAuthPage: false);
    if(numberAfterValidation == ""){
      _contactPersonNumberController.text = address.contactPersonNumber?.replaceAll("null", "") ?? "";
    }else{
      _contactPersonNumberController.text = numberAfterValidation;
    }
    _cityController.text = address.city ?? '';
    _landmarkController.text = address.landmark ?? '';
    _streetController.text = address.street ?? "";
    _zipController.text = address.zipCode ?? '';
    _houseController.text = address.house ?? '';
    _floorController.text = address.floor ?? '';

    final locationController = Get.find<LocationController>();
    final dialCode = CountryCode.fromCountryCode(
      Get.find<SplashController>().configModel.content?.countryCode ?? 'BD',
    ).dialCode;
    if (dialCode != null && dialCode.isNotEmpty) {
      locationController.countryDialCode = dialCode;
    }
    locationController.updateAddressLabel(addressLabelString: address.addressLabel ?? "", shouldUpdate: false);
    if (address.addressType == Address.billing.name) {
      locationController.updateAddressType(Address.billing, shouldUpdate: false);
    } else {
      locationController.updateAddressType(Address.service, shouldUpdate: false);
    }
    locationController.setPlaceMark(addressModel: address);
    locationController.buttonDisabledOption = false;
    locationController.setUpdateAddress(address, shouldUpdate: false);

    _initialPosition = LatLng(
      double.tryParse(address.latitude ?? '') ?? 0,
      double.tryParse(address.longitude ?? '') ?? 0,
    );
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _bottomSheetExtent.dispose();
    Get.find<LocationController>().clearMapController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_initialPosition == null) {
      return CustomPopWidget(
        child: Scaffold(
          appBar: CustomAppBar(
            title: widget.address != null ? 'update_address'.tr : 'select_your_location'.tr,
          ),
          body: const Center(child: CustomLoader()),
        ),
      );
    }

    double bottomPadding = MediaQuery.of(context).padding.bottom;

    return CustomPopWidget(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: CustomAppBar(
          title: widget.address != null
              ? 'update_address'.tr
              : _showDetailsStep
                  ? 'address_info'.tr
                  : 'select_your_location'.tr,
          onBackPressed: widget.address == null && _showDetailsStep
              ? () => setState(() => _showDetailsStep = false)
              : null,
        ),
        drawer: ResponsiveHelper.isDesktop(context) ? const AddressSelectionDrawer() : null,
        endDrawer: ResponsiveHelper.isDesktop(context) ? const MenuDrawer() : null,
        
        body: !ResponsiveHelper.isDesktop(context)
            ? widget.address != null
                ? _MobileAddressLayout(
                    initialPosition: _initialPosition!,
                    controller: _controller,
                    fromCheckout: widget.fromCheckout,
                    formKey: addressFormKey,
                    contactPersonNameController: _contactPersonNameController,
                    contactPersonNumberController: _contactPersonNumberController,
                    serviceAddressController: _serviceAddressController,
                    houseController: _houseController,
                    floorController: _floorController,
                    landmarkController: _landmarkController,
                    cityController: _cityController,
                    zipController: _zipController,
                    streetController: _streetController,
                    nameNode: _nameNode,
                    numberNode: _numberNode,
                    serviceAddressNode: _serviceAddressNode,
                    houseNode: _houseNode,
                    floorNode: _floorNode,
                    landmarkNode: _landmarkNode,
                    cityNode: _cityNode,
                    zipNode: _zipNode,
                    streetNode: _streetNode,
                    onSave: () => _saveAddress(Get.find<LocationController>()),
                    isUpdate: true,
                    onCameraMove: (position) => _cameraPosition = position,
                    onCameraIdle: () {
                      try {
                        Get.find<LocationController>().updatePosition(_cameraPosition!, true, formCheckout: widget.fromCheckout);
                      } catch (error) {
                        if (kDebugMode) {
                          print('error : $error');
                        }
                      }
                    },
                    onMapCreated: (GoogleMapController controller) {
                      Get.find<LocationController>().setMapController(controller);
                      _controller.complete(controller);
                    },
                    checkPermission: _checkPermission,
                    bottomSheetExtent: _bottomSheetExtent,
                    onOpenPickMap: _openPickMapScreen,
                  )
                : _showDetailsStep
                    ? _MobileAddressDetailsStep(
                        formKey: addressFormKey,
                        contactPersonNameController: _contactPersonNameController,
                        contactPersonNumberController: _contactPersonNumberController,
                        serviceAddressController: _serviceAddressController,
                        houseController: _houseController,
                        floorController: _floorController,
                        landmarkController: _landmarkController,
                        cityController: _cityController,
                        zipController: _zipController,
                        streetController: _streetController,
                        nameNode: _nameNode,
                        numberNode: _numberNode,
                        serviceAddressNode: _serviceAddressNode,
                        houseNode: _houseNode,
                        floorNode: _floorNode,
                        landmarkNode: _landmarkNode,
                        cityNode: _cityNode,
                        zipNode: _zipNode,
                        streetNode: _streetNode,
                        onSave: () => _saveAddress(Get.find<LocationController>()),
                        onChangeLocation: () => setState(() => _showDetailsStep = false),
                      )
                    : _MobileAddressLocationStep(
                        initialPosition: _initialPosition!,
                        controller: _controller,
                        fromCheckout: widget.fromCheckout,
                        serviceAddressController: _serviceAddressController,
                        onContinue: _continueToAddressDetails,
                        onCameraMove: (position) => _cameraPosition = position,
                        onCameraIdle: () {
                          try {
                            Get.find<LocationController>().updatePosition(_cameraPosition!, true, formCheckout: widget.fromCheckout);
                          } catch (error) {
                            if (kDebugMode) {
                              print('error : $error');
                            }
                          }
                        },
                        onMapCreated: (GoogleMapController controller) {
                          Get.find<LocationController>().setMapController(controller);
                          _controller.complete(controller);
                        },
                        checkPermission: _checkPermission,
                        onOpenPickMap: _openPickMapScreen,
                      )
            : _DesktopAddressLayout(
                initialPosition: _initialPosition!,
                controller: _controller,
                fromCheckout: widget.fromCheckout,
                formKey: addressFormKey,
                contactPersonNameController: _contactPersonNameController,
                contactPersonNumberController: _contactPersonNumberController,
                serviceAddressController: _serviceAddressController,
                houseController: _houseController,
                floorController: _floorController,
                landmarkController: _landmarkController,
                cityController: _cityController,
                zipController: _zipController,
                streetController: _streetController,
                nameNode: _nameNode,
                numberNode: _numberNode,
                serviceAddressNode: _serviceAddressNode,
                houseNode: _houseNode,
                floorNode: _floorNode,
                landmarkNode: _landmarkNode,
                cityNode: _cityNode,
                zipNode: _zipNode,
                streetNode: _streetNode,
                onSave: () => _saveAddress(Get.find<LocationController>()),
                isUpdate: widget.address != null,
                bottomPadding: bottomPadding,
                onCameraMove: (position) => _cameraPosition = position,
                onCameraIdle: () {
                  try {
                    Get.find<LocationController>().updatePosition(_cameraPosition!, true, formCheckout: widget.fromCheckout);
                  } catch (error) {
                    if (kDebugMode) {
                      print('error : $error');
                    }
                  }
                },
                onMapCreated: (GoogleMapController controller) {
                  Get.find<LocationController>().setMapController(controller);
                  _controller.complete(controller);

                },
                checkPermission: _checkPermission,
              ),
      ),
    );
  }

  void _continueToAddressDetails() {
    final locationController = Get.find<LocationController>();
    if (locationController.loading) {
      return;
    }
    if (locationController.buttonDisabled) {
      customSnackBar('service_not_available_in_this_area'.tr, type: ToasterMessageType.info);
      return;
    }
    final addressText = _serviceAddressController.text.trim().isNotEmpty
        ? _serviceAddressController.text.trim()
        : locationController.address.address?.trim() ?? '';
    if (addressText.isEmpty) {
      customSnackBar('pick_an_address'.tr, type: ToasterMessageType.info);
      return;
    }
    _syncFieldsFromLocationController();
    setState(() => _showDetailsStep = true);
  }

  String _formatContactPhone(LocationController locationController) {
    final dialCode = locationController.countryDialCode;
    final localNumber = PhoneVerificationHelper.isPhoneValid(
      dialCode + _contactPersonNumberController.text,
      fromAuthPage: false,
    );
    return dialCode + localNumber;
  }

  void _saveAddress (LocationController locationController ) async {
    final isValid = addressFormKey.currentState!.validate();

    if(isValid ){
      addressFormKey.currentState!.save();

      if (locationController.position.latitude == 0 &&
          locationController.position.longitude == 0) {
        customSnackBar('pick_an_address'.tr, type: ToasterMessageType.info);
        return;
      }

      var zoneId = locationController.zoneID.isNotEmpty
          ? locationController.zoneID
          : widget.address?.zoneId;
      if (zoneId == null || zoneId.isEmpty) {
        final zoneResponse = await locationController.getZone(
          locationController.position.latitude.toString(),
          locationController.position.longitude.toString(),
          false,
          isLoading: true,
        );
        if (zoneResponse.isSuccess && zoneResponse.zoneIds.isNotEmpty) {
          zoneId = zoneResponse.zoneIds;
        }
      }

      AddressModel addressModel = AddressModel(
        id: widget.address?.id ,
        addressType: locationController.selectedAddressType.name,
        addressLabel:locationController.selectedAddressLabel.name.toLowerCase(),
        contactPersonName: _contactPersonNameController.text,
        contactPersonNumber: _formatContactPhone(locationController),
        address: _serviceAddressController.text,
        city: _cityController.text,
        zipCode: _zipController.value.text,
        country: _defaultCountryName(),
        landmark: _landmarkController.text.trim(),
        house: _houseController.text,
        floor: _floorController.text,
        latitude: locationController.position.latitude.toString(),
        longitude: locationController.position.longitude.toString(),
        zoneId: zoneId,
        street: _streetController.text,
      );
      if (kDebugMode) {
        print("After Address Model and Save Button , Country Code is ${addressModel.contactPersonNumber}");
      }
      if(widget.address == null) {
        locationController.addAddress(
          addressModel,
          fromAddAddressScreen: true,
          fromCheckout: widget.fromCheckout,
        );
      }else {
        if((widget.address!.id !=null && widget.address!.id != "null" && Get.find<AuthController>().isLoggedIn())){

          locationController.updateAddress(addressModel, widget.address!.id!).then((response) {
            if(response.isSuccess!) {
              if(widget.fromCheckout){
                locationController.updateSelectedAddress(addressModel);
              }
              Get.back();
              customSnackBar(response.message!.tr,type : ToasterMessageType.success, showDefaultSnackBar: ResponsiveHelper.isDesktop(Get.context) ? true : false);
            }else {
              customSnackBar(response.message!.tr, showDefaultSnackBar: ResponsiveHelper.isDesktop(Get.context) ? true : false);
            }
          });
        }else{
          locationController.updateSelectedAddress(addressModel);
          Get.back();
        }
      }
    }
  }

  void _checkPermission(Function onTap) async {
    LocationPermission permission = await Geolocator.checkPermission();
    if(permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if(permission == LocationPermission.denied) {
      customSnackBar('you_have_to_allow'.tr, type: ToasterMessageType.info);
    }else if(permission == LocationPermission.deniedForever) {
      Get.dialog(const PermissionDialog());
    }else {
      onTap();
    }
  }
}

// Step 1: Pick location on map
class _MobileAddressLocationStep extends StatelessWidget {
  final LatLng initialPosition;
  final Completer<GoogleMapController> controller;
  final bool fromCheckout;
  final TextEditingController serviceAddressController;
  final VoidCallback onContinue;
  final Function(CameraPosition) onCameraMove;
  final Function() onCameraIdle;
  final Function(GoogleMapController) onMapCreated;
  final Function(Function) checkPermission;
  final Future<void> Function() onOpenPickMap;

  const _MobileAddressLocationStep({
    required this.initialPosition,
    required this.controller,
    required this.fromCheckout,
    required this.serviceAddressController,
    required this.onContinue,
    required this.onCameraMove,
    required this.onCameraIdle,
    required this.onMapCreated,
    required this.checkPermission,
    required this.onOpenPickMap,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LocationController>(
      builder: (locationController) {
        final addressText = locationController.address.address?.trim().isNotEmpty == true
            ? locationController.address.address!.trim()
            : serviceAddressController.text.trim();

        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: Stack(
                children: [
                  GoogleMap(
                    minMaxZoomPreference: const MinMaxZoomPreference(0, 16),
                    initialCameraPosition: CameraPosition(
                      target: MapHelper.resolveMapTarget(
                        usePickPosition: false,
                        fallback: initialPosition,
                      ),
                      zoom: 16,
                    ),
                    zoomControlsEnabled: false,
                    onCameraIdle: onCameraIdle,
                    onCameraMove: onCameraMove,
                    onMapCreated: onMapCreated,
                    style: Get.isDarkMode
                        ? Get.find<ThemeController>().darkMap
                        : Get.find<ThemeController>().lightMap,
                    myLocationButtonEnabled: false,
                    webCameraControlEnabled: false,
                  ),
                  if (locationController.loading)
                    Container(
                      color: Colors.black.withValues(alpha: 0.1),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                  if (!locationController.loading)
                    Center(
                      child: Image.asset(Images.marker, height: 40, width: 40),
                    ),
                  Positioned(
                    top: Dimensions.paddingSizeDefault,
                    left: Dimensions.paddingSizeSmall,
                    right: Dimensions.paddingSizeSmall,
                    child: LocationSearchDialog(
                      getMapController: () => Get.find<LocationController>().mapController,
                      pickedLocation: addressText.isEmpty ? 'search_location'.tr : addressText,
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search, size: 20, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                            Expanded(
                              child: Text(
                                addressText.isEmpty ? 'search_location'.tr : addressText,
                                style: robotoRegular.copyWith(
                                  fontSize: Dimensions.fontSizeSmall,
                                  color: Theme.of(context).hintColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    bottom: 120,
                    child: Padding(
                      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                      child: Align(
                        alignment: Get.find<LocalizationController>().isLtr
                            ? Alignment.bottomRight
                            : Alignment.bottomLeft,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () => onOpenPickMap(),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                                  color: Theme.of(context).cardColor,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(Icons.fullscreen, color: Theme.of(context).primaryColor, size: 24),
                              ),
                            ),
                            const SizedBox(height: Dimensions.paddingSizeSmall),
                            InkWell(
                              onTap: () => checkPermission(() {
                                Get.find<LocationController>().getCurrentLocation(
                                  true,
                                  deviceCurrentLocation: true,
                                  isFromCheckout: fromCheckout,
                                  mapController: Get.find<LocationController>().mapController,
                                ).then((address) {
                                  serviceAddressController.text = address.address ?? '';
                                });
                              }),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                                  color: Theme.of(context).cardColor,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(Icons.my_location, color: Theme.of(context).primaryColor, size: 24),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(
                  Dimensions.paddingSizeDefault,
                  Dimensions.paddingSizeDefault,
                  Dimensions.paddingSizeDefault,
                  MediaQuery.of(context).padding.bottom + Dimensions.paddingSizeDefault,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusLarge)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.location_on, color: Theme.of(context).colorScheme.primary, size: 22),
                        const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                        Expanded(
                          child: Text(
                            addressText.isEmpty ? 'search_location'.tr : addressText,
                            style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Dimensions.paddingSizeSmall),
                    Text(
                      'select_from_map'.tr,
                      style: robotoRegular.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeDefault),
                    CustomButton(
                      radius: Dimensions.radiusSmall,
                      fontSize: Dimensions.fontSizeLarge,
                      buttonText: 'continue'.tr,
                      isLoading: locationController.loading,
                      onPressed: (locationController.loading || locationController.buttonDisabled)
                          ? null
                          : onContinue,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Step 2: Address details form
class _MobileAddressDetailsStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController contactPersonNameController;
  final TextEditingController contactPersonNumberController;
  final TextEditingController serviceAddressController;
  final TextEditingController houseController;
  final TextEditingController floorController;
  final TextEditingController landmarkController;
  final TextEditingController cityController;
  final TextEditingController zipController;
  final TextEditingController streetController;
  final FocusNode nameNode;
  final FocusNode numberNode;
  final FocusNode serviceAddressNode;
  final FocusNode houseNode;
  final FocusNode floorNode;
  final FocusNode landmarkNode;
  final FocusNode cityNode;
  final FocusNode zipNode;
  final FocusNode streetNode;
  final VoidCallback onSave;
  final VoidCallback onChangeLocation;

  const _MobileAddressDetailsStep({
    required this.formKey,
    required this.contactPersonNameController,
    required this.contactPersonNumberController,
    required this.serviceAddressController,
    required this.houseController,
    required this.floorController,
    required this.landmarkController,
    required this.cityController,
    required this.zipController,
    required this.streetController,
    required this.nameNode,
    required this.numberNode,
    required this.serviceAddressNode,
    required this.houseNode,
    required this.floorNode,
    required this.landmarkNode,
    required this.cityNode,
    required this.zipNode,
    required this.streetNode,
    required this.onSave,
    required this.onChangeLocation,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LocationController>(
      builder: (locationController) {
        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: onChangeLocation,
                        child: Row(
                          children: [
                            Icon(Icons.edit_location_alt, color: Theme.of(context).colorScheme.primary, size: 18),
                            const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                            Text(
                              'change_address'.tr,
                              style: robotoMedium.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: Dimensions.fontSizeDefault,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeDefault),
                      AddressDetailsSection(
                        serviceAddressController: serviceAddressController,
                        houseController: houseController,
                        floorController: floorController,
                        cityController: cityController,
                        landmarkController: landmarkController,
                        zipController: zipController,
                        streetController: streetController,
                        serviceAddressNode: serviceAddressNode,
                        houseNode: houseNode,
                        floorNode: floorNode,
                        cityNode: cityNode,
                        landmarkNode: landmarkNode,
                        zipNode: zipNode,
                        streetNode: streetNode,
                        nextFocus: nameNode,
                      ),
                      const SizedBox(height: Dimensions.paddingSizeLarge),
                      ContactInfoSection(
                        nameController: contactPersonNameController,
                        numberController: contactPersonNumberController,
                        nameNode: nameNode,
                        numberNode: numberNode,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(
                Dimensions.paddingSizeDefault,
                Dimensions.paddingSizeDefault,
                Dimensions.paddingSizeDefault,
                MediaQuery.of(context).padding.bottom + Dimensions.paddingSizeDefault,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: CustomButton(
                radius: Dimensions.radiusSmall,
                fontSize: Dimensions.fontSizeLarge,
                buttonText: 'save_location'.tr,
                isLoading: locationController.isLoading,
                onPressed: (locationController.buttonDisabled || locationController.loading) ? null : onSave,
              ),
            ),
          ],
        );
      },
    );
  }
}

// Mobile Layout Widget (edit address)
class _MobileAddressLayout extends StatelessWidget {
  final LatLng initialPosition;
  final Completer<GoogleMapController> controller;
  final bool fromCheckout;
  final GlobalKey<FormState> formKey;
  final TextEditingController contactPersonNameController;
  final TextEditingController contactPersonNumberController;
  final TextEditingController serviceAddressController;
  final TextEditingController houseController;
  final TextEditingController floorController;
  final TextEditingController landmarkController;
  final TextEditingController cityController;
  final TextEditingController zipController;
  final TextEditingController streetController;
  final FocusNode nameNode;
  final FocusNode numberNode;
  final FocusNode serviceAddressNode;
  final FocusNode houseNode;
  final FocusNode floorNode;
  final FocusNode landmarkNode;
  final FocusNode cityNode;
  final FocusNode zipNode;
  final FocusNode streetNode;
  final VoidCallback onSave;
  final bool isUpdate;
  final ValueNotifier<double> bottomSheetExtent;
  final Function(CameraPosition) onCameraMove;
  final Function() onCameraIdle;
  final Function(GoogleMapController) onMapCreated;
  final Function(Function) checkPermission;
  final Future<void> Function() onOpenPickMap;

  const _MobileAddressLayout({
    required this.initialPosition,
    required this.controller,
    required this.fromCheckout,
    required this.formKey,
    required this.contactPersonNameController,
    required this.contactPersonNumberController,
    required this.serviceAddressController,
    required this.houseController,
    required this.floorController,
    required this.landmarkController,
    required this.cityController,
    required this.zipController,
    required this.streetController,
    required this.nameNode,
    required this.numberNode,
    required this.serviceAddressNode,
    required this.houseNode,
    required this.floorNode,
    required this.landmarkNode,
    required this.cityNode,
    required this.zipNode,
    required this.streetNode,
    required this.onSave,
    required this.isUpdate,
    required this.bottomSheetExtent,
    required this.onCameraMove,
    required this.onCameraIdle,
    required this.onMapCreated,
    required this.checkPermission,
    required this.onOpenPickMap,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LocationController>(
      builder: (locationController) {
        return Stack(
          fit: StackFit.expand,
          children: [
            // Full-screen map behind the bottom sheet (uses scaffold body height, not Get.height)
            Positioned.fill(
              child: Stack(
                children: [
                  GoogleMap(
                    minMaxZoomPreference: const MinMaxZoomPreference(0, 16),
                    initialCameraPosition: CameraPosition(
                      target: MapHelper.resolveMapTarget(
                        usePickPosition: false,
                        fallback: initialPosition,
                      ),
                      zoom: 16,
                    ),
                    zoomControlsEnabled: false,
                    onCameraIdle: onCameraIdle,
                    onCameraMove: onCameraMove,
                    onMapCreated: onMapCreated,
                    style: Get.isDarkMode
                        ? Get.find<ThemeController>().darkMap
                        : Get.find<ThemeController>().lightMap,
                    myLocationButtonEnabled: false,
                    webCameraControlEnabled: false,
                  ),
                  if (locationController.loading)
                    Container(
                      color: Colors.black.withValues(alpha: 0.1),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                  if (!locationController.loading)
                    Center(
                      child: Image.asset(Images.marker, height: 40, width: 40),
                    ),

                    Positioned(
                      top: Dimensions.paddingSizeDefault,
                      left: Dimensions.paddingSizeSmall,
                      right: Dimensions.paddingSizeSmall,
                      child: LocationSearchDialog(
                        getMapController: () => Get.find<LocationController>().mapController,
                        pickedLocation: serviceAddressController.text.isEmpty
                            ? 'search_location'.tr
                            : serviceAddressController.text,
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(
                            horizontal: Dimensions.paddingSizeSmall,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.search,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                              Expanded(
                                child: Text(
                                  serviceAddressController.text.isEmpty
                                      ? 'search_location'.tr
                                      : serviceAddressController.text,
                                  style: robotoRegular.copyWith(
                                    fontSize: Dimensions.fontSizeSmall,
                                    color: Theme.of(context).hintColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    Positioned.fill(
                      bottom: 70,
                      child: Padding(
                        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                        child: Align(
                          alignment: Get.find<LocalizationController>().isLtr ? Alignment.bottomRight : Alignment.bottomLeft,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Fullscreen button
                              InkWell(
                                onTap: () => onOpenPickMap(),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                                    color: Theme.of(context).cardColor,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.fullscreen,
                                    color: Theme.of(context).primaryColor,
                                    size: 24,
                                  ),
                                ),
                              ),
                              const SizedBox(height: Dimensions.paddingSizeSmall),

                              // My location button
                              InkWell(
                                onTap: () => checkPermission(() {
                                  Get.find<LocationController>().getCurrentLocation(
                                    true,
                                    deviceCurrentLocation: true,
                                    isFromCheckout: fromCheckout,
                                    mapController: Get.find<LocationController>().mapController,
                                  );
                                }),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                                    color: Theme.of(context).cardColor,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.my_location,
                                    color: Theme.of(context).primaryColor,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Draggable Bottom Sheet
            AddressFormBottomSheet(
              formKey: formKey,
              contactPersonNameController: contactPersonNameController,
              contactPersonNumberController: contactPersonNumberController,
              serviceAddressController: serviceAddressController,
              houseController: houseController,
              floorController: floorController,
              landmarkController: landmarkController,
              cityController: cityController,
              zipController: zipController,
              streetController: streetController,
              nameNode: nameNode,
              numberNode: numberNode,
              serviceAddressNode: serviceAddressNode,
              houseNode: houseNode,
              floorNode: floorNode,
              landmarkNode: landmarkNode,
              cityNode: cityNode,
              zipNode: zipNode,
              streetNode: streetNode,
              onSave: onSave,
              isUpdate: isUpdate,
              bottomSheetExtent: bottomSheetExtent,
            ),
          ],
        );
      },
    );
  }
}
// Desktop Layout Widget
class _DesktopAddressLayout extends StatelessWidget {
  final LatLng initialPosition;
  final Completer<GoogleMapController> controller;
  final bool fromCheckout;
  final GlobalKey<FormState> formKey;
  final TextEditingController contactPersonNameController;
  final TextEditingController contactPersonNumberController;
  final TextEditingController serviceAddressController;
  final TextEditingController houseController;
  final TextEditingController floorController;
  final TextEditingController landmarkController;
  final TextEditingController cityController;
  final TextEditingController zipController;
  final TextEditingController streetController;
  final FocusNode nameNode;
  final FocusNode numberNode;
  final FocusNode serviceAddressNode;
  final FocusNode houseNode;
  final FocusNode floorNode;
  final FocusNode landmarkNode;
  final FocusNode cityNode;
  final FocusNode zipNode;
  final FocusNode streetNode;
  final VoidCallback onSave;
  final bool isUpdate;
  final double bottomPadding;
  final Function(CameraPosition) onCameraMove;
  final Function() onCameraIdle;
  final Function(GoogleMapController) onMapCreated;
  final Function(Function) checkPermission;

  const _DesktopAddressLayout({
    required this.initialPosition,
    required this.controller,
    required this.fromCheckout,
    required this.formKey,
    required this.contactPersonNameController,
    required this.contactPersonNumberController,
    required this.serviceAddressController,
    required this.houseController,
    required this.floorController,
    required this.landmarkController,
    required this.cityController,
    required this.zipController,
    required this.streetController,
    required this.nameNode,
    required this.numberNode,
    required this.serviceAddressNode,
    required this.houseNode,
    required this.floorNode,
    required this.landmarkNode,
    required this.cityNode,
    required this.zipNode,
    required this.streetNode,
    required this.onSave,
    required this.isUpdate,
    required this.bottomPadding,
    required this.onCameraMove,
    required this.onCameraIdle,
    required this.onMapCreated,
    required this.checkPermission,
  });

  @override
  Widget build(BuildContext context) {
    return FooterBaseView(
      child: Center(child: SizedBox(
        width: Dimensions.webMaxWidth,
        child: GetBuilder<LocationController>(builder: (locationController) {
          return Form(key: formKey, child: Column(
            children: [
              if(ResponsiveHelper.isDesktop(context))
                Padding(
                  padding: const EdgeInsets.only(top: Dimensions.paddingSizeLarge),
                  child: Text(isUpdate ? 'update_address'.tr : 'add_address'.tr, style: robotoSemiBold.copyWith(
                    fontSize: Dimensions.fontSizeExtraLarge,
                  )),
                ),

              AnimatedSize(
                duration: Duration(milliseconds: 400),
                curve: Curves.easeIn,
                child: IntrinsicHeight(
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: WebShadowWrap(
                      child: Padding(
                        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'select_from_map'.tr,
                              style: robotoSemiBold.copyWith(fontSize: Dimensions.fontSizeSmall),
                            ),
                            const SizedBox(height: Dimensions.paddingSizeDefault),
                            AddressMapSection(
                              initialPosition: initialPosition,
                              controller: controller,
                              onCameraMove: onCameraMove,
                              onCameraIdle: onCameraIdle,
                              onMapCreated: onMapCreated,
                              fromCheckout: fromCheckout,
                              isDesktop: true,
                              isUpdate: isUpdate,
                              serviceAddressController: serviceAddressController,
                            ),
                          ],
                        ),
                      ),
                    )),

                    const SizedBox(width: Dimensions.paddingSizeLarge),

                    Expanded(child: WebShadowWrap(
                      child: Padding(
                        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault).copyWith(
                          bottom: 0,
                        ),
                        child: Column(
                          children: [
                            AddressDetailsSection(
                              serviceAddressController: serviceAddressController,
                              houseController: houseController,
                              floorController: floorController,
                              cityController: cityController,
                              landmarkController: landmarkController,
                              zipController: zipController,
                              streetController: streetController,
                              serviceAddressNode: serviceAddressNode,
                              houseNode: houseNode,
                              floorNode: floorNode,
                              cityNode: cityNode,
                              landmarkNode: landmarkNode,
                              zipNode: zipNode,
                              streetNode: streetNode,
                              nextFocus: nameNode,
                            ),

                            const SizedBox(height: Dimensions.paddingSizeTextFieldGap),

                            // Contact Info Section
                            ContactInfoSection(
                              nameController: contactPersonNameController,
                              numberController: contactPersonNumberController,
                              nameNode: nameNode,
                              numberNode: numberNode,
                              nextFocus: serviceAddressNode,
                            ),
                          ],
                        ),
                      ),
                    )),
                  ]),
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeDefault),

              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                CustomButton(
                  width: 200,
                  radius: Dimensions.radiusSmall,
                  fontSize: Dimensions.fontSizeExtraSmall,
                  buttonText: 'cancel'.tr ,
                  textStyle: robotoSemiBold.copyWith(color: Theme.of(context).textTheme.titleLarge?.color ),
                  backgroundColor: Theme.of(context).disabledColor.withAlpha(40),
                  onPressed: ()=> Get.key.currentState!.canPop()
                      ? Get.back()
                      : Get.toNamed(RouteHelper.getInitialRoute()),
                ),
                const SizedBox(width: Dimensions.paddingSizeLarge * 2),

                CustomButton(
                  width: 200,
                  radius: Dimensions.radiusSmall,
                  fontSize: Dimensions.fontSizeExtraSmall,
                  buttonText: isUpdate ? 'update_address'.tr : 'save_location'.tr,
                  isLoading: locationController.isLoading,
                  onPressed: (locationController.buttonDisabled
                      || locationController.loading)
                      ? null
                      : onSave,
                ),
              ]),
            ],
          ));

        }),
      )),
    );
  }
}
