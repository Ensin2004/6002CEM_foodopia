import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/theme_extension.dart';
import '../../../../../core/widgets/images/app_remote_or_asset_image.dart';
import '../../../../../core/widgets/media/app_recipe_media.dart';

/// Displays recipe review media.
class ReviewHeroImage extends StatefulWidget {
  final List<String> media;

  const ReviewHeroImage({super.key, required this.media});

  @override
  State<ReviewHeroImage> createState() => _ReviewHeroImageState();
}

/// Tracks the currently displayed review media item.
class _ReviewHeroImageState extends State<ReviewHeroImage> {
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border, width: 1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Stack(
          children: [
            ColoredBox(
              color: colors.surfaceContainerHighest,
              child: AspectRatio(
                aspectRatio: 1.55,
                child: PageView.builder(
                  itemCount: widget.media.length,
                  onPageChanged: (index) {
                    setState(() => _currentImageIndex = index);
                  },
                  itemBuilder: (context, index) {
                    final mediaPath = widget.media[index];
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => showRecipeMediaDialog(context, mediaPath),
                      child: isRecipeVideoPath(mediaPath)
                          ? AppRecipeMedia(
                              mediaPath: mediaPath,
                              fit: BoxFit.contain,
                              showVideoControls: true,
                              allowFullscreen: true,
                            )
                          : AppRemoteOrAssetImage(
                              imagePath: mediaPath,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.contain,
                            ),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: colors.onSurface.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.media.isEmpty ? "0/0" : "${_currentImageIndex + 1}/${widget.media.length}",
                  style: context.text.bodySmall?.copyWith(
                    color: colors.surface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
