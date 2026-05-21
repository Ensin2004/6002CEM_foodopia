import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';

class AddMoreButtonSmall extends StatelessWidget {
  final VoidCallback onPressed;

  const AddMoreButtonSmall({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.only(top: AppSpacing.xs),
        ),
        label: const Text("+  Add more"),
      ),
    );
  }
}
