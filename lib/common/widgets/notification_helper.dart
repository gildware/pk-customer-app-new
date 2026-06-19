import 'dart:convert';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:demandium/common/widgets/demo_reset_dialog_widget.dart';
import 'package:demandium/feature/booking/widget/booking_ignored_bottom_sheet.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:demandium/firebase_options.dart';
import 'package:demandium/util/core_export.dart';

class NotificationHelper {

  static Future<void> createAndroidNotificationChannels(
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin,
  ) async {
    if (!GetPlatform.isAndroid) return;

    const withSound = AndroidNotificationChannel(
      'demandium',
      'demandium with sound',
      description: 'Notifications with sound',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('notification'),
    );
    const withoutSound = AndroidNotificationChannel(
      'demandiumWithoutsound',
      'demandium without sound',
      description: 'Notifications without sound',
      importance: Importance.max,
      playSound: false,
    );

    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(withSound);
    await androidPlugin?.createNotificationChannel(withoutSound);
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
          else if(notificationBody.notificationType == 'bidding' || notificationBody.notificationType == 'bid-withdraw'){
            Get.toNamed(RouteHelper.getMyPostScreen(fromNotification: "fromNotification"));
          }

          else if(notificationBody.notificationType == 'logout'){
            Get.find<AuthController>().clearSharedData();
            Get.offNamed(RouteHelper.getSignInRoute());
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
              }else{
                Get.find<ConversationController>().getChannelList(1, type: "serviceman");
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

          Get.find<AuthController>().logOut();
          Get.find<AuthController>().clearSharedData();
          Get.find<AuthController>().googleLogout();
          Get.find<AuthController>().signOutWithFacebook();
          Get.find<LocationController>().updateSelectedAddress(null);
          Get.offNamed(RouteHelper.getSignInRoute());
          customSnackBar(message.data['title'], duration: 4);
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
        }
        else{
          NotificationHelper.showNotification(message, flutterLocalNotificationsPlugin, false);
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
            player.play(AssetSource('notification.wav'));
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
         else if(notificationBody.notificationType == 'logout'){
           Get.find<AuthController>().clearSharedData();
           Get.offNamed(RouteHelper.getSignInRoute());
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

  static Future<void> showNotification(RemoteMessage message, FlutterLocalNotificationsPlugin fln, bool data) async {
    final title = message.data['title'] ?? message.notification?.title;
    final body = message.data['body'] ?? message.notification?.body ?? '';
    final playLoad = jsonEncode(message.data);
    if (title == null || title.isEmpty) return;

    if (GetPlatform.isIOS) {
      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      const platformChannelSpecifics = NotificationDetails(iOS: darwinDetails);
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
        await showBigPictureNotificationHiddenLargeIcon(title, body, playLoad, image, fln);
      }catch(e) {
        await showBigTextNotification(title, body, playLoad, orderID, fln);
      }

    }else {
      await showBigTextNotification(title, body, playLoad, orderID, fln);
    }
  }

  static Future<void> showBackgroundNotification(
    RemoteMessage message,
    FlutterLocalNotificationsPlugin fln,
  ) async {
    await createAndroidNotificationChannels(fln);
    await showNotification(message, fln, false);
  }

  static Future<void> showTextNotification(String title, String? body, String orderID, FlutterLocalNotificationsPlugin fln) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'demandium', 'demandium', playSound: true,
      importance: Importance.max, priority: Priority.max, sound: RawResourceAndroidNotificationSound('notification'),
    );
    int randomNumber = Random().nextInt(100);
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await fln.show(id: randomNumber, title: title, body: body, notificationDetails: platformChannelSpecifics, payload: orderID);
  }

  static Future<void> showBigTextNotification(String title, String? body, String payload, String image, FlutterLocalNotificationsPlugin fln) async {
    BigTextStyleInformation bigTextStyleInformation = BigTextStyleInformation(
      body ?? "", htmlFormatBigText: true,
      contentTitle: title, htmlFormatContentTitle: true,
    );
    if(!_notificationSoundEnabled()){
      AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
        "demandiumWithoutsound","demandium without sound", channelDescription:"description",
        playSound: false,
        importance: Importance.max,
        styleInformation: bigTextStyleInformation, priority: Priority.max,

      );

      int randomNumber = Random().nextInt(100);

      NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
      await fln.show(id: randomNumber, title: title, body: body, notificationDetails: platformChannelSpecifics, payload: payload);
    }
    else {
      AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
        "demandium", 'demandium with sound', channelDescription:"description",
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('notification'),
        importance: Importance.max,
        styleInformation: bigTextStyleInformation, priority: Priority.max,
      );
      int randomNumber = Random().nextInt(100);
      NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
      await fln.show(id: randomNumber, title: title, body: body, notificationDetails: platformChannelSpecifics, payload: payload);
    }
  }

  static Future<void> showBigPictureNotificationHiddenLargeIcon(String title, String body, String payload, String image, FlutterLocalNotificationsPlugin fln) async {
    final String largeIconPath = await _downloadAndSaveFile(image, 'largeIcon');
    final String bigPicturePath = await _downloadAndSaveFile(image, 'bigPicture');
    final BigPictureStyleInformation bigPictureStyleInformation = BigPictureStyleInformation(
      FilePathAndroidBitmap(bigPicturePath), hideExpandedLargeIcon: true,
      contentTitle: title, htmlFormatContentTitle: true,
      summaryText: body, htmlFormatSummaryText: true,
    );
    if(!_notificationSoundEnabled()){
      AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
        "demandiumWithoutsound","demandium without sound", channelDescription:"description",
        playSound: false,
        largeIcon: FilePathAndroidBitmap(largeIconPath), priority: Priority.max,
        styleInformation: bigPictureStyleInformation, importance: Importance.max,
      );
      int randomNumber = Random().nextInt(100);
      NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
      await fln.show(id: randomNumber, title: title, body: body, notificationDetails: platformChannelSpecifics, payload: payload);

    }else{
      AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
        "demandium", 'demandium with sound', channelDescription:"description",
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('notification'),
        largeIcon: FilePathAndroidBitmap(largeIconPath), priority: Priority.max,
        styleInformation: bigPictureStyleInformation, importance: Importance.max,
      );
      int randomNumber = Random().nextInt(100);
      NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
      await fln.show(id: randomNumber, title: title, body: body, notificationDetails: platformChannelSpecifics, payload: payload);
    }
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
}

@pragma('vm:entry-point')
Future<dynamic> myBackgroundMessageHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (kDebugMode) {
    print("onBackground: ${message.notification?.title}/${message.notification?.body}/${message.notification?.titleLocKey}");
  }

  if (message.notification != null) {
    return;
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
  await NotificationHelper.showBackgroundNotification(message, fln);
}