import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../common_widgets/auto_refresh.dart';
import '../../../common_widgets/empty_state.dart';
import '../../../common_widgets/job_status_chip.dart';
import '../../../common_widgets/onee_loader.dart';
import '../../../common_widgets/primary_button.dart';
import '../../../common_widgets/profile_image_avatar.dart';
import '../../../utils/job_statuses.dart';
import '../model/job_models.dart';
import 'job_detail_controller.dart';

class JobDetailView extends GetView<JobDetailController> {
  const JobDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.job.value == null) {
        return const Scaffold(
          backgroundColor: AppColors.white,
          body: Center(child: OneeLoader()),
        );
      }

      final error = controller.error.value;
      if (error != null && controller.job.value == null) {
        return Scaffold(
          backgroundColor: AppColors.white,
          appBar: AppBar(title: const Text('Job details')),
          body: ErrorState(message: error, onRetry: controller.load),
        );
      }

      final job = controller.job.value;
      if (job == null) {
        return const Scaffold(
          backgroundColor: AppColors.white,
          body: EmptyState(message: 'Job not found.'),
        );
      }

      return Scaffold(
        backgroundColor: AppColors.white,
        body: AutoRefresh(
          onRefresh: controller.load,
          child: Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.gold,
                  onRefresh: controller.load,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    slivers: [
                      SliverToBoxAdapter(child: _DetailHero(job: job)),
                      SliverToBoxAdapter(child: _StatusTimeline(status: job.status)),
                      SliverToBoxAdapter(child: _CustomerCard(job: job)),
                      SliverToBoxAdapter(child: _ProblemBlock(job: job)),
                      if (job.amount != null)
                        SliverToBoxAdapter(
                          child: _AmountRow(amount: job.amount!),
                        ),
                      if (job.createdOn != null)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                            child: Text(
                              'Created ${DateFormat('dd MMM yyyy · HH:mm').format(job.createdOn!.toLocal())}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.mutedBrown,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      if (JobStatuses.isCancelledGroup(job.status))
                        SliverToBoxAdapter(child: _CancelledNote(job: job)),
                      if (JobStatuses.isCompleted(job.status) && job.hasRating)
                        SliverToBoxAdapter(child: _RatingBlock(job: job)),
                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    ],
                  ),
                ),
              ),
              _DetailActions(controller: controller, job: job),
            ],
          ),
        ),
      );
    });
  }
}

class _DetailHero extends StatelessWidget {
  const _DetailHero({required this.job});

  final JobDetail job;

  String get _headline {
    if (JobStatuses.isAccepted(job.status)) return 'Job accepted';
    if (JobStatuses.isOngoing(job.status)) return 'Job in progress';
    if (JobStatuses.isCompleted(job.status)) return 'Job completed';
    if (job.status?.toLowerCase() == 'cancelled') return 'Job cancelled';
    if (JobStatuses.isFailed(job.status)) return 'Job failed';
    return 'Job details';
  }

