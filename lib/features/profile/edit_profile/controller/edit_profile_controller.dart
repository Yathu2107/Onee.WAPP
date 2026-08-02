import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app_service/network/api_response.dart';
import '../../../../common_widgets/app_snackbar.dart';
import '../../../../utils/phone_validator.dart';
import '../../../auth/repository/auth_repository.dart';
import '../../controller/profile_controller.dart';

class EditProfileController extends GetxController {
  EditProfileController(this._authRepository);

  final AuthRepository _authRepository;
  final formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();

  final isLoading = false.obs;
  final isSaving = false.obs;
  final imagePath = RxnString();
  final existingImageUrl = RxnString();

  final ImagePicker _picker = ImagePicker();

  @override
  void onReady() {
    super.onReady();
    loadUser();
  }

  Future<void> loadUser() async {
    isLoading.value = true;
    try {
      final response = await _authRepository.getLoggedWorkerDetails();
      final user = response.result;
      if (user == null) {
        AppSnackbar.error('Could not load your profile.');
        return;
      }

      nameController.text = user.name ?? '';
      emailController.text = user.email ?? '';
      phoneController.text = user.phoneNumber ?? '';
      existingImageUrl.value = user.proImg;
      imagePath.value = null;
    } on ApiException catch (e) {
      AppSnackbar.error(e.message);
    } catch (_) {
      AppSnackbar.error('Failed to load profile.');
    } finally {
      isLoading.value = false;
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

  void clearImage() {
    imagePath.value = null;
    existingImageUrl.value = null;
  }

  Future<void> submit() async {
    if (isSaving.value) return;
    if (!(formKey.currentState?.validate() ?? false)) return;

    isSaving.value = true;
    try {
      final response = await _authRepository.updateWorker(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        phoneNumber: phoneController.text.trim(),
        imagePath: imagePath.value,
      );

      if (Get.isRegistered<ProfileController>()) {
        await Get.find<ProfileController>().loadUser();
      }

      Get.back();
      AppSnackbar.success(
        response.text.isNotEmpty
            ? response.text
            : 'Profile updated successfully.',
      );
    } on ApiException catch (e) {
      AppSnackbar.error(e.message);
    } catch (_) {
      AppSnackbar.error('Update failed. Please try again.');
    } finally {
      isSaving.value = false;
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
