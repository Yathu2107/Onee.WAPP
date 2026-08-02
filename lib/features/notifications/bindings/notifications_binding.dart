import 'package:get/get.dart';

import '../../../app_service/network/dio_client.dart';
import '../controller/notifications_controller.dart';
import '../repository/notification_repository.dart';

class NotificationsBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<NotificationRepository>()) {
      Get.lazyPut<NotificationRepository>(
        () => NotificationRepository(Get.find<DioClient>()),
        fenix: true,
      );
    }

    Get.lazyPut<NotificationsController>(
      () => NotificationsController(Get.find<NotificationRepository>()),
      fenix: true,
    );
  }
}
