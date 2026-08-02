import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app_service/network/api_response.dart';
import '../../../../common_widgets/app_snackbar.dart';
import '../../../../utils/phone_validator.dart';
import '../../repository/auth_repository.dart';

class CompleteRegistrationController extends GetxController {
  CompleteRegistrationController(this._authRepository);

  final AuthRepository _authRepository;
  final formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();

  final isLoading = false.obs;
  final imagePath = RxnString();

  final ImagePicker _picker = ImagePicker();

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map && args['phone'] != null) {
      phoneController.text = args['phone'].toString();
    }
  }

  Future<void> pickImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1200,
    );
    if (file != null) {
      imagePath.value = file.path;
    }
  }

  void clearImage() => imagePath.value = null;

  Future<void> submit() async {
    if (isLoading.value) return;
    if (!(formKey.currentState?.validate() ?? false)) return;

    isLoading.value = true;
    try {
      final response = await _authRepository.register(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        phoneNumber: phoneController.text.trim(),
        imagePath: imagePath.value,
      );

      Get.offAllNamed(
        AppRoutes.selectSkills,
        arguments: {'mode': 'onboarding'},
      );
      AppSnackbar.success(
        response.text.isNotEmpty
            ? response.text
            : 'Worker registered successfully.',
      );
    } on ApiException catch (e) {
      AppSnackbar.error(e.message);
    } catch (_) {
      AppSnackbar.error('Registration failed. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Name is required';
    if (value.trim().length < 2) return 'Enter a valid name';
    return null;
  }

  String? validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email is required';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    if (!ok) return 'Enter a valid email';
    return null;
  }

  String? validatePhone(String? value) => PhoneValidator.validate(value);

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.onClose();
  }
}
