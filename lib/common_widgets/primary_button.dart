import 'package:flutter/material.dart';

import '../app/theme/app_colors.dart';
import 'onee_loader.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final canTap = enabled && !isLoading && onPressed != null;

    return AnimatedScale(
      scale: canTap ? 1 : 0.98,
      duration: const Duration(milliseconds: 150),
      child: ElevatedButton(
        onPressed: canTap ? onPressed : null,
        style: ElevatedButton.styleFrom(
          disabledBackgroundColor: AppColors.gold.withValues(alpha: 0.45),
          disabledForegroundColor: AppColors.nearBlack.withValues(alpha: 0.5),
        ),
        child: isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: OneeLoader(size: 22),
              )
            : Text(label),
      ),
    );
  }
}
