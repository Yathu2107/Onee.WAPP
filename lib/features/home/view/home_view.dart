import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../common_widgets/empty_state.dart';
import '../../../common_widgets/onee_loader.dart';
import '../../addresses/model/address_models.dart';
import '../../jobs/model/job_models.dart';
import '../controller/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Obx(() {
        if (controller.isLoading.value && controller.worker.value == null) {
          return const Center(child: OneeLoader());
        }

        return RefreshIndicator(
          color: AppColors.gold,
          displacement: 48,
          onRefresh: () => controller.refreshAll(refreshLocation: true),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: _OffersHero(
                  name: controller.worker.value?.name,
                  isOnline: controller.isOnline,
                  isToggling: controller.isTogglingOnline.value,
                  onToggle: controller.toggleOnline,
                ),
              ),
              SliverToBoxAdapter(
                child: Obx(
                  () => _AddressBar(
                    address: controller.selectedAddress.value,
                    onChange: controller.goAddresses,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Obx(() {
                  if (controller.hasSkills.value) {
                    return const SizedBox.shrink();
                  }
                  return _SkillsBanner(onTap: controller.goSelectSkills);
                }),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Job offers',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.nearBlack,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              _OffersSliver(controller: controller),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        );
      }),
    );
  }
}

class _AddressBar extends StatelessWidget {
  const _AddressBar({
    required this.address,
    required this.onChange,
  });

  final SavedAddress? address;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final hasAddress = address != null;
    final label = hasAddress &&
            address!.label != null &&
            address!.label!.trim().isNotEmpty
        ? address!.label!.trim()
        : (hasAddress ? 'Saved address' : 'No address');
    final line = hasAddress &&
            address!.addressLine != null &&
            address!.addressLine!.trim().isNotEmpty
        ? address!.addressLine!.trim()
        : (hasAddress
            ? 'Tap Change to update details'
            : 'Add a saved address for jobs');

    return Material(
      color: AppColors.white,
      child: InkWell(
        onTap: onChange,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: AppColors.mutedBrown.withValues(alpha: 0.16),
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.cream.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: AppColors.gold,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.nearBlack,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      line,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.mutedBrown.withValues(alpha: 0.95),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                hasAddress ? 'Change' : 'Add',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OffersHero extends StatelessWidget {
  const _OffersHero({
    required this.name,
    required this.isOnline,
    required this.isToggling,
    required this.onToggle,
  });

  final String? name;
  final bool isOnline;
  final bool isToggling;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final display = _firstName(name);

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
        padding: EdgeInsets.fromLTRB(24, top + 16, 24, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              'assets/images/Logo_splash.png',
              height: 40,
              fit: BoxFit.contain,
              alignment: Alignment.centerLeft,
            ),
            const SizedBox(height: 24),
            Text(
              'Hi, $display',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.nearBlack,
                height: 1.1,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isOnline
                  ? 'You are visible to nearby customers.'
                  : 'Go online to receive job offers.',
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                color: AppColors.mutedBrown,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            _OnlineToggleCard(
              isOnline: isOnline,
              isToggling: isToggling,
              onToggle: onToggle,
            ),
          ],
        ),
      ),
    );
  }

  static String _firstName(String? name) {
    if (name == null || name.trim().isEmpty) return 'there';
    return name.trim().split(RegExp(r'\s+')).first;
  }
}

class _OnlineToggleCard extends StatelessWidget {
  const _OnlineToggleCard({
    required this.isOnline,
    required this.isToggling,
    required this.onToggle,
  });

  final bool isOnline;
  final bool isToggling;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
      decoration: BoxDecoration(
        color: AppColors.nearBlack,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isOnline ? const Color(0xFF2E7D32) : AppColors.mutedBrown,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isOnline
                  ? Icons.sensors_rounded
                  : Icons.sensors_off_rounded,
              color: AppColors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOnline ? 'Online' : 'Offline',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isOnline
                      ? 'Receiving offers now'
                      : 'Tap to start receiving offers',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.cream,
                  ),
                ),
              ],
            ),
          ),
          if (isToggling)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.gold,
              ),
            )
          else
            Switch.adaptive(
              value: isOnline,
              onChanged: onToggle,
              activeThumbColor: AppColors.gold,
              activeTrackColor: AppColors.gold.withValues(alpha: 0.45),
            ),
        ],
      ),
    );
  }
}

class _SkillsBanner extends StatelessWidget {
  const _SkillsBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cream.withValues(alpha: 0.65),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: Row(
            children: [
              const Icon(Icons.handyman_outlined, color: AppColors.gold),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Add your skills to receive job offers',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.nearBlack,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.mutedBrown.withValues(alpha: 0.8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OffersSliver extends StatelessWidget {
  const _OffersSliver({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Touch tick so countdown labels rebuild.
      controller.nowTick.value;

      final error = controller.offersError.value;
      final items = controller.offers;

      if (error != null && items.isEmpty) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: ErrorState(
            message: error,
            onRetry: controller.loadOffers,
          ),
        );
      }

      if (items.isEmpty) {
        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 20, 8, 0),
            child: EmptyState(
              message: controller.isOnline
                  ? "You're online. Waiting for jobs…"
                  : 'Go online to receive offers',
              icon: controller.isOnline
                  ? Icons.hourglass_top_rounded
                  : Icons.sensors_off_rounded,
            ),
          ),
        );
      }

      return SliverList.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final offer = items[index];
          return _OfferTile(
            offer: offer,
            countdown: controller.countdownLabel(offer),
            onTap: () => controller.openOffer(offer.id),
            showDivider: index < items.length - 1,
          );
        },
      );
    });
  }
}

class _OfferTile extends StatelessWidget {
  const _OfferTile({
    required this.offer,
    required this.countdown,
    required this.onTap,
    required this.showDivider,
  });

  final JobListItem offer;
  final String countdown;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final title =
        (offer.problemText != null && offer.problemText!.trim().isNotEmpty)
            ? offer.problemText!.trim()
            : (offer.categoryName ?? 'Job #${offer.id}');
    final customer = offer.customerName?.trim();

    return Material(
      color: AppColors.white,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
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
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.cream.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.work_outline_rounded,
                  color: AppColors.gold,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
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
                    if (customer != null && customer.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        customer,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.mutedBrown,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.nearBlack,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        countdown,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.gold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 8),
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
