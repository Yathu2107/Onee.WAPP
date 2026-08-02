import 'dart:async';

import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app_service/network/api_response.dart';
import '../../../app_service/realtime/signalr_service.dart';
import '../../../common_widgets/app_snackbar.dart';
import '../../../utils/job_statuses.dart';
import '../model/job_models.dart';
import '../repository/job_repository.dart';

class OfferDetailController extends GetxController {
  OfferDetailController(this._jobRepository);

  final JobRepository _jobRepository;

  final isLoading = false.obs;
  final isAccepting = false.obs;
  final isDeclining = false.obs;
  final job = Rxn<JobDetail>();
  final error = RxnString();
  final offerCountdown = RxnString();
  final isExpired = false.obs;

  late final int jobId;
  Worker? _jobUpdatedWorker;
  Worker? _jobOfferWorker;
  Timer? _countdownTimer;
  bool _reloadAfterExpire = false;

  @override
  void onInit() {
    super.onInit();
    jobId = _parseJobId();
  }

  int _parseJobId() {
    final args = Get.arguments;
    if (args is int) return args;
    if (args is Map) {
      final raw = args['jobId'] ?? args['id'];
      if (raw is int) return raw;
      return int.tryParse(raw?.toString() ?? '') ?? 0;
    }
    return 0;
  }

  @override
  void onReady() {
    super.onReady();
    if (jobId <= 0) {
      error.value = 'Invalid job offer.';
      return;
    }
    load();
    _listenSignalR();
  }

  void _listenSignalR() {
    if (!Get.isRegistered<SignalRService>()) return;
    final signalR = Get.find<SignalRService>();
    signalR.connect().then((_) => signalR.joinJob(jobId));

    _jobUpdatedWorker = ever<JobDetail?>(signalR.jobUpdated, (detail) {
      if (detail == null || detail.id != jobId) return;
      job.value = detail;
      _startOfferCountdown();
      if (!JobStatuses.isOffering(detail.status)) {
        Get.offNamed(AppRoutes.jobDetail, arguments: {'jobId': jobId});
      }
    });

    _jobOfferWorker = ever<JobDetail?>(signalR.jobOffer, (detail) {
      if (detail == null || detail.id != jobId) return;
      job.value = detail;
      _startOfferCountdown();
    });
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = null;
    try {
      final response = await _jobRepository.getJob(jobId);
      final detail = response.result;
      job.value = detail;
      _startOfferCountdown();
      if (detail != null && !JobStatuses.isOffering(detail.status)) {
        Get.offNamed(AppRoutes.jobDetail, arguments: {'jobId': jobId});
      }
    } on ApiException catch (e) {
      error.value = e.message;
      AppSnackbar.error(e.message);
    } catch (_) {
      error.value = 'Failed to load offer.';
      AppSnackbar.error('Failed to load offer.');
    } finally {
      isLoading.value = false;
    }
  }

  void _startOfferCountdown() {
    _countdownTimer?.cancel();
    offerCountdown.value = null;
    isExpired.value = false;
    final detail = job.value;
    if (!JobStatuses.isOffering(detail?.status) ||
        detail?.offerExpiresAt == null) {
      return;
    }
    _reloadAfterExpire = false;

    void tick() {
      final current = job.value;
      if (current?.offerExpiresAt == null) return;
      final expires = current!.offerExpiresAt!.toLocal();
      final remaining = expires.difference(DateTime.now());
      if (remaining.isNegative) {
        offerCountdown.value = 'Expired';
        isExpired.value = true;
        _countdownTimer?.cancel();
        if (!_reloadAfterExpire) {
          _reloadAfterExpire = true;
          load();
        }
        return;
      }
      isExpired.value = false;
      final m = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
      final s = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
      final h = remaining.inHours;
      offerCountdown.value =
          h > 0 ? '${h.toString().padLeft(2, '0')}:$m:$s' : '$m:$s';
    }

    tick();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  Future<void> accept() async {
    if (isAccepting.value || isDeclining.value || isExpired.value) return;
    if (!JobStatuses.canAcceptDecline(job.value?.status)) return;

    isAccepting.value = true;
    try {
      final response = await _jobRepository.accept(jobId);
      job.value = response.result;
      Get.offNamed(AppRoutes.jobDetail, arguments: {'jobId': jobId});
    } on ApiException catch (e) {
      AppSnackbar.error(e.message);
    } catch (_) {
      AppSnackbar.error('Failed to accept offer.');
    } finally {
      isAccepting.value = false;
    }
  }

  Future<void> decline() async {
    if (isAccepting.value || isDeclining.value) return;
    if (!JobStatuses.canAcceptDecline(job.value?.status)) return;

    isDeclining.value = true;
    try {
      await _jobRepository.decline(jobId);
      Get.back();
    } on ApiException catch (e) {
      AppSnackbar.error(e.message);
    } catch (_) {
      AppSnackbar.error('Failed to decline offer.');
    } finally {
      isDeclining.value = false;
    }
  }

  @override
  void onClose() {
    _countdownTimer?.cancel();
    _jobUpdatedWorker?.dispose();
    _jobOfferWorker?.dispose();
    if (Get.isRegistered<SignalRService>() && jobId > 0) {
      Get.find<SignalRService>().leaveJob(jobId);
    }
    super.onClose();
  }
}
