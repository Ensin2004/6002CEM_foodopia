import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_extension.dart';
import '../../../../../core/widgets/images/app_remote_or_asset_image.dart';

class ReviewHeroImage extends StatefulWidget {
  final List<String> media;

  const ReviewHeroImage({
    super.key,
    required this.media
  });

  @override
  State<ReviewHeroImage> createState() => _ReviewHeroImageState();
}

class _ReviewHeroImageState extends State<ReviewHeroImage> {
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
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
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _showExpandedImage(context, widget.media[index]),
                      child: AppRemoteOrAssetImage(
                        imagePath: widget.media.isEmpty ? "" : widget.media[index],
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
              top: AppSpacing.sm,
              right: AppSpacing.sm,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: colors.onSurface.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  widget.media.isEmpty ? "0/0" : "${_currentImageIndex + 1}/${widget.media.length}",
                  style: context.text.bodySmall?.copyWith(
                    color: colors.surface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showExpandedImage(BuildContext context, String imagePath) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog.fullscreen(
          backgroundColor: Colors.black,
          child: SafeArea(
            child: Stack(
              children: [
                Center(
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: AppRemoteOrAssetImage(
                      imagePath: imagePath,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Positioned(
                  top: AppSpacing.sm,
                  right: AppSpacing.sm,
                  child: IconButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}