import 'package:demandium/helper/address_session_helper.dart';
import 'package:get/get.dart';
import 'package:demandium/util/core_export.dart';
import 'package:demandium/common/widgets/staggered_list_animation.dart';
import 'package:demandium/common/widgets/custom_highlight_animation_widget.dart';
import 'package:demandium/feature/location/widget/pickmap_dialog_widget.dart';
import 'package:skeletonizer/skeletonizer.dart';

class AddressSelectionBottomSheet extends StatelessWidget {
  final bool mandatory;
  final String? redirectRoute;
  const AddressSelectionBottomSheet({
    super.key,
    this.mandatory = false,
    this.redirectRoute,
  });

  @override
  Widget build(BuildContext context) {
    bool isLoggedIn = Get.find<AuthController>().isLoggedIn();
    
    if (isLoggedIn) {
      Get.find<LocationController>().getAddressList();
    }

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
                                redirectRoute: redirectRoute,
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
                            redirectRoute: redirectRoute,
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

class AddressListContent extends StatelessWidget {
  final LocationController locationController;
  final Function(AddressModel)? onAddressTap;
  final String? redirectRoute;
  
  const AddressListContent({
    super.key,
    required this.locationController,
    this.onAddressTap,
    this.redirectRoute,
  });

  @override
  Widget build(BuildContext context) {

    return Skeletonizer(
      enabled: locationController.addressList == null,
      child: StaggeredListAnimationWrapper(
        // Key changes when list length changes, forcing animation to replay
        key: ValueKey(locationController.addressList?.length),
        duration: const Duration(milliseconds: 600),
        child: ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: locationController.addressList!.length,
          itemBuilder: (context, index) {
            final address = locationController.addressList![index];
            final isSelected = locationController.getUserAddress()?.id == address.id;
            final isNewlyAdded = locationController.newlyAddedAddressId == address.id;

            return StaggeredListAnimationItem(
              index: index,
              child: AddressListItem(
                address: address,
                isSelected: isSelected,
                isNewlyAdded: isNewlyAdded,
                onTap: () async {
                  if (onAddressTap != null) {
                    onAddressTap!(address);
                  } else {
                    Get.dialog(const CustomLoader(), barrierDismissible: false);
                    await AddressSessionHelper.applySelectedAddress(
                      address,
                      redirectRoute: redirectRoute ?? RouteHelper.getMainRoute('home'),
                      canRoute: true,
                    );
                    if (Get.isDialogOpen == true) Get.back();
                  }
                },
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
  final VoidCallback onTap;
  
  const AddressListItem({
    super.key,
    required this.address,
    required this.isSelected,
    required this.isNewlyAdded,
    required this.onTap,
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
    return CustomHighlightAnimationWidget(
      shouldAnimate: isNewlyAdded,
      child: Builder(
        builder: (context) {
          // Use the highlight animation extension methods
          final backgroundColor = isSelected 
              ? Theme.of(context).hintColor.withValues(alpha: 0.1)
              : context.highlightBackgroundColor(
                  null,
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                );

          final borderColor = context.highlightBorderColor(
            Theme.of(context).hintColor.withValues(alpha: 0.2),
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
          );
          
          return InkWell(
            onTap: onTap,
            child: Container(
              margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
              padding: const EdgeInsets.all(15), // 15px padding as per Figma
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(8), // 8px radius as per Figma
                border: Border.all(
                  color: borderColor!,
                  width: 1, // 1px border as per Figma
                ),
              ),
              child: Row(
                children: [
                  // Address Icon (simple, no background)


                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [

                            Icon(
                              _getAddressIcon(),
                              color: Theme.of(context).colorScheme.primary,
                              size: Dimensions.paddingSizeLarge,
                            ),
                            const SizedBox(width: Dimensions.paddingSizeExtraSmall),



                            Text(
                              (address.addressLabel ?? 'others').tr,
                              style: isSelected
                                  ? robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)
                                  : robotoRegular.copyWith(fontSize: Dimensions.fontSizeLarge),
                            ),
                          ],
                        ),
                        const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                        Row(
                          children: [
                            SizedBox(width: Dimensions.paddingSizeExtraLarge),

                            Flexible(child: Text(
                              address.address ?? '',
                              style: robotoRegular.copyWith(
                                fontSize: Dimensions.fontSizeSmall,
                                color: Theme.of(context).textTheme.titleLarge?.color?.withValues(alpha: 0.5),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: Dimensions.paddingSizeSmall),
                  
                  // Radio Button
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected 
                            ? Theme.of(context).colorScheme.primary 
                            : Theme.of(context).hintColor.withValues(alpha: 0.5),
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
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          )
                        : null,
                  ),
                ],
              ),
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
            iconColor: Theme.of(context).primaryColor,
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
                    if (Get.isDialogOpen == true) Get.back();
                    customSnackBar('pick_an_address'.tr, type: ToasterMessageType.info);
                    return;
                  }

                  ZoneResponseModel response = await locationController.getZone(
                    address.latitude!,
                    address.longitude!,
                    false,
                  );

                  if (Get.isDialogOpen == true) Get.back();

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
                  );
                } catch (_) {
                  if (Get.isDialogOpen == true) Get.back();
                  customSnackBar('500'.tr, type: ToasterMessageType.error);
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