  String get _subtitle {
    if (JobStatuses.isAccepted(job.status)) {
      return 'Chat with the customer and confirm the amount.';
    }
    if (JobStatuses.isOngoing(job.status)) {
      return 'Finish the work, then mark the job complete.';
    }
    if (JobStatuses.isCompleted(job.status)) {
      return 'Nice work — this job is done.';
    }
    return 'Review the details of this job.';
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final category = job.categoryName?.trim().isNotEmpty == true
        ? job.categoryName!.trim()
        : 'Job #${job.id}';

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFF6D8),
            AppColors.cream,
            AppColors.white,
          ],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(8, top + 4, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    if (Navigator.of(context).canPop()) {
                      Get.back();
                    } else {
                      Get.offAllNamed(AppRoutes.home);
                    }
                  },
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: AppColors.nearBlack,
                ),
                const Expanded(
                  child: Text(
                    'Job details',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.nearBlack,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _headline,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppColors.nearBlack,
                            height: 1.15,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      JobStatusChip(status: job.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                      color: AppColors.mutedBrown.withValues(alpha: 0.98),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      '$category · #${job.id}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.nearBlack,
                      ),
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

class _StatusTimeline extends StatelessWidget {
  const _StatusTimeline({required this.status});

  final String? status;

  static const _steps = [
    JobStatuses.offering,
    JobStatuses.accepted,
    JobStatuses.ongoing,
    JobStatuses.completed,
  ];

  int get _activeIndex {
    final s = status?.trim().toLowerCase();
    if (s == 'offering') return 0;
    if (s == 'accepted') return 1;
    if (s == 'ongoing') return 2;
    if (s == 'completed') return 3;
    if (s == 'cancelled' || s == 'failed') return -1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final active = _activeIndex;
    final cancelled = JobStatuses.isCancelledGroup(status);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Progress',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.nearBlack,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < _steps.length; i++) ...[
                if (i > 0)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: !cancelled && active >= i
                          ? AppColors.gold
                          : AppColors.mutedBrown.withValues(alpha: 0.2),
                    ),
                  ),
                _TimelineDot(
                  label: _steps[i],
                  reached: !cancelled && active >= i,
                  current: !cancelled && active == i,
                ),
              ],
            ],
          ),
          if (cancelled) ...[
            const SizedBox(height: 10),
            Text(
              status ?? 'Cancelled',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFFB3261E),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TimelineDot extends StatelessWidget {
  const _TimelineDot({
    required this.label,
    required this.reached,
    required this.current,
  });

  final String label;
  final bool reached;
  final bool current;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: current ? 18 : 12,
          height: current ? 18 : 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: reached ? AppColors.gold : AppColors.white,
            border: Border.all(
              color: reached
                  ? AppColors.gold
                  : AppColors.mutedBrown.withValues(alpha: 0.35),
              width: 2,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: current ? FontWeight.w800 : FontWeight.w600,
            color: reached ? AppColors.nearBlack : AppColors.mutedBrown,
          ),
        ),
      ],
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.job});

  final JobDetail job;

  @override
  Widget build(BuildContext context) {
    final name = job.customerName?.trim().isNotEmpty == true
        ? job.customerName!.trim()
        : 'Customer';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.mutedBrown.withValues(alpha: 0.16),
          ),
        ),
        child: Row(
          children: [
            ProfileImageAvatar(
              imageUrl: job.customerImageUrl,
              size: 52,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Customer',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mutedBrown,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.nearBlack,
                    ),
                  ),
                ],
              ),
            ),
            if (JobStatuses.canChat(job.status))
              IconButton.filled(
                onPressed: () => Get.find<JobDetailController>().goChat(),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.nearBlack,
                ),
                icon: const Icon(Icons.chat_bubble_rounded, size: 20),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProblemBlock extends StatelessWidget {
  const _ProblemBlock({required this.job});

  final JobDetail job;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Problem',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.nearBlack,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E7),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.mutedBrown.withValues(alpha: 0.14),
              ),
            ),
            child: Text(
              job.problemText?.trim().isNotEmpty == true
                  ? job.problemText!.trim()
                  : '—',
              style: const TextStyle(
                fontSize: 15,
                height: 1.45,
                fontWeight: FontWeight.w500,
                color: AppColors.nearBlack,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({required this.amount});

  final double amount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: [
          const Text(
            'Amount',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.mutedBrown,
            ),
          ),
          const Spacer(),
          Text(
            'LKR ${amount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.nearBlack,
            ),
          ),
        ],
      ),
    );
  }
}

class _CancelledNote extends StatelessWidget {
  const _CancelledNote({required this.job});

  final JobDetail job;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFB3261E).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          job.cancelReason?.trim().isNotEmpty == true
              ? job.cancelReason!.trim()
              : JobStatuses.isFailed(job.status)
                  ? 'This job failed.'
                  : 'This job was cancelled.',
          style: const TextStyle(
            fontSize: 13,
            height: 1.4,
            fontWeight: FontWeight.w600,
            color: Color(0xFFB3261E),
          ),
        ),
      ),
    );
  }
}

class _RatingBlock extends StatelessWidget {
  const _RatingBlock({required this.job});

  final JobDetail job;

  @override
  Widget build(BuildContext context) {
    final stars = job.rating?.rating ?? 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Customer rating',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.nearBlack,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${'★' * stars}${'☆' * (5 - stars)}',
            style: const TextStyle(
              fontSize: 20,
              color: AppColors.gold,
              letterSpacing: 2,
            ),
          ),
          if (job.rating?.feedback?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(
              job.rating!.feedback!.trim(),
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w500,
                color: AppColors.mutedBrown,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailActions extends StatelessWidget {
  const _DetailActions({
    required this.controller,
    required this.job,
  });

  final JobDetailController controller;
  final JobDetail job;

  @override
  Widget build(BuildContext context) {
    final status = job.status;
    final canChat = JobStatuses.canChat(status);
    final canConfirm = JobStatuses.canConfirmAmount(status);
    final canComplete = JobStatuses.canComplete(status);

    if (!canChat && !canConfirm && !canComplete) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        12 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(
            color: AppColors.mutedBrown.withValues(alpha: 0.14),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (canChat)
            PrimaryButton(
              label: 'Open chat',
              onPressed: controller.goChat,
            ),
          if (canConfirm) ...[
            if (canChat) const SizedBox(height: 10),
            PrimaryButton(
              label: 'Confirm amount',
              onPressed: controller.goConfirmAmount,
            ),
          ],
          if (canComplete) ...[
            if (canChat || canConfirm) const SizedBox(height: 10),
            Obx(
              () => PrimaryButton(
                label: 'Complete job',
                isLoading: controller.isCompleting.value,
                onPressed: controller.complete,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
