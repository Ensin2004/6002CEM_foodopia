import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_extension.dart';
import '../../../../../core/widgets/buttons/primary_button.dart';
import '../../../../../core/widgets/images/app_remote_or_asset_image.dart';
import '../../../../../core/widgets/media/app_recipe_media.dart';

/// Bottom sheet for viewing and managing selected recipe media.
class RecipeImageEditSheet extends StatelessWidget {
  final List<File> images;
  final List<String> existingImageUrls;
  final ValueChanged<int> onRemove;
  final ValueChanged<int> onRemoveExisting;
  final VoidCallback onKeep;

  const RecipeImageEditSheet({
    super.key,
    required this.images,
    this.existingImageUrls = const [],
    required this.onRemove,
    required this.onRemoveExisting,
    required this.onKeep,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxSheetHeight = MediaQuery.sizeOf(context).height * 0.72;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.lg + bottomInset,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxSheetHeight),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Visual indicator that the sheet can be dragged down
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Header with total media count
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "Selected Media",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.titleMedium,
                    ),
                  ),
                  Text(
                    "${images.length + existingImageUrls.length}/10",
                    style: context.text.bodySmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Selected media display in grid
              Expanded(
                child: GridView.builder(
                  shrinkWrap: true,
                  itemCount: images.length + existingImageUrls.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: AppSpacing.sm,
                    mainAxisSpacing: AppSpacing.sm,
                  ),
                  itemBuilder: (context, index) {
                    // Display existing images first, then local files
                    if (index < existingImageUrls.length) {
                      return _SelectedMediaTile(
                        imageUrl: existingImageUrls[index],
                        index: index,
                        onRemove: () => onRemoveExisting(index),
                      );
                    }
                    final fileIndex = index - existingImageUrls.length;
                    return _SelectedMediaTile(
                      imageFile: images[fileIndex],
                      index: index,
                      onRemove: () => onRemove(fileIndex),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Action Button
              PrimaryButton(text: "Keep Selected Media", onPressed: onKeep),
            ],
          ),
        ),
      ),
    );
  }
}

/// Displays one selected recipe media item with preview and remove control.
class _SelectedMediaTile extends StatelessWidget {
  final File? imageFile;
  final String? imageUrl;
  final int index;
  final VoidCallback onRemove;

  const _SelectedMediaTile({
    this.imageFile,
    this.imageUrl,
    required this.index,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Show the appropriate preview based on media type
            imageFile != null
                ? _MediaTilePreview(file: imageFile!)
                : isRecipeVideoPath(imageUrl!)
                ? AppRecipeMediaPreview(mediaPath: imageUrl!, fit: BoxFit.cover)
                : AppRemoteOrAssetImage(imagePath: imageUrl!, fit: BoxFit.cover),

            // Top-left corner - index number
            Positioned(
              left: AppSpacing.xs,
              top: AppSpacing.xs,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: colors.onSurface.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "${index + 1}",
                  style: context.text.bodySmall?.copyWith(
                    color: colors.surface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            // Top-right corner - close button
            Positioned(
              right: AppSpacing.xs,
              top: AppSpacing.xs,
              child: InkWell(
                onTap: onRemove,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.90),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: AppColors.error,
                    size: 16,
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

/// Shows an individual media in a tile
class _MediaTilePreview extends StatelessWidget {
  final File file;

  const _MediaTilePreview({required this.file});

  @override
  Widget build(BuildContext context) {
    // Check if the file is a video based on its extension
    if (isRecipeVideoPath(file.path)) {
      // Show video preview with cover image
      return AppRecipeMediaPreview(mediaPath: file.path, fit: BoxFit.cover);
    }
    // Show image preview
    return Image.file(file, fit: BoxFit.cover);
  }
}
