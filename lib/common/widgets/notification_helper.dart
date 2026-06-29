import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:demandium/common/widgets/demo_reset_dialog_widget.dart';
import 'package:demandium/feature/booking/widget/booking_ignored_bottom_sheet.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:demandium/firebase_options.dart';
import 'package:demandium/helper/notification_sound_util.dart';
import 'package:demandium/util/core_export.dart';

class NotificationHelper {

  static Future<void> createAndroidNotificationChannels(
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin,
  ) async {
    if (!GetPlatform.isAndroid) return;

    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await NotificationSoundUtil.deleteLegacyAndroidChannels(androidPlugin);
    for (final channel in NotificationSoundUtil.buildAndroidChannels()) {
      await androidPlugin?.createNotificationChannel(channel);
    }
  }

  static Future<void> initialize(FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin) async {
    await createAndroidNotificationChannels(flutterLocalNotificationsPlugin);
    var androidInitialize = const AndroidInitializationSettings('notification_icon');
    var iOSInitialize = const DarwinInitializationSettings();
    var initializationsSettings = InitializationSettings(android: androidInitialize, iOS: iOSInitialize);
    flutterLocalNotificationsPlugin.initialize(settings: initializationsSettings, onDidReceiveNotificationResponse: (payload) async {
      if (kDebugMode) {
        print("Payload: $payload");
      }

      try{
        if(payload.payload!=null && payload.payload!=''){
          NotificationBody notificationBody = NotificationBody.fromJson(jsonDecode(payload.payload!));
          if (kDebugMode) {
            print("Type: ${notificationBody.notificationType}");
          }
          if(notificationBody.notificationType == "chatting"){

            if(!GetPlatform.isWeb){
              if(Get.currentRoute.contains(RouteHelper.chatScreen)){
                Get.back();
                Get.back();
              } else if(Get.currentRoute.contains(RouteHelper.chatInbox)){
                Get.back();
              }
            }
            Get.toNamed(RouteHelper.getChatScreenRoute(
                notificationBody.channelId??"",
                notificationBody.userType == 'super-admin' ? "admin" : notificationBody.userName??"",
                notificationBody.userProfileImage??"",
                notificationBody.userPhone??"",
                notificationBody.userType??"",
                fromNotification: "fromNotification"
            ));
          }
          else if(_isInAppCallEvent(notificationBody.notificationType)){
            if(Get.isRegistered<InAppCallController>()){
              unawaited(Get.find<InAppCallController>().handlePushData(notificationBody.toJson()));
            }
          }
          else if(notificationBody.notificationType == 'bidding' || notificationBody.notificationType == 'bid-withdraw'){
            Get.toNamed(RouteHelper.getMyPostScreen(fromNotification: "fromNotification"));
          }

          else if(notificationBody.notificationType == 'logout'){
            Get.find<AuthController>().performLogout(showSuccessMessage: false);
          }
          else if(notificationBody.notificationType == 'wallet'){
            if(!Get.currentRoute.contains(RouteHelper.myWallet)){
              Get.toNamed(RouteHelper.getMyWalletScreen(fromNotification: "fromNotification"));
            }else{
              Get.find<WalletController>().getWalletTransactionData(1, reload: true);
            }
          }
          else if(notificationBody.notificationType == 'loyalty_point'){
            if(!Get.currentRoute.contains(RouteHelper.loyaltyPoint)){
              Get.toNamed(RouteHelper.getLoyaltyPointScreen(fromNotification: "fromNotification"));
            }
          }
          else if(NotificationHelper.isReviewNotification(notificationBody)){
            NotificationHelper.openReviewNotificationTarget();
          }
          else if(notificationBody.notificationType == 'booking' && notificationBody.bookingId !=null && notificationBody.bookingId!=''){
            if(notificationBody.bookingType == "repeat" && notificationBody.repeatBookingType == "single"){
              Get.toNamed(RouteHelper.getBookingDetailsScreen( subBookingId : notificationBody.bookingId!,fromPage: 'fromNotification'));
            }else if(notificationBody.bookingType == "repeat" && notificationBody.repeatBookingType != "single"){
              Get.toNamed(RouteHelper.getRepeatBookingDetailsScreen( bookingId : notificationBody.bookingId, fromPage : "fromNotification"));
            }else{
              Get.toNamed(RouteHelper.getBookingDetailsScreen( bookingID:notificationBody.bookingId!,fromPage: 'fromNotification'));
            }
          } else if(notificationBody.notificationType=='privacy_policy' && notificationBody.title!=null && notificationBody.title!=''){
            Get.toNamed(RouteHelper.getPrivacyPolicyRoute());
          }else if(notificationBody.notificationType=='terms_and_conditions' && notificationBody.title!=null && notificationBody.title!=''){
              Get.toNamed(RouteHelper.getTermsAndConditionsRoute());
          }else if(NotificationHelper.isServiceNotification(notificationBody)){
            await NotificationHelper.navigateToServiceNotification(notificationBody);
          }else{
              Get.toNamed(RouteHelper.getNotificationRoute());
          }
        }
      }catch (e) {
        if (kDebugMode) {
          print("");
        }
      }
      return;
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print("onMessage: Notification Type => ${message.data["type"]}/ Title => ${message.data['title']} ${message.notification?.title}/${message.notification?.body}/${message.notification?.titleLocKey}");
        print("onMessage: Notification Body => ${message.data.toString()}");
      }
      if(!ResponsiveHelper.isWeb()){
        if(message.data['type']=='bidding'){

          if((message.data['post_id']!="" && message.data['post_id']!=null) && (message.data['provider_id']!="" && message.data['provider_id']!=null)){
            Get.find<CreatePostController>().providerBidDetailsForNotification(message.data['post_id'],message.data['provider_id']);
          }else{
            NotificationHelper.showNotification(message, flutterLocalNotificationsPlugin, false);
          }

          if(Get.currentRoute==RouteHelper.myPost){
            Get.find<CreatePostController>().getMyPostList(1);
          }
        }

        else if(message.data['type']=='bid-withdraw'){
          if(Get.currentRoute.contains(RouteHelper.customPostCheckout)){
            Future.delayed(const Duration(microseconds: 300), () {
              Get.dialog(
                const ProviderWithdrawBidDialog(),
                barrierDismissible: false,
              );
            });

          }else{
            NotificationHelper.showNotification(message, flutterLocalNotificationsPlugin, false);
          }
        }

        else if(message.data['type'] == 'chatting'){
          if((message.data['channel_id']!="" && message.data['channel_id']!=null)){

            if(Get.currentRoute.contains(RouteHelper.chatScreen) && message.data['channel_id'] == Get.find<ConversationController>().channelId){
              Get.find<ConversationController>().cleanOldData();
              Get.find<ConversationController>().setChannelId(message.data['channel_id']);
              Get.find<ConversationController>().getConversation(message.data['channel_id'], 1,isInitial:true);
            }else if(Get.currentRoute.contains(RouteHelper.chatInbox) || Get.currentRoute.contains(RouteHelper.chatScreen)){
              if (kDebugMode) {
                print("${message.data['user_type']}");
              }
              NotificationHelper.showNotification(message, flutterLocalNotificationsPlugin, false);
              if(message.data['user_type'] == 'provider-admin'){
                Get.find<ConversationController>().getChannelList(1);
              }else if(AppFeatureFlags.servicemanEnabled){
                Get.find<ConversationController>().getChannelList(1, type: "serviceman");
              }else{
                Get.find<ConversationController>().getChannelList(1, type: "provider");
              }
            }else{
              NotificationHelper.showNotification(message, flutterLocalNotificationsPlugin, false);
            }

          } else{
            NotificationHelper.showNotification(message, flutterLocalNotificationsPlugin, false);
          }
        }
        else if(message.data['type'] == 'logout'){
          NotificationHelper.showNotification(message, flutterLocalNotificationsPlugin,false);

          Get.find<AuthController>().performLogout(showSuccessMessage: false).then((_) {
            customSnackBar(message.data['title'], duration: 4);
          });
        }
        else if(message.data['type'] == 'maintenance'){
          Get.find<SplashController>().getConfigData();
        }
        else if(message.data['type'] == 'demo_reset') {
          if(Get.find<SplashController>().configModel.content?.appEnvironment == "demo"){
            Get.dialog(const DemoResetDialogWidget(), barrierDismissible: false);
          }
        }
        else if(message.data['type'] == 'booking_ignored') {
          showModalBottomSheet(
            isDismissible: false,
            backgroundColor: Colors.transparent,
            context: Get.context!,
              builder: (context) =>  NotificationIgnoredBottomSheet(bookingId: message.data['booking_id']),
          );
          _refreshInAppNotificationList();
        }
        else if(_isInAppCallEvent(message.data['type']?.toString())) {
          if(Get.isRegistered<InAppCallController>()){
            unawaited(Get.find<InAppCallController>().handlePushData(Map<String, dynamic>.from(message.data)));
          }
        }
        else{
          NotificationHelper.showNotification(message, flutterLocalNotificationsPlugin, false);
          _refreshInAppNotificationList();
        }
      }
      else{
        NotificationBody notificationBody = NotificationBody.fromJson(message.data);

        if(message.data["type"]=="chatting" && (message.data['channel_id']!="" && message.data['channel_id']!=null) &&
            message.data['channel_id'] == Get.find<ConversationController>().channelId && Get.currentRoute.contains(RouteHelper.chatScreen)){
          Get.find<ConversationController>().cleanOldData();
          Get.find<ConversationController>().setChannelId(message.data['channel_id']);
          Get.find<ConversationController>().getConversation(message.data['channel_id'], 1,isInitial:true);
        } else if(notificationBody.notificationType =="booking_ignored" && notificationBody.bookingId != null){

          if(Get.find<AuthController>().isNotificationActive()){
            final player = AudioPlayer();
            player.play(AssetSource(NotificationSoundUtil.assetSoundForType(message.data['type']?.toString())));
          }
          Get.dialog( Center(child: NotificationIgnoredBottomSheet(bookingId: message.data['booking_id'],)), barrierDismissible: false);
        }
        else if(message.data["type"]=="bid-withdraw" && Get.currentRoute.contains(RouteHelper.customPostCheckout)){
          Future.delayed(const Duration(microseconds: 500), () {
            Get.dialog(
              const ProviderWithdrawBidDialog(),
              barrierDismissible: false,
            );
          });
        }
        else{

          Future.delayed(const Duration(milliseconds: 1700), (){
            Get.dialog(PushNotificationDialog(
                title: message.notification!.title,
                notificationBody: notificationBody
            ));
          });

        }

        if(message.data["type"]=="bidding" &&Get.currentRoute==RouteHelper.myPost && (message.data['post_id']!="" && message.data['post_id']!=null)){
          Get.find<CreatePostController>().getMyPostList(1,reload: true);
        }
        _refreshInAppNotificationList();
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage? message) async {
      printLog("onMessageOpenApp: ${message?.notification!.title}/${message?.notification!.body}/${message?.notification!.titleLocKey} || ${message?.data}");

     try{
       if(message !=null && message.data.isNotEmpty) {
         NotificationBody notificationBody = convertNotification(message.data);
         if(notificationBody.notificationType == "chatting"){

           if(!GetPlatform.isWeb){
             if(Get.currentRoute.contains(RouteHelper.chatScreen)){
               Get.back();
               Get.back();
             } else if(Get.currentRoute.contains(RouteHelper.chatInbox)){
               Get.back();
             }
           }
           Get.toNamed(RouteHelper.getChatScreenRoute(
               notificationBody.channelId??"",
               notificationBody.userType == 'super-admin' ? "admin" : notificationBody.userName??"",
               notificationBody.userProfileImage??"",
               notificationBody.userPhone??"",
               notificationBody.userType??"",
               fromNotification: "fromNotification"
           ));
         }
         else if(_isInAppCallEvent(notificationBody.notificationType)){
           if(Get.isRegistered<InAppCallController>()){
             await Get.find<InAppCallController>().handlePushData(notificationBody.toJson());
           }
         }
         else if(notificationBody.notificationType == 'bidding' || notificationBody.notificationType == 'bid-withdraw'){
          if(!Get.currentRoute.contains(RouteHelper.myWallet)){
            Get.toNamed(RouteHelper.getMyPostScreen(fromNotification: "fromNotification"));
          }
         }
         else if(notificationBody.notificationType == 'booking' && notificationBody.bookingId != null && notificationBody.bookingId !=''){
           if(notificationBody.bookingType == "repeat" && notificationBody.repeatBookingType == "single"){
             Get.toNamed(RouteHelper.getBookingDetailsScreen( subBookingId : notificationBody.bookingId!,fromPage: 'fromNotification'));
           }else if(notificationBody.bookingType == "repeat" && notificationBody.repeatBookingType != "single"){
             Get.toNamed(RouteHelper.getRepeatBookingDetailsScreen( bookingId : notificationBody.bookingId, fromPage : "fromNotification"));
           }else{
             Get.toNamed(RouteHelper.getBookingDetailsScreen( bookingID:notificationBody.bookingId!,fromPage: 'fromNotification'));
           }
         }
         else if(notificationBody.notificationType == 'privacy_policy' && notificationBody.title != null && notificationBody.title !=''){
           Get.toNamed(RouteHelper.getPrivacyPolicyRoute());
         }
         else if(notificationBody.notificationType == 'terms_and_conditions' && notificationBody.title != null && notificationBody.title !=''){
           Get.toNamed(RouteHelper.getTermsAndConditionsRoute());
         }
         else if(notificationBody.notificationType == "wallet"){
          Get.toNamed(RouteHelper.getMyWalletScreen(fromNotification: "fromNotification"));
         }
         else if(notificationBody.notificationType == 'loyalty_point'){
           if(!Get.currentRoute.contains(RouteHelper.loyaltyPoint)){
             Get.toNamed(RouteHelper.getLoyaltyPointScreen(fromNotification: "fromNotification"));
           }
         }
         else if(NotificationHelper.isReviewNotification(notificationBody)){
           NotificationHelper.openReviewNotificationTarget();
         }
         else if(notificationBody.notificationType == 'logout'){
           Get.find<AuthController>().performLogout(showSuccessMessage: false);
         }
         else if(NotificationHelper.isServiceNotification(notificationBody)){
           await NotificationHelper.navigateToServiceNotification(notificationBody);
         }
         else{
           Get.toNamed(RouteHelper.getNotificationRoute());
         }
       }
     }catch (e) {
       if (kDebugMode) {
         print("");
       }
     }
    });
  }

