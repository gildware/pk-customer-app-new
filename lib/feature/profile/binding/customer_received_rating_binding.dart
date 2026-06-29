import 'package:demandium/util/core_export.dart';
import 'package:get/get.dart';

class CustomerReceivedRatingBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<UserRepo>()) {
      Get.lazyPut(
        () => UserRepo(apiClient: Get.find(), sharedPreferences: Get.find()),
      );
    }
    if (!Get.isRegistered<CustomerReceivedRatingController>()) {
      Get.lazyPut(
        () => CustomerReceivedRatingController(userRepo: Get.find()),
      );
    }
  }
}
