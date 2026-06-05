import 'package:demandium/util/core_export.dart';
import 'package:get/get.dart';


class ApiChecker {
  static void checkApi(Response response, {bool showDefaultToaster = true}) {

    if(response.statusCode == 401) {
      Get.find<AuthController>().clearSharedData(response: response);
      if(Get.currentRoute != RouteHelper.getInitialRoute()){
        Get.offAllNamed(RouteHelper.getInitialRoute());
        customSnackBar("${response.statusCode!}".tr);
      }
    } else if(response.statusCode == 204) {
      customSnackBar('information_not_found'.tr, showDefaultSnackBar: showDefaultToaster);
      Get.offAllNamed(RouteHelper.getInitialRoute());

    } else if(response.statusCode == 500){
      customSnackBar("${response.statusCode!}".tr, showDefaultSnackBar: showDefaultToaster);
    }
    else if(response.statusCode == 400){
      final body = response.body;
      if(body is Map && body['errors'] != null){
        final errors = body['errors'];
        if(errors is List && errors.isNotEmpty){
          customSnackBar(
            "${errors[0]['message']}",
            showDefaultSnackBar: showDefaultToaster,
            aboveOverlays: Get.isBottomSheetOpen == true || Get.isDialogOpen == true,
          );
          return;
        }
      }
      _showFallbackMessage(response, showDefaultToaster: showDefaultToaster);
    }
    else if(response.statusCode == 429){
      customSnackBar("too_many_request".tr, showDefaultSnackBar: showDefaultToaster);
    }
    else{
      _showFallbackMessage(response, showDefaultToaster: showDefaultToaster);
    }
  }

  static void _showFallbackMessage(Response response, {required bool showDefaultToaster}) {
    final body = response.body;
    if (body is Map && body['message'] != null) {
      customSnackBar("${body['message']}", showDefaultSnackBar: showDefaultToaster);
      return;
    }
    final statusText = response.statusText;
    if (statusText != null && statusText.isNotEmpty) {
      customSnackBar(statusText, showDefaultSnackBar: showDefaultToaster);
      return;
    }
    customSnackBar('connection_to_api_server_failed'.tr, showDefaultSnackBar: showDefaultToaster);
  }
}