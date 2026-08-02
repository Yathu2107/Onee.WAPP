import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../common_widgets/primary_button.dart';
import 'address_form_controller.dart';

class AddressFormView extends GetView<AddressFormController> {
  const AddressFormView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(controller.isEditing ? 'Edit Address' : 'Add Address'),
      ),
      body: SafeArea(
        child: Form(
          key: controller.formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _MapHero(controller: controller),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Details',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.nearBlack,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Name this place and confirm the pin on the map.',
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.4,
                                color: AppColors.mutedBrown.withValues(
                                  alpha: 0.95,
                                ),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 18),
                            const _FieldLabel('Label'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: controller.labelController,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              validator: controller.validateLabel,
                              decoration: const InputDecoration(
                                hintText: 'Home, Workshop, …',
                                prefixIcon: Icon(Icons.label_outline_rounded),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const _FieldLabel('Address line'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: controller.addressLineController,
                              textCapitalization:
                                  TextCapitalization.sentences,
                              textInputAction: TextInputAction.done,
                              maxLines: 2,
                              validator: controller.validateAddressLine,
                              decoration: const InputDecoration(
                                hintText: 'Street, city, landmarks…',
                                prefixIcon: Icon(Icons.home_outlined),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Obx(
                              () => _DefaultToggle(
                                value: controller.isDefault.value,
                                onChanged: (v) =>
                                    controller.isDefault.value = v,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Obx(() {
                              final p = controller.markerPoint.value;
                              return Text(
                                'Pin · ${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.mutedBrown,
                                ),
                              );
                            }),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
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
                child: Obx(
                  () => PrimaryButton(
                    label: controller.isEditing
                        ? 'Update address'
                        : 'Save address',
                    isLoading: controller.isLoading.value,
                    onPressed: controller.submit,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapHero extends StatelessWidget {
  const _MapHero({required this.controller});

  final AddressFormController controller;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          height: 260,
          width: double.infinity,
          child: Obx(() {
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
        ),
        Positioned(
          top: 12,
          right: 12,
          child: Obx(
            () => Material(
              color: AppColors.white,
              elevation: 2,
              shadowColor: AppColors.nearBlack.withValues(alpha: 0.12),
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
                        'My location',
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
        const Positioned(
          left: 16,
          bottom: 16,
          child: Text(
            'Tap map to move pin',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.mutedBrown,
            ),
          ),
        ),
      ],
    );
  }
}

class _DefaultToggle extends StatelessWidget {
  const _DefaultToggle({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cream.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Set as default address',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.nearBlack,
                fontSize: 14,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.gold,
            activeTrackColor: AppColors.gold.withValues(alpha: 0.45),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.nearBlack,
      ),
    );
  }
}
