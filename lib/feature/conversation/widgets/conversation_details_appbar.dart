import 'package:demandium/util/core_export.dart';
import 'package:get/get.dart';

class ConversationDetailsAppBar extends StatelessWidget implements PreferredSizeWidget{
  final String? name;
  final String? image;
  final String? phone;
  final String fromNotification;
  final String? channelId;
  final String? userType;

  const ConversationDetailsAppBar({
    super.key,
    this.name,
    this.image,
    this.phone,
    this.fromNotification = "",
    this.channelId,
    this.userType,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      titleSpacing: 0,
      backgroundColor: Get.isDarkMode ? Theme.of(context).cardColor.withValues(alpha: .2):Theme.of(context).primaryColor,
      title: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                color: Colors.white
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: CustomImage(image: image),
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),

          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              Text( name?.tr ??"", style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault,
                color:  Colors.white,
              )),

              if(phone != "" && Get.find<SplashController>().configModel.content?.phoneNumberVisibility == 1) Padding(padding: const EdgeInsets.only(top: 3),
                child: Text(phone ?? "", style: robotoLight.copyWith( fontSize: Dimensions.fontSizeSmall,
                  color:  Colors.white,
                )),
              ),

            ]),
          ),
        ],
      ),
      actions: [
        GetBuilder<InAppCallController>(builder: (callController) {
          final effectiveChannelId = (channelId != null && channelId!.isNotEmpty)
              ? channelId
              : (Get.isRegistered<ConversationController>()
                  ? Get.find<ConversationController>().channelId
                  : null);
          if (!callController.shouldShowCallButton(effectiveChannelId, userType)) {
            return const SizedBox.shrink();
          }

          return IconButton(
            onPressed: callController.busy
                ? null
                : () => callController.startCall(
                      effectiveChannelId!,
                      peerName: name,
                      peerImage: image,
                      peerPhone: phone,
                      peerUserType: userType,
                    ),
            icon: const Icon(Icons.call, color: Colors.white),
            tooltip: 'call'.tr,
          );
        }),
        const SizedBox(width: 4),
      ],
      leading: IconButton(onPressed: () {
        if(fromNotification == "fromNotification"){
          Get.offNamed(RouteHelper.getInboxScreenRoute(fromNotification: fromNotification));
        }else if (Navigator.canPop(context)) {
          Get.back();
        } else {
          Get.offNamed(RouteHelper.getInboxScreenRoute());
        }
      },
        icon: Icon(Icons.arrow_back_ios,color:Theme.of(context).primaryColorLight,size: 20,),
      ),
    );
  }

  @override
  Size get preferredSize => const Size(double.maxFinite, 55);
}
