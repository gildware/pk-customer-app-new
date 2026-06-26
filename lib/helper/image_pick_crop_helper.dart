import 'package:demandium/common/enums/enums.dart';
import 'package:demandium/common/widgets/custom_snackbar.dart';
import 'package:demandium/feature/splash/controller/splash_controller.dart';
import 'package:demandium/helper/file_validation_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickCropHelper {
  static int _maxImageBytes() {
    final configModel = Get.find<SplashController>().configModel;
    return configModel.content?.maxImageUploadSize ?? 20971520;
  }

  static Future<XFile?> pickCropAndValidate({
    ImageSource source = ImageSource.gallery,
    bool lockAspectRatio = true,
    double ratioX = 1,
    double ratioY = 1,
    CropAspectRatioPreset? androidInitPreset,
    int? maxSizeInBytes,
  }) async {
    final maxSize = maxSizeInBytes ?? _maxImageBytes();
    final picked = await FileValidationHelper.validateAndPickImage(
      source: source,
    );
    if (picked == null) return null;

    return _cropAndValidate(
      picked,
      lockAspectRatio: lockAspectRatio,
      ratioX: ratioX,
      ratioY: ratioY,
      androidInitPreset: androidInitPreset,
      maxSizeInBytes: maxSize,
    );
  }

  static Future<List<XFile>> pickMultipleCropAndValidate({
    bool lockAspectRatio = false,
    double ratioX = 1,
    double ratioY = 1,
    int? maxSizeInBytes,
  }) async {
    final maxSize = maxSizeInBytes ?? _maxImageBytes();
    final pickedImages =
        await FileValidationHelper.validateAndPickMultipleImages();
    if (pickedImages.isEmpty) return [];

    final croppedImages = <XFile>[];
    for (final image in pickedImages) {
      final cropped = await _cropAndValidate(
        image,
        lockAspectRatio: lockAspectRatio,
        ratioX: ratioX,
        ratioY: ratioY,
        maxSizeInBytes: maxSize,
        showUnavailableSnackBar: croppedImages.isEmpty,
      );
      if (cropped != null) {
        croppedImages.add(cropped);
      }
    }
    return croppedImages;
  }

  static Future<XFile?> _cropAndValidate(
    XFile picked, {
    required bool lockAspectRatio,
    required double ratioX,
    required double ratioY,
    CropAspectRatioPreset? androidInitPreset,
    required int maxSizeInBytes,
    bool showUnavailableSnackBar = true,
  }) async {
    try {
      final cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
        aspectRatio:
            lockAspectRatio ? CropAspectRatio(ratioX: ratioX, ratioY: ratioY) : null,
        compressFormat: ImageCompressFormat.jpg,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'crop_image'.tr,
            toolbarColor: Get.theme.primaryColor,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: androidInitPreset ??
                (ratioX == ratioY
                    ? CropAspectRatioPreset.square
                    : CropAspectRatioPreset.original),
            lockAspectRatio: lockAspectRatio,
            hideBottomControls: false,
          ),
          IOSUiSettings(
            title: 'crop_image'.tr,
            aspectRatioLockEnabled: lockAspectRatio,
            resetAspectRatioEnabled: !lockAspectRatio,
            hidesNavigationBar: false,
          ),
        ],
      );

      if (cropped == null) {
        return null;
      }

      final croppedFile = XFile(cropped.path);
      final sizeError = await FileValidationHelper.validateFileSizeAsync(
        file: croppedFile,
        maxSizeInBytes: maxSizeInBytes,
      );
      if (sizeError != null) {
        customSnackBar(sizeError, type: ToasterMessageType.error);
        return null;
      }
      return croppedFile;
    } catch (e) {
      debugPrint('Image crop error: $e — using original pick');
      if (showUnavailableSnackBar) {
        customSnackBar(
          'crop_image_unavailable_using_original'.tr,
          type: ToasterMessageType.info,
        );
      }
      return picked;
    }
  }
}
