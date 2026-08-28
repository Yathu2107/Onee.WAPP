import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../app/theme/app_colors.dart';

/// Circular profile photo with network loading and a local fallback asset.
class ProfileImageAvatar extends StatelessWidget {
  const ProfileImageAvatar({
    super.key,
    this.imageUrl,
    required this.size,
    this.borderColor,
    this.borderWidth = 1.5,
    this.defaultAsset = 'assets/images/default_worker.png',
  });

  final String? imageUrl;
  final double size;
  final Color? borderColor;
  final double borderWidth;
  final String defaultAsset;

  @override
  Widget build(BuildContext context) {
    final hasNetwork =
        imageUrl != null && imageUrl!.trim().isNotEmpty;
    final border = borderColor ?? AppColors.gold.withValues(alpha: 0.5);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: border, width: borderWidth),
      ),
      child: ClipOval(
        child: hasNetwork
            ? CachedNetworkImage(
                imageUrl: imageUrl!.trim(),
                fit: BoxFit.cover,
                width: size,
                height: size,
                placeholder: (_, _) => Image.asset(
                  defaultAsset,
                  fit: BoxFit.cover,
                  width: size,
                  height: size,
                ),
                errorWidget: (_, _, _) => Image.asset(
                  defaultAsset,
                  fit: BoxFit.cover,
                  width: size,
                  height: size,
                ),
              )
            : Image.asset(
                defaultAsset,
                fit: BoxFit.cover,
                width: size,
                height: size,
              ),
      ),
    );
  }
}
