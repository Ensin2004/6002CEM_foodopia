import 'dart:convert';

import 'package:flutter/material.dart';

class AppRemoteOrAssetImage extends StatelessWidget {
  final String imagePath;
  final double? width;
  final double? height;
  final BoxFit fit;

  const AppRemoteOrAssetImage({
    super.key,
    required this.imagePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final trimmedPath = imagePath.trim();
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

    if (trimmedPath.isEmpty) {
      return _ImageFallback(width: width, height: height);
    }

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

class AppRemoteOrAssetAvatar extends StatelessWidget {
  final String imagePath;
  final double radius;
  final Color? backgroundColor;

  const AppRemoteOrAssetAvatar({
    super.key,
    required this.imagePath,
    this.radius = 18,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final trimmedPath = imagePath.trim();
    ImageProvider? imageProvider;

    if (trimmedPath.startsWith('http://') ||
        trimmedPath.startsWith('https://')) {
      imageProvider = NetworkImage(trimmedPath);
    } else if (trimmedPath.isNotEmpty) {
      imageProvider = AssetImage(trimmedPath);
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      backgroundImage: imageProvider,
      child: imageProvider == null ? const Icon(Icons.person) : null,
    );
  }
}

class _ImageFallback extends StatelessWidget {
  final double? width;
  final double? height;

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
