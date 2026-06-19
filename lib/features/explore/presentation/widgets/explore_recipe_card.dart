import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/widgets/images/app_remote_or_asset_image.dart';
import '../../../../core/widgets/media/app_recipe_media.dart';
import '../../../meal_plan/domain/entities/meal_calorie_guidance.dart';
import '../../domain/entities/explore_recipe.dart';

// Displays a single recipe card with image, metadata, author info, and action buttons
class ExploreRecipeCard extends StatelessWidget {
  // The recipe data entity containing all display information
  final ExploreRecipe recipe;
  // Callback when the entire card is tapped (navigation)
  final VoidCallback? onTap;
  // Callback when the comment/chat icon is tapped
  final VoidCallback onComingSoonTap;
  // Callback when the favourite icon is tapped
  final VoidCallback onFavouriteTap;
  // Callback when the image is long-pressed for additional options
  final VoidCallback? onImageLongPress;
  // Flag to disable all interactions and apply visual dimming
  final bool disabled;
  final MealCalorieGuidance? calorieGuidance;

  const ExploreRecipeCard({
    super.key,
    required this.recipe,
    required this.onTap,
    required this.onComingSoonTap,
    required this.onFavouriteTap,
    this.onImageLongPress,
    this.disabled = false,
    this.calorieGuidance,
  });

