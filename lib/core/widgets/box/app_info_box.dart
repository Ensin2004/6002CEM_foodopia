import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../theme/theme_extension.dart';

class AppInfoBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Color backgroundColor;
  final Color iconBackgroundColor;
  final Color iconColor;

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
