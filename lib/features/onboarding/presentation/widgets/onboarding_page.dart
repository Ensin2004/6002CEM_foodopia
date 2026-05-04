import 'package:flutter/material.dart';
import 'package:foodopia/core/theme/theme_extension.dart';

import '../../domain/entities/onboarding_item.dart';

/// Defines behavior for onboarding page.
class OnboardingPage extends StatelessWidget {
  final OnboardingItem item;
  final double pageOffset;

  /// Creates a onboarding page instance.
  const OnboardingPage({
    super.key,
    required this.item,
    required this.pageOffset,
  });

  /// Builds the widget tree for this component.
  @override
  Widget build(BuildContext context) {
    /// Handles the padding operation.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          /// Creates a spacer instance.
          const Spacer(flex: 2),

          /// Creates a stack instance.
          Stack(
            alignment: Alignment.center,
            children: [
              Transform.translate(
                offset: Offset(pageOffset * 10, 0),
                child: Opacity(
                  opacity: 0.9,
                  child: Image.asset(
                    "assets/images/onboarding_vector.png",
                    height: 320,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(pageOffset * 30, 0),
                child: Transform.scale(
                  scale: (1 - pageOffset.abs() * 0.05).clamp(0.85, 1.0),
                  child: Image.asset(
                    item.image,
                    height: 240,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),

          /// Creates a spacer instance.
          const Spacer(),

          // --- ANIMATED CONTENT GROUP ---
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: (1 - pageOffset.abs()).clamp(0.0, 1.0),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Constrain height to content
              children: [
                // --- TITLE ---
                Text(
                  item.title,
                  textAlign: TextAlign.center,
                  style: context.text.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: context.colors.onSurface,
                  ),
                ),

                /// Creates a sized box instance.
                const SizedBox(height: 12),

                // --- DESCRIPTION ---
                Text(
                  item.description,
                  textAlign: TextAlign.center,
                  style: context.text.bodyMedium?.copyWith(
                    height: 1.5,
                    letterSpacing: 0.2,
                    color: context.colors.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),

          /// Creates a spacer instance.
          const Spacer(flex: 3),
        ],
      ),
    );
  }
}
