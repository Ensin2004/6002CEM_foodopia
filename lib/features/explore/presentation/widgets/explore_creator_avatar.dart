import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/images/app_remote_or_asset_image.dart';

// Displays a circular avatar for a creator with optional border decoration
class ExploreCreatorAvatar extends StatelessWidget {
  // Path to the creator's avatar image (asset or network URL)
  final String imagePath;
  // Radius of the avatar container (determines total size)
  final double radius;
  // Width and height of the image inside the avatar
  final double imageSize;
  // Size of the fallback person icon when no image is available
  final double iconSize;
  // Whether to display a primary-colored border around the avatar
  final bool hasBorder;

  const ExploreCreatorAvatar({
    super.key,
    required this.imagePath,
    required this.radius,
    required this.imageSize,
    required this.iconSize,
    this.hasBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    // Determines if the image path contains a valid non-empty string
    final hasImage = imagePath.trim().isNotEmpty;

    return Container(
      // Sets the container dimensions based on the provided radius
      width: radius * 2,
      height: radius * 2,
      // Applies padding only when border is enabled to prevent border clipping
      padding: hasBorder ? const EdgeInsets.all(2) : EdgeInsets.zero,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // Conditionally applies a border when hasBorder is true
        border: hasBorder
            ? Border.all(color: AppColors.primary, width: 1.5)
            : null,
      ),
      child: CircleAvatar(
        backgroundColor: Colors.white,
        child: hasImage
            ? ClipOval(
          // Clips the image to a circular shape
          child: AppRemoteOrAssetImage(
            imagePath: imagePath,
            width: imageSize,
            height: imageSize,
          ),
        )
            : Icon(Icons.person, color: AppColors.primary, size: iconSize),
      ),
    );
  }
}