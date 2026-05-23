import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../domain/entities/library_recipe.dart';

class LibraryRecipeCard extends StatelessWidget {
  final LibraryRecipe recipe;
  final VoidCallback onTap;
  final VoidCallback onComingSoonTap;
  final VoidCallback onFavouriteTap;

  const LibraryRecipeCard({
    super.key,
    required this.recipe,
    required this.onTap,
    required this.onComingSoonTap,
    required this.onFavouriteTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = context.text;
    final colors = context.colors;

    return Material(
      color: colors.surface,
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(
                      color: colors.surfaceContainerHighest,
                      child: _RecipeImage(path: recipe.imagePath),
                    ),
                    Positioned(
                      right: 8,
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
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              recipe.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.titleMedium?.copyWith(
                                height: 1.15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          _RatingLabel(recipe: recipe),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        recipe.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(height: 1.35),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: colors.primary,
                            backgroundImage: _imageProvider(
                              recipe.authorAvatarPath,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  recipe.author,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  recipe.publishedAtLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          _CountWithIcon(
                            icon: Icons.chat_bubble,
                            label: _compactCount(recipe.commentCount),
                            onTap: onComingSoonTap,
                          ),
                          const SizedBox(width: 6),
                          InkResponse(
                            onTap: onFavouriteTap,
                            radius: 18,
                            child: Icon(
                              recipe.isFollowingAuthor
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: recipe.isFollowingAuthor
                                  ? AppColors.favourite
                                  : AppColors.textSecondary,
                              size: 22,
                            ),
                          ),
                        ],
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
        color: Colors.black.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.visibility, size: 13, color: Colors.white),
            const SizedBox(width: 3),
            Text(
              _compactCount(count),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
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
            style: context.text.bodySmall?.copyWith(
              color: AppColors.textSecondary.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(width: 3),
          Icon(
            icon,
            size: 18,
            color: AppColors.textSecondary.withValues(alpha: 0.55),
          ),
        ],
      ),
    );
  }
}

class _RecipeImage extends StatelessWidget {
  final String path;

  const _RecipeImage({required this.path});

  @override
  Widget build(BuildContext context) {
    if (_isNetworkPath(path)) {
      return Image.network(
        path,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const Icon(Icons.image_not_supported),
      );
    }

    return Image.asset(
      path,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
    );
  }
}

ImageProvider _imageProvider(String path) {
  if (_isNetworkPath(path)) return NetworkImage(path);
  return AssetImage(path);
}

bool _isNetworkPath(String path) {
  return path.startsWith('http://') || path.startsWith('https://');
}

String _compactCount(int value) {
  if (value >= 1000) {
    final compact = value / 1000;
    return '${compact.toStringAsFixed(compact >= 10 ? 0 : 1)}k';
  }
  return '$value';
}
