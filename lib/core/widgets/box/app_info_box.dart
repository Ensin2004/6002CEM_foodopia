import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../theme/theme_extension.dart';

/// Information box widget for displaying status messages.
/// Used for weather, tips, and informational content.
class AppInfoBox extends StatelessWidget {
  /// Icon to display.
  final IconData icon;

  /// Title text.
  final String title;

  /// Message text.
  final String message;

  /// Background color of the box.
  final Color backgroundColor;

  /// Background color of the icon container.
  final Color iconBackgroundColor;

  /// Color of the icon and border.
  final Color iconColor;

  /// Creates a new app info box instance.
  const AppInfoBox({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.backgroundColor,
    required this.iconBackgroundColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: iconColor.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          // Icon container.
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBackgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),

          // Text content.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.text.bodyMedium),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: context.text.bodySmall?.copyWith(
                    color: iconColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}