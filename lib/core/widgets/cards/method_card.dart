import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/theme_extension.dart';

/// Method card widget for selecting options.
/// Used for recipe creation methods and other selection flows.
class MethodCard extends StatelessWidget {
  /// Icon to display.
  final IconData icon;

  /// Title text.
  final String title;

  /// Subtitle description.
  final String subtitle;

  /// Callback when the card is tapped.
  final VoidCallback onTap;

  /// Creates a new method card instance.
  const MethodCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 220),
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: AppColors.border,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon.
            Icon(icon, size: 72, color: const Color(0xFFC9CBCD)),
            const SizedBox(height: AppSpacing.md),

            // Title.
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.text.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),

            // Subtitle.
            Text(
              subtitle,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: context.text.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}