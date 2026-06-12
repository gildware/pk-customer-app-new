import 'package:demandium/helper/address_session_helper.dart';
import 'package:get/get.dart';
import 'package:demandium/util/core_export.dart';

class AreaNotServiceableScreen extends StatelessWidget {
  const AreaNotServiceableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final address = Get.find<LocationController>().getUserAddress();

    return Scaffold(
      appBar: CustomAppBar(title: 'set_location'.tr, isBackButtonExist: false),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                Images.notAvailableIcon,
                width: 90,
                height: 90,
                color: Theme.of(context).disabledColor,
              ),
              const SizedBox(height: Dimensions.paddingSizeLarge),
              Text(
                'this_area_is_not_serviceable'.tr,
                style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeExtraLarge),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Dimensions.paddingSizeDefault),
              if (address?.address?.isNotEmpty ?? false)
                Text(
                  address!.address!,
                  style: robotoRegular.copyWith(
                    fontSize: Dimensions.fontSizeDefault,
                    color: Theme.of(context).hintColor,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: Dimensions.paddingSizeExtraLarge),
              CustomButton(
                buttonText: 'change_address'.tr,
                onPressed: () => AddressSessionHelper.openAddressPicker(mandatory: true),
              ),
              const SizedBox(height: Dimensions.paddingSizeDefault),
              TextButton(
                onPressed: () => Get.toNamed(RouteHelper.getServiceArea()),
                child: Text(
                  'view_available_areas'.tr,
                  style: robotoMedium.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
