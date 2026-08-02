import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app_service/network/api_response.dart';
import '../../../app_service/push/fcm_service.dart';
import '../../../app_service/realtime/signalr_service.dart';
import '../../../common_widgets/app_snackbar.dart';
import '../../auth/model/auth_models.dart';
import '../../auth/repository/auth_repository.dart';
import '../../skills/model/category_models.dart';
import '../../skills/repository/category_repository.dart';

class ProfileController extends GetxController {
  ProfileController(this._authRepository, this._categoryRepository);

  final AuthRepository _authRepository;
  final CategoryRepository _categoryRepository;

  final isLoading = false.obs;
  final isLoggingOut = false.obs;
  final isTogglingOnline = false.obs;
  final worker = Rxn<WorkerDetails>();
  final skills = <WorkerCategoryItem>[].obs;

  @override
  void onReady() {
    super.onReady();
    loadUser();
  }

  Future<void> loadUser() async {
    isLoading.value = true;
    try {
      final response = await _authRepository.getLoggedWorkerDetails();
      worker.value = response.result;
      await loadSkills();
    } on ApiException catch (e) {
      AppSnackbar.error(e.message);
      if (e.statusCode == 401 || e.statusCode == 404) {
        await _authRepository.clearSession();
        Get.offAllNamed(AppRoutes.phoneLogin);
      }
    } catch (_) {
      AppSnackbar.error('Failed to load profile.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadSkills() async {
    try {
      final response = await _categoryRepository.listMine();
      skills.assignAll(response.result ?? <WorkerCategoryItem>[]);
    } catch (_) {
      // Keep previous skills on failure.
    }
  }

  Future<void> toggleOnline(bool value) async {
    if (isTogglingOnline.value) return;
    isTogglingOnline.value = true;
    try {
      await _authRepository.setOnlineStatus(value);
      final current = worker.value;
      if (current != null) {
        worker.value = WorkerDetails(
          name: current.name,
          email: current.email,
          phoneNumber: current.phoneNumber,
          proImg: current.proImg,
          isOnline: value,
          isActive: current.isActive,
          latitude: current.latitude,
          longitude: current.longitude,
          averageRating: current.averageRating,
          ratingCount: current.ratingCount,
        );
      }
      AppSnackbar.success(value ? 'You are online.' : 'You are offline.');
    } on ApiException catch (e) {
      AppSnackbar.error(e.message);
    } catch (_) {
      AppSnackbar.error('Could not update online status.');
    } finally {
      isTogglingOnline.value = false;
    }
  }

  Future<void> goEditProfile() async {
    await Get.toNamed(AppRoutes.editProfile);
    await loadUser();
  }

  Future<void> goAddresses() async {
    await Get.toNamed(AppRoutes.addresses);
  }

  Future<void> goSetLocation() async {
    await Get.toNamed(AppRoutes.setLocation);
    await loadUser();
  }

  Future<void> goSkills() async {
    await Get.toNamed(
      AppRoutes.selectSkills,
      arguments: {'mode': 'edit'},
    );
    await loadSkills();
  }

  Future<void> logout() async {
    if (isLoggingOut.value) return;
    isLoggingOut.value = true;
    try {
      if (Get.isRegistered<FcmService>()) {
        await Get.find<FcmService>().removeFromBackend();
      }

      try {
        await _authRepository.logout();
      } catch (_) {
        // Always clear local session even if API fails.
      }

      if (Get.isRegistered<SignalRService>()) {
        await Get.find<SignalRService>().disconnect();
      }

      await _authRepository.clearSession();
      Get.offAllNamed(AppRoutes.phoneLogin);
    } finally {
      isLoggingOut.value = false;
    }
  }
}
