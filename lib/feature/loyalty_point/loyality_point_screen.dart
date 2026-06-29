import 'package:demandium/common/widgets/custom_pop_widget.dart';
import 'package:demandium/util/core_export.dart';
import 'package:get/get.dart';
import 'package:demandium/common/widgets/address_selection_drawer.dart';

class LoyaltyPointScreen extends StatefulWidget {
  final String? fromNotification;
  const LoyaltyPointScreen({super.key, this.fromNotification}) ;

  @override
  State<LoyaltyPointScreen> createState() => _LoyaltyPointScreenState();
}

class _LoyaltyPointScreenState extends State<LoyaltyPointScreen> {
  bool _featureRedirectScheduled = false;

  void _redirectIfFeatureDisabled(SplashController splashController) {
    if (_featureRedirectScheduled) {
      return;
    }
    if (splashController.currentDataSource == DataSourceEnum.client &&
        splashController.configModel.content?.loyaltyPointStatus == 0) {
      _featureRedirectScheduled = true;
      runAfterFrame(() => Get.offAllNamed(RouteHelper.getMainRoute("home")));
    }
  }

  void _handleBack(BuildContext context) {
    if (widget.fromNotification == "fromNotification" || !Navigator.canPop(context)) {
      Get.offAllNamed(RouteHelper.getMainRoute("home"));
    } else {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SplashController>(
      builder: (splashController) {
        _redirectIfFeatureDisabled(splashController);
        return CustomPopWidget(
          onPopInvoked: () => _handleBack(context),
          isNavigationOnOnPop: true,
          child: Scaffold(
            drawer: ResponsiveHelper.isDesktop(context) ? const AddressSelectionDrawer() : null,

            endDrawer:ResponsiveHelper.isDesktop(context) ? const MenuDrawer():null,
            appBar: CustomAppBar(title: 'loyalty_point'.tr,actionWidget: InkWell(
              onTap: (){
                showGeneralDialog(
                  context: context,
                  barrierDismissible: true,
                  transitionDuration: const Duration(milliseconds: 500),
                  barrierLabel: MaterialLocalizations.of(context).dialogLabel,
                  barrierColor: Colors.black.withValues(alpha: 0.5),
                  pageBuilder: (context, _, a) {
                    return const LoyaltyPointUsesManualDialog();
                  },
                  transitionBuilder: (context, animation, secondaryAnimation, child) {
                    return SlideTransition(
                      position: CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOut,
                      ).drive(Tween<Offset>(
                        begin: const Offset(0, -1.0),
                        end: Offset.zero,
                      )),
                      child: child,
                    );
                  },
                );
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(15,0, 15, 0),
                child: Image.asset(Images.info,width: 20,height: 20,color: Colors.white,),
              ),
            ),
              onBackPressed: () => _handleBack(context)
              ,bgColor: Theme.of(context).cardColor,),
            body: GetBuilder<LoyaltyPointController>(
              initState: (_){
                Get.find<LoyaltyPointController>().getLoyaltyPointData(1);
              },
          builder: (loyaltyPointController){
          
            return FooterBaseView(
              isScrollView: true,
              child: SizedBox(
                width: Dimensions.webMaxWidth,
                child:loyaltyPointController.loyaltyPointModel!=null? Column(children: [
                  const Column(crossAxisAlignment: CrossAxisAlignment.start,children: [
          
                    LoyaltyPointTopCard(),
          
                    LoyaltyPointListView(),
                  ]),
                  if(ResponsiveHelper.isDesktop(context))
                  Padding(
                    padding: const EdgeInsets.only(bottom:Dimensions.paddingSizeSmall),
                    child: CustomButton(
                      width: Dimensions.currencyConvertButtonHeight,
                      buttonText: "convert_to_currency".tr,
                      assetIcon: Images.convertPoint,
                      height: 45,
                      radius: Dimensions.radiusExtraMoreLarge,
                      onPressed: (){
                        showDialog(context: context, builder: (_){
                          return const ConvertLoyaltyPointDialog();
                        });
                      },
                    ),
                  )
                ]):Center(
                  child: SizedBox(
                    height: ResponsiveHelper.isDesktop(context)?100: Get.height*0.85,
                      child: const Center(child: CircularProgressIndicator(),)),
                ),
              ),
            );
                }),
                bottomSheet: GetBuilder<LoyaltyPointController>(builder: (loyaltyPointController){
          if(!ResponsiveHelper.isDesktop(context) && Get.find<LoyaltyPointController>().loyaltyPointModel!=null){
            return SizedBox(
              height: 60,
              width: Get.width,
              child: CustomButton(
                width: Dimensions.currencyConvertButtonHeight,
                buttonText: "convert_to_currency".tr,
                assetIcon: Images.convertPoint,
                height: 45,
                radius: Dimensions.radiusExtraMoreLarge,
                onPressed: (){
                  showDialog(context: context, builder: (_){
                    return const ConvertLoyaltyPointDialog();
                  });
                },
              ),
            );
          }else{
            return const SizedBox();
          }
                }),
          ),
        );
      }
    );
  }
}
