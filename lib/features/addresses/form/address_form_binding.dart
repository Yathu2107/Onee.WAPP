import 'package:get/get.dart';

import '../../../app_service/network/dio_client.dart';
import '../repository/address_repository.dart';
import 'address_form_controller.dart';

class AddressFormBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<AddressRepository>()) {
      Get.lazyPut<AddressRepository>(
        () => AddressRepository(Get.find<DioClient>()),
        fenix: true,
      );
    }

    Get.lazyPut<AddressFormController>(
      () => AddressFormController(Get.find<AddressRepository>()),
    );
  }
}
