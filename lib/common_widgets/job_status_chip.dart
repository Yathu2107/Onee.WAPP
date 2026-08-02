import 'package:flutter/material.dart';

import '../app/theme/app_colors.dart';
import '../utils/job_statuses.dart';

class JobStatusChip extends StatelessWidget {
  const JobStatusChip({super.key, required this.status});

  final String? status;

  Color get _bg {
    switch (status) {
      case JobStatuses.offering:
        return AppColors.cream;
      case JobStatuses.accepted:
        return AppColors.gold.withValues(alpha: 0.25);
      case JobStatuses.ongoing:
        return AppColors.gold.withValues(alpha: 0.45);
      case JobStatuses.completed:
        return const Color(0xFF2E7D32).withValues(alpha: 0.15);
      case JobStatuses.cancelled:
      case JobStatuses.failed:
        return const Color(0xFFB3261E).withValues(alpha: 0.12);
      default:
        return AppColors.mutedBrown.withValues(alpha: 0.15);
    }
  }

  Color get _fg {
    switch (status) {
      case JobStatuses.completed:
        return const Color(0xFF2E7D32);
      case JobStatuses.cancelled:
      case JobStatuses.failed:
        return const Color(0xFFB3261E);
      default:
        return AppColors.nearBlack;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status ?? 'Unknown',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: _fg,
        ),
      ),
    );
  }
}
