import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../../../common_widgets/empty_state.dart';
import '../../../common_widgets/onee_loader.dart';
import '../model/job_models.dart';
import 'job_chat_controller.dart';

class JobChatView extends GetView<JobChatController> {
  const JobChatView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF2),
      body: Column(
        children: [
          Obx(
            () => _ChatHeader(
              customerName: controller.customerName.value,
              category: controller.jobCategory.value,
              jobId: controller.jobId,
            ),
          ),
          Expanded(
            child: Obx(() {
              final _ = controller.currentUserId.value;

              if (controller.isLoading.value && controller.messages.isEmpty) {
                return const Center(child: OneeLoader());
              }

              final error = controller.error.value;
              if (error != null && controller.messages.isEmpty) {
                return ErrorState(
                  message: error,
                  onRetry: controller.loadChat,
                );
              }

              if (controller.messages.isEmpty) {
                return const EmptyState(
                  message: 'No messages yet.\nSay hello to start the chat.',
                  icon: Icons.chat_bubble_outline_rounded,
                );
              }

              return ListView.builder(
                controller: controller.scrollController,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                itemCount: controller.messages.length,
                itemBuilder: (context, index) {
                  final message = controller.messages[index];
                  final showDay = index == 0 ||
                      !_sameDay(
                        controller.messages[index - 1].createdOn,
                        message.createdOn,
                      );
                  return Column(
                    children: [
                      if (showDay) _DayDivider(date: message.createdOn),
                      _Bubble(
                        message: message,
                        isMine: controller.isMine(message),
                      ),
                    ],
                  );
                },
              );
            }),
          ),
          Obx(() {
            if (!controller.canCompose.value) {
              return _ComposerLocked(
                status: controller.jobStatus.value,
              );
            }
            return _Composer(controller: controller);
          }),
        ],
      ),
    );
  }

  bool _sameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    final la = a.toLocal();
    final lb = b.toLocal();
    return la.year == lb.year && la.month == lb.month && la.day == lb.day;
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.customerName,
    required this.category,
    required this.jobId,
  });

  final String customerName;
  final String category;
  final int jobId;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFF6D8),
            AppColors.cream,
            Color(0xFFFFFBF2),
          ],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(8, top + 4, 16, 14),
        child: Row(
          children: [
            IconButton(
              onPressed: Get.back,
              icon: const Icon(Icons.arrow_back_rounded),
              color: AppColors.nearBlack,
            ),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.55),
                ),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/default_worker.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.nearBlack,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    category.isNotEmpty ? '$category · #$jobId' : 'Job #$jobId',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mutedBrown,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayDivider extends StatelessWidget {
  const _DayDivider({required this.date});

  final DateTime? date;

  @override
  Widget build(BuildContext context) {
    final label = date == null
        ? 'Messages'
        : DateFormat('EEE, dd MMM').format(date!.toLocal());

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: AppColors.mutedBrown.withValues(alpha: 0.18),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.mutedBrown,
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: AppColors.mutedBrown.withValues(alpha: 0.18),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.isMine});

  final JobChatMessage message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final time = message.createdOn != null
        ? DateFormat('HH:mm').format(message.createdOn!.toLocal())
        : null;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 8,
          left: isMine ? 48 : 0,
          right: isMine ? 0 : 48,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        decoration: BoxDecoration(
          color: isMine ? AppColors.nearBlack : AppColors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMine ? 18 : 5),
            bottomRight: Radius.circular(isMine ? 5 : 18),
          ),
          border: isMine
              ? null
              : Border.all(
                  color: AppColors.mutedBrown.withValues(alpha: 0.14),
                ),
          boxShadow: [
            BoxShadow(
              color: AppColors.nearBlack.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMine &&
                message.senderName != null &&
                message.senderName!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  message.senderName!,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gold,
                  ),
                ),
              ),
            Text(
              message.message,
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
                fontWeight: FontWeight.w500,
                color: isMine ? AppColors.white : AppColors.nearBlack,
              ),
            ),
            if (time != null) ...[
              const SizedBox(height: 5),
              Text(
                time,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isMine
                      ? AppColors.cream.withValues(alpha: 0.75)
                      : AppColors.mutedBrown.withValues(alpha: 0.85),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller});

  final JobChatController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        14,
        10,
        14,
        10 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(
            color: AppColors.mutedBrown.withValues(alpha: 0.14),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E7),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppColors.mutedBrown.withValues(alpha: 0.16),
                ),
              ),
              child: TextField(
                controller: controller.messageController,
                textCapitalization: TextCapitalization.sentences,
                minLines: 1,
                maxLines: 4,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.nearBlack,
                ),
                decoration: const InputDecoration(
                  hintText: 'Type a message…',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => controller.send(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Obx(
            () => Material(
              color: AppColors.gold,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: controller.isSending.value ? null : controller.send,
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(
                    child: controller.isSending.value
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.nearBlack,
                            ),
                          )
                        : const Icon(
                            Icons.send_rounded,
                            color: AppColors.nearBlack,
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComposerLocked extends StatelessWidget {
  const _ComposerLocked({required this.status});

  final String? status;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        16,
        14,
        16,
        14 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(
            color: AppColors.mutedBrown.withValues(alpha: 0.14),
          ),
        ),
      ),
      child: Text(
        status == null
            ? 'Chat is unavailable for this job.'
            : 'Chat is closed ($status).',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.mutedBrown,
        ),
      ),
    );
  }
}
