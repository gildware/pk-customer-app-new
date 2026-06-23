import 'package:demandium/common/widgets/custom_pop_widget.dart';
import 'package:demandium/util/core_export.dart';
import 'package:get/get.dart';

class ProviderSubCategoryServicesScreen extends StatelessWidget {
  final String title;
  final List<Service> services;
  final ProviderData? providerData;

  const ProviderSubCategoryServicesScreen({
    super.key,
    required this.title,
    required this.services,
    this.providerData,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPopWidget(
      child: Scaffold(
        appBar: CustomAppBar(title: title, showCart: true),
        body: FooterBaseView(
          child: SizedBox(
            width: Dimensions.webMaxWidth,
            child: services.isEmpty
                ? NoDataScreen(text: 'no_services_found'.tr, type: NoDataType.service)
                : Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingSizeDefault,
                      vertical: Dimensions.paddingSizeDefault,
                    ),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: ServiceCardLayout.gridDelegate(context),
                      itemCount: services.length,
                      itemBuilder: (context, index) {
                        return ServiceWidgetVertical(
                          service: services[index],
                          fromType: 'provider_details',
                          providerData: providerData,
                        );
                      },
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
