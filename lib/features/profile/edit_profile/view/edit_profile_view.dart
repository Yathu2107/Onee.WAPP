import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../common_widgets/onee_loader.dart';
import '../../../../common_widgets/primary_button.dart';
import '../controller/edit_profile_controller.dart';

class EditProfileView extends GetView<EditProfileController> {
  const EditProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: OneeLoader());
        }

        return Form(
          key: controller.formKey,
          child: Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: _EditProfileHero(onBack: () => Get.back()),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const _ProfilePhotoPicker(),
                            const SizedBox(height: 28),
                            const _FieldLabel('Full name'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: controller.nameController,
                              textInputAction: TextInputAction.next,
                              textCapitalization: TextCapitalization.words,
                              validator: controller.validateName,
                              decoration: const InputDecoration(
                                hintText: 'Your name',
                                prefixIcon: Icon(Icons.person_outline_rounded),
                              ),
                            ),
                            const SizedBox(height: 18),
                            const _FieldLabel('Email'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: controller.emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              validator: controller.validateEmail,
                              decoration: const InputDecoration(
                                hintText: 'you@email.com',
                                prefixIcon: Icon(Icons.mail_outline_rounded),
                              ),
                            ),
                            const SizedBox(height: 18),
                            const _FieldLabel('Mobile number'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: controller.phoneController,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.done,
                              maxLength: 10,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                              validator: controller.validatePhone,
                              decoration: const InputDecoration(
                                hintText: '07XXXXXXXX',
                                prefixIcon: Icon(Icons.smartphone_rounded),
                                counterText: '',
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                  child: Obx(
                    () => PrimaryButton(
                      label: 'Save changes',
                      isLoading: controller.isSaving.value,
                      onPressed: controller.submit,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _EditProfileHero extends StatelessWidget {
  const _EditProfileHero({required this.onBack});

  final VoidCallback onBack;

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
        padding: EdgeInsets.fromLTRB(16, top + 8, 24, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              color: AppColors.nearBlack,
            ),
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Edit profile',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: AppColors.nearBlack,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Keep your details up to date for customers.',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.mutedBrown,
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

class _ProfilePhotoPicker extends GetView<EditProfileController> {
  const _ProfilePhotoPicker();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final local = controller.imagePath.value;
      final remote = controller.existingImageUrl.value;

      Widget avatar;
      if (local != null && local.isNotEmpty) {
        avatar = Image.file(File(local), fit: BoxFit.cover);
      } else if (remote != null && remote.isNotEmpty) {
        avatar = CachedNetworkImage(
          imageUrl: remote,
          fit: BoxFit.cover,
          placeholder: (context, url) =>
              const Center(child: OneeLoader(size: 22)),
          errorWidget: (context, url, error) => Image.asset(
            'assets/images/default_worker.png',
            fit: BoxFit.cover,
          ),
        );
      } else {
        avatar = Image.asset(
          'assets/images/default_worker.png',
          fit: BoxFit.cover,
        );
      }

      return Column(
        children: [
          GestureDetector(
            onTap: controller.pickImage,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.gold, width: 2.5),
              ),
              clipBehavior: Clip.antiAlias,
              child: avatar,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: controller.pickImage,
                child: const Text(
                  'Change photo',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.nearBlack,
                  ),
                ),
              ),
              if (local != null || (remote != null && remote.isNotEmpty))
                TextButton(
                  onPressed: controller.clearImage,
                  child: const Text(
                    'Remove',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.mutedBrown,
                    ),
                  ),
                ),
            ],
          ),
        ],
      );
    });
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
