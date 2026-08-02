import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../common_widgets/onee_loader.dart';
import '../../../../common_widgets/primary_button.dart';
import '../../../../utils/constants.dart';
import '../controller/otp_verify_controller.dart';

class OtpVerifyView extends GetView<OtpVerifyController> {
  const OtpVerifyView({super.key});

  @override
  Widget build(BuildContext context) {
    final fieldWidth = ((MediaQuery.sizeOf(context).width - 56 - 40) / 6)
        .clamp(42.0, 52.0);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 20,
                    color: AppColors.nearBlack,
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 550),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 16 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'Enter verification code',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: AppColors.nearBlack,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text.rich(
                            TextSpan(
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.45,
                                color: AppColors.mutedBrown,
                                fontWeight: FontWeight.w500,
                              ),
                              children: [
                                const TextSpan(
                                  text: 'We sent a 6-digit SMS code to\n',
                                ),
                                TextSpan(
                                  text: controller.phone,
                                  style: const TextStyle(
                                    color: AppColors.nearBlack,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 650),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 18 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: PinCodeTextField(
                        appContext: context,
                        length: AppConstants.otpLength,
                        controller: controller.otpController,
                        keyboardType: TextInputType.number,
                        animationType: AnimationType.scale,
                        animationDuration: const Duration(milliseconds: 160),
                        enableActiveFill: true,
                        autoDisposeControllers: false,
                        autoFocus: true,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        onChanged: controller.onOtpChanged,
                        onCompleted: (_) => controller.verifyOtp(),
                        pinTheme: PinTheme(
                          shape: PinCodeFieldShape.box,
                          borderRadius: BorderRadius.circular(14),
                          fieldHeight: 56,
                          fieldWidth: fieldWidth,
                          borderWidth: 1.2,
                          activeFillColor:
                              AppColors.cream.withValues(alpha: 0.35),
                          selectedFillColor:
                              AppColors.cream.withValues(alpha: 0.45),
                          inactiveFillColor:
                              AppColors.cream.withValues(alpha: 0.22),
                          activeColor: AppColors.gold,
                          selectedColor: AppColors.gold,
                          inactiveColor:
                              AppColors.mutedBrown.withValues(alpha: 0.28),
                        ),
                        cursorColor: AppColors.nearBlack,
                        textStyle: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.nearBlack,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const _ExpiryAndResend(),
                    const SizedBox(height: 32),
                    Obx(
                      () => PrimaryButton(
                        label: 'Verify',
                        isLoading: controller.isLoading.value,
                        enabled: controller.otpValue.value.length ==
                            AppConstants.otpLength,
                        onPressed: controller.verifyOtp,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () => Get.back(),
                      child: const Text(
                        'Change phone number',
                        style: TextStyle(
                          color: AppColors.mutedBrown,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpiryAndResend extends GetView<OtpVerifyController> {
  const _ExpiryAndResend();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final expired = controller.isOtpExpired;
      final canResend = controller.canResend;
      final isResending = controller.isResending.value;
      final expiryLabel = controller.expiryLabel;
      final resendSeconds = controller.resendSecondsLeft.value;

      return Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: expired
                  ? const Color(0xFFB3261E).withValues(alpha: 0.08)
                  : AppColors.cream.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  expired ? Icons.timer_off_outlined : Icons.timer_outlined,
                  size: 16,
                  color: expired
                      ? const Color(0xFFB3261E)
                      : AppColors.mutedBrown,
                ),
                const SizedBox(width: 6),
                Text(
                  expired ? 'Code expired' : 'Expires in $expiryLabel',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: expired
                        ? const Color(0xFFB3261E)
                        : AppColors.mutedBrown,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (isResending)
            const OneeLoader(size: 22)
          else
            TextButton(
              onPressed: canResend ? controller.resendOtp : null,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.gold,
                disabledForegroundColor:
                    AppColors.mutedBrown.withValues(alpha: 0.7),
              ),
              child: Text(
                canResend ? 'Resend code' : 'Resend in ${resendSeconds}s',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      );
    });
  }
}
