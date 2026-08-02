import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app_service/network/api_response.dart';
import '../../../common_widgets/app_snackbar.dart';
import '../../../utils/job_statuses.dart';
import '../repository/job_repository.dart';

class ConfirmAmountController extends GetxController {
  ConfirmAmountController(this._jobRepository);

  final JobRepository _jobRepository;

  final amountController = TextEditingController();
  final isSubmitting = false.obs;
  final isLoading = false.obs;
  final error = RxnString();

  late final int jobId;

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
    _prefetchAmount();
  }

  Future<void> _prefetchAmount() async {
    isLoading.value = true;
    try {
      final response = await _jobRepository.getJob(jobId);
      final amount = response.result?.amount;
      if (amount != null && amount > 0) {
        amountController.text = amount.toStringAsFixed(2);
      }
      if (!JobStatuses.canConfirmAmount(response.result?.status)) {
        Get.back();
        AppSnackbar.info('This job is no longer awaiting amount confirmation.');
      }
    } catch (_) {
      // Prefill is optional — user can still type an amount.
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> submit() async {
    if (isSubmitting.value) return;

    final raw = amountController.text.trim().replaceAll(',', '');
    final amount = double.tryParse(raw);
    if (amount == null || amount <= 0) {
      AppSnackbar.info('Enter a valid amount greater than zero.');
      return;
    }

    isSubmitting.value = true;
    try {
      await _jobRepository.confirm(jobId, amount);
      Get.back(result: true);
      AppSnackbar.success('Amount confirmed. Job is now Ongoing.');
    } on ApiException catch (e) {
      AppSnackbar.error(e.message);
    } catch (_) {
      AppSnackbar.error('Failed to confirm amount.');
    } finally {
      isSubmitting.value = false;
    }
  }

  @override
  void onClose() {
    amountController.dispose();
    super.onClose();
  }
}
