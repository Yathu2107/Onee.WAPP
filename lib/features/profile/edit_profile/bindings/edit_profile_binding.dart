import 'package:get/get.dart';

import '../../../auth/repository/auth_repository.dart';
import '../controller/edit_profile_controller.dart';

class EditProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EditProfileController>(
      () => EditProfileController(Get.find<AuthRepository>()),
    );
  }
}
