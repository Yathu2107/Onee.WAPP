import 'package:get/get.dart';

import '../../../app_service/network/dio_client.dart';
import '../controller/select_skills_controller.dart';
import '../repository/category_repository.dart';

class SelectSkillsBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<CategoryRepository>()) {
      Get.lazyPut<CategoryRepository>(
        () => CategoryRepository(Get.find<DioClient>()),
        fenix: true,
      );
    }

    Get.lazyPut<SelectSkillsController>(
      () => SelectSkillsController(Get.find<CategoryRepository>()),
      fenix: true,
    );
  }
}
