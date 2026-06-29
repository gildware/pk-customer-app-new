import 'package:demandium/util/core_export.dart';
import 'package:get/get.dart';



class ChannelItem extends StatelessWidget {
  final ChannelData channelData;
  final bool isAdmin;
  const ChannelItem({super.key, required this.channelData, this.isAdmin = false,}) ;
  @override
  Widget build(BuildContext context) {

    ConversationUserModel? conversationUser;
    int? isRead;
    int? isSeen;
    String? lastMessage;

    String userName = "${Get.find<UserController>().userInfoModel?.fName} ${Get.find<UserController>().userInfoModel?.lName}";

    if(channelData.channelUsers !=null && channelData.channelUsers!.length > 1){
      conversationUser = channelData.channelUsers?[0].user?.userType != "customer" ? channelData.channelUsers![0] : channelData.channelUsers![1];
      isRead = channelData.channelUsers![0].user?.userType == "customer" ? channelData.channelUsers![0].isRead! : channelData.channelUsers![1].isRead!;
      isSeen = channelData.channelUsers?[0].user?.userType == "customer" ? channelData.channelUsers![1].isRead : channelData.channelUsers![0].isRead;
    }

    String imageWithPath = conversationUser?.user?.userType=="super-admin"? "${Get.find<SplashController>().configModel.content?.logoFullPath}"
        : conversationUser?.user?.userType == 'provider-admin' ? "${conversationUser?.user?.provider?.logoFullPath}"
        : "${conversationUser?.user?.profileImageFullPath}";

    if(channelData.lastSentMessage !=null ){
      if(channelData.lastMessageSentUser == userName){
        lastMessage = "${'you'.tr}: ${channelData.lastSentMessage}";
      }else{
        lastMessage ="${channelData.lastSentMessage}";
      }

    }else{
      if(channelData.lastSentAttachmentType !=null){
        if((channelData.lastSentAttachmentType == "png" || channelData.lastSentAttachmentType == "jpg")){
          if(channelData.lastMessageSentUser == userName){

            if(channelData.lastSentFileCount!=null && channelData.lastSentFileCount! > 1){
              lastMessage = "${'you_sent'.tr} ${channelData.lastSentFileCount} ${'photos'.tr}";
            }else{
              lastMessage = "you_sent_a_photo".tr;
            }

          }else{

            if(channelData.lastSentFileCount!=null && channelData.lastSentFileCount! > 1){
              lastMessage = "${'sent'.tr} ${channelData.lastSentFileCount!} ${'photos'.tr}";
            }else{
              lastMessage = 'sent_a_photo'.tr;
            }

          }
        }else{

          if(channelData.lastMessageSentUser == userName){
            if(channelData.lastSentFileCount!=null && channelData.lastSentFileCount! > 1){
              lastMessage = "${'you_sent'.tr} ${channelData.lastSentFileCount} ${"attachments".tr}";
            }else{
              lastMessage = "you_sent_an_attachment".tr;
            }

          }else{
            if(channelData.lastSentFileCount!=null && channelData.lastSentFileCount! > 1){
              lastMessage = "${'sent'.tr} ${channelData.lastSentFileCount!} ${'attachments'.tr}";
            }else{
              lastMessage = 'sent_an_attachment'.tr;
            }

          }
        }
      }
    }
    if (kDebugMode) {
      print("Provider : ${conversationUser?.user?.provider?.companyName}");
    }

    return conversationUser != null ? Container(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: Dimensions.paddingSizeEight),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
          color: isRead == 0 ? Theme.of(context).primaryColor.withValues(alpha: Get.isDarkMode?0.2:0.05) : Theme.of(context).cardColor.withValues(alpha: Get.isDarkMode?0.5:1),
          boxShadow: lightShadow ,
          border: Border.all(
            color:  isRead == 0 ? Theme.of(context).primaryColor.withValues(alpha: 0.5): Theme.of(context).cardColor,
            width: 0.5,
          )
      ),
      child: Stack( children: [

        Padding(padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeEight),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(borderRadius: BorderRadius.circular(50),
              child: CustomImage(height: 42, width: 42,
                image: imageWithPath,
                placeholder: isAdmin? Images.adminPlaceHolder : Images.userPlaceHolder,
              ),
            ),

            const SizedBox(width: Dimensions.paddingSizeSmall),

            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              Row(children: [
                Expanded(
                  child: Text(isAdmin ? "admin".tr : conversationUser.user?.userType == 'provider-admin' ? "${conversationUser.user?.provider?.companyName}" :"${ conversationUser.user?.firstName??""} ${ conversationUser.user?.lastName}",
                    style: robotoBold.copyWith(
                        fontSize: Dimensions.fontSizeDefault,
                        color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7)
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                if( conversationUser.user?.userType == "super-admin") Padding(
                  padding: const EdgeInsets.only(left: Dimensions.paddingSizeExtraSmall),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: .2),
                      borderRadius: const BorderRadius.all(Radius.circular(8.0)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall, vertical: 2),
                      child: Text('support'.tr, style: robotoMedium.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: Dimensions.fontSizeExtraSmall,
                      )),
                    ),
                  ),
                ),

                const SizedBox(width: Dimensions.paddingSizeExtraSmall),

                Text(DateConverter.dateMonthYearTime(DateConverter.isoUtcStringToLocalDate(conversationUser.updatedAt!)),
                  style: robotoRegular.copyWith(color: Theme.of(context).hintColor, fontSize: Dimensions.fontSizeExtraSmall),
                  textDirection: TextDirection.ltr,
                ),
              ]),

              if(lastMessage!=null) Padding(padding: const EdgeInsets.only(top: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(lastMessage.capitalizeFirst ?? "" ,
                        style: isRead ==0 ? robotoMedium.copyWith(
                          color: Theme.of(context).textTheme.bodySmall!.color!.withValues(alpha: 0.7),
                          fontSize: Dimensions.fontSizeSmall,
                        ) : robotoRegular.copyWith(
                          color: Theme.of(context).textTheme.bodySmall!.color!.withValues(alpha: 0.5),
                          fontSize: Dimensions.fontSizeSmall,
                        ),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    if(channelData.lastMessageSentUser == userName) Icon(Icons.done_all,
                      color: isSeen ==1  && isRead == 1 ? context.tabSelectedColor : Theme.of(context).hintColor.withValues(alpha: 0.7),
                      size: 16,
                    ),
                  ],
                ),
              ),

            ])),
          ]),
        ),

        Positioned.fill(child: CustomInkWell(
          radius: Dimensions.radiusDefault,
          onTap:(){
            Get.find<ConversationController>().resetImageFile();
            String name = isAdmin ? "admin".tr : conversationUser?.user?.userType == 'provider-admin' ? "${conversationUser?.user?.provider?.companyName}" : "${ conversationUser?.user?.firstName ?? ""} ${ conversationUser?.user?.lastName??""}";
            String image = imageWithPath;
            String phone =  conversationUser?.user?.phone??"";
            String userType =  conversationUser?.user?.userType??"";
            Get.toNamed(RouteHelper.getChatScreenRoute(
                conversationUser?.channelId ?? "",name,image,phone,userType));
          },
        ),)


      ],),

    ) : const SizedBox();
  }
}

