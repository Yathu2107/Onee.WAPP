import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/theme/app_colors.dart';
import '../../app_service/notifications/notification_badge_service.dart';
import '../../app_service/notifications/push_banner_bridge.dart';
import '../../app_service/push/fcm_service.dart';
import '../../app_service/realtime/signalr_service.dart';
import '../../common_widgets/auto_refresh.dart';
import '../home/bindings/home_binding.dart';
import '../home/controller/home_controller.dart';
import '../home/view/home_view.dart';
import '../jobs/bindings/my_jobs_binding.dart';
import '../jobs/controller/my_jobs_controller.dart';
import '../jobs/offer/job_offer_alert_service.dart';
import '../jobs/view/my_jobs_view.dart';
import '../notifications/bindings/notifications_binding.dart';
import '../notifications/controller/notifications_controller.dart';
import '../notifications/view/notifications_view.dart';
import '../profile/bindings/profile_binding.dart';
import '../profile/controller/profile_controller.dart';
import '../profile/view/profile_view.dart';

class MainShellBinding extends Bindings {
  @override
  void dependencies() {
    HomeBinding().dependencies();
    MyJobsBinding().dependencies();
    NotificationsBinding().dependencies();
    ProfileBinding().dependencies();
  }
}

class MainShellView extends StatefulWidget {
  const MainShellView({super.key});

  @override
  State<MainShellView> createState() => _MainShellViewState();
}

class _MainShellViewState extends State<MainShellView> {
  int _index = 0;

  final _pages = const [
    HomeView(),
    MyJobsView(),
    NotificationsView(),
    ProfileView(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (Get.isRegistered<SignalRService>()) {
        await Get.find<SignalRService>().connect();
      }
      if (Get.isRegistered<PushBannerBridge>()) {
        Get.find<PushBannerBridge>().start();
      }
      if (Get.isRegistered<JobOfferAlertService>()) {
        Get.find<JobOfferAlertService>().start();
        await Get.find<JobOfferAlertService>().consumeStoredPendingOffer();
      }
      if (Get.isRegistered<FcmService>()) {
        await Get.find<FcmService>().registerWithBackend();
      }
      await _refreshTab(0);
    });
  }

  Future<void> _refreshTab(int index) async {
    switch (index) {
      case 0:
        if (Get.isRegistered<HomeController>()) {
          await Get.find<HomeController>().refreshAll();
        }
        break;
      case 1:
        if (Get.isRegistered<MyJobsController>()) {
          await Get.find<MyJobsController>().load(silent: true);
        }
        break;
      case 2:
        if (Get.isRegistered<NotificationsController>()) {
          await Get.find<NotificationsController>().load();
        }
        if (Get.isRegistered<NotificationBadgeService>()) {
          await Get.find<NotificationBadgeService>().refresh();
        }
        break;
      case 3:
        if (Get.isRegistered<ProfileController>()) {
          await Get.find<ProfileController>().loadUser();
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AutoRefresh(
      onRefresh: () => _refreshTab(_index),
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: IndexedStack(index: _index, children: _pages),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          backgroundColor: AppColors.white,
          indicatorColor: AppColors.cream,
          onDestinationSelected: (i) {
            setState(() => _index = i);
            _refreshTab(i);
          },
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            const NavigationDestination(
              icon: Icon(Icons.work_outline_rounded),
              selectedIcon: Icon(Icons.work_rounded),
              label: 'My Jobs',
            ),
            NavigationDestination(
              icon: Obx(() {
                final count = Get.isRegistered<NotificationBadgeService>()
                    ? Get.find<NotificationBadgeService>().unreadCount.value
                    : 0;
                return Badge(
                  isLabelVisible: count > 0,
                  label: Text('$count'),
                  child: const Icon(Icons.notifications_outlined),
                );
              }),
              selectedIcon: const Icon(Icons.notifications_rounded),
              label: 'Alerts',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
