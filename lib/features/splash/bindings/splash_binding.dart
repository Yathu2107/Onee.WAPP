import 'package:get/get.dart';

import '../../../app_service/network/dio_client.dart';
import '../../../app_service/storage/secure_storage_service.dart';
import '../../auth/repository/auth_repository.dart';
import '../controller/splash_controller.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    _ensureCoreServices();
    // Eager put so onReady always runs (lazyPut can stall with initialRoute).
    if (!Get.isRegistered<SplashController>()) {
      Get.put<SplashController>(
        SplashController(
          Get.find<AuthRepository>(),
          Get.find<SecureStorageService>(),
        ),
      );
    }
  }
}

void _ensureCoreServices() {
  if (!Get.isRegistered<SecureStorageService>()) {
    Get.put<SecureStorageService>(SecureStorageService(), permanent: true);
  }
  if (!Get.isRegistered<DioClient>()) {
    Get.put<DioClient>(DioClient(Get.find()), permanent: true);
  }
  if (!Get.isRegistered<AuthRepository>()) {
    Get.put<AuthRepository>(
      AuthRepository(dioClient: Get.find(), storage: Get.find()),
      permanent: true,
    );
  }
}