  static Future<void> showNotification(
    RemoteMessage message,
    FlutterLocalNotificationsPlugin fln,
    bool data, {
    bool fromBackgroundHandler = false,
  }) async {
    if (GetPlatform.isIOS && message.notification != null) {
      return;
    }
    final title = message.data['title'] ?? message.notification?.title;
    final body = message.data['body'] ?? message.notification?.body ?? '';
    final playLoad = jsonEncode(message.data);
    if (title == null || title.isEmpty) return;

    final notificationType = message.data['type']?.toString();
    final soundEnabled = _notificationSoundEnabled();

    if (GetPlatform.isIOS) {
      final darwinDetails = NotificationSoundUtil.darwinDetailsForType(
        notificationType,
        withSound: soundEnabled,
      );
      final platformChannelSpecifics = NotificationDetails(iOS: darwinDetails);
      await fln.show(
        id: Random().nextInt(100000),
        title: title,
        body: body,
        notificationDetails: platformChannelSpecifics,
        payload: playLoad,
      );
      return;
    }

    String? orderID;
    String? image;
    orderID = message.data['booking_id'].toString();
    image = (message.data['image'] != null && message.data['image'].isNotEmpty)
        ? message.data['image'].startsWith('http') ? message.data['image']
        : '${AppConstants.baseUrl}/storage/app/public/notification/${message.data['image']}' : null;

    if(image != null && image.isNotEmpty) {
      try{
        await showBigPictureNotificationHiddenLargeIcon(title, body, playLoad, image, fln, notificationType, message.data);
      }catch(e) {
        await showBigTextNotification(title, body, playLoad, orderID, fln, notificationType, messageData: message.data);
      }

    }else {
      await showBigTextNotification(title, body, playLoad, orderID, fln, notificationType, messageData: message.data);
    }

    if (!fromBackgroundHandler) {
      await _playAndroidForegroundSound(notificationType, message.data);
    }
  }

