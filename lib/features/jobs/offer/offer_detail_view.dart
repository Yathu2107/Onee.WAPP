import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../common_widgets/empty_state.dart';
import '../../../common_widgets/job_status_chip.dart';
import '../../../common_widgets/onee_loader.dart';
import '../../../common_widgets/primary_button.dart';
import '../model/job_models.dart';
import 'offer_detail_controller.dart';

class OfferDetailView extends GetView<OfferDetailController> {
  const OfferDetailView({super.key});

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
          appBar: AppBar(title: const Text('Job offer')),
          body: ErrorState(message: error, onRetry: controller.load),
        );
      }

      final job = controller.job.value;
      if (job == null) {
        return const Scaffold(
          backgroundColor: AppColors.white,
          body: EmptyState(message: 'Offer not found.'),
        );
      }

      return Scaffold(
        backgroundColor: AppColors.white,
        body: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _OfferHero(job: job)),
                  SliverToBoxAdapter(child: _CustomerCard(job: job)),
                  SliverToBoxAdapter(child: _ProblemBlock(job: job)),
                  if (job.customerLatitude != null &&
                      job.customerLongitude != null)
                    SliverToBoxAdapter(
                      child: _MapPin(
                        lat: job.customerLatitude!,
                        lng: job.customerLongitude!,
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: Obx(() {
                      final countdown = controller.offerCountdown.value;
                      if (countdown == null) return const SizedBox.shrink();
                      return _CountdownBanner(
                        text: countdown,
                        expired: controller.isExpired.value,
                      );
                    }),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            ),
            _OfferActions(controller: controller),
          ],
        ),
      );
    });
  }
}

class _OfferHero extends StatelessWidget {
  const _OfferHero({required this.job});

  final JobDetail job;

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
                    'Job offer',
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
                      const Expanded(
                        child: Text(
                          'New offer',
                          style: TextStyle(
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
                    'Review the job and accept before the timer ends.',
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

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.job});

  final JobDetail job;

  @override
  Widget build(BuildContext context) {
    final name = job.customerName?.trim().isNotEmpty == true
        ? job.customerName!.trim()
        : 'Customer';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
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
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.5),
                  width: 1.5,
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

class _MapPin extends StatelessWidget {
  const _MapPin({required this.lat, required this.lng});

  final double lat;
  final double lng;

  @override
  Widget build(BuildContext context) {
    final point = LatLng(lat, lng);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Location',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.nearBlack,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              height: 180,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: point,
                  initialZoom: 14,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.onee_wapp',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: point,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: AppColors.gold,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountdownBanner extends StatelessWidget {
  const _CountdownBanner({required this.text, required this.expired});

  final String text;
  final bool expired;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: expired
              ? const Color(0xFFB3261E).withValues(alpha: 0.1)
              : AppColors.cream.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: expired
                ? const Color(0xFFB3261E).withValues(alpha: 0.35)
                : AppColors.gold.withValues(alpha: 0.45),
          ),
        ),
        child: Row(
          children: [
            Icon(
              expired ? Icons.timer_off_rounded : Icons.timer_outlined,
              color: expired ? const Color(0xFFB3261E) : AppColors.nearBlack,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                expired ? 'Offer expired' : 'Offer expires in $text',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: expired
                      ? const Color(0xFFB3261E)
                      : AppColors.nearBlack,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfferActions extends StatelessWidget {
  const _OfferActions({required this.controller});

  final OfferDetailController controller;

  @override
  Widget build(BuildContext context) {
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
      child: Obx(() {
        final accepting = controller.isAccepting.value;
        final declining = controller.isDeclining.value;
        final expired = controller.isExpired.value;
        final busy = accepting || declining;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PrimaryButton(
              label: 'Accept',
              isLoading: accepting,
              enabled: !busy && !expired,
              onPressed: controller.accept,
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: busy ? null : controller.decline,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.nearBlack,
                side: BorderSide(
                  color: AppColors.mutedBrown.withValues(alpha: 0.45),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: declining
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Decline',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
          ],
        );
      }),
    );
  }
}
