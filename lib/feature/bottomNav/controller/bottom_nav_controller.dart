import 'dart:async';

import 'package:demandium/helper/address_session_helper.dart';
import 'package:get/get.dart';

enum BnbItem {homePage, bookings, biddings, aiChat, more}
class BottomNavController extends GetxController implements GetxService{
  static BottomNavController get to => Get.find();

  var currentPage = BnbItem.homePage;
  void changePage(BnbItem bnbItem, {bool shouldUpdate = true}) {
    currentPage = bnbItem;

    if(shouldUpdate){
      update();
    }

    if (bnbItem == BnbItem.homePage) {
      unawaited(AddressSessionHelper.performPendingHomeRefreshIfHomeVisible());
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
