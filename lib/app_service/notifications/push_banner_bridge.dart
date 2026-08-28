import 'package:get/get.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import '../../features/jobs/model/job_models.dart';
import '../../features/jobs/offer/job_offer_alert_service.dart';
import '../notifications/local_notification_service.dart';
import '../notifications/notification_badge_service.dart';
import '../realtime/signalr_service.dart';
import '../storage/secure_storage_service.dart';

/// Turns SignalR job/chat/offer events into system banner notifications.
class PushBannerBridge extends GetxService {
  Worker? _offerWorker;
  Worker? _jobWorker;
  Worker? _chatWorker;
  int? _lastOfferId;
  String? _lastJobKey;
  int? _lastChatId;
  String? _currentUserId;

  Future<void> start() async {
    if (!Get.isRegistered<SignalRService>()) return;
    final signalR = Get.find<SignalRService>();

    _offerWorker?.dispose();
    _jobWorker?.dispose();
    _chatWorker?.dispose();
    await _loadCurrentUserId();

    _offerWorker = ever<JobDetail?>(signalR.jobOffer, (detail) {
      if (detail == null) return;
      if (detail.id == _lastOfferId) return;
      _lastOfferId = detail.id;

      // JobOfferAlertService owns FG popup + BG auto-open.
      if (Get.isRegistered<JobOfferAlertService>() &&
          Get.find<JobOfferAlertService>().handlesOfferAlerts) {
        _refreshBadge();
        return;
      }

      final preview = detail.problemText?.trim();
      _show(
        title: 'New job offer',
        body: (preview != null && preview.isNotEmpty)
            ? (preview.length > 80
                ? '${preview.substring(0, 80)}...'
                : preview)
            : 'A new job is waiting for you.',
        jobId: detail.id,
        type: 'job_offer',
      );
      _refreshBadge();
    });

    _jobWorker = ever<JobDetail?>(signalR.jobUpdated, (detail) {
      if (detail == null) return;
      final key = '${detail.id}:${detail.status}';
      if (key == _lastJobKey) return;
      _lastJobKey = key;

      final status = detail.status?.trim();
      if (status == null || status.isEmpty) return;

      // Offering updates for workers are handled by JobOffer / offer alerts.
      if (status.toLowerCase() == 'offering') {
        _refreshBadge();
        return;
      }

      _show(
        title: 'Job update',
        body: 'Your job is now $status.',
        jobId: detail.id,
        type: 'job_updated',
      );
      _refreshBadge();
    });

    _chatWorker = ever<JobChatMessage?>(signalR.chatMessage, (msg) {
      if (msg == null) return;
      if (msg.id == _lastChatId) return;
      _lastChatId = msg.id;

      // Never banner the sender for their own message.
      if (_isOwnMessage(msg.senderId)) return;

      final preview = msg.message.trim();
      if (preview.isEmpty) return;

      _show(
        title: 'New message',
        body: preview.length > 80 ? '${preview.substring(0, 80)}...' : preview,
        jobId: msg.jobId,
        type: 'chat_message',
      );
      _refreshBadge();
    });
  }

  Future<void> _loadCurrentUserId() async {
    try {
      if (!Get.isRegistered<SecureStorageService>()) return;
      final token = await Get.find<SecureStorageService>().getToken();
      if (token == null || token.isEmpty) return;
      final decoded = JwtDecoder.decode(token);
      _currentUserId = (decoded['uid']?.toString() ??
              decoded['sub']?.toString() ??
              decoded['nameid']?.toString() ??
              '')
          .trim();
    } catch (_) {
      _currentUserId = null;
    }
  }

  bool _isOwnMessage(String senderId) {
    final uid = _currentUserId?.trim() ?? '';
    final sender = senderId.trim();
    if (uid.isEmpty || sender.isEmpty) return false;
    return uid.toLowerCase() == sender.toLowerCase();
  }

  void _show({
    required String title,
    required String body,
    required int jobId,
    required String type,
  }) {
    if (!Get.isRegistered<LocalNotificationService>()) return;
    Get.find<LocalNotificationService>().show(
      title: title,
      body: body,
      jobId: jobId,
      type: type,
    );
  }

  void _refreshBadge() {
    if (Get.isRegistered<NotificationBadgeService>()) {
      Get.find<NotificationBadgeService>().refresh();
    }
  }

  @override
  void onClose() {
    _offerWorker?.dispose();
    _jobWorker?.dispose();
    _chatWorker?.dispose();
    super.onClose();
  }
}
