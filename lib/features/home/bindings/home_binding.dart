import 'package:get/get.dart';

import '../../../app_service/network/dio_client.dart';
import '../../addresses/repository/address_repository.dart';
import '../../auth/repository/auth_repository.dart';
import '../../jobs/repository/job_repository.dart';
import '../../skills/repository/category_repository.dart';
import '../controller/home_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<JobRepository>()) {
      Get.lazyPut<JobRepository>(
        () => JobRepository(Get.find<DioClient>()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<CategoryRepository>()) {
      Get.lazyPut<CategoryRepository>(
        () => CategoryRepository(Get.find<DioClient>()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<AddressRepository>()) {
      Get.lazyPut<AddressRepository>(
        () => AddressRepository(Get.find<DioClient>()),
        fenix: true,
      );
    }

    Get.lazyPut<HomeController>(
      () => HomeController(
        Get.find<AuthRepository>(),
        Get.find<JobRepository>(),
        Get.find<CategoryRepository>(),
        Get.find<AddressRepository>(),
      ),
    );
  }
}
