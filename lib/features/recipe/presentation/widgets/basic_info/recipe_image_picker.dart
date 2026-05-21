import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_extension.dart';
import '../../../../../core/widgets/cards/method_card.dart';

class RecipeImagePicker extends StatefulWidget {
  final List<File> images;
  final VoidCallback onPick;
  final VoidCallback onEdit;

  const RecipeImagePicker({
    super.key,
    required this.images,
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

    if (_currentImageIndex >= widget.images.length) {
      setState(() {
        _currentImageIndex = widget.images.isEmpty
            ? 0
            : widget.images.length - 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (widget.images.isEmpty) {
      return MethodCard(
        icon: Icons.add_photo_alternate_outlined,
        title: "Upload Image",
        subtitle: "Upload image for your recipe.",
        onTap: widget.onPick,
      );
    }

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
                  itemCount: widget.images.length,
                  onPageChanged: (index) {
                    setState(() => _currentImageIndex = index);
                  },
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _showExpandedImage(context, widget.images[index]),
                      child: Image.file(widget.images[index], fit: BoxFit.contain),
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
              right: AppSpacing.sm,
              top: AppSpacing.sm,
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
                  "${_currentImageIndex + 1}/${widget.images.length}",
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

  Future<void> _showExpandedImage(BuildContext context, File image) async {
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
                    child: Image.file(image, fit: BoxFit.contain)
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
