import 'package:demandium/helper/address_session_helper.dart';
import 'package:get/get.dart';
import 'package:demandium/util/core_export.dart';

class ServiceNotAvailableScreen extends StatelessWidget {
  final String fromPage;
  const ServiceNotAvailableScreen({super.key, this.fromPage = ""});

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(Images.notAvailableIcon, width:  90.0, height: 90.0, color: Colors.grey ),
          const SizedBox(height: Dimensions.paddingSizeLarge),

          Text(fromPage == "search_page"? "there_are_no_services_related_to_your_search".tr : "services_are_not_available".tr,
            style: robotoMedium.copyWith( fontSize: Dimensions.fontSizeExtraLarge),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Dimensions.paddingSizeLarge),

          fromPage != "search_page"?
          Text("please_select_among".tr, style: robotoMedium.copyWith( fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).hintColor), textAlign: TextAlign.center)
          : const SizedBox(),

          const SizedBox(height: Dimensions.paddingSizeLarge),

          fromPage != "search_page"?
          Column(
            children: [
              CustomButton(
                buttonText: 'change_address'.tr,
                onPressed: () => AddressSessionHelper.openAddressPicker(mandatory: true),
              ),
              const SizedBox(height: Dimensions.paddingSizeDefault),
              InkWell(
                onTap: () => Get.toNamed(RouteHelper.getServiceArea()),
                child: Text(
                  "view_available_areas".tr,
                  style: robotoMedium.copyWith(
                    fontSize: Dimensions.fontSizeDefault,
                    color: Theme.of(context).colorScheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ) : const SizedBox(),

        ]
      ),
    );
  }
}
