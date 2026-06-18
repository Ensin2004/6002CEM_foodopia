import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../theme/theme_extension.dart';

/// Reusable tip/info box for guidance inside forms and admin screens.
class AppTipBox extends StatelessWidget {
  /// Title of the tip.
  final String title;

  /// Message content.
  final String message;

  /// Background color of the box.
  final Color backgroundColor;

  /// Color of the icon.
  final Color iconColor;

  /// Icon to display.
  final IconData icon;

  /// Creates a new app tip box instance.
  const AppTipBox({
    super.key,
    this.title = 'Tip',
    required this.message,
    required this.backgroundColor,
    required this.iconColor,
    this.icon = Icons.lightbulb_outline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Icon.
          Icon(icon, color: iconColor, size: 30),
          const SizedBox(width: AppSpacing.md),

          // Text content.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.text.titleMedium),
                const SizedBox(height: 2),
                Text(message, style: context.text.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}