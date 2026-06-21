import 'dart:convert';

import 'package:flutter/material.dart';

/// Widget that displays an image from either a remote URL or local asset.
/// Supports HTTP/HTTPS URLs, base64 data URIs, and asset paths.
class AppRemoteOrAssetImage extends StatelessWidget {
  /// Path to the image (URL, asset path, or base64 data URI).
  final String imagePath;

  /// Optional width of the image.
  final double? width;

  /// Optional height of the image.
  final double? height;

  /// Box fit for the image.
  final BoxFit fit;

  /// Creates a new app remote or asset image instance.
  const AppRemoteOrAssetImage({
    super.key,
    required this.imagePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    // Trim the path.
    final trimmedPath = imagePath.trim();

    // Check if it's a remote URL.
    if (trimmedPath.startsWith('http://') ||
        trimmedPath.startsWith('https://')) {
      return Image.network(
        trimmedPath,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) =>
            _ImageFallback(width: width, height: height),
      );
    }

    // Check if it's a base64 data URI.
    if (trimmedPath.startsWith('data:image/')) {
      final commaIndex = trimmedPath.indexOf(',');
      final base64Data = commaIndex >= 0
          ? trimmedPath.substring(commaIndex + 1)
          : '';

      if (base64Data.isNotEmpty) {
        return Image.memory(
          base64Decode(base64Data),
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) =>
              _ImageFallback(width: width, height: height),
        );
      }
    }

    // Return fallback for empty path.
    if (trimmedPath.isEmpty) {
      return _ImageFallback(width: width, height: height);
    }

    // Load from assets.
    return Image.asset(
      trimmedPath,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) =>
          _ImageFallback(width: width, height: height),
    );
  }
}

/// Widget that displays an avatar image from either a remote URL or local asset.
/// Uses CircleAvatar with fallback to person icon.
class AppRemoteOrAssetAvatar extends StatelessWidget {
  /// Path to the image (URL or asset path).
  final String imagePath;

  /// Radius of the avatar.
  final double radius;

  /// Background color of the avatar.
  final Color? backgroundColor;

  /// Creates a new app remote or asset avatar instance.
  const AppRemoteOrAssetAvatar({
    super.key,
    required this.imagePath,
    this.radius = 18,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    // Trim the path.
    final trimmedPath = imagePath.trim();

    // Determine the image provider.
    ImageProvider? imageProvider;

    if (trimmedPath.startsWith('http://') ||
        trimmedPath.startsWith('https://')) {
      imageProvider = NetworkImage(trimmedPath);
    } else if (trimmedPath.isNotEmpty) {
      imageProvider = AssetImage(trimmedPath);
    }

    // Return the CircleAvatar.
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      backgroundImage: imageProvider,
      child: imageProvider == null ? const Icon(Icons.person) : null,
    );
  }
}

/// Fallback widget for when an image fails to load.
class _ImageFallback extends StatelessWidget {
  /// Optional width of the fallback.
  final double? width;

  /// Optional height of the fallback.
  final double? height;

  /// Creates a new image fallback instance.
  const _ImageFallback({this.width, this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: const ColoredBox(
        color: Color(0xFFEDEFF2),
        child: Center(child: Icon(Icons.image_not_supported_outlined)),
      ),
    );
  }
}