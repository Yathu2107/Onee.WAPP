import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app_service/network/api_response.dart';
import '../../../app_service/realtime/signalr_service.dart';
import '../../../common_widgets/app_snackbar.dart';
import '../../addresses/model/address_models.dart';
import '../../addresses/repository/address_repository.dart';
import '../../auth/model/auth_models.dart';
import '../../auth/repository/auth_repository.dart';
import '../../jobs/model/job_models.dart';
import '../../jobs/offer/job_offer_alert_service.dart';
import '../../jobs/repository/job_repository.dart';
import '../../skills/repository/category_repository.dart';

class HomeController extends GetxController {
  HomeController(
    this._authRepository,
    this._jobRepository,
    this._categoryRepository,
    this._addressRepository,
  );

  final AuthRepository _authRepository;
  final JobRepository _jobRepository;
  final CategoryRepository _categoryRepository;
  final AddressRepository _addressRepository;

  final isLoading = false.obs;
  final isTogglingOnline = false.obs;
  final isRefreshingLocation = false.obs;
  final worker = Rxn<WorkerDetails>();
  final selectedAddress = Rxn<SavedAddress>();
  final offers = <JobListItem>[].obs;
  final offersError = RxnString();
  final hasSkills = true.obs;
  final nowTick = DateTime.now().obs;

  Worker? _offerListener;
  Timer? _countdownTimer;

  bool get isOnline => worker.value?.isOnline ?? false;

  @override
  void onReady() {
    super.onReady();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      nowTick.value = DateTime.now();
    });
    _listenOffers();
    refreshAll();
  }

  void _listenOffers() {
    if (!Get.isRegistered<SignalRService>()) return;
    _offerListener?.dispose();
    _offerListener = ever(Get.find<SignalRService>().jobOffer, (detail) {
      if (detail == null) return;
      // Popup + tone is handled by JobOfferAlertService.
      loadOffers(silent: true);
    });
  }

  Future<void> refreshAll({bool refreshLocation = true}) async {
    await Future.wait([
      loadWorker(),
      loadOffers(),
      loadSkillsFlag(),
      loadDefaultAddress(),
      if (refreshLocation) maybeRefreshLocation(),
    ]);
  }

  Future<void> loadDefaultAddress() async {
    try {
      final response = await _addressRepository.list();
      final list = response.result ?? <SavedAddress>[];
      if (list.isEmpty) {
        selectedAddress.value = null;
        return;
      }
      selectedAddress.value = list.firstWhere(
        (a) => a.isDefault,
        orElse: () => list.first,
      );
    } catch (_) {
      // Keep previous selection if refresh fails.
    }
  }

  Future<void> goAddresses() async {
    await Get.toNamed(AppRoutes.addresses);
    await loadDefaultAddress();
  }

  Future<void> loadWorker() async {
    isLoading.value = true;
    try {
      final response = await _authRepository.getLoggedWorkerDetails();
      worker.value = response.result;
    } on ApiException catch (e) {
      AppSnackbar.error(e.message);
      if (e.statusCode == 401 || e.statusCode == 404) {
        await _authRepository.clearSession();
        Get.offAllNamed(AppRoutes.phoneLogin);
      }
    } catch (_) {
      AppSnackbar.error('Failed to load profile.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadOffers({bool silent = false}) async {
    if (!silent) offersError.value = null;
    try {
      final response = await _jobRepository.getOffers();
      final items = response.result ?? <JobListItem>[];
      offers.assignAll(items);
      if (Get.isRegistered<JobOfferAlertService>()) {
        await Get.find<JobOfferAlertService>().onOffersLoaded(items);
      }
    } on ApiException catch (e) {
      offersError.value = e.message;
      if (!silent) AppSnackbar.error(e.message);
    } catch (_) {
      offersError.value = 'Failed to load offers.';
      if (!silent) AppSnackbar.error('Failed to load offers.');
    }
  }

  Future<void> loadSkillsFlag() async {
    try {
      final response = await _categoryRepository.listMine();
      hasSkills.value = (response.result ?? []).isNotEmpty;
    } catch (_) {
      // Keep previous value.
    }
  }

  Future<void> toggleOnline(bool value) async {
    if (isTogglingOnline.value) return;
    isTogglingOnline.value = true;
    try {
      await _authRepository.setOnlineStatus(value);
      final current = worker.value;
      if (current != null) {
        worker.value = WorkerDetails(
          name: current.name,
          email: current.email,
          phoneNumber: current.phoneNumber,
          proImg: current.proImg,
          isOnline: value,
          isActive: current.isActive,
          latitude: current.latitude,
          longitude: current.longitude,
          averageRating: current.averageRating,
          ratingCount: current.ratingCount,
        );
      } else {
        await loadWorker();
      }
      AppSnackbar.success(value ? 'You are online.' : 'You are offline.');
      await loadOffers(silent: true);
    } on ApiException catch (e) {
      AppSnackbar.error(e.message);
    } catch (_) {
      AppSnackbar.error('Could not update online status.');
    } finally {
      isTogglingOnline.value = false;
    }
  }

  Future<void> maybeRefreshLocation() async {
    if (isRefreshingLocation.value) return;
    isRefreshingLocation.value = true;
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      await _authRepository.setLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (_) {
      // Optional — ignore failures on resume/refresh.
    } finally {
      isRefreshingLocation.value = false;
    }
  }

  Future<void> goSelectSkills() async {
    await Get.toNamed(
      AppRoutes.selectSkills,
      arguments: {'mode': 'edit'},
    );
    await loadSkillsFlag();
  }

  Future<void> openOffer(int jobId) async {
    await Get.toNamed(AppRoutes.offerDetail, arguments: {'jobId': jobId});
    await loadOffers(silent: true);
  }

  Duration? remainingFor(JobListItem offer) {
    final expires = offer.offerExpiresAt;
    if (expires == null) return null;
    final left = expires.difference(nowTick.value);
    return left.isNegative ? Duration.zero : left;
  }

  String countdownLabel(JobListItem offer) {
    final left = remainingFor(offer);
    if (left == null) return 'Open offer';
    if (left == Duration.zero) return 'Expired';
    final m = left.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = left.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (left.inHours > 0) {
      return '${left.inHours}:$m:$s';
    }
    return '$m:$s';
  }

  @override
  void onClose() {
    _offerListener?.dispose();
    _countdownTimer?.cancel();
    super.onClose();
  }
}
