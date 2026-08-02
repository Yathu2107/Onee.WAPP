import 'package:get/get.dart';

import '../auth/repository/auth_repository.dart';
import 'set_location_controller.dart';

class SetLocationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SetLocationController>(
      () => SetLocationController(Get.find<AuthRepository>()),
    );
  }
}
