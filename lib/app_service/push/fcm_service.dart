import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import '../../app/routes/app_routes.dart';
import '../../features/auth/repository/auth_repository.dart';
import '../../features/jobs/offer/job_offer_alert_service.dart';
import '../notifications/local_notification_service.dart';
import '../storage/secure_storage_service.dart';
import '../notifications/pending_job_offer_store.dart';

bool _isJobOfferType(String? type) {
  final t = (type ?? '').trim().toLowerCase();
  return t == 'job_offer' || t == 'joboffer' || t == 'offer';
}

/// Background/killed: wake the app via full-screen offer notification.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  final type = message.data['type']?.toString();
  final jobIdRaw =
      message.data['jobId'] ?? message.data['fk_job_ID'] ?? message.data['job_id'];
  final jobId = int.tryParse(jobIdRaw?.toString() ?? '');

  if (_isJobOfferType(type) && jobId != null && jobId > 0) {
    final title = message.notification?.title ??
        message.data['title']?.toString() ??
        'Incoming job request';
    final body = message.notification?.body ??
        message.data['body']?.toString() ??
        'A customer needs your help.';
    try {
      await PendingJobOfferStore.save(jobId);
      await showOneeJobOfferBanner(
        title: title,
        body: body,
        jobId: jobId,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Background job-offer notification failed: $e');
    }
    return;
  }

  if (message.notification != null) return;

  final title = message.data['title']?.toString();
  final body = message.data['body']?.toString();
  if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
    return;
  }

  try {
    await showOneePushBanner(
      title: title ?? 'Onee Worker',
      body: body ?? '',
      jobId: jobId,
      type: type,
    );
  } catch (e) {
    if (kDebugMode) debugPrint('Background local notification failed: $e');
  }
}

class FcmService extends GetxService {
  String? _token;
  String? get token => _token;

  String get platform => Platform.isIOS ? 'ios' : 'android';

  bool _ready = false;
  String? _currentUserId;

  Future<void> init() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      _token = await messaging.getToken();
      _ready = true;
      await _loadCurrentUserId();

      FirebaseMessaging.onMessage.listen(_onForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
      final initial = await messaging.getInitialMessage();
      if (initial != null) {
        _handleMessage(initial);
      }

      messaging.onTokenRefresh.listen((t) async {
        _token = t;
        await registerWithBackend();
      });

      if (kDebugMode) {
        debugPrint('FCM token: $_token');
      }
    } catch (e) {
      _ready = false;
      if (kDebugMode) {
        debugPrint(
          'FCM unavailable (add google-services.json / GoogleService-Info.plist): $e',
        );
      }
    }
  }

  Future<void> registerWithBackend() async {
    if (!_ready || _token == null || _token!.isEmpty) return;
    if (!Get.isRegistered<AuthRepository>()) return;
    try {
      await Get.find<AuthRepository>().registerDeviceToken(
        token: _token!,
        platform: platform,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('register-device-token failed: $e');
    }
  }

  Future<void> removeFromBackend() async {
    if (_token == null || _token!.isEmpty) return;
    if (!Get.isRegistered<AuthRepository>()) return;
    try {
      await Get.find<AuthRepository>().removeDeviceToken(
        token: _token!,
        platform: platform,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('remove device-token failed: $e');
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    final type = (message.data['type']?.toString() ?? '').trim().toLowerCase();

    final jobIdRaw =
        message.data['jobId'] ?? message.data['fk_job_ID'] ?? message.data['job_id'];
    final jobId = int.tryParse(jobIdRaw?.toString() ?? '');

    if (type == 'chat_message' || type == 'chat') {
      final senderId = message.data['senderId']?.toString() ?? '';
      if (_isCurrentUser(senderId)) return;
    }

    if (_isJobOfferType(type) &&
        jobId != null &&
        jobId > 0 &&
        Get.isRegistered<JobOfferAlertService>()) {
      Get.find<JobOfferAlertService>().onPushOffer(
        jobId: jobId,
        forcePopup: true,
      );
      return;
    }

    final title =
        message.notification?.title ?? message.data['title']?.toString();
    final body =
        message.notification?.body ?? message.data['body']?.toString();

    if (title == null && body == null) return;

    if (Get.isRegistered<LocalNotificationService>()) {
      Get.find<LocalNotificationService>().show(
        title: title ?? 'Onee Worker',
        body: body ?? '',
        jobId: jobId,
        type: type,
      );
    } else {
      showOneePushBanner(
        title: title ?? 'Onee Worker',
        body: body ?? '',
        jobId: jobId,
        type: type,
      );
    }
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

  bool _isCurrentUser(String? userId) {
    final uid = _currentUserId?.trim() ?? '';
    final other = userId?.trim() ?? '';
    if (uid.isEmpty || other.isEmpty) return false;
    return uid.toLowerCase() == other.toLowerCase();
  }

  void _handleMessage(RemoteMessage message) {
    final jobIdRaw =
        message.data['jobId'] ?? message.data['fk_job_ID'] ?? message.data['job_id'];
    final jobId = int.tryParse(jobIdRaw?.toString() ?? '');
    if (jobId == null || jobId <= 0) return;

    final type = (message.data['type']?.toString() ?? '').trim().toLowerCase();
    if (_isJobOfferType(type)) {
      if (Get.isRegistered<JobOfferAlertService>()) {
        Get.find<JobOfferAlertService>().onPushOffer(
          jobId: jobId,
          forcePopup: true,
        );
        return;
      }
      Get.toNamed(AppRoutes.offerDetail, arguments: {'jobId': jobId});
      return;
    }
    if (type == 'chat_message' || type == 'chat') {
      Get.toNamed(AppRoutes.jobChat, arguments: {'jobId': jobId});
      return;
    }
    Get.toNamed(AppRoutes.jobDetail, arguments: {'jobId': jobId});
  }
}
