import 'dart:async';

import 'package:demandium/feature/booking/controller/service_booking_controller.dart';
import 'package:demandium/feature/create_post/controller/create_post_controller.dart';
import 'package:demandium/helper/address_session_helper.dart';
import 'package:demandium/feature/auth/controller/auth_controller.dart';
import 'package:get/get.dart';

enum BnbItem {homePage, bookings, biddings, aiChat, more}
class BottomNavController extends GetxController implements GetxService{
  static BottomNavController get to => Get.find();

  var currentPage = BnbItem.homePage;
  void changePage(BnbItem bnbItem, {bool shouldUpdate = true}) {
    final previousPage = currentPage;
    currentPage = bnbItem;

    if(shouldUpdate){
      update();
    }

    if (bnbItem == BnbItem.homePage) {
      unawaited(AddressSessionHelper.performPendingHomeRefreshIfHomeVisible());
    }

    if (shouldUpdate && previousPage != bnbItem) {
      unawaited(_refreshTabData(bnbItem));
    }
  }

  Future<void> _refreshTabData(BnbItem bnbItem) async {
    if (!Get.isRegistered<AuthController>() || !Get.find<AuthController>().isLoggedIn()) {
      return;
    }

    switch (bnbItem) {
      case BnbItem.bookings:
        if (Get.isRegistered<ServiceBookingController>()) {
          await Get.find<ServiceBookingController>().refreshCurrentBookingTab();
        }
        break;
      case BnbItem.biddings:
        if (Get.isRegistered<CreatePostController>()) {
          await Get.find<CreatePostController>().getMyPostList(1, reload: true);
        }
        break;
      default:
        break;
    }
  }

  int _currentMenuPageIndex = 0;
  int get currentMenuPageIndex => _currentMenuPageIndex;

  void updateMenuPageIndex(int index, {bool shouldUpdate = false}){
    _currentMenuPageIndex = index;
    if(shouldUpdate){
      update();
    }
  }
}
