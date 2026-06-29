import 'package:demandium/helper/address_session_helper.dart';
import 'package:get/get.dart';
import 'package:demandium/util/core_export.dart';
import 'package:demandium/common/widgets/staggered_list_animation.dart';
import 'package:demandium/common/widgets/custom_highlight_animation_widget.dart';
import 'package:demandium/feature/location/widget/pickmap_dialog_widget.dart';
import 'package:skeletonizer/skeletonizer.dart';

class AddressSelectionBottomSheet extends StatefulWidget {
  final bool mandatory;
  final String? redirectRoute;
  const AddressSelectionBottomSheet({
    super.key,
    this.mandatory = false,
    this.redirectRoute,
  });

  @override
  State<AddressSelectionBottomSheet> createState() => _AddressSelectionBottomSheetState();
}

class _AddressSelectionBottomSheetState extends State<AddressSelectionBottomSheet> {
  @override
  void initState() {
    super.initState();
    if (Get.find<AuthController>().isLoggedIn()) {
      Get.find<LocationController>().getAddressList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = Get.find<AuthController>().isLoggedIn();

    return PointerInterceptor(
      child: GetBuilder<LocationController>(
        builder: (locationController) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: Get.height * 0.80,
            ),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusLarge)),
              color: Theme.of(context).cardColor,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Draggable handle
                const SizedBox(height: Dimensions.paddingSizeDefault),
                Container(
                  height: 5,
                  width: 45,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    color: Theme.of(context).hintColor.withValues(alpha: 0.15),
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeDefault),


                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                  child: Text(
                    'select_your_address'.tr,
                    style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeExtraLarge),
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeLarge),

                // My Addresses header with Add New Address link (only for logged in users)
                if (isLoggedIn && (locationController.addressList?.isNotEmpty ?? false))
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'my_address'.tr,
                          style: robotoMedium.copyWith(
                            fontSize: Dimensions.fontSizeLarge,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),