  static Future<void> showBackgroundNotification(
    RemoteMessage message,
    FlutterLocalNotificationsPlugin fln,
  ) async {
    await createAndroidNotificationChannels(fln);
    await showNotification(message, fln, false, fromBackgroundHandler: true);
  }

  static Future<void> showTextNotification(String title, String? body, String orderID, FlutterLocalNotificationsPlugin fln, {String? notificationType}) async {
    final androidPlatformChannelSpecifics = NotificationSoundUtil.androidDetailsForType(
      notificationType,
      withSound: _notificationSoundEnabled(),
    );
    int randomNumber = Random().nextInt(100);
    final platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await fln.show(id: randomNumber, title: title, body: body, notificationDetails: platformChannelSpecifics, payload: orderID);
  }

  static Future<void> showBigTextNotification(String title, String? body, String payload, String image, FlutterLocalNotificationsPlugin fln, String? notificationType, {Map<String, dynamic>? messageData}) async {
    final resolvedType = notificationType ?? NotificationSoundUtil.typeFromPayload(payload);
    BigTextStyleInformation bigTextStyleInformation = BigTextStyleInformation(
      body ?? "", htmlFormatBigText: true,
      contentTitle: title, htmlFormatContentTitle: true,
    );
    final androidPlatformChannelSpecifics = messageData != null
        ? NotificationSoundUtil.androidDetailsFromData(
            messageData,
            withSound: _notificationSoundEnabled(),
            styleInformation: bigTextStyleInformation,
          )
        : NotificationSoundUtil.androidDetailsForType(
            resolvedType,
            withSound: _notificationSoundEnabled(),
            styleInformation: bigTextStyleInformation,
          );

    int randomNumber = Random().nextInt(100);

    NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await fln.show(id: randomNumber, title: title, body: body, notificationDetails: platformChannelSpecifics, payload: payload);
  }

