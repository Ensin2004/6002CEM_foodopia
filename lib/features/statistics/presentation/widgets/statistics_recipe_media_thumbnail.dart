// These notes explain the statistics page code in simple words.
// Only comments were added here; the code behaviour stays the same.
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/media/app_recipe_media.dart';

/// Circular, non-interactive recipe media used throughout statistics views.
// Handles StatisticsRecipeMediaThumbnail for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class StatisticsRecipeMediaThumbnail extends StatelessWidget {
  final String? mediaPath;
  final IconData fallbackIcon;
  final double size;
  final Color backgroundColor;
  final Color iconColor;
  final Color? borderColor;

  // Handles StatisticsRecipeMediaThumbnail for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  const StatisticsRecipeMediaThumbnail({
    super.key,
    required this.mediaPath,
    required this.fallbackIcon,
    required this.size,
    this.backgroundColor = const Color(0xFFEAF8F0),
    this.iconColor = AppColors.primary,
    this.borderColor,
  });

  // Handles build for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  @override
  Widget build(BuildContext context) {
    final path = mediaPath?.trim() ?? '';

    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: borderColor == null ? null : Border.all(color: borderColor!),
      ),
      child: path.isEmpty
          ? Icon(fallbackIcon, color: iconColor, size: size * 0.56)
          : AppRecipeMediaPreview(
              mediaPath: path,
              fit: BoxFit.cover,
              showPlayOverlay: false,
            ),
    );
  }
}
