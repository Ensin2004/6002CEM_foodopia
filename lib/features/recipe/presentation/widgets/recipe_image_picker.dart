import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/widgets/cards/method_card.dart';

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
        _currentImageIndex = widget.images.isEmpty ? 0 : widget.images.length - 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return MethodCard(
        icon: Icons.add_photo_alternate_outlined,
        title: "Upload Image",
        subtitle: "Upload image for your recipe.",
        onTap: widget.onPick,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              itemCount: widget.images.length,
              onPageChanged: (index) {
                setState(() {
                  _currentImageIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return Image.file(
                  widget.images[index],
                  fit: BoxFit.cover,
                );
              },
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
                  color: Colors.white.withValues(alpha: 0.90),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  "${_currentImageIndex + 1}/${widget.images.length}",
                  style: context.text.labelLarge?.copyWith(
                    color: AppColors.textPrimary,
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

class _ImageActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ImageActionButton({
    required this.icon,
    required this.onTap
  });

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