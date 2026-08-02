import 'package:get/get.dart';

import '../../../app_service/network/dio_client.dart';
import '../../../app_service/storage/secure_storage_service.dart';
import '../repository/job_repository.dart';
import 'job_chat_controller.dart';

class JobChatBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<JobRepository>()) {
      Get.lazyPut<JobRepository>(
        () => JobRepository(Get.find<DioClient>()),
        fenix: true,
      );
    }

    Get.lazyPut<JobChatController>(
      () => JobChatController(
        Get.find<JobRepository>(),
        Get.find<SecureStorageService>(),
      ),
    );
  }
}
