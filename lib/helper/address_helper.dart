import 'package:demandium/util/core_export.dart';
import 'package:get/get.dart';

class AddressHelper {
  static bool hasValidContactPerson(AddressModel? address) {
    if (address == null) return false;
    final name = address.contactPersonName?.trim();
    final phone = address.contactPersonNumber?.trim();
    if (name == null || name.isEmpty || name == 'null') return false;
    if (phone == null || phone.isEmpty || phone == 'null') return false;
    return true;
  }

  /// Fills missing contact fields from the logged-in user profile when possible.
  static AddressModel ensureContactPerson(AddressModel address) {
    if (hasValidContactPerson(address)) return address;

    if (Get.find<AuthController>().isLoggedIn()) {
      final user = Get.find<UserController>().userInfoModel;
      final firstName = user?.fName?.trim() ?? '';
      final lastName = user?.lName?.trim() ?? '';
      final fullName = '$firstName $lastName'.trim();

      if (!hasValidContactPerson(address) && fullName.isNotEmpty) {
        address.contactPersonName = fullName;
      }
      final phone = user?.phone?.trim();
      if ((address.contactPersonNumber == null ||
              address.contactPersonNumber!.isEmpty ||
              address.contactPersonNumber == 'null') &&
          phone != null &&
          phone.isNotEmpty) {
        address.contactPersonNumber = phone;
      }
    }
    return address;
  }
}
