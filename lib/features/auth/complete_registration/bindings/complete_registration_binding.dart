import 'package:get/get.dart';

import '../../repository/auth_repository.dart';
import '../controller/complete_registration_controller.dart';

class CompleteRegistrationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CompleteRegistrationController>(
      () => CompleteRegistrationController(Get.find<AuthRepository>()),
    );
  }
}
