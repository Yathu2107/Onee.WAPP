import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app_service/network/api_response.dart';
import '../../../common_widgets/app_snackbar.dart';
import '../model/address_models.dart';
import '../repository/address_repository.dart';

class AddressesController extends GetxController {
  AddressesController(this._repository);

  final AddressRepository _repository;

  final isLoading = false.obs;
  final isBusy = false.obs;
  final addresses = <SavedAddress>[].obs;
  final error = RxnString();

  @override
  void onReady() {
    super.onReady();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = null;
    try {
      final response = await _repository.list();
      addresses.assignAll(response.result ?? <SavedAddress>[]);
    } on ApiException catch (e) {
      error.value = e.message;
      AppSnackbar.error(e.message);
    } catch (_) {
      error.value = 'Failed to load addresses.';
      AppSnackbar.error('Failed to load addresses.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshList() => load();

  Future<void> setDefault(SavedAddress address) async {
    if (isBusy.value) return;
    isBusy.value = true;
    try {
      final response = await _repository.setDefault(address.id);
      AppSnackbar.success(
        response.text.isNotEmpty ? response.text : 'Default address updated.',
      );
      await load();
    } on ApiException catch (e) {
      AppSnackbar.error(e.message);
    } catch (_) {
      AppSnackbar.error('Failed to set default address.');
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> deleteAddress(SavedAddress address) async {
    if (isBusy.value) return;
    isBusy.value = true;
    try {
      final response = await _repository.delete(address.id);
      AppSnackbar.success(
        response.text.isNotEmpty ? response.text : 'Address deleted.',
      );
      addresses.removeWhere((a) => a.id == address.id);
    } on ApiException catch (e) {
      AppSnackbar.error(e.message);
    } catch (_) {
      AppSnackbar.error('Failed to delete address.');
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> goAdd() async {
    final result = await Get.toNamed(AppRoutes.addressForm);
    if (result != null) await load();
  }

  Future<void> goEdit(SavedAddress address) async {
    final result = await Get.toNamed(
      AppRoutes.addressForm,
      arguments: address,
    );
    if (result != null) await load();
  }
}
