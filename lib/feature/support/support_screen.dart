import 'package:demandium/common/widgets/custom_pop_widget.dart';
import 'package:get/get.dart';
import 'package:demandium/util/core_export.dart';
import 'package:demandium/common/widgets/address_selection_drawer.dart';

class SupportScreen extends StatelessWidget {

  const SupportScreen({super.key}) ;
  @override
  Widget build(BuildContext context) {

    final String phone = Get.find<SplashController>().configModel.content!.businessPhone.toString();
    final String emailAddress = Get.find<SplashController>().configModel.content!.businessEmail.toString();

    return CustomPopWidget(
      child: Scaffold(
        drawer: ResponsiveHelper.isDesktop(context) ? const AddressSelectionDrawer() : null,
        endDrawer:ResponsiveHelper.isDesktop(context) ? const MenuDrawer():null,
        appBar: CustomAppBar(title: 'help_&_support'.tr,),
        body: Center(
          child: FooterBaseView(child: WebShadowWrap(child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeLarge, horizontal: Dimensions.paddingSizeExtraLarge),
            child: Column(children: [
              Image.asset(Images.helpAndSupport, width: 160, height: 140),
              const SizedBox(height: Dimensions.paddingSizeExtraLarge),

              Text(
                'contact_for_support'.tr,
                style: robotoBold.copyWith(fontSize: Dimensions.fontSizeOverLarge),
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
                child: Text(
                  'we_are_here_to_help_contact_our_support'.tr,
                  textAlign: TextAlign.center,
                  style: robotoRegular.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                    color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: .5),
                  ),
                ),
              ),
              const SizedBox(height: Dimensions.paddingForChattingButton),

              ResponsiveHelper.isDesktop(context) ?
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: SupportContactCard(
                  title: 'call_our_customer_support'.tr,
                  subtitle: 'contact_us_through_our_customer_care_number'.tr,
                  contactInfo: phone,
                  icon: Icons.phone,
                  onTap: () async => await launchUrl(Uri(scheme: 'tel', path: phone)),
                )),
                const SizedBox(width: Dimensions.paddingSizeLarge),

                Expanded(child: SupportContactCard(
                  title: 'send_us_email_through'.tr,
                  subtitle: 'typically_the_support_team_send_you_any_feedback'.tr,
                  contactInfo: emailAddress,
                  icon: Icons.email_outlined,
                  onTap: () async => await launchUrl(Uri(scheme: 'mailto', path: emailAddress)),
                )),
              ]) :
              Column(children: [
                SupportContactCard(
                  title: 'call_our_customer_support'.tr,
                  subtitle: 'contact_us_through_our_customer_care_number'.tr,
                  contactInfo: phone,
                  icon: Icons.phone,
                  onTap: () async => await launchUrl(Uri(scheme: 'tel', path: phone)),
                ),
                const SizedBox(height: Dimensions.paddingSizeLarge),

                SupportContactCard(
                  title: 'send_us_email_through'.tr,
                  subtitle: 'typically_the_support_team_send_you_any_feedback'.tr,
                  contactInfo: emailAddress,
                  icon: Icons.email_outlined,
                  onTap: () async => await launchUrl(Uri(scheme: 'mailto', path: emailAddress)),
                ),
              ]),
              const SizedBox(height: Dimensions.paddingSizeExtraLarge),
            ]),
          ))),
        ),
      ),
    );
  }
}


class SupportContactCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String contactInfo;
  final IconData icon;
  final VoidCallback onTap;

  const SupportContactCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.contactInfo,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        border: Border.all(
          color: Theme.of(context).hintColor.withValues(alpha: .08),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withValues(alpha: .04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: .08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Theme.of(context).primaryColor, size: 20),
        ),
        const SizedBox(width: Dimensions.paddingSizeSmall),

        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            title,
            style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault),
          ),
          const SizedBox(height: Dimensions.paddingSizeTine),

          Text(
            subtitle,
            style: robotoRegular.copyWith(
              fontSize: Dimensions.fontSizeExtraSmall,
              color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: .5),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: Dimensions.paddingSizeExtraSmall),

          Row(children: [
            Expanded(child: Text(
              contactInfo,
              style: robotoMedium.copyWith(
                fontSize: Dimensions.fontSizeDefault,
                color: Theme.of(context).textTheme.bodyLarge!.color,
              ),
            )),

            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(50),
              child: Container(
                width: 25, height: 25,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Theme.of(context).cardColor, size: 14),
              ),
            ),
          ]),
        ])),
      ]),
    );
  }
}