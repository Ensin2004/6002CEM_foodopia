import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_spacing.dart';

/// Shows a source picker for add-recipe image selection.
Future<ImageSource?> showAddRecipeImageSourceSheet(
  BuildContext context, {
  String cameraLabel = 'Take Photo',
  String galleryLabel = 'Choose from Gallery',
}) {
  return showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Visual indicator that the sheet can be dragged down to dismiss
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Camera Option
              _ImageSourceTile(
                icon: Icons.photo_camera_outlined,
                title: cameraLabel,
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),

              // Gallery Option
              _ImageSourceTile(
                icon: Icons.photo_library_outlined,
                title: galleryLabel,
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// A list tile widget for displaying an option.
class _ImageSourceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ImageSourceTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
    );
  }
}
