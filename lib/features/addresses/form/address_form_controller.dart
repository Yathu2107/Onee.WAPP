import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../../../app_service/network/api_response.dart';
import '../../../common_widgets/app_snackbar.dart';
import '../model/address_models.dart';
import '../repository/address_repository.dart';

class AddressFormController extends GetxController {
  AddressFormController(this._repository);

  final AddressRepository _repository;

  static const LatLng defaultColombo = LatLng(6.9271, 79.8612);

  final formKey = GlobalKey<FormState>();
  final labelController = TextEditingController();
  final addressLineController = TextEditingController();
  final mapController = MapController();

  final isLoading = false.obs;
  final isLocating = false.obs;
  final isDefault = false.obs;
  final markerPoint = defaultColombo.obs;

  SavedAddress? editing;
  bool returnResult = false;

  bool get isEditing => editing != null;

  @override
  void onInit() {
    super.onInit();
    _parseArgs();
  }

  void _parseArgs() {
    final args = Get.arguments;
    if (args is SavedAddress) {
      editing = args;
    } else if (args is Map) {
      final addressArg = args['address'] ?? args['SavedAddress'];
      if (addressArg is SavedAddress) {
        editing = addressArg;
      }
      returnResult = args['returnResult'] == true;
    }

    final current = editing;
    if (current != null) {
      labelController.text = current.label ?? '';
      addressLineController.text = current.addressLine ?? '';
      isDefault.value = current.isDefault;
      if (current.latitude != null && current.longitude != null) {
        markerPoint.value = LatLng(current.latitude!, current.longitude!);
      }
    }
  }

  void onMapTap(TapPosition tapPosition, LatLng point) {
    markerPoint.value = point;
  }

  Future<void> useCurrentLocation() async {
    if (isLocating.value) return;
    isLocating.value = true;
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        AppSnackbar.error('Location services are disabled.');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        AppSnackbar.error('Location permission is required.');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final point = LatLng(position.latitude, position.longitude);
      markerPoint.value = point;
      mapController.move(point, 15);
    } catch (_) {
      AppSnackbar.error('Could not get current location.');
    } finally {
      isLocating.value = false;
    }
  }

  String? validateLabel(String? value) {
    if (value == null || value.trim().isEmpty) return 'Label is required';
    return null;
  }

  String? validateAddressLine(String? value) {
    if (value == null || value.trim().isEmpty) return 'Address is required';
    return null;
  }

  Future<void> submit() async {
    if (isLoading.value) return;
    if (!(formKey.currentState?.validate() ?? false)) return;

    isLoading.value = true;
    try {
      final label = labelController.text.trim();
      final addressLine = addressLineController.text.trim();
      final lat = markerPoint.value.latitude;
      final lng = markerPoint.value.longitude;

      final ApiResponse<SavedAddress> response;
      if (isEditing) {
        response = await _repository.update(
          id: editing!.id,
          label: label,
          addressLine: addressLine,
          latitude: lat,
          longitude: lng,
          isDefault: isDefault.value,
        );
      } else {
        response = await _repository.create(
          label: label,
          addressLine: addressLine,
          latitude: lat,
          longitude: lng,
          isDefault: isDefault.value,
        );
      }

      final saved = response.result;
      final message = response.text.isNotEmpty
          ? response.text
          : (isEditing ? 'Address updated.' : 'Address saved.');

      if (returnResult && saved != null) {
        Get.back(result: saved);
      } else {
        Get.back(result: saved ?? true);
      }
      AppSnackbar.success(message);
    } on ApiException catch (e) {
      AppSnackbar.error(e.message);
    } catch (_) {
      AppSnackbar.error(
        isEditing ? 'Failed to update address.' : 'Failed to save address.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    labelController.dispose();
    addressLineController.dispose();
    mapController.dispose();
    super.onClose();
  }
}
