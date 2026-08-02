import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../../../common_widgets/empty_state.dart';
import '../../../common_widgets/job_status_chip.dart';
import '../../../common_widgets/onee_loader.dart';
import '../../../utils/job_statuses.dart';
import '../controller/my_jobs_controller.dart';
import '../model/job_models.dart';

class MyJobsView extends GetView<MyJobsController> {
  const MyJobsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          Obx(() {
            final selected = controller.filter.value;
            final active = controller
                .filteredJobsFor(MyJobsFilter.active)
                .length;
            final total = controller.allJobs.length;
            return _MyJobsHero(
              selected: selected,
              activeCount: active,
              totalCount: total,
              onFilter: controller.setFilter,
            );
          }),
          Expanded(
            child: Obx(() {
              final loading = controller.isLoading.value;
              final err = controller.error.value;
              final selected = controller.filter.value;
              final jobs = controller.filteredJobsFor(selected);
              final totalCount = controller.allJobs.length;

              if (loading && totalCount == 0) {
                return const Center(child: OneeLoader());
              }

              if (err != null && totalCount == 0) {
                return ErrorState(message: err, onRetry: controller.load);
              }

              return RefreshIndicator(
                color: AppColors.gold,
                displacement: 28,
                onRefresh: controller.refreshList,
                child: jobs.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        children: [
                          const SizedBox(height: 72),
                          EmptyState(
                            message: _emptyMessage(selected),
                            icon: Icons.work_outline_rounded,
                          ),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.only(bottom: 28),
                        itemCount: jobs.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                              child: Text(
                                '${jobs.length} '
                                '${jobs.length == 1 ? 'job' : 'jobs'}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.mutedBrown,
                                ),
                              ),
                            );
                          }
                          final job = jobs[index - 1];
                          return _JobRow(
                            job: job,
                            onTap: () => controller.openJob(job),
                            showDivider: index < jobs.length,
                          );
                        },
                      ),
              );
            }),
          ),
        ],
      ),
    );
  }

  String _emptyMessage(MyJobsFilter filter) {
    switch (filter) {
      case MyJobsFilter.active:
        return 'No active jobs right now.';
      case MyJobsFilter.completed:
        return 'No completed jobs yet.';
      case MyJobsFilter.other:
        return 'No other jobs.';
    }
  }
}

class _MyJobsHero extends StatelessWidget {
  const _MyJobsHero({
    required this.selected,
    required this.activeCount,
    required this.totalCount,
    required this.onFilter,
  });

  final MyJobsFilter selected;
  final int activeCount;
  final int totalCount;
  final ValueChanged<MyJobsFilter> onFilter;

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
            AppColors.white,
          ],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, top + 18, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Jobs',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: AppColors.nearBlack,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              activeCount > 0
                  ? '$activeCount active · $totalCount total'
                  : totalCount > 0
                      ? '$totalCount jobs in your history'
                      : 'Track offers from accept to complete',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.mutedBrown.withValues(alpha: 0.98),
              ),
            ),
            const SizedBox(height: 18),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Active',
                    selected: selected == MyJobsFilter.active,
                    onTap: () => onFilter(MyJobsFilter.active),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Completed',
                    selected: selected == MyJobsFilter.completed,
                    onTap: () => onFilter(MyJobsFilter.completed),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Other',
                    selected: selected == MyJobsFilter.other,
                    onTap: () => onFilter(MyJobsFilter.other),
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.nearBlack
          : AppColors.white.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? AppColors.nearBlack
                  : AppColors.gold.withValues(alpha: 0.35),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: selected ? AppColors.gold : AppColors.nearBlack,
            ),
          ),
        ),
      ),
    );
  }
}

class _JobRow extends StatelessWidget {
  const _JobRow({
    required this.job,
    required this.onTap,
    required this.showDivider,
  });

  final JobListItem job;
  final VoidCallback onTap;
  final bool showDivider;

  IconData get _icon {
    final status = job.status?.toLowerCase();
    if (status == 'offering') return Icons.radar_rounded;
    if (status == 'accepted') return Icons.check_circle_outline_rounded;
    if (status == 'ongoing') return Icons.handyman_rounded;
    if (status == 'completed') return Icons.task_alt_rounded;
    if (status == 'cancelled' || status == 'failed') {
      return Icons.cancel_outlined;
    }
    return Icons.work_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final title =
        (job.problemText != null && job.problemText!.trim().isNotEmpty)
            ? job.problemText!.trim()
            : (job.categoryName ?? 'Job #${job.id}');
    final date = job.createdOn != null
        ? DateFormat('dd MMM · HH:mm').format(job.createdOn!.toLocal())
        : null;
    final category = job.categoryName?.trim();
    final customer = job.customerName?.trim();
    final meta = [
      if (category != null && category.isNotEmpty) category,
      if (customer != null && customer.isNotEmpty) customer,
      ?date,
    ].join(' · ');

    final isActive = JobStatuses.isActive(job.status);

    return Material(
      color: isActive
          ? AppColors.cream.withValues(alpha: 0.28)
          : AppColors.white,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 14, 16, 14),
          decoration: BoxDecoration(
            border: showDivider
                ? Border(
                    bottom: BorderSide(
                      color: AppColors.mutedBrown.withValues(alpha: 0.12),
                    ),
                  )
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.cream.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_icon, color: AppColors.gold, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.nearBlack,
                              height: 1.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        JobStatusChip(status: job.status),
                      ],
                    ),
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.mutedBrown,
                        ),
                      ),
                    ],
                    if (job.amount != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'LKR ${job.amount!.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.nearBlack,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10, left: 4),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.mutedBrown.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
