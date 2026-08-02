import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app_service/network/api_response.dart';
import '../../../../common_widgets/app_snackbar.dart';
import '../../repository/auth_repository.dart';

class PhoneLoginController extends GetxController {
  PhoneLoginController(this._authRepository);

  final AuthRepository _authRepository;

  final formKey = GlobalKey<FormState>();
  final phoneController = TextEditingController();
  final isLoading = false.obs;

  Future<void> continueWithPhone() async {
    if (isLoading.value) return;
    if (!(formKey.currentState?.validate() ?? false)) return;

    final phone = phoneController.text.trim();
    isLoading.value = true;
    try {
      final response = await _authRepository.verifyPhone(phone);
      Get.toNamed(AppRoutes.otpVerify, arguments: {'phone': phone});
      AppSnackbar.success(
        response.text.isNotEmpty ? response.text : 'OTP sent successfully.',
      );
    } on ApiException catch (e) {
      AppSnackbar.error(e.message);
    } catch (_) {
      AppSnackbar.error('Failed to send OTP. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    phoneController.dispose();
    super.onClose();
  }
}
