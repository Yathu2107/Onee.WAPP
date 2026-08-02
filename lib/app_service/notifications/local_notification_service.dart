import 'dart:convert';
import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';
import '../../features/jobs/offer/job_offer_alert_service.dart';
import 'pending_job_offer_store.dart';

const oneeNotificationChannelId = 'onee_job_updates';
const oneeNotificationChannelName = 'Job updates';
const oneeNotificationChannelDesc =
    'Offers, status changes, and messages for your jobs';

const oneeJobOfferChannelId = 'onee_job_offers_v3';
const oneeJobOfferChannelName = 'Incoming job offers';
const oneeJobOfferChannelDesc =
    'Automatically opens Onee Worker and shows the accept popup';

void _navigateFromPayload({int? jobId, String? type}) {
  if (jobId == null || jobId <= 0) return;
  final t = type?.trim().toLowerCase() ?? '';
  if (t == 'job_offer' || t == 'joboffer' || t == 'offer') {
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
  if (t == 'chat_message' || t == 'chat') {
    Get.toNamed(AppRoutes.jobChat, arguments: {'jobId': jobId});
    return;
  }
  Get.toNamed(AppRoutes.jobDetail, arguments: {'jobId': jobId});
}

AndroidNotificationChannel _offerChannel() {
  return AndroidNotificationChannel(
    oneeJobOfferChannelId,
    oneeJobOfferChannelName,
    description: oneeJobOfferChannelDesc,
    importance: Importance.max,
    playSound: true,
    sound: const RawResourceAndroidNotificationSound('job_offer_ring'),
    enableVibration: true,
    audioAttributesUsage: AudioAttributesUsage.alarm,
  );
}

/// Full-screen intent that wakes/opens the app. Safe from background isolate.
Future<void> showOneeJobOfferBanner({
  required String title,
  required String body,
  required int jobId,
  int id = 900001,
}) async {
  await PendingJobOfferStore.save(jobId);

  final plugin = FlutterLocalNotificationsPlugin();

  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosInit = DarwinInitializationSettings();

  await plugin.initialize(
    settings: const InitializationSettings(android: androidInit, iOS: iosInit),
  );

  final android = plugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();
  await android?.createNotificationChannel(_offerChannel());

  final payload = jsonEncode({
    'jobId': jobId,
    'type': 'job_offer',
  });

  await plugin.show(
    id: id,
    title: title,
    body: body,
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        oneeJobOfferChannelId,
        oneeJobOfferChannelName,
        channelDescription: oneeJobOfferChannelDesc,
        importance: Importance.max,
        priority: Priority.max,
        category: AndroidNotificationCategory.call,
        fullScreenIntent: true,
        visibility: NotificationVisibility.public,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('job_offer_ring'),
        enableVibration: true,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFFEBB407),
        colorized: false,
        ticker: 'Incoming job request',
        timeoutAfter: 90000,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
        sound: 'job_offer_ring.wav',
      ),
    ),
    payload: payload,
  );
}

Future<void> showOneePushBanner({
  required String title,
  required String body,
  int? jobId,
  String? type,
  int id = 0,
}) async {
  final t = type?.trim().toLowerCase() ?? '';
  if ((t == 'job_offer' || t == 'joboffer' || t == 'offer') &&
      jobId != null &&
      jobId > 0) {
    await showOneeJobOfferBanner(
      title: title,
      body: body,
      jobId: jobId,
      id: id == 0 ? 900001 : id,
    );
    return;
  }

  final plugin = FlutterLocalNotificationsPlugin();

  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosInit = DarwinInitializationSettings();

  await plugin.initialize(
    settings: const InitializationSettings(android: androidInit, iOS: iosInit),
  );

  final android = plugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();
  await android?.createNotificationChannel(
    const AndroidNotificationChannel(
      oneeNotificationChannelId,
      oneeNotificationChannelName,
      description: oneeNotificationChannelDesc,
      importance: Importance.high,
      playSound: true,
    ),
  );

  final payload = jsonEncode({
    'jobId': ?jobId,
    'type': ?type,
  });

  await plugin.show(
    id: id == 0 ? DateTime.now().millisecondsSinceEpoch ~/ 1000 : id,
    title: title,
    body: body,
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        oneeNotificationChannelId,
        oneeNotificationChannelName,
        channelDescription: oneeNotificationChannelDesc,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFFEBB407),
        colorized: false,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    ),
    payload: payload,
  );
}

