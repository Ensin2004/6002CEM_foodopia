import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/widgets/images/app_remote_or_asset_image.dart';
import '../../domain/entities/explore_recipe.dart';

class ExploreRecipeCard extends StatelessWidget {
  final ExploreRecipe recipe;
  final VoidCallback onTap;
  final VoidCallback onComingSoonTap;
  final VoidCallback? onImageLongPress;

  const ExploreRecipeCard({
    super.key,
    required this.recipe,
    required this.onTap,
    required this.onComingSoonTap,
    this.onImageLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = context.text;
    final colors = context.colors;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(8),
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 92,
                width: double.infinity,
                child: Stack(
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
                            child: AppRemoteOrAssetImage(
                              imagePath: recipe.imagePath,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.58),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.visibility,
                                size: 13,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                _compactCount(recipe.totalViews),
                                style: textTheme.labelSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 34,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                recipe.title,
                                maxLines: 2,
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
                      SizedBox(
                        height: 28,
                        child: Text(
                          recipe.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(height: 1.22),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 36,
                        child: Row(
                          children: [
                            AppRemoteOrAssetAvatar(
                              radius: 16,
                              backgroundColor: colors.primary,
                              imagePath: recipe.authorAvatarPath,
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
                            const SizedBox(width: 5),
                            InkResponse(
                              onTap: onComingSoonTap,
                              radius: 18,
                              child: Icon(
                                Icons.bookmark,
                                size: 18,
                                color: AppColors.textSecondary.withValues(
                                  alpha: 0.55,
                                ),
                              ),
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

  String _compactCount(int value) {
    if (value >= 1000) {
      final compact = value / 1000;
      return '${compact.toStringAsFixed(compact >= 10 ? 0 : 1)}k';
    }
    return '$value';
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
