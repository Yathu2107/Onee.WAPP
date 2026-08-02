import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app_service/network/api_response.dart';
import '../../../../common_widgets/app_snackbar.dart';
import '../../../../utils/constants.dart';
import '../../../skills/repository/category_repository.dart';
import '../../repository/auth_repository.dart';

class OtpVerifyController extends GetxController {
  OtpVerifyController(this._authRepository);

  final AuthRepository _authRepository;

  late final String phone;
  final otpController = TextEditingController();
  final isLoading = false.obs;
  final isResending = false.obs;
  final otpValue = ''.obs;

  final expirySecondsLeft = AppConstants.otpExpirySeconds.obs;
  final resendSecondsLeft = AppConstants.otpResendCooldownSeconds.obs;

  Timer? _expiryTimer;
  Timer? _resendTimer;

  bool get canResend => resendSecondsLeft.value <= 0 && !isResending.value;
  bool get isOtpExpired => expirySecondsLeft.value <= 0;

  String get expiryLabel {
    final m = expirySecondsLeft.value ~/ 60;
    final s = expirySecondsLeft.value % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map && args['phone'] != null) {
      phone = args['phone'].toString();
    } else {
      phone = '';
    }
    _startExpiryCountdown();
    _startResendCooldown();
  }

  void onOtpChanged(String value) {
    otpValue.value = value;
  }

  Future<void> verifyOtp() async {
    if (isLoading.value) return;

    final otp = otpValue.value.trim();
    if (otp.length != AppConstants.otpLength) {
      AppSnackbar.error('Enter the 6-digit OTP');
      return;
    }
    if (isOtpExpired) {
      AppSnackbar.error('OTP has expired. Please resend a new code.');
      return;
    }

    isLoading.value = true;
    try {
      final response = await _authRepository.verifyOtp(
        phoneNumber: phone,
        otp: otp,
      );
      final result = response.result;
      if (result == null) {
        throw ApiException(message: 'Invalid OTP response from server.');
      }

      await _authRepository.persistSession(result);

      if (AuthNextStep.isRegister(result.nextStep)) {
        Get.offAllNamed(
          AppRoutes.completeRegistration,
          arguments: {'phone': phone},
        );
        AppSnackbar.success(
          response.text.isNotEmpty
              ? response.text
              : 'OTP verified successfully.',
        );
        return;
      }

      // home_page — gate on skills before Main shell
      await _goHomeOrSkills();
      AppSnackbar.success(
        response.text.isNotEmpty ? response.text : 'OTP verified successfully.',
      );
    } on ApiException catch (e) {
      AppSnackbar.error(e.message);
    } catch (_) {
      AppSnackbar.error('OTP verification failed. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _goHomeOrSkills() async {
    if (Get.isRegistered<CategoryRepository>()) {
      try {
        final skills =
            await Get.find<CategoryRepository>().listMine();
        final mine = skills.result ?? const [];
        if (mine.isEmpty) {
          Get.offAllNamed(
            AppRoutes.selectSkills,
            arguments: {
              'mode': 'onboarding',
              'phone': phone,
            },
          );
          return;
        }
      } catch (_) {
        // Fall through to home; Home banner still reminds if empty.
      }
    }
    Get.offAllNamed(AppRoutes.home, arguments: {'phone': phone});
  }

  Future<void> resendOtp() async {
    if (!canResend) return;

    isResending.value = true;
    try {
      final response = await _authRepository.resendOtp(phone);
      AppSnackbar.success(
        response.text.isNotEmpty ? response.text : 'OTP sent successfully.',
      );
      otpController.clear();
      otpValue.value = '';
      _startExpiryCountdown();
      _startResendCooldown();
    } on ApiException catch (e) {
      AppSnackbar.error(e.message);
    } catch (_) {
      AppSnackbar.error('Failed to resend OTP.');
    } finally {
      isResending.value = false;
    }
  }

  void _startExpiryCountdown() {
    _expiryTimer?.cancel();
    expirySecondsLeft.value = AppConstants.otpExpirySeconds;
    _expiryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (expirySecondsLeft.value <= 0) {
        timer.cancel();
        return;
      }
      expirySecondsLeft.value--;
    });
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    resendSecondsLeft.value = AppConstants.otpResendCooldownSeconds;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendSecondsLeft.value <= 0) {
        timer.cancel();
        return;
      }
      resendSecondsLeft.value--;
    });
  }

  @override
  void onClose() {
    _expiryTimer?.cancel();
    _resendTimer?.cancel();
    otpController.dispose();
    super.onClose();
  }
}
