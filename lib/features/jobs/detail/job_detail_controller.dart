import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app_service/network/api_response.dart';
import '../../../app_service/realtime/signalr_service.dart';
import '../../../common_widgets/app_snackbar.dart';
import '../../../utils/job_statuses.dart';
import '../model/job_models.dart';
import '../repository/job_repository.dart';

class JobDetailController extends GetxController {
  JobDetailController(this._jobRepository);

  final JobRepository _jobRepository;

  final isLoading = false.obs;
  final isCompleting = false.obs;
  final job = Rxn<JobDetail>();
  final error = RxnString();

  late final int jobId;
  Worker? _jobUpdatedWorker;

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
      error.value = 'Invalid job.';
      return;
    }
    load();
    _joinAndListen();
  }

  Future<void> _joinAndListen() async {
    if (!Get.isRegistered<SignalRService>()) return;
    final signalR = Get.find<SignalRService>();
    await signalR.connect();
    await signalR.joinJob(jobId);

    _jobUpdatedWorker = ever<JobDetail?>(signalR.jobUpdated, (detail) {
      if (detail == null || detail.id != jobId) return;
      job.value = detail;
      if (JobStatuses.isOffering(detail.status)) {
        Get.offNamed(AppRoutes.offerDetail, arguments: {'jobId': jobId});
      }
    });
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = null;
    try {
      final response = await _jobRepository.getJob(jobId);
      final detail = response.result;
      job.value = detail;
      if (detail != null && JobStatuses.isOffering(detail.status)) {
        Get.offNamed(AppRoutes.offerDetail, arguments: {'jobId': jobId});
      }
    } on ApiException catch (e) {
      error.value = e.message;
      AppSnackbar.error(e.message);
    } catch (_) {
      error.value = 'Failed to load job.';
      AppSnackbar.error('Failed to load job.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> goChat() async {
    await Get.toNamed(AppRoutes.jobChat, arguments: {'jobId': jobId});
    await load();
  }

  Future<void> goConfirmAmount() async {
    await Get.toNamed(AppRoutes.confirmAmount, arguments: {'jobId': jobId});
    await load();
  }

  Future<void> complete() async {
    if (isCompleting.value) return;
    if (!JobStatuses.canComplete(job.value?.status)) return;

    isCompleting.value = true;
    try {
      final response = await _jobRepository.complete(jobId);
      job.value = response.result;
      Get.offAllNamed(AppRoutes.home);
      AppSnackbar.success('Job marked complete.');
    } on ApiException catch (e) {
      AppSnackbar.error(e.message);
    } catch (_) {
      AppSnackbar.error('Failed to complete job.');
    } finally {
      isCompleting.value = false;
    }
  }

  @override
  void onClose() {
    _jobUpdatedWorker?.dispose();
    if (Get.isRegistered<SignalRService>() && jobId > 0) {
      Get.find<SignalRService>().leaveJob(jobId);
    }
    super.onClose();
  }
}
