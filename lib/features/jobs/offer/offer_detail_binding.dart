import 'package:get/get.dart';

import '../../../app_service/network/dio_client.dart';
import '../repository/job_repository.dart';
import 'offer_detail_controller.dart';

class OfferDetailBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<JobRepository>()) {
      Get.lazyPut<JobRepository>(
        () => JobRepository(Get.find<DioClient>()),
        fenix: true,
      );
    }

    Get.lazyPut<OfferDetailController>(
      () => OfferDetailController(Get.find<JobRepository>()),
    );
  }
}
