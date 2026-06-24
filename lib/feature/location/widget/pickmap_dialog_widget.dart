import 'package:get/get.dart';
import 'package:demandium/util/core_export.dart';
import 'package:demandium/common/widgets/map_view_widget.dart';

class PickMapDialogWidget extends StatefulWidget {
  final AddressModel? previousAddress;

  const PickMapDialogWidget({
    super.key,
    this.previousAddress,
  });

  @override
  State<PickMapDialogWidget> createState() => _PickMapDialogWidgetState();
}

class _PickMapDialogWidgetState extends State<PickMapDialogWidget> {
  GoogleMapController? _mapController;
  CameraPosition? _cameraPosition;
  LatLng? _initialPosition;
  bool _isMapReady = false;
  bool _mapInitializing = true;
  bool _zonesLoaded = false;
  Set<Polygon> _polygons = {};

  @override
  void initState() {
    super.initState();
    final locationController = Get.find<LocationController>();
    locationController.beginMapPolygonValidation();
    
    // Initialize map position
    if (widget.previousAddress != null && 
        widget.previousAddress!.latitude != null && 
        widget.previousAddress!.longitude != null) {
      _initialPosition = LatLng(
        double.tryParse(widget.previousAddress!.latitude!) ?? 0,
        double.tryParse(widget.previousAddress!.longitude!) ?? 0,
      );
    } else {
      _initialPosition = LatLng(
        Get.find<SplashController>().configModel.content?.defaultLocation?.latitude ?? 23.00000,
        Get.find<SplashController>().configModel.content?.defaultLocation?.longitude ?? 90.00000,
      );
    }
    
    // Set pick data for location controller
    Get.find<LocationController>().setPickData();

    _cameraPosition = CameraPosition(target: _initialPosition!, zoom: 16);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadServiceAreaPolygons());
  }

  Future<void> _loadServiceAreaPolygons() async {
    final serviceAreaController = Get.find<ServiceAreaController>();
    await serviceAreaController.getZoneList(reload: false);
    final zones = serviceAreaController.zoneList;
    if (!mounted || zones == null || zones.isEmpty) {
      return;
    }

    final polygons = MapHelper.polygonsFromZoneModels(zones);
    Get.find<LocationController>().setMapValidationPolygons(polygons);

    setState(() {
      _polygons = MapHelper.polygonsFromZones(zones);
      _zonesLoaded = true;
    });
    if (mounted && _cameraPosition != null) {
      await Get.find<LocationController>().updatePosition(
        _cameraPosition!,
        false,
        formCheckout: false,
      );
    }
  }

  @override
  void dispose() {
    Get.find<LocationController>().endMapPolygonValidation();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
      ),
      backgroundColor: Theme.of(context).cardColor,
      clipBehavior: Clip.antiAliasWithSaveLayer,
      child: SizedBox(
        width: Dimensions.webMaxWidth * 0.8,
        height: Get.height * 0.85,
        child: Column(
          children: [
            // Dialog Header
            const _DialogHeader(),
            
            // Map View
            Expanded(child: Padding(
              padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                child: MapViewWidget(
                    fromAddAddress: true,
                    initialPosition: _initialPosition,
                    polygons: _polygons,
                    onMapCreated: _onMapCreated,
                    onCameraMove: _onCameraMove,
                    onCameraMoveStarted: _onCameraMoveStarted,
                    onCameraIdle: _onCameraIdle,
                    onLocationTap: _onLocationTap,
                    onPickLocationTap: _onPickLocationTap,
                    getMapController: () => _mapController,
                  ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  // Map callback methods
  void _onMapCreated(GoogleMapController mapController) {
    _mapController = mapController;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _mapInitializing = true;
      if (!_zonesLoaded) {
        await _loadServiceAreaPolygons();
      }
      final locationController = Get.find<LocationController>();
      await locationController.getCurrentLocation(
        false,
        mapController: mapController,
        defaultLatLng: _initialPosition,
      );
      _cameraPosition = CameraPosition(
        target: LatLng(
          locationController.pickPosition.latitude,
          locationController.pickPosition.longitude,
        ),
        zoom: 16,
      );
      await Future.delayed(const Duration(milliseconds: 300));
      _mapInitializing = false;
      _isMapReady = true;
    });
  }

  void _onCameraMove(CameraPosition cameraPosition) {
    _cameraPosition = cameraPosition;
  }

  void _onCameraMoveStarted() {
    if (!_isMapReady || _mapInitializing) return;
    Get.find<LocationController>().updateCameraMovingStatus(true);
  }

  void _onCameraIdle() {
    if (!_isMapReady || _mapInitializing || _cameraPosition == null || !_zonesLoaded) return;
    final locationController = Get.find<LocationController>();
    locationController.updateCameraMovingStatus(false);
    locationController.updatePosition(
      _cameraPosition!,
      false,
      formCheckout: false,
    );
  }

  void _onLocationTap() {
    _checkPermission(() async {
      final locationController = Get.find<LocationController>();
      await locationController.getCurrentLocation(
        false,
        deviceCurrentLocation: true,
        mapController: _mapController,
      );
      if (locationController.buttonDisabled) {
        customSnackBar('service_not_available_in_this_area'.tr, type: ToasterMessageType.error);
      }
    });
  }

  Future<void> _onPickLocationTap() async {
    final locationController = Get.find<LocationController>();

    if (locationController.isCameraMoving ||
        locationController.loading ||
        locationController.buttonDisabled ||
        !locationController.inZone) {
      return;
    }

    if (_cameraPosition != null) {
      await locationController.updatePosition(
        _cameraPosition!,
        false,
        formCheckout: false,
      );
    }

    if (!locationController.inZone || locationController.buttonDisabled) {
      customSnackBar('service_not_available_in_this_area'.tr, type: ToasterMessageType.error);
      return;
    }

    final pickedPoint = LatLng(
      locationController.pickPosition.latitude,
      locationController.pickPosition.longitude,
    );
    if (!locationController.isPointInsideServiceAreaPolygons(pickedPoint)) {
      customSnackBar('service_not_available_in_this_area'.tr, type: ToasterMessageType.error);
      return;
    }

    final isServiceable = await locationController.validatePickedLocationServiceable();
    if (!isServiceable) {
      customSnackBar('service_not_available_in_this_area'.tr, type: ToasterMessageType.error);
      return;
    }

    final pickedAddress = locationController.pickAddress.address ?? '';
    if (locationController.pickPosition.latitude != 0 && pickedAddress.isNotEmpty) {
      String? firstName;

      if (Get.find<AuthController>().isLoggedIn() &&
          Get.find<UserController>().userInfoModel?.phone != null &&
          Get.find<UserController>().userInfoModel?.fName != null) {
        firstName = "${Get.find<UserController>().userInfoModel?.fName} ";
      }

      AddressModel address = AddressModel(
        latitude: locationController.pickPosition.latitude.toString(),
        longitude: locationController.pickPosition.longitude.toString(),
        addressType: 'others',
        address: locationController.pickAddress.address ?? "",
        city: locationController.pickAddress.city ?? "",
        country: locationController.pickAddress.country ?? "",
        house: locationController.pickAddress.house ?? "",
        street: locationController.pickAddress.street ?? "",
        zipCode: locationController.pickAddress.zipCode ?? "",
        addressLabel: AddressSessionHelper.selectedFromMapSourceLabel,
        contactPersonNumber: firstName != null
            ? Get.find<UserController>().userInfoModel?.phone ?? ""
            : "",
        contactPersonName: firstName != null
            ? "$firstName${Get.find<UserController>().userInfoModel?.lName ?? ""}"
            : "",
      );

      await AddressSessionHelper.applySelectedAddress(
        address,
        redirectRoute: RouteHelper.getMainRoute('home'),
        canRoute: false,
        closeOverlays: false,
      );

      Get.back();
    } else {
      customSnackBar('pick_an_address'.tr, type: ToasterMessageType.info);
    }
  }

  void _checkPermission(Function onTap) async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      customSnackBar('you_have_to_allow'.tr, type: ToasterMessageType.info);
    } else if (permission == LocationPermission.deniedForever) {
      Get.dialog(const PermissionDialog());
    } else {
      onTap();
    }
  }
}

/// Dialog header with title and close button
class _DialogHeader extends StatelessWidget {
  
  const _DialogHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).hintColor.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        color: Theme.of(context).hintColor.withValues(alpha: 0.1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'set_location'.tr,
            style: robotoSemiBold.copyWith(
              fontSize: Dimensions.fontSizeExtraLarge,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          InkWell(
            onTap: () => Get.back(),
            child: Container(
              padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                size: Dimensions.paddingSizeLarge,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


