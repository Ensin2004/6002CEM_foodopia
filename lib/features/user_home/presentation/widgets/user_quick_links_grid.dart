import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../domain/entities/user_home_dashboard.dart';

/// Grid of quick links for the user home page.
/// Displays clickable tiles with icons and labels.
class UserQuickLinksGrid extends StatelessWidget {
  /// List of quick links to display.
  final List<UserHomeQuickLink> links;

  /// Callback when a link is tapped.
  final ValueChanged<UserHomeQuickLinkTarget> onLinkTap;

  /// Creates a new user quick links grid instance.
  const UserQuickLinksGrid({
    super.key,
    required this.links,
    required this.onLinkTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: links.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        childAspectRatio: 1.02,
      ),
      itemBuilder: (context, index) {
        // Get the link at the current index.
        final link = links[index];

        return InkWell(
          onTap: () => onLinkTap(link.target),
          borderRadius: BorderRadius.circular(8),
          child: Ink(
            decoration: BoxDecoration(
              color: const Color(0xFFF0F8F2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon.
                  Icon(link.icon, color: context.colors.primary, size: 28),
                  const SizedBox(height: AppSpacing.sm),

                  // Title.
                  Text(
                    link.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.labelMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}