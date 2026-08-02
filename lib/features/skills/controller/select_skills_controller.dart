import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app_service/network/api_response.dart';
import '../../../common_widgets/app_snackbar.dart';
import '../model/category_models.dart';
import '../repository/category_repository.dart';

class SelectSkillsController extends GetxController {
  SelectSkillsController(this._repository);

  final CategoryRepository _repository;

  /// `onboarding` | `edit` (default)
  late final String mode;

  final isLoading = false.obs;
  final isSaving = false.obs;
  final searchQuery = ''.obs;
  final categories = <CategoryItem>[].obs;
  final selectedIds = <int>{}.obs;
  final error = RxnString();

  bool get isOnboarding => mode == 'onboarding';

  int get selectedCount => selectedIds.length;

  List<CategoryItem> get filteredCategories {
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isEmpty) return categories.toList();
    return categories
        .where((c) => c.categoryName.toLowerCase().contains(q))
        .toList();
  }

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map && args['mode'] != null) {
      mode = args['mode'].toString().trim().toLowerCase();
    } else if (args is String) {
      mode = args.trim().toLowerCase();
    } else {
      mode = 'edit';
    }
  }

  @override
  void onReady() {
    super.onReady();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = null;
    try {
      final results = await Future.wait([
        _repository.listAll(),
        _repository.listMine(),
      ]);

      final all = (results[0] as ApiResponse<List<CategoryItem>>).result ??
          <CategoryItem>[];
      final mine =
          (results[1] as ApiResponse<List<WorkerCategoryItem>>).result ??
              <WorkerCategoryItem>[];

      categories.assignAll(all);
      selectedIds
        ..clear()
        ..addAll(mine.map((m) => m.categoryId).where((id) => id > 0));
    } on ApiException catch (e) {
      error.value = e.message;
      AppSnackbar.error(e.message);
    } catch (_) {
      error.value = 'Failed to load skills.';
      AppSnackbar.error('Failed to load skills.');
    } finally {
      isLoading.value = false;
    }
  }

  void onSearchChanged(String value) => searchQuery.value = value;

  void toggle(int categoryId) {
    if (selectedIds.contains(categoryId)) {
      selectedIds.remove(categoryId);
    } else {
      selectedIds.add(categoryId);
    }
  }

  bool isSelected(int categoryId) => selectedIds.contains(categoryId);

  Future<void> submit() async {
    if (isSaving.value) return;

    final ids = selectedIds.toList()..sort();

    if (isOnboarding && ids.isEmpty) {
      AppSnackbar.error('Select at least one skill to continue.');
      return;
    }

    if (!isOnboarding && ids.isEmpty) {
      final confirmed = await Get.dialog<bool>(
        AlertDialog(
          backgroundColor: AppColors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Clear all skills?',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.nearBlack,
            ),
          ),
          content: const Text(
            "You won't get matched jobs",
            style: TextStyle(
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
                'Continue',
                style: TextStyle(
                  color: Color(0xFFB3261E),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    isSaving.value = true;
    try {
      final response = await _repository.save(ids);
      final message = response.text.isNotEmpty
          ? response.text
          : (isOnboarding ? 'Skills saved.' : 'Skills updated.');

      if (isOnboarding) {
        Get.offAllNamed(AppRoutes.home);
        AppSnackbar.info(
          'Go online from Home to start receiving job offers.',
        );
      } else {
        Get.back(result: true);
        AppSnackbar.success(message);
      }
    } on ApiException catch (e) {
      AppSnackbar.error(e.message);
    } catch (_) {
      AppSnackbar.error('Failed to save skills.');
    } finally {
      isSaving.value = false;
    }
  }
}
