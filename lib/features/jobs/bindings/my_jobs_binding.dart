import 'package:get/get.dart';

import '../../../app_service/network/dio_client.dart';
import '../controller/my_jobs_controller.dart';
import '../repository/job_repository.dart';

class MyJobsBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<JobRepository>()) {
      Get.lazyPut<JobRepository>(
        () => JobRepository(Get.find<DioClient>()),
        fenix: true,
      );
    }

    Get.lazyPut<MyJobsController>(
      () => MyJobsController(Get.find<JobRepository>()),
      fenix: true,
    );
  }
}
