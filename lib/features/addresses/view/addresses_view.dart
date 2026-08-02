import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../common_widgets/auto_refresh.dart';
import '../../../common_widgets/empty_state.dart';
import '../../../common_widgets/onee_loader.dart';
import '../controller/addresses_controller.dart';
import '../model/address_models.dart';

class AddressesView extends GetView<AddressesController> {
  const AddressesView({super.key});

  @override
  Widget build(BuildContext context) {
    return AutoRefresh(
      onRefresh: controller.load,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: Column(
          children: [
            Obx(() {
              final count = controller.addresses.length;
              final hasDefault = controller.addresses.any((a) => a.isDefault);
              return _AddressesHero(
                count: count,
                hasDefault: hasDefault,
                onBack: () => Get.back(),
                onAdd: controller.goAdd,
              );
            }),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value &&
                    controller.addresses.isEmpty) {
                  return const Center(child: OneeLoader());
                }

                final error = controller.error.value;
                if (error != null && controller.addresses.isEmpty) {
                  return ErrorState(message: error, onRetry: controller.load);
                }

                final items = controller.addresses;

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
                            const SizedBox(height: 64),
                            const EmptyState(
                              message:
                                  'No saved addresses yet.\nAdd one for your jobs.',
                              icon: Icons.location_on_outlined,
                            ),
                            const SizedBox(height: 28),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 48),
                              child: _AddAddressCta(onPressed: controller.goAdd),
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
                                padding:
                                    const EdgeInsets.fromLTRB(24, 16, 24, 8),
                                child: Text(
                                  '${items.length} '
                                  '${items.length == 1 ? 'address' : 'addresses'}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.mutedBrown,
                                  ),
                                ),
                              );
                            }

                            final address = items[index - 1];
                            return _AddressRow(
                              address: address,
                              onTap: () => controller.goEdit(address),
                              onSetDefault: address.isDefault
                                  ? null
                                  : () => controller.setDefault(address),
                              onDelete: () =>
                                  _confirmDelete(context, address),
                              showDivider: index < items.length,
                            );
                          },
                        ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    SavedAddress address,
  ) async {
    final label = address.label?.trim().isNotEmpty == true
        ? address.label!.trim()
        : 'this address';
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete address?',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.nearBlack,
          ),
        ),
        content: Text(
          'Remove "$label" from your saved places?',
          style: const TextStyle(
            color: AppColors.mutedBrown,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.mutedBrown,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Color(0xFFB3261E),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.deleteAddress(address);
    }
  }
}

class _AddressesHero extends StatelessWidget {
  const _AddressesHero({
    required this.count,
    required this.hasDefault,
    required this.onBack,
    required this.onAdd,
  });

  final int count;
  final bool hasDefault;
  final VoidCallback onBack;
  final VoidCallback onAdd;

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
        padding: EdgeInsets.fromLTRB(16, top + 8, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: AppColors.nearBlack,
                ),
                const Spacer(),
                Material(
                  color: AppColors.nearBlack,
                  borderRadius: BorderRadius.circular(999),
                  child: InkWell(
                    onTap: onAdd,
                    borderRadius: BorderRadius.circular(999),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_rounded,
                            size: 18,
                            color: AppColors.gold,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Add',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Text(
                'Saved addresses',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: AppColors.nearBlack,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                count == 0
                    ? 'Places you use for jobs'
                    : hasDefault
                        ? '$count saved · default set'
                        : '$count saved · set a default',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.mutedBrown.withValues(alpha: 0.98),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddAddressCta extends StatelessWidget {
  const _AddAddressCta({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.nearBlack,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_rounded, color: AppColors.gold, size: 20),
              SizedBox(width: 8),
              Text(
                'Add address',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddressRow extends StatelessWidget {
  const _AddressRow({
    required this.address,
    required this.onTap,
    required this.onSetDefault,
    required this.onDelete,
    required this.showDivider,
  });

  final SavedAddress address;
  final VoidCallback onTap;
  final VoidCallback? onSetDefault;
  final VoidCallback onDelete;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final label = (address.label != null && address.label!.trim().isNotEmpty)
        ? address.label!.trim()
        : 'Address';
    final line =
        (address.addressLine != null && address.addressLine!.trim().isNotEmpty)
            ? address.addressLine!.trim()
            : 'No address line';

    return Material(
      color: address.isDefault
          ? AppColors.cream.withValues(alpha: 0.35)
          : AppColors.white,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 14, 8, 14),
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
                child: Icon(
                  Icons.location_on_rounded,
                  color: address.isDefault
                      ? AppColors.gold
                      : AppColors.mutedBrown,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.nearBlack,
                            ),
                          ),
                        ),
                        if (address.isDefault) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.nearBlack,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Default',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.gold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      line,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                        color: AppColors.mutedBrown.withValues(alpha: 0.95),
                      ),
                    ),
                    if (onSetDefault != null) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: onSetDefault,
                        child: const Text(
                          'Set as default',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.nearBlack,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: onTap,
                tooltip: 'Edit',
                icon: const Icon(
                  Icons.edit_outlined,
                  color: AppColors.mutedBrown,
                  size: 20,
                ),
              ),
              IconButton(
                onPressed: onDelete,
                tooltip: 'Delete',
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.mutedBrown.withValues(alpha: 0.85),
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
