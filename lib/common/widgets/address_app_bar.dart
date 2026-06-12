import 'package:demandium/helper/address_session_helper.dart';
import 'package:get/get.dart';
import 'package:demandium/util/core_export.dart';

class AddressAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool? backButton;
  const AddressAppBar({super.key, this.backButton = true});
  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    return AppBar(
      backgroundColor:Get.isDarkMode ? Theme.of(context).cardColor.withValues(alpha: .2):Theme.of(context).primaryColor,
      shape: Border(bottom: BorderSide(width: .4, color: Theme.of(context).primaryColorLight.withValues(alpha: .2))),
      elevation: 0, leadingWidth: backButton! ? Dimensions.paddingSizeLarge : 0,
      leading: backButton! ? IconButton(
        icon: const Icon(Icons.arrow_back_ios),
        color: Theme.of(context).cardColor,
        onPressed: () => Navigator.pop(context),
      ):
      const SizedBox(),
      title: Row( children: [
        Expanded(
          child: InkWell(
            splashColor: Colors.transparent,
            hoverColor: Colors.transparent,
            highlightColor: Colors.transparent,
            onTap: () => AddressSessionHelper.openAddressPicker(),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('services_in'.tr, style: robotoRegular.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeSmall)),
              const SizedBox(height: Dimensions.paddingSizeTine),
              GetBuilder<LocationController>(builder: (locationController) {
                final hasAddress = AddressSessionHelper.hasValidActiveAddress();
                final address = locationController.getUserAddress();
                final addressText = hasAddress
                    ? (address?.address ?? '')
                    : 'select_your_location'.tr;
                final labelText = hasAddress
                    ? AddressSessionHelper.displayAddressLabelText(address)
                    : null;
                final tooltipMessage = hasAddress && labelText != null
                    ? '$labelText: $addressText'
                    : addressText;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      constraints: BoxConstraints(maxWidth: size.width * 0.5),
                      child: Tooltip(
                        message: tooltipMessage,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              hasAddress
                                  ? AddressSessionHelper.addressHeaderIcon(address)
                                  : Icons.location_on,
                              color: Colors.white,
                              size: Dimensions.paddingSizeDefault,
                            ),
                            const SizedBox(width: Dimensions.paddingSizeMini),
                            if (labelText != null) ...[
                              Text(
                                labelText,
                                style: robotoSemiBold.copyWith(
                                  color: Colors.white,
                                  fontSize: Dimensions.fontSizeSmall,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: Dimensions.paddingSizeTine,
                                ),
                                child: Text(
                                  '·',
                                  style: robotoMedium.copyWith(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: Dimensions.fontSizeSmall,
                                  ),
                                ),
                              ),
                            ],
                            Flexible(
                              child: Text(
                                addressText,
                                style: robotoMedium.copyWith(
                                  color: Colors.white,
                                  fontSize: Dimensions.fontSizeSmall,
                                  fontStyle: hasAddress ? FontStyle.normal : FontStyle.italic,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 12),
                    const SizedBox(width: Dimensions.paddingSizeLarge),
                  ],
                );
              }),
            ]),
          ),
        ),
        InkWell(
          hoverColor: Colors.transparent,
          onTap: () => Get.toNamed(RouteHelper.getCartRoute()),
          child: CartWidget(
            color: Colors.white,
            size: Dimensions.cartWidgetSize,
          ),
        ),
        const SizedBox(width: Dimensions.paddingSizeDefault),
        InkWell(
          hoverColor: Colors.transparent,
          onTap: () => Get.toNamed(RouteHelper.getNotificationRoute()),
          child: const Icon(Icons.notifications, size: 25, color: Colors.white),
        ),
      ]),
    );
  }
  @override
  Size get preferredSize => Size(Dimensions.webMaxWidth, GetPlatform.isDesktop ? 70 :  56);
}