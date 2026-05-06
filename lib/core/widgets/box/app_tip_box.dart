import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../theme/theme_extension.dart';

/// Reusable tip/info box for guidance inside forms and admin screens.
class AppTipBox extends StatelessWidget {
  final String title;
  final String message;
  final Color backgroundColor;
  final Color iconColor;
  final IconData icon;

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
          Icon(icon, color: iconColor, size: 30),
          const SizedBox(width: AppSpacing.md),
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
