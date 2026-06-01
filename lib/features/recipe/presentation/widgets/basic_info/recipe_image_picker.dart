import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_extension.dart';
import '../../../../../core/widgets/cards/method_card.dart';
import '../../../../../core/widgets/images/app_remote_or_asset_image.dart';
import '../../../../../core/widgets/media/app_recipe_media.dart';

class RecipeImagePicker extends StatefulWidget {
  final List<File> images;
  final List<String> existingImageUrls;
  final VoidCallback onPick;
  final VoidCallback onEdit;

  const RecipeImagePicker({
    super.key,
    required this.images,
    this.existingImageUrls = const [],
    required this.onPick,
    required this.onEdit,
  });

  @override
  State<RecipeImagePicker> createState() => _RecipeImagePickerState();
}

class _RecipeImagePickerState extends State<RecipeImagePicker> {
  int _currentImageIndex = 0;

  @override
  void didUpdateWidget(covariant RecipeImagePicker oldWidget) {
    super.didUpdateWidget(oldWidget);

    final imageCount = widget.existingImageUrls.length + widget.images.length;
    if (_currentImageIndex >= imageCount) {
      setState(() {
        _currentImageIndex = imageCount == 0 ? 0 : imageCount - 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final imageCount = widget.existingImageUrls.length + widget.images.length;
    if (imageCount == 0) {
      return MethodCard(
        icon: Icons.perm_media_outlined,
        title: "Upload Media",
        subtitle: "Upload images or videos for your recipe.",
        onTap: widget.onPick,
      );
    }

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
                  itemCount: imageCount,
                  onPageChanged: (index) {
                    setState(() => _currentImageIndex = index);
                  },
                  itemBuilder: (context, index) {
                    final existingUrl = index < widget.existingImageUrls.length
                        ? widget.existingImageUrls[index]
                        : null;
                    final fileIndex = index - widget.existingImageUrls.length;
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => existingUrl == null
                          ? showRecipeMediaDialog(context, widget.images[fileIndex].path)
                          : showRecipeMediaDialog(context, existingUrl),
                      child: existingUrl == null
                          ? _RecipeMediaPreview(file: widget.images[fileIndex], fit: BoxFit.contain)
                          : isRecipeVideoPath(existingUrl)
                          ? AppRecipeMedia(
                              mediaPath: existingUrl,
                              fit: BoxFit.contain,
                              showVideoControls: true,
                              allowFullscreen: true,
                            )
                          : AppRemoteOrAssetImage(
                              imagePath: existingUrl,
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
              left: AppSpacing.sm,
              top: AppSpacing.sm,
              child: Row(
                children: [
                  _ImageActionButton(icon: Icons.add, onTap: widget.onPick),
                  const SizedBox(width: AppSpacing.sm),
                  _ImageActionButton(icon: Icons.edit, onTap: widget.onEdit),
                ],
              ),
            ),
            Positioned(
              right: 10,
              top: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: colors.onSurface.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${_currentImageIndex + 1}/$imageCount",
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

class _RecipeMediaPreview extends StatelessWidget {
  final File file;
  final BoxFit fit;

  const _RecipeMediaPreview({required this.file, required this.fit});

  @override
  Widget build(BuildContext context) {
    if (isRecipeVideoPath(file.path)) {
      return AppRecipeMedia(
        mediaPath: file.path,
        fit: fit,
        showVideoControls: true,
        allowFullscreen: true,
      );
    }
    return Image.file(file, fit: fit);
  }
}

class _ImageActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ImageActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}
