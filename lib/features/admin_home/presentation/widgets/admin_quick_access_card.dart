import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../domain/entities/admin_home_dashboard.dart';

/// Quick access card widget for the admin home page.
/// Displays a navigation shortcut with icon and description.
class AdminQuickAccessCard extends StatelessWidget {
  /// The quick access item to display.
  final AdminQuickAccessItem item;

  /// Called when the shortcut is tapped.
  final VoidCallback? onTap;

  /// Creates a new admin quick access card instance.
  const AdminQuickAccessCard({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF1FAF4),
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon.
              Icon(item.icon, color: context.colors.primary, size: 24),
              const SizedBox(height: AppSpacing.sm),

              // Title.
              Text(
                item.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.text.titleSmall?.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
