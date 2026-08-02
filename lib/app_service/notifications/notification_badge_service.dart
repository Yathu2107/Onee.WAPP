import 'package:get/get.dart';

import '../../features/notifications/repository/notification_repository.dart';

class NotificationBadgeService extends GetxService {
  final unreadCount = 0.obs;

  Future<void> refresh() async {
    if (!Get.isRegistered<NotificationRepository>()) return;
    try {
      final response =
          await Get.find<NotificationRepository>().unreadCount();
      unreadCount.value = response.result ?? 0;
    } catch (_) {
      // Keep last known count on failure.
    }
  }

  void setCount(int count) => unreadCount.value = count;

  void decrement() {
    if (unreadCount.value > 0) unreadCount.value--;
  }

  void clear() => unreadCount.value = 0;
}
