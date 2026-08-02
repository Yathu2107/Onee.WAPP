import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../../../common_widgets/empty_state.dart';
import '../../../common_widgets/onee_loader.dart';
import '../controller/notifications_controller.dart';
import '../model/notification_models.dart';

class NotificationsView extends GetView<NotificationsController> {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          Obx(() {
            final selected = controller.filter.value;
            final unread = controller.unreadCount;
            final total = controller.notifications.length;
            return _NotificationsHero(
              selected: selected,
              unreadCount: unread,
              totalCount: total,
              isBusy: controller.isBusy.value,
              onFilter: controller.setFilter,
              onMarkAllRead: unread > 0 ? controller.markAllRead : null,
            );
          }),
          Expanded(
            child: Obx(() {
              final loading = controller.isLoading.value;
              final err = controller.error.value;
              final selected = controller.filter.value;
              final items = controller.filteredFor(selected);
              final totalCount = controller.notifications.length;

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
                child: items.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        children: [
                          const SizedBox(height: 72),
                          EmptyState(
                            message: selected == NotificationsFilter.unread
                                ? 'You\'re all caught up.\nNo unread notifications.'
                                : 'No notifications yet.\nOffers and job updates will show here.',
                            icon: selected == NotificationsFilter.unread
                                ? Icons.mark_email_read_outlined
                                : Icons.notifications_none_rounded,
                          ),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.only(bottom: 28),
                        itemCount: items.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                              child: Text(
                                '${items.length} '
                                '${items.length == 1 ? 'notification' : 'notifications'}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.mutedBrown,
                                ),
                              ),
                            );
                          }
                          final item = items[index - 1];
                          return _NotificationRow(
                            notification: item,
                            onTap: () => controller.onTap(item),
                            showDivider: index < items.length,
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
}

class _NotificationsHero extends StatelessWidget {
  const _NotificationsHero({
    required this.selected,
    required this.unreadCount,
    required this.totalCount,
    required this.isBusy,
    required this.onFilter,
    required this.onMarkAllRead,
  });

  final NotificationsFilter selected;
  final int unreadCount;
  final int totalCount;
  final bool isBusy;
  final ValueChanged<NotificationsFilter> onFilter;
  final VoidCallback? onMarkAllRead;

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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: AppColors.nearBlack,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                if (onMarkAllRead != null)
                  Material(
                    color: AppColors.white.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(999),
                    child: InkWell(
                      onTap: isBusy ? null : onMarkAllRead,
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          isBusy ? '…' : 'Mark all read',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.nearBlack,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              unreadCount > 0
                  ? '$unreadCount unread · $totalCount total'
                  : totalCount > 0
                      ? 'All caught up · $totalCount total'
                      : 'Job offers and updates land here',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.mutedBrown.withValues(alpha: 0.98),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                _FilterChip(
                  label: 'All',
                  selected: selected == NotificationsFilter.all,
                  onTap: () => onFilter(NotificationsFilter.all),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: unreadCount > 0 ? 'Unread ($unreadCount)' : 'Unread',
                  selected: selected == NotificationsFilter.unread,
                  onTap: () => onFilter(NotificationsFilter.unread),
                ),
              ],
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

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({
    required this.notification,
    required this.onTap,
    required this.showDivider,
  });

  final AppNotification notification;
  final VoidCallback onTap;
  final bool showDivider;

  IconData get _icon {
    switch (notification.type?.toLowerCase()) {
      case 'job_offer':
      case 'joboffer':
      case 'offer':
        return Icons.radar_rounded;
      case 'job_updated':
        return Icons.work_outline_rounded;
      case 'chat_message':
      case 'chat':
        return Icons.chat_bubble_outline_rounded;
      case 'complaint_update':
        return Icons.report_gmailerrorred_outlined;
      case 'admin_broadcast':
        return Icons.campaign_outlined;
      case 'system':
        return Icons.info_outline_rounded;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  String get _relativeTime {
    final created = notification.createdOn?.toLocal();
    if (created == null) return '';

    final now = DateTime.now();
    final diff = now.difference(created);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('dd MMM · HH:mm').format(created);
  }

  @override
  Widget build(BuildContext context) {
    final unread = !notification.isRead;
    final title = notification.title?.trim().isNotEmpty == true
        ? notification.title!.trim()
        : 'Notification';
    final body = notification.body?.trim();
    final canOpenJob = notification.jobId != null && notification.jobId! > 0;

    return Material(
      color: unread
          ? AppColors.cream.withValues(alpha: 0.35)
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
              Stack(
                clipBehavior: Clip.none,
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
                  if (unread)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.white, width: 1.5),
                        ),
                      ),
                    ),
                ],
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
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight:
                                  unread ? FontWeight.w800 : FontWeight.w700,
                              color: AppColors.nearBlack,
                              height: 1.3,
                            ),
                          ),
                        ),
                        if (_relativeTime.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            _relativeTime,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.mutedBrown.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (body != null && body.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        body,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          fontWeight:
                              unread ? FontWeight.w600 : FontWeight.w500,
                          color: AppColors.mutedBrown.withValues(
                            alpha: unread ? 0.95 : 0.85,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (canOpenJob)
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
