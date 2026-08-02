import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app_service/network/api_response.dart';
import '../../../app_service/realtime/signalr_service.dart';
import '../../../common_widgets/app_snackbar.dart';
import '../../../utils/job_statuses.dart';
import '../model/job_models.dart';
import '../repository/job_repository.dart';

enum MyJobsFilter { active, completed, other }

class MyJobsController extends GetxController {
  MyJobsController(this._jobRepository);

  final JobRepository _jobRepository;

  final isLoading = false.obs;
  final filter = MyJobsFilter.active.obs;
  final allJobs = <JobListItem>[].obs;
  final error = RxnString();

  Worker? _jobUpdatedWorker;

  List<JobListItem> filteredJobsFor(MyJobsFilter selected) {
    final jobs = allJobs.toList();
    switch (selected) {
      case MyJobsFilter.active:
        return jobs.where((j) => JobStatuses.isActive(j.status)).toList();
      case MyJobsFilter.completed:
        return jobs.where((j) => JobStatuses.isCompleted(j.status)).toList();
      case MyJobsFilter.other:
        return jobs
            .where(
              (j) =>
                  JobStatuses.isCancelledGroup(j.status) ||
                  JobStatuses.isOffering(j.status),
            )
            .toList();
    }
  }

  @override
  void onReady() {
    super.onReady();
    load();
    _listenSignalR();
  }

  void _listenSignalR() {
    if (!Get.isRegistered<SignalRService>()) return;
    final signalR = Get.find<SignalRService>();
    _jobUpdatedWorker = ever<JobDetail?>(signalR.jobUpdated, (detail) {
      if (detail == null) return;
      load(silent: true);
    });
  }

  Future<void> load({bool silent = false}) async {
    if (!silent) isLoading.value = true;
    error.value = null;
    try {
      final response = await _jobRepository.getMyJobs();
      allJobs.assignAll(response.result ?? <JobListItem>[]);
    } on ApiException catch (e) {
      error.value = e.message;
      if (!silent) AppSnackbar.error(e.message);
    } catch (_) {
      error.value = 'Failed to load jobs.';
      if (!silent) AppSnackbar.error('Failed to load jobs.');
    } finally {
      if (!silent) isLoading.value = false;
    }
  }

  Future<void> refreshList() => load();

  void setFilter(MyJobsFilter value) => filter.value = value;

  Future<void> openJob(JobListItem job) async {
    final route = JobStatuses.isOffering(job.status)
        ? AppRoutes.offerDetail
        : AppRoutes.jobDetail;
    await Get.toNamed(route, arguments: {'jobId': job.id});
    await load(silent: true);
  }

  @override
  void onClose() {
    _jobUpdatedWorker?.dispose();
    super.onClose();
  }
}