class LocalNotificationService extends GetxService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;
  int _id = 0;
  String? _lastDedupeKey;
  DateTime? _lastDedupeAt;

  Future<LocalNotificationService> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onTap,
    );

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        oneeNotificationChannelId,
        oneeNotificationChannelName,
        description: oneeNotificationChannelDesc,
        importance: Importance.high,
        playSound: true,
      ),
    );
    await android?.createNotificationChannel(_offerChannel());
    await android?.requestNotificationsPermission();
    try {
      final granted = await android?.requestFullScreenIntentPermission();
      if (kDebugMode) {
        debugPrint('Full-screen intent permission granted=$granted');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Full-screen intent permission request failed: $e');
      }
    }

    _ready = true;

    try {
      final launch = await _plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp == true) {
        final raw = launch!.notificationResponse?.payload;
        if (raw != null && raw.isNotEmpty) {
          final map = jsonDecode(raw) as Map<String, dynamic>;
          final jobId = int.tryParse(map['jobId']?.toString() ?? '');
          final type = map['type']?.toString();
          Future<void>.delayed(const Duration(milliseconds: 900), () {
            _navigateFromPayload(jobId: jobId, type: type);
          });
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Launch notification details failed: $e');
    }

    return this;
  }

  Future<void> show({
    required String title,
    required String body,
    int? jobId,
    String? type,
  }) async {
    if (!_ready) return;

    final t = type?.trim().toLowerCase() ?? '';
    if ((t == 'job_offer' || t == 'joboffer' || t == 'offer') &&
        jobId != null &&
        jobId > 0) {
      await showJobOffer(title: title, body: body, jobId: jobId);
      return;
    }

    final dedupeKey = '${jobId ?? ''}|$title|$body';
    final now = DateTime.now();
    if (_lastDedupeKey == dedupeKey &&
        _lastDedupeAt != null &&
        now.difference(_lastDedupeAt!) < const Duration(seconds: 4)) {
      return;
    }
    _lastDedupeKey = dedupeKey;
    _lastDedupeAt = now;

    try {
      await showOneePushBanner(
        title: title,
        body: body,
        jobId: jobId,
        type: type,
        id: _id++,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Local notification failed: $e');
    }
  }

  Future<void> showJobOffer({
    required String title,
    required String body,
    required int jobId,
  }) async {
    final dedupeKey = 'offer|$jobId';
    final now = DateTime.now();
    if (_lastDedupeKey == dedupeKey &&
        _lastDedupeAt != null &&
        now.difference(_lastDedupeAt!) < const Duration(seconds: 3)) {
      return;
    }
    _lastDedupeKey = dedupeKey;
    _lastDedupeAt = now;

    try {
      await showOneeJobOfferBanner(
        title: title,
        body: body,
        jobId: jobId,
        id: 900000 + (jobId % 1000),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Job offer notification failed: $e');
    }
  }

  Future<void> cancelJobOffer(int jobId) async {
    try {
      await _plugin.cancel(id: 900000 + (jobId % 1000));
    } catch (_) {}
  }

  void _onTap(NotificationResponse response) {
    final raw = response.payload;
    if (raw == null || raw.isEmpty) return;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final jobId = int.tryParse(map['jobId']?.toString() ?? '');
      final type = map['type']?.toString();
      _navigateFromPayload(jobId: jobId, type: type);
    } catch (_) {}
  }
}
