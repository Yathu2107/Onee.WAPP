import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';

import '../../app/theme/app_colors.dart';
import '../../common_widgets/primary_button.dart';
import 'set_location_controller.dart';

class SetLocationView extends GetView<SetLocationController> {
  const SetLocationView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(title: const Text('Set location')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Obx(() {
                    final point = controller.markerPoint.value;
                    return FlutterMap(
                      mapController: controller.mapController,
                      options: MapOptions(
                        initialCenter: point,
                        initialZoom: 14,
                        onTap: controller.onMapTap,
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
                              width: 48,
                              height: 48,
                              alignment: Alignment.topCenter,
                              child: const Icon(
                                Icons.location_on_rounded,
                                color: AppColors.gold,
                                size: 48,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Obx(
                      () => Material(
                        color: AppColors.white,
                        elevation: 2,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          onTap: controller.isLocating.value
                              ? null
                              : controller.useCurrentLocation,
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (controller.isLocating.value)
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.gold,
                                    ),
                                  )
                                else
                                  const Icon(
                                    Icons.my_location_rounded,
                                    size: 18,
                                    color: AppColors.gold,
                                  ),
                                const SizedBox(width: 8),
                                const Text(
                                  'GPS',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.nearBlack,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Obx(() {
                final p = controller.markerPoint.value;
                return Text(
                  '${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mutedBrown,
                  ),
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Obx(
                () => PrimaryButton(
                  label: 'Save location',
                  isLoading: controller.isSaving.value,
                  onPressed: controller.save,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
