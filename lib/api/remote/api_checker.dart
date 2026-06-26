import 'dart:async';

import 'package:demandium/helper/auth_session_helper.dart';
import 'package:demandium/helper/silent_api_context.dart';
import 'package:demandium/util/core_export.dart';
import 'package:get/get.dart';


class ApiChecker {
  static void checkApi(Response response, {bool showDefaultToaster = true}) {
    if (!showDefaultToaster) {
      return;
    }

    if (SilentApiContext.isActive) {
      return;
    }

    if (response.statusCode == 401) {
      if (_handleZoneMismatch(response, showDefaultToaster: showDefaultToaster)) {
        return;
      }

      if (!Get.find<AuthController>().isLoggedIn()) {
        _showFallbackMessage(response, showDefaultToaster: showDefaultToaster);
        return;
      }

      unawaited(AuthSessionHelper.recoverFromExpiredAuth(
        response: response,
        showSnackBar: showDefaultToaster,
      ));
    } else if (response.statusCode == 204) {
      if (Get.find<AuthController>().isLoggedIn()) {
        customSnackBar('information_not_found'.tr, showDefaultSnackBar: showDefaultToaster);
        runAfterFrame(() => Get.offAllNamed(RouteHelper.getInitialRoute()));
      } else {
        _showFallbackMessage(response, showDefaultToaster: showDefaultToaster);
      }
    } else if (response.statusCode == 500) {
      customSnackBar('500'.tr, showDefaultSnackBar: showDefaultToaster);
    } else if (response.statusCode == 400) {
      final body = response.body;
      if (body is Map && body['errors'] != null) {
        final errors = body['errors'];
        if (errors is List && errors.isNotEmpty) {
          customSnackBar(
            "${errors[0]['message']}",
            showDefaultSnackBar: showDefaultToaster,
            aboveOverlays: Get.isBottomSheetOpen == true || Get.isDialogOpen == true,
          );
          return;
        }
      }
      _showFallbackMessage(response, showDefaultToaster: showDefaultToaster);
    } else if (response.statusCode == 429) {
      customSnackBar("too_many_request".tr, showDefaultSnackBar: showDefaultToaster);
    } else {
      _showFallbackMessage(response, showDefaultToaster: showDefaultToaster);
    }
  }

  static bool _handleZoneMismatch(Response response, {required bool showDefaultToaster}) {
    final body = response.body;
    if (body is! Map || body['response_code'] != 'zone_404') {
      return false;
    }

    if (Get.isRegistered<LocationController>()) {
      Get.find<LocationController>().refreshSavedAddressZone();
    }
    customSnackBar('zone_404'.tr, showDefaultSnackBar: showDefaultToaster);
    return true;
  }

  static void _showFallbackMessage(Response response, {required bool showDefaultToaster}) {
    final body = response.body;
    if (body is Map && body['message'] != null) {
      customSnackBar("${body['message']}", showDefaultSnackBar: showDefaultToaster);
      return;
    }

    final statusText = response.statusText;
    if (statusText != null &&
        statusText.isNotEmpty &&
        statusText.toLowerCase() != 'internal server error') {
      customSnackBar(statusText, showDefaultSnackBar: showDefaultToaster);
      return;
    }

    customSnackBar('connection_to_api_server_failed'.tr, showDefaultSnackBar: showDefaultToaster);
  }
}
