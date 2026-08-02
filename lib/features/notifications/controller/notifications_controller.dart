import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app_service/network/api_response.dart';
import '../../../app_service/notifications/notification_badge_service.dart';
import '../../../common_widgets/app_snackbar.dart';
import '../model/notification_models.dart';
import '../repository/notification_repository.dart';

enum NotificationsFilter { all, unread }

class NotificationsController extends GetxController {
  NotificationsController(this._repository);

  final NotificationRepository _repository;

  final isLoading = false.obs;
  final isBusy = false.obs;
  final filter = NotificationsFilter.all.obs;
  final notifications = <AppNotification>[].obs;
  final error = RxnString();

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  List<AppNotification> filteredFor(NotificationsFilter selected) {
    final items = notifications.toList();
    switch (selected) {
      case NotificationsFilter.all:
        return items;
      case NotificationsFilter.unread:
        return items.where((n) => !n.isRead).toList();
    }
  }

  void setFilter(NotificationsFilter value) => filter.value = value;

  @override
  void onReady() {
    super.onReady();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = null;
    try {
      final response = await _repository.list();
      notifications.assignAll(response.result ?? <AppNotification>[]);
      await _refreshBadge();
    } on ApiException catch (e) {
      error.value = e.message;
      AppSnackbar.error(e.message);
    } catch (_) {
      error.value = 'Failed to load notifications.';
      AppSnackbar.error('Failed to load notifications.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshList() => load();

  Future<void> markRead(AppNotification notification) async {
    if (notification.isRead || isBusy.value) return;
    isBusy.value = true;
    try {
      await _repository.markRead(notification.id);
      final index = notifications.indexWhere((n) => n.id == notification.id);
      if (index >= 0) {
        final n = notifications[index];
        notifications[index] = AppNotification(
          id: n.id,
          title: n.title,
          body: n.body,
          type: n.type,
          jobId: n.jobId,
          isRead: true,
          createdOn: n.createdOn,
        );
      }
      await _refreshBadge();
    } on ApiException catch (e) {
      AppSnackbar.error(e.message);
    } catch (_) {
      AppSnackbar.error('Failed to mark as read.');
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> markAllRead() async {
    if (isBusy.value) return;
    isBusy.value = true;
    try {
      final response = await _repository.markAllRead();
      notifications.assignAll(
        notifications
            .map(
              (n) => AppNotification(
                id: n.id,
                title: n.title,
                body: n.body,
                type: n.type,
                jobId: n.jobId,
                isRead: true,
                createdOn: n.createdOn,
              ),
            )
            .toList(),
      );
      AppSnackbar.success(
        response.text.isNotEmpty ? response.text : 'All marked as read.',
      );
      await _refreshBadge();
    } on ApiException catch (e) {
      AppSnackbar.error(e.message);
    } catch (_) {
      AppSnackbar.error('Failed to mark all as read.');
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> onTap(AppNotification notification) async {
    if (!notification.isRead) {
      await markRead(notification);
    }
    final jobId = notification.jobId;
    if (jobId == null || jobId <= 0) return;

    final type = (notification.type ?? '').trim().toLowerCase();
    if (type == 'job_offer' || type == 'joboffer' || type == 'offer') {
      await Get.toNamed(AppRoutes.offerDetail, arguments: {'jobId': jobId});
    } else if (type == 'chat_message' || type == 'chat') {
      await Get.toNamed(AppRoutes.jobChat, arguments: {'jobId': jobId});
    } else {
      await Get.toNamed(AppRoutes.jobDetail, arguments: {'jobId': jobId});
    }
    await load();
  }

  Future<void> _refreshBadge() async {
    if (Get.isRegistered<NotificationBadgeService>()) {
      await Get.find<NotificationBadgeService>().refresh();
    }
  }
}
