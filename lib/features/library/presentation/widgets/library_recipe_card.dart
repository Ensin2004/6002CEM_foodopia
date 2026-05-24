import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/widgets/images/app_remote_or_asset_image.dart';
import '../../domain/entities/library_recipe.dart';

class LibraryRecipeCard extends StatelessWidget {
  final LibraryRecipe recipe;
  final VoidCallback onTap;
  final VoidCallback onComingSoonTap;
  final VoidCallback onFavouriteTap;
  final bool isHighlighted;

  const LibraryRecipeCard({
    super.key,
    required this.recipe,
    required this.onTap,
    required this.onComingSoonTap,
    required this.onFavouriteTap,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = context.text;
    final colors = context.colors;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(8),
      elevation: isHighlighted ? 6 : 3,
      shadowColor: isHighlighted
          ? colors.primary.withValues(alpha: 0.24)
          : Colors.black.withValues(alpha: 0.18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
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
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8),
                      ),
                      child: ColoredBox(
                        color: colors.surfaceContainerHighest,
                        child: AppRemoteOrAssetImage(
                          imagePath: recipe.imagePath,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
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
                      top: 8,
                      child: _ViewsBadge(count: recipe.totalViews),
                    ),
                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: _StatusBadge(recipe: recipe),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
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
                              child: _RatingLabel(recipe: recipe),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 5),
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
                              child: AppRemoteOrAssetAvatar(
                                radius: 16,
                                backgroundColor: colors.primary,
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
                                      color: AppColors.textSecondary.withValues(
                                        alpha: 0.72,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final LibraryRecipe recipe;

  const _StatusBadge({required this.recipe});

  @override
  Widget build(BuildContext context) {
    final label = recipe.isSelfPublished
        ? recipe.isPublished
              ? 'PUBLIC'
              : 'PRIVATE'
        : 'FAVOURITE';
    final foreground = recipe.isPublished || !recipe.isSelfPublished
        ? AppColors.primary
        : AppColors.error;

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

class _RatingLabel extends StatelessWidget {
  final LibraryRecipe recipe;

  const _RatingLabel({required this.recipe});

  @override
  Widget build(BuildContext context) {
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

String _compactCount(int value) {
  if (value >= 1000) {
    final compact = value / 1000;
    return '${compact.toStringAsFixed(compact >= 10 ? 0 : 1)}k';
  }
  return '$value';
}
