import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import '../../../app_service/network/api_response.dart';
import '../../../app_service/realtime/signalr_service.dart';
import '../../../app_service/storage/secure_storage_service.dart';
import '../../../common_widgets/app_snackbar.dart';
import '../../../utils/job_statuses.dart';
import '../model/job_models.dart';
import '../repository/job_repository.dart';

class JobChatController extends GetxController {
  JobChatController(this._jobRepository, this._storage);

  final JobRepository _jobRepository;
  final SecureStorageService _storage;

  final messageController = TextEditingController();
  final scrollController = ScrollController();

  final isLoading = false.obs;
  final isSending = false.obs;
  final messages = <JobChatMessage>[].obs;
  final error = RxnString();
  final currentUserId = ''.obs;
  final customerName = 'Customer'.obs;
  final jobCategory = ''.obs;
  final jobStatus = RxnString();
  final canCompose = false.obs;

  late final int jobId;
  Worker? _chatWorker;
  Worker? _jobUpdatedWorker;
  Timer? _pollTimer;

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
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _loadCurrentUserId();
    await Future.wait([loadChat(), _loadJobHeader()]);
    await _joinAndListen();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _mergeChatSilently();
    });
  }

  Future<void> _loadJobHeader() async {
    try {
      final response = await _jobRepository.getJob(jobId);
      final job = response.result;
      if (job == null) return;
      customerName.value = job.customerName?.trim().isNotEmpty == true
          ? job.customerName!.trim()
          : 'Customer';
      jobCategory.value = job.categoryName?.trim() ?? '';
      jobStatus.value = job.status;
      canCompose.value = JobStatuses.canChat(job.status);
    } catch (_) {}
  }

  Future<void> _loadCurrentUserId() async {
    try {
      final token = await _storage.getToken();
      if (token == null || token.isEmpty) return;
      final decoded = JwtDecoder.decode(token);
      final uid = decoded['uid']?.toString() ??
          decoded['sub']?.toString() ??
          decoded['nameid']?.toString() ??
          '';
      currentUserId.value = uid.trim();
    } catch (_) {
      currentUserId.value = '';
    }
  }

  Future<void> _joinAndListen() async {
    if (!Get.isRegistered<SignalRService>()) return;
    final signalR = Get.find<SignalRService>();
    await signalR.connect();
    await signalR.joinJob(jobId);

    _chatWorker = ever<JobChatMessage?>(signalR.chatMessage, (msg) {
      if (msg == null || msg.jobId != jobId) return;
      _upsertMessage(msg);
    });

    _jobUpdatedWorker = ever<JobDetail?>(signalR.jobUpdated, (detail) {
      if (detail == null || detail.id != jobId) return;
      jobStatus.value = detail.status;
      canCompose.value = JobStatuses.canChat(detail.status);
      if (detail.customerName?.trim().isNotEmpty == true) {
        customerName.value = detail.customerName!.trim();
      }
    });
  }

  void _upsertMessage(JobChatMessage msg) {
    final exists = messages.any((m) => m.id == msg.id && msg.id != 0);
    if (exists) return;
    messages.add(msg);
    _scrollToBottom();
  }

  Future<void> _mergeChatSilently() async {
    try {
      final response = await _jobRepository.getChat(jobId);
      final remote = response.result ?? <JobChatMessage>[];
      var added = false;
      for (final msg in remote) {
        final exists = messages.any((m) => m.id == msg.id && msg.id != 0);
        if (!exists) {
          messages.add(msg);
          added = true;
        }
      }
      if (added) {
        messages.sort((a, b) {
          final aTime = a.createdOn?.millisecondsSinceEpoch ?? a.id;
          final bTime = b.createdOn?.millisecondsSinceEpoch ?? b.id;
          return aTime.compareTo(bTime);
        });
        messages.refresh();
        _scrollToBottom();
      }
    } catch (_) {}
  }

  Future<void> loadChat() async {
    isLoading.value = true;
    error.value = null;
    try {
      final response = await _jobRepository.getChat(jobId);
      messages.assignAll(response.result ?? <JobChatMessage>[]);
      _scrollToBottom();
    } on ApiException catch (e) {
      error.value = e.message;
      AppSnackbar.error(e.message);
    } catch (_) {
      error.value = 'Failed to load chat.';
      AppSnackbar.error('Failed to load chat.');
    } finally {
      isLoading.value = false;
    }
  }

  bool isMine(JobChatMessage message) {
    final uid = currentUserId.value.trim();
    final sender = message.senderId.trim();
    if (uid.isEmpty || sender.isEmpty) return false;
    return uid.toLowerCase() == sender.toLowerCase();
  }

  Future<void> send() async {
    if (isSending.value) return;
    if (!canCompose.value) {
      AppSnackbar.info('Chat is only available while the job is active.');
      return;
    }
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    isSending.value = true;
    try {
      final response = await _jobRepository.sendChat(jobId, text);
      messageController.clear();
      final sent = response.result;
      if (sent != null) {
        _upsertMessage(sent);
      }
    } on ApiException catch (e) {
      AppSnackbar.error(e.message);
    } catch (_) {
      AppSnackbar.error('Failed to send message.');
    } finally {
      isSending.value = false;
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      scrollController.animateTo(
        scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void onClose() {
    _pollTimer?.cancel();
    _chatWorker?.dispose();
    _jobUpdatedWorker?.dispose();
    if (Get.isRegistered<SignalRService>() && jobId > 0) {
      Get.find<SignalRService>().leaveJob(jobId);
    }
    messageController.dispose();
    scrollController.dispose();
    super.onClose();
  }
}
