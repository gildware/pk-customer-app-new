import 'package:get/get.dart';
import 'package:demandium/util/core_export.dart';
import 'package:demandium/common/widgets/image_dialog.dart';

class NotificationController extends GetxController implements GetxService{
  bool _isLoading = false;

  final NotificationRepo notificationRepo;
  NotificationController({required this.notificationRepo});


  NotificationModel? _notificationModel;
  NotificationModel? get notificationModel => _notificationModel;
  List<String> dateList = [];
  List allNotificationList=[];
  List<dynamic> notificationList=[];
  bool get isLoading => _isLoading;

  int _unreadNotificationCount = 0;
  int get unseenNotificationCount => _unreadNotificationCount;

  int _offset = 1;
  int get offset => _offset;
  final ScrollController scrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();
    getUnreadNotificationCount();
  }

  Future<void> getUnreadNotificationCount() async {
    final response = await notificationRepo.getUnreadCount();
    if (response.statusCode == 200) {
      final count = response.body['content']?['unread_count'];
      _unreadNotificationCount = count is int ? count : int.tryParse('$count') ?? 0;
      update();
    }
  }

  Future<void> refreshInboxFromPush() async {
    await getNotifications(1, reload: true, silent: true);
  }

  Future<void> getNotifications(int offset, {bool reload = true, bool silent = false})async{
    _offset = offset;

    if (offset == 1 && Get.isRegistered<LocationController>()) {
      await Get.find<LocationController>().refreshSavedAddressZone();
    }

    if (!silent) {
      _isLoading = true;
      update();
    }
    Response response = await notificationRepo.getNotificationList(offset);
    if(response.statusCode == 200){
      if(reload){
        allNotificationList = [];
        notificationList = [];
        dateList = [];
      }else{
        allNotificationList =[];
      }
      _notificationModel =  NotificationModel.fromJson(response.body);
      for (var data in notificationModel!.content!.data!) {
        if(!dateList.contains(DateConverter.dateStringMonthYear(DateTime.tryParse(data.createdAt!)))) {
          dateList.add(DateConverter.dateStringMonthYear(DateTime.tryParse(data.createdAt!)));
        }
      }

      for (var data in notificationModel!.content!.data!) {
        allNotificationList.add(data);
      }

      for(int i=0; i< dateList.length;i++){
        notificationList.add([]);
        for (var element in allNotificationList) {
          if(dateList[i] == DateConverter.dateStringMonthYear(DateTime.tryParse(element.createdAt!))){
            notificationList[i].add(element);
          }
        }
      }
      await getUnreadNotificationCount();
      _isLoading =false;
    } else{
      _isLoading =false;
      ApiChecker.checkApi(response);
    }
    update();
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    if (notificationId.isEmpty) {
      return;
    }
    final response = await notificationRepo.markAsRead(notificationId);
    if (response.statusCode == 200) {
      for (final item in allNotificationList) {
        if (item is NotificationData && item.id == notificationId) {
          item.isRead = true;
        }
      }
      if (_unreadNotificationCount > 0) {
        _unreadNotificationCount--;
      }
      update();
      unawaited(getUnreadNotificationCount());
    }
  }

  Future<void> handleInboxNotificationTap(NotificationData notification) async {
    if (notification.id != null && notification.isRead != true) {
      await markNotificationAsRead(notification.id!);
    }

    final action = _resolveInboxAction(notification);

    Get.dialog(
      ImageDialog(
        imageUrl: notification.coverImageFullPath ?? '',
        title: notification.title?.trim() ?? '',
        subTitle: notification.description ?? '',
        actionButtonText: action?.labelKey.tr,
        onActionPressed: action?.onPressed,
      ),
    );
  }

  _InboxNotificationAction? _resolveInboxAction(NotificationData notification) {
    final type = notification.notificationType?.trim().toLowerCase() ?? '';

    switch (type) {
      case 'booking':
      case 'booking_ignored':
      case 'offline-payment':
        final bookingIdentifier = _resolveBookingIdentifier(notification);
        if (bookingIdentifier != null && bookingIdentifier.isNotEmpty) {
          return _InboxNotificationAction(
            labelKey: 'view_booking',
            onPressed: () => _openBookingFromInbox(notification, bookingIdentifier),
          );
        }
        break;
      case 'review':
        return _InboxNotificationAction(
          labelKey: 'view_review',
          onPressed: () => NotificationHelper.openReviewNotificationTarget(),
        );
      case 'wallet':
        return _InboxNotificationAction(
          labelKey: 'view_wallet',
          onPressed: () => Get.toNamed(RouteHelper.getMyWalletScreen(fromNotification: 'fromNotification')),
        );
      case 'loyalty_point':
        return _InboxNotificationAction(
          labelKey: 'view_loyalty_point',
          onPressed: () => Get.toNamed(RouteHelper.getLoyaltyPointScreen(fromNotification: 'fromNotification')),
        );
    }

    return null;
  }

  String? _resolveBookingIdentifier(NotificationData notification) {
    if (!_isBookingRelatedNotification(notification)) {
      return null;
    }

    return _bookingIdFromNotification(notification);
  }

  String? _bookingIdFromNotification(NotificationData notification) {
    final bookingId = notification.bookingId?.trim();
    if (bookingId != null && bookingId.isNotEmpty) {
      return bookingId;
    }

    return _extractReadableIdFromText(notification.description)
        ?? _extractReadableIdFromText(notification.title);
  }

  bool _isBookingRelatedNotification(NotificationData notification) {
    final type = notification.notificationType?.trim().toLowerCase() ?? '';
    return type == 'booking' || type == 'booking_ignored' || type == 'offline-payment';
  }

  String? _extractReadableIdFromText(String? text) {
    if (text == null || text.trim().isEmpty) {
      return null;
    }

    final match = RegExp(r'\(\s*([A-Z0-9]+)\s*\)').firstMatch(text);
    return match?.group(1)?.trim();
  }

  void _openBookingFromInbox(NotificationData notification, String bookingIdentifier) {
    if (bookingIdentifier.isEmpty) {
      return;
    }

    final bookingType = notification.bookingType?.trim();
    final repeatType = notification.repeatType?.trim();
    if (bookingType == 'repeat' && repeatType == 'single') {
      Get.toNamed(
        RouteHelper.getBookingDetailsScreen(
          subBookingId: bookingIdentifier,
          fromPage: 'fromNotification',
        ),
      );
      return;
    }
    if (bookingType == 'repeat' && repeatType != 'single') {
      Get.toNamed(
        RouteHelper.getRepeatBookingDetailsScreen(
          bookingId: bookingIdentifier,
          fromPage: 'fromNotification',
        ),
      );
      return;
    }
    Get.toNamed(
      RouteHelper.getBookingDetailsScreen(
        bookingID: bookingIdentifier,
        fromPage: 'fromNotification',
      ),
    );
  }
}

class _InboxNotificationAction {
  const _InboxNotificationAction({required this.labelKey, required this.onPressed});

  final String labelKey;
  final VoidCallback onPressed;
}
