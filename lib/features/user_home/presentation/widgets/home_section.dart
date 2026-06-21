import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extension.dart';

/// Section widget for the home page.
/// Displays a title with a child widget below.
class HomeSection extends StatelessWidget {
  /// Title of the section.
  final String title;

  /// Child widget to display below the title.
  final Widget child;

  /// Creates a new home section instance.
  const HomeSection({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.pagePadding.copyWith(
        top: AppSpacing.sm,
        bottom: AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title.
          Text(
            title,
            style: context.text.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Child content.
          child,
        ],
      ),
    );
  }
}