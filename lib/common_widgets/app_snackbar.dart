import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../app/theme/app_colors.dart';

class AppSnackbar {
  AppSnackbar._();

  static void success(String message) {
    _show(
      title: 'Success',
      message: message,
      backgroundColor: AppColors.nearBlack,
      colorText: AppColors.white,
      duration: const Duration(seconds: 3),
    );
  }

  static void error(String message) {
    _show(
      title: 'Error',
      message: message,
      backgroundColor: AppColors.nearBlack,
      colorText: AppColors.cream,
      duration: const Duration(seconds: 4),
    );
  }

  static void info(String message) {
    _show(
      title: 'Onee Worker',
      message: message,
      backgroundColor: AppColors.mutedBrown,
      colorText: AppColors.white,
    );
  }

  static void _show({
    required String title,
    required String message,
    required Color backgroundColor,
    required Color colorText,
    Duration duration = const Duration(seconds: 3),
  }) {
    // Avoid stacking overlays that steal the next Get.back() from real routes.
    if (Get.isSnackbarOpen) {
      Get.closeAllSnackbars();
    }
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: backgroundColor,
      colorText: colorText,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: duration,
    );
  }
}
