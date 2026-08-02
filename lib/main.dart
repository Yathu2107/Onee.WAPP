import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';

import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/theme/app_theme.dart';
import 'app_service/network/debug_http_overrides.dart';
import 'app_service/network/dio_client.dart';
import 'app_service/notifications/local_notification_service.dart';
import 'app_service/notifications/notification_badge_service.dart';
import 'app_service/notifications/push_banner_bridge.dart';
import 'app_service/push/fcm_service.dart';
import 'app_service/realtime/signalr_service.dart';
import 'app_service/storage/secure_storage_service.dart';
import 'common_widgets/auto_refresh.dart';
import 'features/addresses/repository/address_repository.dart';
import 'features/auth/repository/auth_repository.dart';
import 'features/jobs/offer/job_offer_alert_service.dart';
import 'features/jobs/repository/job_repository.dart';
import 'features/notifications/repository/notification_repository.dart';
import 'features/skills/repository/category_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Local API uses a self-signed cert; Dio already bypasses it, but SignalR
  // WebSockets need a global HttpOverrides to connect over HTTPS on LAN.
  if (kDebugMode && !kIsWeb) {
    HttpOverrides.global = DebugHttpOverrides();
  }

  // Register before runApp so killed/background FCM can wake the isolate.
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('Firebase bootstrap skipped: $e');
  }

  await dotenv.load(fileName: '.env');

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  final storage = SecureStorageService();
  final dioClient = DioClient(storage);
  final authRepository = AuthRepository(
    dioClient: dioClient,
    storage: storage,
  );

  Get.put<SecureStorageService>(storage, permanent: true);
  Get.put<DioClient>(dioClient, permanent: true);
  Get.put<AuthRepository>(authRepository, permanent: true);
  Get.put<JobRepository>(JobRepository(dioClient), permanent: true);
  Get.put<AddressRepository>(AddressRepository(dioClient), permanent: true);
  Get.put<NotificationRepository>(
    NotificationRepository(dioClient),
    permanent: true,
  );
  Get.put<CategoryRepository>(CategoryRepository(dioClient), permanent: true);
  Get.put<SignalRService>(SignalRService(storage), permanent: true);
  Get.put<NotificationBadgeService>(
    NotificationBadgeService(),
    permanent: true,
  );

  final localNotifications = LocalNotificationService();
  await localNotifications.init();
  Get.put<LocalNotificationService>(localNotifications, permanent: true);
  Get.put<PushBannerBridge>(PushBannerBridge(), permanent: true);
  Get.put<JobOfferAlertService>(JobOfferAlertService(), permanent: true);

  final fcm = FcmService();
  Get.put<FcmService>(fcm, permanent: true);
  await fcm.init();

  runApp(const OneeWorkerApp());
}

class OneeWorkerApp extends StatelessWidget {
  const OneeWorkerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Onee Worker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      themeMode: ThemeMode.light,
      darkTheme: AppTheme.light,
      initialRoute: AppRoutes.splash,
      getPages: AppPages.pages,
      defaultTransition: Transition.cupertino,
      navigatorObservers: [appRouteObserver],
    );
  }
}