  @override
  Widget build(BuildContext context) {
    // Retrieves text styles from the context theme extension
    final textTheme = context.text;
    // Retrieves color scheme from the context theme extension
    final colors = context.colors;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(8),
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      child: InkWell(
        // Disables tap interaction when the card is in disabled state
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Opacity(
          // Reduces visual prominence when disabled
          opacity: disabled ? 0.48 : 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image section taking 5/8 of the card height
                Expanded(
                  flex: 5,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Positioned.fill(
                        child: GestureDetector(
                          onLongPress: onImageLongPress,
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(8),
                            ),
                            child: ColoredBox(
                              color: colors.surfaceContainerHighest,
                              child: AppRecipeMediaPreview(
                                mediaPath: recipe.imagePath,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Favourite button positioned in top-right corner
                      Positioned(
                        top: 6,
                        right: 6,
                        child: disabled
                            ? const _AlreadyAddedBadge()
                            : _ImageIconButton(
                          icon: recipe.isFavourite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: recipe.isFavourite
                              ? AppColors.favourite
                              : Colors.white,
                          onTap: onFavouriteTap,
                        ),
                      ),
                      // Views badge positioned in top-left corner
                      Positioned(
                        left: 8,
                        top: 8,
                        child: _ViewsBadge(count: recipe.totalViews),
                      ),
                      if (calorieGuidance != null)
                        Positioned(
                          left: 8,
                          bottom: 8,
                          child: _ExploreCalorieBadge(
                            guidance: calorieGuidance!,
                          ),
                        ),
                    ],
                  ),
                ),
                // Metadata section taking 3/8 of the card height
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title row with rating display
                        SizedBox(
                          height: 20,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  recipe.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.labelLarge?.copyWith(
                                    color: colors.onSurface,
                                    height: 1.15,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Padding(
                                padding: const EdgeInsets.only(top: 1),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      recipe.rating.toStringAsFixed(1),
                                      style: textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    const Icon(
                                      Icons.star,
                                      size: 18,
                                      color: AppColors.secondary,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 5),
                        // Description line with ellipsis for overflow
                        SizedBox(
                          height: 18,
                          child: Text(
                            recipe.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(height: 1.22),
                          ),
                        ),
                        const SizedBox(height: 5),
                        // Author info row with avatar, name, date, and comment count
                        SizedBox(
                          height: 34,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(1.5),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.primary,
                                    width: 1.4,
                                  ),
                                ),
                                child: _ExploreAuthorAvatar(
                                  imagePath: recipe.authorAvatarPath,
                                ),
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      recipe.author,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      recipe.publishedAtLabel,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary
                                            .withValues(alpha: 0.72),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Comment count with chat bubble icon
                              _CountWithIcon(
                                icon: Icons.chat_bubble,
                                label: _compactCount(recipe.commentCount),
                                onTap: onComingSoonTap,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Formats a number into compact notation (e.g., 1.2k, 10k)
  String _compactCount(int value) {
    if (value >= 1000) {
      final compact = value / 1000;
      return '${compact.toStringAsFixed(compact >= 10 ? 0 : 1)}k';
    }
    return '$value';
  }
}

// Displays an "Added" badge indicating the recipe is already in the collection
/// Calorie guidance badge for explore recipe cards.
class _ExploreCalorieBadge extends StatelessWidget {
  /// Guidance details for the recipe.
  final MealCalorieGuidance guidance;

  /// Creates a new explore calorie badge instance.
  const _ExploreCalorieBadge({required this.guidance});

  @override
  Widget build(BuildContext context) {
    // Badge color follows the shared calorie guidance status.
    final foreground = switch (guidance.status) {
      MealCalorieGuidanceStatus.exceeds => const Color(0xFFE2762D),
      MealCalorieGuidanceStatus.nearTarget => AppColors.secondary,
      MealCalorieGuidanceStatus.fits => AppColors.primary,
      MealCalorieGuidanceStatus.unknown => AppColors.textSecondary,
    };

    return Container(
      constraints: const BoxConstraints(maxWidth: 116),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        guidance.badgeLabel,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.text.bodySmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _AlreadyAddedBadge extends StatelessWidget {
  const _AlreadyAddedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.64),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Added',
        style: context.text.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// Renders the author's avatar image or a fallback person icon
class _ExploreAuthorAvatar extends StatelessWidget {
  // Path to the author's avatar image asset or URL
  final String imagePath;

  const _ExploreAuthorAvatar({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    // Checks if the image path contains any visible characters
    final hasImage = imagePath.trim().isNotEmpty;

    return CircleAvatar(
      radius: 16,
      backgroundColor: Colors.white,
      child: hasImage
          ? ClipOval(
        child: AppRemoteOrAssetImage(
          imagePath: imagePath,
          width: 32,
          height: 32,
        ),
      )
          : const Icon(Icons.person, color: AppColors.primary, size: 20),
    );
  }
}

// Circular icon button with semi-transparent background overlay
class _ImageIconButton extends StatelessWidget {
  // The icon to display (favorite or favorite_border)
  final IconData icon;
  // Color of the icon
  final Color color;
  // Callback when the button is tapped
  final VoidCallback onTap;

  const _ImageIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.58),
      shape: const CircleBorder(),
      child: InkResponse(
        onTap: onTap,
        radius: 19,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}

// Displays the view count with an eye icon in a rounded badge
class _ViewsBadge extends StatelessWidget {
  // Total view count to display
  final int count;

  const _ViewsBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.visibility, size: 16, color: AppColors.primary),
            const SizedBox(width: 5),
            Text(
              _compactCount(count),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Displays a count with an icon and handles tap interactions
class _CountWithIcon extends StatelessWidget {
  // The icon to display next to the count
  final IconData icon;
  // The formatted count label text
  final String label;
  // Callback when the count/icon area is tapped
  final VoidCallback onTap;

  const _CountWithIcon({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 18,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.labelMedium?.copyWith(
              color: AppColors.textSecondary.withValues(alpha: 0.72),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            icon,
            size: 20,
            color: AppColors.textSecondary.withValues(alpha: 0.55),
          ),
        ],
      ),
    );
  }
}

// Formats a numeric value into a compact string with 'k' suffix for thousands
String _compactCount(int value) {
  if (value >= 1000) {
    final compact = value / 1000;
    return '${compact.toStringAsFixed(compact >= 10 ? 0 : 1)}k';
  }
  return '$value';
}