import 'package:flutter/material.dart';

import '../../../../core/theme/theme_extension.dart';
import '../../domain/entities/admin_home_dashboard.dart';

/// Feedback card widget for the admin home page.
/// Displays user feedback with rating and comment.
class AdminFeedbackCard extends StatelessWidget {
  /// The feedback item to display.
  final AdminFeedbackItem feedback;

  /// Creates a new admin feedback card instance.
  const AdminFeedbackCard({super.key, required this.feedback});

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
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFFFF1C2),
            child: Text(
              feedback.initials,
              style: context.text.titleSmall?.copyWith(
                color: const Color(0xFFFFA000),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Feedback content.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User name.
                Text(
                  feedback.userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.titleSmall?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),

                // Star rating.
                _RatingStars(rating: feedback.rating),
                const SizedBox(height: 6),

                // Comment.
                Text(
                  feedback.comment,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall?.copyWith(
                    color: context.colors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),

                // Time ago.
                Text(feedback.timeAgo, style: context.text.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Star rating display widget.
class _RatingStars extends StatelessWidget {
  /// The rating value.
  final double rating;

  /// Creates a new rating stars instance.
  const _RatingStars({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < rating.round() ? Icons.star : Icons.star_border,
          color: const Color(0xFFFFC107),
          size: 15,
        );
      }),
    );
  }
}