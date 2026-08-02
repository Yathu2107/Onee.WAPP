import 'package:get/get.dart';

import '../../../app_service/network/dio_client.dart';
import '../controller/addresses_controller.dart';
import '../repository/address_repository.dart';

class AddressesBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<AddressRepository>()) {
      Get.lazyPut<AddressRepository>(
        () => AddressRepository(Get.find<DioClient>()),
        fenix: true,
      );
    }

    Get.lazyPut<AddressesController>(
      () => AddressesController(Get.find<AddressRepository>()),
    );
  }
}