                        InkWell(
                          onTap: () {
                            Get.toNamed(RouteHelper.getAddAddressRoute(false));
                          },
                          child: Text(
                            'add_new_address_plus'.tr,
                            style: robotoMedium.copyWith(
                              fontSize: Dimensions.fontSizeDefault,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                if (isLoggedIn) const SizedBox(height: Dimensions.paddingSizeDefault),

                // Scrollable Content
                Flexible(
                  child: GetBuilder<LocationController>(
                    builder: (locationController) {
                      return SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Dimensions.paddingSizeDefault,
                        ),
                        child: Column(
                          children: [
                            // Address list or empty state
                            if (isLoggedIn && (locationController.addressList?.isNotEmpty ?? false))
                              AddressListContent(
                                locationController: locationController,
                                redirectRoute: widget.redirectRoute,
                              )
                            else
                              const EmptyAddressState(),

                            const SizedBox(height: Dimensions.paddingSizeDefault),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Fixed Action Buttons at Bottom
                GetBuilder<LocationController>(
                  builder: (locationController) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Dimensions.paddingSizeDefault,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AddressActionButtons(
                            locationController: locationController,
                            isLoggedIn: isLoggedIn,
                            redirectRoute: widget.redirectRoute,
                          ),
                          SizedBox(height: MediaQuery.of(context).padding.bottom + Dimensions.paddingSizeDefault),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        }
      ),
    );
  }
}

class AddressListContent extends StatefulWidget {
  final LocationController locationController;
  final Function(AddressModel)? onAddressTap;
  final void Function(AddressModel)? onAddressDeleted;
  final String? redirectRoute;
  final String? selectedAddressId;
  
  const AddressListContent({
    super.key,
    required this.locationController,
    this.onAddressTap,
    this.onAddressDeleted,
    this.redirectRoute,
    this.selectedAddressId,
  });

  @override
  State<AddressListContent> createState() => AddressListContentState();
}

class AddressListContentState extends State<AddressListContent> {
  final Map<String, bool> _serviceableById = {};
  bool _isValidating = false;

  static final Map<String, bool> serviceabilityCache = AddressSessionHelper.addressServiceabilityCache;

  bool isAddressServiceable(AddressModel address) {
    final id = address.id;
    if (id != null && _serviceableById.containsKey(id)) {
      return _serviceableById[id]!;
    }
    return AddressSessionHelper.isAddressLikelyServiceable(address);
  }

  bool get hasNonServiceableAddresses {
    final list = widget.locationController.addressList;
    if (list == null || list.isEmpty) return false;
    return list.any((address) => !isAddressServiceable(address));
  }

  @override
  void initState() {
    super.initState();
    _validateAddresses();
  }

  @override
  void didUpdateWidget(covariant AddressListContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.locationController.addressList?.length !=
        widget.locationController.addressList?.length) {
      _validateAddresses();
    }
  }

  Future<void> _validateAddresses() async {
    final list = widget.locationController.addressList;
    if (list == null || list.isEmpty) return;

    setState(() => _isValidating = true);

    final results = <String, bool>{};
    for (final address in list) {
      final id = address.id;
      if (id == null) continue;

      if (serviceabilityCache.containsKey(id)) {
        results[id] = serviceabilityCache[id]!;
        continue;
      }

      final serviceable = await AddressSessionHelper.evaluateAddressServiceability(address);
      results[id] = serviceable;
      serviceabilityCache[id] = serviceable;
    }

    if (!mounted) return;
    setState(() {
      _serviceableById
        ..clear()
        ..addAll(results);
      _isValidating = false;
    });
    AddressSessionHelper.addressServiceabilityCache
      ..clear()
      ..addAll(results);
    widget.locationController.refreshUi();
  }

  void _confirmDeleteAddress(BuildContext context, AddressModel address) {
    if (Get.isSnackbarOpen) {
      Get.back();
    }
    Get.dialog(
      ConfirmationDialog(
        icon: Images.warning,
        description: 'are_you_sure_want_to_delete_address'.tr,
        onYesPressed: () async {
          Get.back();
          Get.dialog(const CustomLoader(), barrierDismissible: false);
          final response = await widget.locationController.deleteUserAddressByID(address);
          if (address.id != null) {
            AddressSessionHelper.addressServiceabilityCache.remove(address.id);
          }
          if (Get.isDialogOpen == true) Get.back();
          customSnackBar(
            response.message!.tr.capitalizeFirst!,
            type: response.isSuccess == true ? ToasterMessageType.success : ToasterMessageType.error,
          );
          if (response.isSuccess == true && mounted) {
            widget.onAddressDeleted?.call(address);
            _validateAddresses();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: widget.locationController.addressList == null,
      child: StaggeredListAnimationWrapper(
        key: ValueKey(widget.locationController.addressList?.length),
        duration: const Duration(milliseconds: 600),
        child: ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: widget.locationController.addressList!.length,
          itemBuilder: (context, index) {
            final address = widget.locationController.addressList![index];
            final isSelected = widget.selectedAddressId != null
                ? widget.selectedAddressId == address.id
                : widget.locationController.getUserAddress()?.id == address.id;
            final isNewlyAdded = widget.locationController.newlyAddedAddressId == address.id;
            final isServiceable = isAddressServiceable(address);
            final isDisabled = !isServiceable;

            final isChecking = _isValidating && address.id != null && !_serviceableById.containsKey(address.id);
            return StaggeredListAnimationItem(
              index: index,
              child: AddressListItem(
                address: address,
                isSelected: isSelected,
                isNewlyAdded: isNewlyAdded,
                isDisabled: isDisabled,
                isChecking: isChecking,
                onTap: isDisabled
                    ? null
                    : () async {
                  if (widget.onAddressTap != null) {
                    widget.onAddressTap!(address);
                  } else {
                    Get.dialog(const CustomLoader(), barrierDismissible: false);
                    await AddressSessionHelper.applySelectedAddress(
                      address,
                      redirectRoute: widget.redirectRoute ?? RouteHelper.getMainRoute('home'),
                      canRoute: true,
                    );
                    if (Get.isDialogOpen == true) Get.back();
                  }
                },
                onDelete: isDisabled && !isChecking
                    ? () => _confirmDeleteAddress(context, address)
                    : null,
              ),
            );
          },
        ),
      ),
    );
  }
}

class AddressListItem extends StatelessWidget {
  final AddressModel address;
  final bool isSelected;
  final bool isNewlyAdded;
  final bool isDisabled;
  final bool isChecking;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  
  const AddressListItem({
    super.key,
    required this.address,
    required this.isSelected,
    required this.isNewlyAdded,
    this.isDisabled = false,
    this.isChecking = false,
    this.onTap,
    this.onDelete,
  });
  
  IconData _getAddressIcon() {
    switch (address.addressLabel?.toLowerCase()) {
      case 'home':
        return Icons.home;
      case 'office':
        return Icons.work;
      default:
        return Icons.widgets;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disabledColor = theme.disabledColor;
    final primaryColor = theme.colorScheme.primary;
    final contentColor = isDisabled ? disabledColor : theme.textTheme.bodyLarge?.color;
    final iconColor = isDisabled ? disabledColor : primaryColor;

    return CustomHighlightAnimationWidget(
      shouldAnimate: isNewlyAdded && !isDisabled,
      child: Builder(
        builder: (context) {
          final backgroundColor = isDisabled
              ? theme.hintColor.withValues(alpha: 0.06)
              : isSelected
                  ? theme.hintColor.withValues(alpha: 0.1)
                  : context.highlightBackgroundColor(
                      null,
                      primaryColor.withValues(alpha: 0.08),
                    );

          final borderColor = isDisabled
              ? theme.hintColor.withValues(alpha: 0.15)
              : context.highlightBorderColor(
                  theme.hintColor.withValues(alpha: 0.2),
                  primaryColor.withValues(alpha: 0.4),
                );
          
          return Container(
            margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: borderColor!,
                width: 1,
              ),
            ),
            child: Stack(
              children: [
                Opacity(
                  opacity: isDisabled ? 0.55 : 1,
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        15,
                        15,
                        isDisabled && onDelete != null ? 48 : 15,
                        15,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _getAddressIcon(),
                                      color: iconColor,
                                      size: Dimensions.paddingSizeLarge,
                                    ),
                                    const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                                    Expanded(
                                      child: Text(
                                        (address.addressLabel ?? 'others').tr,
                                        style: (isSelected && !isDisabled)
                                            ? robotoBold.copyWith(
                                                fontSize: Dimensions.fontSizeLarge,
                                                color: contentColor,
                                              )
                                            : robotoRegular.copyWith(
                                                fontSize: Dimensions.fontSizeLarge,
                                                color: contentColor,
                                              ),
                                      ),
                                    ),
                                    if (isChecking)
                                      SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: primaryColor.withValues(alpha: 0.6),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                                Padding(
                                  padding: const EdgeInsets.only(left: Dimensions.paddingSizeExtraLarge),
                                  child: Text(
                                    address.address ?? '',
                                    style: robotoRegular.copyWith(
                                      fontSize: Dimensions.fontSizeSmall,
                                      color: isDisabled
                                          ? disabledColor
                                          : theme.textTheme.titleLarge?.color?.withValues(alpha: 0.5),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isDisabled && !isChecking) ...[
                                  const SizedBox(height: Dimensions.paddingSizeSmall),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.error.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                                      border: Border.all(
                                        color: theme.colorScheme.error.withValues(alpha: 0.2),
                                      ),
                                    ),
                                    child: Text(
                                      'we_dont_service_this_area'.tr,
                                      style: robotoRegular.copyWith(
                                        fontSize: Dimensions.fontSizeSmall,
                                        color: theme.colorScheme.error.withValues(alpha: 0.9),
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (!isDisabled) ...[
                            const SizedBox(width: Dimensions.paddingSizeSmall),
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? primaryColor
                                      : theme.hintColor.withValues(alpha: 0.5),
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? Center(
                                      child: Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: primaryColor,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                if (isDisabled && !isChecking && onDelete != null)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton(
                      onPressed: onDelete,
                      tooltip: 'delete'.tr,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      style: IconButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                        backgroundColor: theme.colorScheme.error.withValues(alpha: 0.1),
                      ),
                      icon: const Icon(Icons.delete_outline, size: 20),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class EmptyAddressState extends StatelessWidget {
  const EmptyAddressState({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: Dimensions.paddingSizeDefault),

        Image.asset(Images.emptyAddress, height: 50),
        const SizedBox(height: Dimensions.paddingSizeDefault),

        Text(
          'opps'.tr,
          textAlign: TextAlign.center,
          style: robotoMedium.copyWith(
            fontSize: Dimensions.fontSizeExtraLarge,
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeDefault),


        Text(
          'you_dont_have_any_saved_address_yet'.tr,
          textAlign: TextAlign.center,
          style: robotoRegular.copyWith(
            fontSize: Dimensions.fontSizeDefault,
            color: Theme.of(context).textTheme.titleLarge?.color?.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeDefault),
      ],
    );
  }
}

class AddressActionButtons extends StatelessWidget {
  final LocationController locationController;
  final bool isLoggedIn;
  final bool fromDrawer;
  final String? redirectRoute;
  
  const AddressActionButtons({
    super.key,
    required this.locationController,
    required this.isLoggedIn,
    this.fromDrawer = false,
    this.redirectRoute,
  });

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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [

        if (isLoggedIn) ...[
          SizedBox(
            width: double.infinity,
            height: 50,
            child: CustomButton(
              buttonText: 'add_new_address_plus'.tr,
              onPressed: () {
                Get.toNamed(RouteHelper.getAddAddressRoute(false));
              },
              radius: Dimensions.radiusSmall,
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),
        ],

        SizedBox(
          width: double.infinity,
          height: 50,
          child: CustomButton(
            buttonText: 'use_current_location'.tr,
            icon: Icons.gps_fixed,
            iconColor: context.adaptivePrimaryColor,
            textStyle: robotoMedium.copyWith(
              fontSize: Dimensions.fontSizeDefault,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
            backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            onPressed: () async {
              if (isRedundentClick(DateTime.now())) {
                return;
              }
              _checkPermission(() async {
                Get.back();
                Get.dialog(const CustomLoader(), barrierDismissible: false);
                try {
                  AddressModel address = await locationController.getCurrentLocation(
                    true,
                    deviceCurrentLocation: true,
                  );

                  if (address.latitude == null ||
                      address.longitude == null ||
                      address.latitude!.isEmpty ||
                      address.longitude!.isEmpty) {
                    customSnackBar('pick_an_address'.tr, type: ToasterMessageType.info);
                    return;
                  }

                  ZoneResponseModel response = await locationController.getZone(
                    address.latitude!,
                    address.longitude!,
                    false,
                  );

                  if (!response.isSuccess) {
                    final message = (response.message?.trim().isNotEmpty ?? false)
                        ? response.message!
                        : '500'.tr;
                    customSnackBar(message.tr, type: ToasterMessageType.error);
                    return;
                  }

                  if ((response.totalServiceCount ?? 0) <= 0) {
                    Get.offNamed(RouteHelper.getAreaNotServiceableRoute());
                    return;
                  }

                  await AddressSessionHelper.applySelectedAddress(
                    address,
                    redirectRoute: redirectRoute ?? RouteHelper.getMainRoute('home'),
                    canRoute: true,
                    closeOverlays: false,
                  );
                } catch (_) {
                  customSnackBar('500'.tr, type: ToasterMessageType.error);
                } finally {
                  if (Get.isDialogOpen == true) Get.back();
                }
              });
            },
            radius: Dimensions.radiusSmall,
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeDefault),

        InkWell(
          onTap: () {
            if (isRedundentClick(DateTime.now())) {
              return;
            }
            
            if (fromDrawer) {
              // Show dialog for desktop/drawer
              Get.dialog(
                PickMapDialogWidget(
                  previousAddress: Get.find<LocationController>().getUserAddress(),
                ),
              );
            } else {
              Get.back(); // Close bottom sheet

              Get.toNamed(RouteHelper.getPickMapRoute(
                isLoggedIn ? RouteHelper.getMainRoute('home') : RouteHelper.accessLocation,
                true,
                'false',
                null,
                Get.find<LocationController>().getUserAddress(),
              ));
            }
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_on_outlined,
                color: Theme.of(context).colorScheme.primary,
                size: 18,
              ),
              const SizedBox(width: Dimensions.paddingSizeExtraSmall),
              Text(
                'set_from_map'.tr,
                textAlign: TextAlign.center,
                style: robotoMedium.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: Dimensions.fontSizeDefault,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
