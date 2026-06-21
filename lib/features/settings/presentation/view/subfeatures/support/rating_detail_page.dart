import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../../core/widgets/custom_app_bar.dart';
import '../../../../domain/entities/rating.dart';
import '../../../../domain/entities/user_profile.dart';

/// Page for displaying detailed information about a rating.
/// Shows user info, star rating, feedback, and timestamp.
class RatingDetailPage extends StatelessWidget {
  /// The rating entity to display.
  final RatingEntity rating;

  /// The user profile of the person who submitted the rating.
  final UserProfile? userProfile;

  /// Creates a new rating detail page instance.
  const RatingDetailPage({super.key, required this.rating, this.userProfile});

  @override
  Widget build(BuildContext context) {
    // Get the theme for styling.
    final theme = Theme.of(context);

    // Get display name from user profile or fallback to user ID.
    final displayName = userProfile?.name ?? rating.userId;

    // Get profile image URL.
    final profileImageUrl = userProfile?.profileImageUrl;

    // Get trimmed feedback.
    final feedback = rating.comment.trim();

    return Scaffold(
      appBar: const CustomAppBar(title: 'Rating Details', centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary card with rating and date.
              _buildSummaryCard(context, displayName),
              const SizedBox(height: 16),

              // User section.
              _buildSectionCard(
                context: context,
                title: 'Submitted by',
                icon: Icons.person_outline_rounded,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: profileImageUrl != null
                          ? NetworkImage(profileImageUrl)
                          : null,
                      backgroundColor: theme.colorScheme.primary.withValues(
                        alpha: 0.12,
                      ),
                      child: profileImageUrl == null
                          ? Icon(
                        Icons.person_outline_rounded,
                        color: theme.colorScheme.primary,
                      )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        displayName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Feedback section.
              _buildSectionCard(
                context: context,
                title: 'Feedback',
                icon: Icons.chat_bubble_outline_rounded,
                child: Text(
                  feedback.isEmpty ? 'No feedback provided.' : feedback,
                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // WIDGET BUILDERS
  // =========================================================================

  /// Builds the summary card with rating and date.
  Widget _buildSummaryCard(BuildContext context, String displayName) {
    // Get the theme for styling.
    final theme = Theme.of(context);

    // Format the update date.
    final formattedDate = DateFormat(
      'MMM dd, yyyy - hh:mm a',
    ).format(rating.updatedAt);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6E9EE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with star icon and rating score.
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.star_rounded,
                  color: Colors.amber.shade700,
                  size: 28,
                ),
              ),
              const Spacer(),
              Text(
                '${rating.stars}/5',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Rating source.
          Text(
            'Rating from $displayName',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),

          // Timestamp.
          _buildMetaLine(
            context,
            icon: Icons.calendar_today_outlined,
            text: formattedDate,
          ),
          const SizedBox(height: 14),

          // Star rating display.
          _buildStarRating(rating.stars, size: 28),
        ],
      ),
    );
  }

  /// Builds a section card with title and content.
  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    // Get the theme for styling.
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6E9EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and title.
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: theme.colorScheme.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  /// Builds a meta line with icon and text.
  Widget _buildMetaLine(
      BuildContext context, {
        required IconData icon,
        required String text,
      }) {
    // Get the theme for styling.
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          icon,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
          size: 17,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  /// Builds a star rating display.
  Widget _buildStarRating(int filledStars, {double size = 24}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
            (index) => Icon(
          index < filledStars ? Icons.star_rounded : Icons.star_border_rounded,
          color: Colors.amber.shade700,
          size: size,
        ),
      ),
    );
  }
}