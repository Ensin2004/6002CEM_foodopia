import 'package:flutter/material.dart';

import '../../../../core/theme/theme_extension.dart';
import '../../domain/entities/admin_home_dashboard.dart';

/// Review card widget for the admin home page.
/// Displays a pending review with user info, title, and badge.
class AdminReviewCard extends StatelessWidget {
  /// The pending review to display.
  final AdminPendingReview review;

  /// Creates a new admin review card instance.
  const AdminReviewCard({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User avatar with initials.
          _InitialAvatar(initials: review.initials),
          const SizedBox(width: 10),

          // Review content.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // User name.
                    Expanded(
                      child: Text(
                        review.userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.titleSmall?.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    // Status badge.
                    _Badge(text: review.badge),
                  ],
                ),
                const SizedBox(height: 6),

                // Title.
                Text(
                  review.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall?.copyWith(
                    color: context.colors.onSurface,
                  ),
                ),
                const SizedBox(height: 10),

                // Time ago.
                Text(review.timeAgo, style: context.text.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// User avatar with initials.
class _InitialAvatar extends StatelessWidget {
  /// User initials.
  final String initials;

  /// Creates a new initial avatar instance.
  const _InitialAvatar({required this.initials});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 22,
      backgroundColor: const Color(0xFFFFF1C2),
      child: Text(
        initials,
        style: context.text.titleSmall?.copyWith(
          color: const Color(0xFFFFA000),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Status badge widget.
class _Badge extends StatelessWidget {
  /// Badge text.
  final String text;

  /// Creates a new badge instance.
  const _Badge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE69A),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        style: context.text.bodySmall?.copyWith(
          color: const Color(0xFFFFA000),
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}