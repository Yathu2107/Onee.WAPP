import 'package:get/get.dart';

import '../../auth/repository/auth_repository.dart';
import '../../skills/repository/category_repository.dart';
import '../controller/profile_controller.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProfileController>(
      () => ProfileController(
        Get.find<AuthRepository>(),
        Get.find<CategoryRepository>(),
      ),
    );
  }
}
