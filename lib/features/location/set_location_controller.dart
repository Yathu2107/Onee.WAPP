import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../../app_service/network/api_response.dart';
import '../../common_widgets/app_snackbar.dart';
import '../auth/repository/auth_repository.dart';

class SetLocationController extends GetxController {
  SetLocationController(this._authRepository);

  final AuthRepository _authRepository;

  static const LatLng defaultColombo = LatLng(6.9271, 79.8612);

  final mapController = MapController();
  final markerPoint = defaultColombo.obs;
  final isLocating = false.obs;
  final isSaving = false.obs;

  @override
  void onReady() {
    super.onReady();
    _seedFromProfile();
  }

  Future<void> _seedFromProfile() async {
    try {
      final response = await _authRepository.getLoggedWorkerDetails();
      final lat = response.result?.latitude;
      final lng = response.result?.longitude;
      if (lat != null && lng != null) {
        final point = LatLng(lat, lng);
        markerPoint.value = point;
        mapController.move(point, 15);
      }
    } catch (_) {}
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

  Future<void> save() async {
    if (isSaving.value) return;
    isSaving.value = true;
    try {
      final response = await _authRepository.setLocation(
        latitude: markerPoint.value.latitude,
        longitude: markerPoint.value.longitude,
      );
      Get.back(result: true);
      AppSnackbar.success(
        response.text.isNotEmpty ? response.text : 'Location updated.',
      );
    } on ApiException catch (e) {
      AppSnackbar.error(e.message);
    } catch (_) {
      AppSnackbar.error('Failed to update location.');
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    mapController.dispose();
    super.onClose();
  }
}
