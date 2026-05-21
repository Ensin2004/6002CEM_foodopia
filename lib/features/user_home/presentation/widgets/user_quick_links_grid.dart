import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../domain/entities/user_home_dashboard.dart';

class UserQuickLinksGrid extends StatelessWidget {
  final List<UserHomeQuickLink> links;
  final ValueChanged<UserHomeQuickLinkTarget> onLinkTap;

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
                  Icon(link.icon, color: context.colors.primary, size: 28),
                  const SizedBox(height: AppSpacing.sm),
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
