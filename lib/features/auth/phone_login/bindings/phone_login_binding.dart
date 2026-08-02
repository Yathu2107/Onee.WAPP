import 'package:get/get.dart';

import '../../repository/auth_repository.dart';
import '../controller/phone_login_controller.dart';

class PhoneLoginBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PhoneLoginController>(
      () => PhoneLoginController(Get.find<AuthRepository>()),
    );
  }
}
