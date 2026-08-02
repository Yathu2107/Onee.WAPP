import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../common_widgets/empty_state.dart';
import '../../../common_widgets/onee_loader.dart';
import '../../../common_widgets/primary_button.dart';
import '../controller/select_skills_controller.dart';
import '../model/category_models.dart';

class SelectSkillsView extends GetView<SelectSkillsController> {
  const SelectSkillsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          _SkillsHero(
            isOnboarding: controller.isOnboarding,
            onBack: controller.isOnboarding ? null : () => Get.back(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
            child: TextField(
              onChanged: controller.onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search skills…',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: AppColors.cream.withValues(alpha: 0.45),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Obx(
              () => Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${controller.selectedCount} selected',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mutedBrown,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.categories.isEmpty) {
                return const Center(child: OneeLoader());
              }

              final err = controller.error.value;
              if (err != null && controller.categories.isEmpty) {
                return ErrorState(message: err, onRetry: controller.load);
              }

              final items = controller.filteredCategories;
              if (items.isEmpty) {
                return EmptyState(
                  message: controller.searchQuery.value.trim().isEmpty
                      ? 'No skills available yet.'
                      : 'No skills match your search.',
                  icon: Icons.handyman_outlined,
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                physics: const BouncingScrollPhysics(),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final item in items)
                      Obx(
                        () => _SkillChip(
                          item: item,
                          selected: controller.isSelected(item.id),
                          onTap: () => controller.toggle(item.id),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border(
                top: BorderSide(
                  color: AppColors.mutedBrown.withValues(alpha: 0.16),
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Obx(
                () => PrimaryButton(
                  label: controller.isOnboarding ? 'Continue' : 'Save',
                  isLoading: controller.isSaving.value,
                  onPressed: controller.submit,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillsHero extends StatelessWidget {
  const _SkillsHero({
    required this.isOnboarding,
    this.onBack,
  });

  final bool isOnboarding;
  final VoidCallback? onBack;

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
            if (onBack != null)
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded),
                color: AppColors.nearBlack,
              )
            else
              const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isOnboarding ? 'Choose your skills' : 'My skills',
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: AppColors.nearBlack,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isOnboarding
                        ? 'Pick at least one skill so we can match you to jobs.'
                        : 'Update the categories you want job offers for.',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.mutedBrown.withValues(alpha: 0.98),
                      height: 1.4,
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

class _SkillChip extends StatelessWidget {
  const _SkillChip({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final CategoryItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.nearBlack : AppColors.cream.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: AppColors.gold,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                item.categoryName,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? AppColors.white : AppColors.nearBlack,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
