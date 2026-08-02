import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../common_widgets/primary_button.dart';
import '../model/job_models.dart';

/// PickMe-style incoming job offer overlay with countdown + accept/decline.
class JobOfferIncomingPopup extends StatefulWidget {
  const JobOfferIncomingPopup({
    super.key,
    required this.job,
    required this.onAccept,
    required this.onDecline,
    required this.onView,
    required this.onExpired,
  });

  final JobDetail job;
  final Future<void> Function() onAccept;
  final Future<void> Function() onDecline;
  final VoidCallback onView;
  final VoidCallback onExpired;

  @override
  State<JobOfferIncomingPopup> createState() => _JobOfferIncomingPopupState();
}

class _JobOfferIncomingPopupState extends State<JobOfferIncomingPopup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  Timer? _countdownTimer;
  String _countdown = '';
  bool _expired = false;
  bool _accepting = false;
  bool _declining = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _tickCountdown();
    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _tickCountdown(),
    );
  }

  void _tickCountdown() {
    final expires = widget.job.offerExpiresAt?.toLocal();
    if (expires == null) {
      if (_countdown.isNotEmpty || _expired) return;
      setState(() => _countdown = '');
      return;
    }

    final remaining = expires.difference(DateTime.now());
    if (remaining.isNegative) {
      _countdownTimer?.cancel();
      if (!_expired) {
        setState(() {
          _expired = true;
          _countdown = 'Expired';
        });
        widget.onExpired();
      }
      return;
    }

    final m = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = remaining.inHours;
    final text = h > 0 ? '${h.toString().padLeft(2, '0')}:$m:$s' : '$m:$s';
    if (!mounted) return;
    setState(() {
      _expired = false;
      _countdown = text;
    });
  }

  Future<void> _accept() async {
    if (_accepting || _declining || _expired) return;
    setState(() => _accepting = true);
    try {
      await widget.onAccept();
    } finally {
      if (mounted) setState(() => _accepting = false);
    }
  }

  Future<void> _decline() async {
    if (_accepting || _declining) return;
    setState(() => _declining = true);
    try {
      await widget.onDecline();
    } finally {
      if (mounted) setState(() => _declining = false);
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final category = job.categoryName?.trim().isNotEmpty == true
        ? job.categoryName!.trim()
        : 'New job offer';
    final customer = job.customerName?.trim().isNotEmpty == true
        ? job.customerName!.trim()
        : 'Customer';
    final problem = job.problemText?.trim().isNotEmpty == true
        ? job.problemText!.trim()
        : 'A customer needs your help.';
    final busy = _accepting || _declining;

    return PopScope(
      canPop: false,
      child: Material(
        color: AppColors.nearBlack.withValues(alpha: 0.55),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.nearBlack.withValues(alpha: 0.18),
                        blurRadius: 28,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(28),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xFFFFF6D8),
                              AppColors.cream,
                              AppColors.white,
                            ],
                          ),
                        ),
                        child: Column(
                          children: [
                            AnimatedBuilder(
                              animation: _pulse,
                              builder: (context, child) {
                                final t = _pulse.value;
                                final scale = 1 + 0.08 * math.sin(t * math.pi);
                                return Transform.scale(
                                  scale: scale,
                                  child: child,
                                );
                              },
                              child: Container(
                                width: 76,
                                height: 76,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.gold.withValues(alpha: 0.22),
                                  border: Border.all(
                                    color: AppColors.gold,
                                    width: 2.5,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.work_rounded,
                                  size: 34,
                                  color: AppColors.nearBlack,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Incoming job request',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.nearBlack,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              category,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.mutedBrown.withValues(
                                  alpha: 0.95,
                                ),
                              ),
                            ),
                            if (_countdown.isNotEmpty) ...[
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: _expired
                                      ? const Color(0xFFB3261E)
                                          .withValues(alpha: 0.1)
                                      : AppColors.white.withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: _expired
                                        ? const Color(0xFFB3261E)
                                            .withValues(alpha: 0.35)
                                        : AppColors.gold.withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Text(
                                  _expired
                                      ? 'Offer expired'
                                      : 'Expires in $_countdown',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: _expired
                                        ? const Color(0xFFB3261E)
                                        : AppColors.nearBlack,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(22, 4, 22, 22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: AppColors.cream,
                                  child: Text(
                                    customer.isNotEmpty
                                        ? customer[0].toUpperCase()
                                        : 'C',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.nearBlack,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'From',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.mutedBrown,
                                        ),
                                      ),
                                      Text(
                                        customer,
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
                              ],
                            ),
                            const SizedBox(height: 14),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF8E7),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.mutedBrown
                                      .withValues(alpha: 0.14),
                                ),
                              ),
                              child: Text(
                                problem,
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.4,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.nearBlack,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            PrimaryButton(
                              label: 'Accept job',
                              isLoading: _accepting,
                              enabled: !busy && !_expired,
                              onPressed: _accept,
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton(
                              onPressed: busy ? null : _decline,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.nearBlack,
                                side: BorderSide(
                                  color: AppColors.mutedBrown
                                      .withValues(alpha: 0.45),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: _declining
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Decline',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                            TextButton(
                              onPressed: busy ? null : widget.onView,
                              child: const Text(
                                'View full details',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.mutedBrown,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<T?> showJobOfferIncomingPopup<T>({
  required JobDetail job,
  required Future<void> Function() onAccept,
  required Future<void> Function() onDecline,
  required VoidCallback onView,
  required VoidCallback onExpired,
}) {
  return Get.dialog<T>(
    JobOfferIncomingPopup(
      job: job,
      onAccept: onAccept,
      onDecline: onDecline,
      onView: onView,
      onExpired: onExpired,
    ),
    barrierDismissible: false,
    barrierColor: Colors.transparent,
  );
}
