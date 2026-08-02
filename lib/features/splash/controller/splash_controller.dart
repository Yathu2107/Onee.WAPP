import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app_service/network/api_response.dart';
import '../../../app_service/storage/secure_storage_service.dart';
import '../../auth/repository/auth_repository.dart';
import '../../skills/repository/category_repository.dart';

class SplashController extends GetxController {
  SplashController(this._authRepository, this._storage);

  final AuthRepository _authRepository;
  final SecureStorageService _storage;

  final isChecking = true.obs;
  bool _navigated = false;

  /// Hard ceiling so splash never hangs on storage/network stalls.
  static const _sessionRestoreTimeout = Duration(seconds: 8);

  @override
  void onReady() {
    super.onReady();
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    try {
      await _restoreSession().timeout(_sessionRestoreTimeout);
    } on TimeoutException catch (e) {
      if (kDebugMode) {
        debugPrint('Splash session restore timed out: $e');
      }
      _goToPhoneLogin();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Splash bootstrap failed: $e');
      }
      _goToPhoneLogin();
    } finally {
      isChecking.value = false;
    }
  }

  Future<void> _restoreSession() async {
    await Future.delayed(const Duration(milliseconds: 700));

    final hasToken = await _storage.hasToken();
    if (!hasToken) {
      _goToPhoneLogin();
      return;
    }

    try {
      final response = await _authRepository.getLoggedWorkerDetails().timeout(
        const Duration(seconds: 6),
      );
      final worker = response.result;

      if (worker == null || !worker.hasName) {
        _navigateOnce(
          AppRoutes.completeRegistration,
          arguments: {
            if (worker?.phoneNumber != null) 'phone': worker!.phoneNumber,
          },
        );
        return;
      }

      await _routeAfterProfile(worker.phoneNumber);
    } on ApiException catch (e) {
      await _storage.clearTokens();
      if (kDebugMode) {
        debugPrint('Splash API error: ${e.code} ${e.message}');
      }
      _goToPhoneLogin();
    } on TimeoutException {
      _goToPhoneLogin();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Splash unexpected error: $e');
      }
      await _storage.clearTokens();
      _goToPhoneLogin();
    }
  }

  Future<void> _routeAfterProfile(String? phone) async {
    if (Get.isRegistered<CategoryRepository>()) {
      try {
        final skillsResponse =
            await Get.find<CategoryRepository>().listMine().timeout(
          const Duration(seconds: 4),
        );
        final mine = skillsResponse.result ?? const [];
        if (mine.isEmpty) {
          _navigateOnce(
            AppRoutes.selectSkills,
            arguments: {
              'mode': 'onboarding',
              'phone': ?phone,
            },
          );
          return;
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Splash skills check failed, going home: $e');
        }
      }
    }

    _navigateOnce(AppRoutes.home);
  }

  void _goToPhoneLogin() => _navigateOnce(AppRoutes.phoneLogin);

  void _navigateOnce(String route, {Map<String, dynamic>? arguments}) {
    if (_navigated) return;
    _navigated = true;

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (Get.currentRoute == route) return;
      Get.offAllNamed(route, arguments: arguments);
    });
  }
}
