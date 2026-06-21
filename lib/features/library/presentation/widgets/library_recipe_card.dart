import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/widgets/images/app_remote_or_asset_image.dart';
import '../../../../core/widgets/media/app_recipe_media.dart';
import '../../../meal_plan/domain/entities/meal_calorie_guidance.dart';
import '../../domain/entities/library_recipe.dart';

// Shows a compact recipe summary card for library grids, favourite lists, and meal-plan selection.
class LibraryRecipeCard extends StatelessWidget {
  final LibraryRecipe recipe;
  final VoidCallback onTap;
  final VoidCallback onComingSoonTap;
  final VoidCallback onFavouriteTap;
  final VoidCallback? onImageLongPress;
  final bool isHighlighted;
  final bool disabled;
  final MealCalorieGuidance? calorieGuidance;

  const LibraryRecipeCard({
    super.key,
    required this.recipe,
    required this.onTap,
    required this.onComingSoonTap,
    required this.onFavouriteTap,
    this.onImageLongPress,
    this.isHighlighted = false,
    this.disabled = false,
    this.calorieGuidance,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = context.text;
    final colors = context.colors;

    // Uses a stronger shadow when the card is focused after returning from recipe detail navigation.
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(8),
      elevation: isHighlighted ? 6 : 3,
      shadowColor: isHighlighted
          ? colors.primary.withValues(alpha: 0.24)
          : Colors.black.withValues(alpha: 0.18),
      child: InkWell(
        // Disables card opening when the recipe has already been added to the active meal plan.
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Opacity(
          // Fades disabled cards while keeping the recipe information visible.
          opacity: disabled ? 0.48 : 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                color: isHighlighted ? colors.primary : AppColors.border,
                width: isHighlighted ? 1.6 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      GestureDetector(
                        // Allows long-press media preview without changing the normal card tap behavior.
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
                      Positioned(
                        left: 8,
                        top: 8,
                        // Shows total recipe views in the image overlay.
                        child: _ViewsBadge(count: recipe.totalViews),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        // Toggles the saved recipe state from the image overlay.
                        child: _ImageIconButton(
                          icon: recipe.isFollowingAuthor
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: recipe.isFollowingAuthor
                              ? AppColors.favourite
                              : Colors.white,
                          onTap: onFavouriteTap,
                        ),
                      ),
                      Positioned(
                        left: 8,
                        bottom: 8,
                        // Labels the recipe as public, private, or favourite.
                        child: _StatusBadge(recipe: recipe),
                      ),
                      if (calorieGuidance != null)
                        Positioned(
                          right: 8,
                          bottom: 8,
                          // Displays meal-plan calorie guidance only during meal selection.
                          child: _LibraryCalorieBadge(
                            guidance: calorieGuidance!,
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 20,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  // Keeps long recipe titles from overflowing the card header.
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
                                // Shows rating for public recipes and a placeholder for private recipes.
                                child: _RatingLabel(recipe: recipe),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 5),
                        SizedBox(
                          height: 18,
                          child: Text(
                            // Shows a one-line recipe summary below the title.
                            recipe.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(height: 1.22),
                          ),
                        ),
                        const SizedBox(height: 5),
                        SizedBox(
                          height: 34,
                          child: Row(
                            children: [
                              Container(
                                // Adds a primary color ring around the recipe author avatar.
                                padding: const EdgeInsets.all(1.5),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.primary,
                                    width: 1.4,
                                  ),
                                ),
                                child: _AuthorAvatar(
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
                                      // Displays the recipe creator name beside the avatar.
                                      recipe.author,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      // Shows the formatted published time below the author name.
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
                              _CountWithIcon(
                                icon: Icons.chat_bubble,
                                label: _compactCount(recipe.commentCount),
                                // Opens the placeholder action for comments until comment navigation is available.
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
}

class _AuthorAvatar extends StatelessWidget {
  final String imagePath;

  const _AuthorAvatar({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    // Falls back to a person icon when no author image is available.
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

class _ImageIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ImageIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Provides a circular tap target for overlay actions on top of recipe media.
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

class _StatusBadge extends StatelessWidget {
  final LibraryRecipe recipe;

  const _StatusBadge({required this.recipe});

  @override
  Widget build(BuildContext context) {
    // Chooses the badge text from ownership and publication state.
    final label = recipe.isSelfPublished
        ? recipe.isPublished
              ? 'PUBLIC'
              : 'PRIVATE'
        : 'FAVOURITE';
    final foreground = recipe.isPublished || !recipe.isSelfPublished
        ? AppColors.primary
        : AppColors.error;

    // Uses white overlay styling so the status stays readable on any recipe image.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
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

/// Calorie guidance badge for library recipe cards.
class _LibraryCalorieBadge extends StatelessWidget {
  /// Guidance details for the recipe.
  final MealCalorieGuidance guidance;

  /// Creates a new library calorie badge instance.
  const _LibraryCalorieBadge({required this.guidance});

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
      constraints: const BoxConstraints(maxWidth: 104),
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

class _RatingLabel extends StatelessWidget {
  final LibraryRecipe recipe;

  const _RatingLabel({required this.recipe});

  @override
  Widget build(BuildContext context) {
    // Private recipes do not show a public rating value.
    if (!recipe.isPublished) {
      return SizedBox(
        width: 64,
        child: Align(
          alignment: Alignment.topRight,
          child: Text(
            'No rating',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: context.text.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    // Public recipes display the average rating beside a star icon.
    return SizedBox(
      width: 44,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            recipe.rating.toStringAsFixed(1),
            style: context.text.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 3),
          const Icon(Icons.star, color: AppColors.secondary, size: 20),
        ],
      ),
    );
  }
}

class _ViewsBadge extends StatelessWidget {
  final int count;

  const _ViewsBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    // Displays recipe view count as an image overlay badge.
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

class _CountWithIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CountWithIcon({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Combines a compact count label with a tappable trailing icon.
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

String _compactCount(int value) {
  // Shortens large counts into a compact thousands label.
  if (value >= 1000) {
    final compact = value / 1000;
    return '${compact.toStringAsFixed(compact >= 10 ? 0 : 1)}k';
  }
  return '$value';
}
