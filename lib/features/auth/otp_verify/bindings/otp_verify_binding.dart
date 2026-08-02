import 'package:get/get.dart';

import '../../repository/auth_repository.dart';
import '../controller/otp_verify_controller.dart';

class OtpVerifyBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OtpVerifyController>(
      () => OtpVerifyController(Get.find<AuthRepository>()),
    );
  }
}