  static Future<void> showBigPictureNotificationHiddenLargeIcon(String title, String body, String payload, String image, FlutterLocalNotificationsPlugin fln, String? notificationType, Map<String, dynamic> messageData) async {
    final String largeIconPath = await _downloadAndSaveFile(image, 'largeIcon');
    final String bigPicturePath = await _downloadAndSaveFile(image, 'bigPicture');
    final BigPictureStyleInformation bigPictureStyleInformation = BigPictureStyleInformation(
      FilePathAndroidBitmap(bigPicturePath), hideExpandedLargeIcon: true,
      contentTitle: title, htmlFormatContentTitle: true,
      summaryText: body, htmlFormatSummaryText: true,
    );
    final androidPlatformChannelSpecifics = NotificationSoundUtil.androidDetailsFromData(
      messageData,
      withSound: _notificationSoundEnabled(),
      styleInformation: bigPictureStyleInformation,
      largeIcon: FilePathAndroidBitmap(largeIconPath),
    );
    int randomNumber = Random().nextInt(100);
    NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await fln.show(id: randomNumber, title: title, body: body, notificationDetails: platformChannelSpecifics, payload: payload);
  }

  static Future<String> _downloadAndSaveFile(String url, String fileName) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final String filePath = '${directory.path}/$fileName';
    final http.Response response = await http.get(Uri.parse(url));
    final File file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    return filePath;
  }

  static bool _notificationSoundEnabled() {
    if (Get.isRegistered<AuthController>()) {
      return Get.find<AuthController>().isNotificationActive();
    }
    return true;
  }

  static Future<void> _playAndroidForegroundSound(
    String? type,
    Map<String, dynamic> data,
  ) async {
    if (!GetPlatform.isAndroid || !_notificationSoundEnabled()) return;

    try {
      final resolvedType = type ?? data['type']?.toString();
      final player = AudioPlayer();
      await player.play(
        AssetSource(NotificationSoundUtil.assetSoundForType(resolvedType)),
      );
    } catch (_) {}
  }

  static NotificationBody convertNotification(Map<String, dynamic> data){
   return NotificationBody.fromJson(data);
  }

  static String resolveServiceSlug(NotificationBody body) {
    final slug = body.serviceSlug?.trim();
    if (slug != null && slug.isNotEmpty) return slug;
    return body.serviceId?.trim() ?? '';
  }

  static bool isServiceNotification(NotificationBody body) {
    return body.notificationType == 'service' && resolveServiceSlug(body).isNotEmpty;
  }

  static Future<void> navigateToServiceNotification(NotificationBody body) async {
    final slug = resolveServiceSlug(body);
    if (slug.isEmpty) {
      Get.toNamed(RouteHelper.getNotificationRoute());
      return;
    }
    if (Get.isRegistered<LocationController>()) {
      await Get.find<LocationController>().refreshSavedAddressZone();
    }
    Get.toNamed(RouteHelper.getServiceRoute(slug, fromPage: 'fromNotification'));
  }

  static void openReviewNotificationTarget() {
    Get.toNamed(RouteHelper.getCustomerReceivedRatingRoute());
  }

  static bool isReviewNotification(NotificationBody? body) {
    return body?.notificationType?.trim().toLowerCase() == 'review';
  }

  static void _refreshInAppNotificationList() {
    if (Get.isRegistered<NotificationController>()) {
      Get.find<NotificationController>().refreshInboxFromPush();
    }
  }

  static bool isInAppCallEvent(String? type) {
    return const {
      'incoming_call',
      'call_accepted',
      'call_declined',
      'call_ended',
      'call_cancelled',
      'call_missed',
    }.contains(type);
  }

  static bool _isInAppCallEvent(String? type) => isInAppCallEvent(type);
}

@pragma('vm:entry-point')
Future<dynamic> myBackgroundMessageHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (kDebugMode) {
    print("onBackground: ${message.data}");
  }

  final fln = FlutterLocalNotificationsPlugin();
  const androidInitialize = AndroidInitializationSettings('notification_icon');
  const iOSInitialize = DarwinInitializationSettings();
  await fln.initialize(
    settings: const InitializationSettings(
      android: androidInitialize,
      iOS: iOSInitialize,
    ),
  );
  await NotificationHelper.createAndroidNotificationChannels(fln);
  await NotificationHelper.showBackgroundNotification(message, fln);
}