import 'package:flutter/material.dart';
import 'package:foodopia/core/theme/theme_extension.dart';

/// A reusable secondary outlined button matching the app's design system.
class SecondaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final double? width;
  final double verticalPadding;
  final BorderRadiusGeometry borderRadius;

  /// Creates a secondary button instance.
  const SecondaryButton({
    Key? key,
    required this.onPressed,
    required this.text,
    this.width,
    this.verticalPadding = 16.0,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  }) : super(key: key);

  /// Builds the widget tree for this component.
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.text;

    /// Handles the sized box operation.
    return SizedBox(
      width: width ?? double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primary,
          backgroundColor: colors.surface,
          padding: EdgeInsets.symmetric(vertical: verticalPadding),
          side: BorderSide(color: colors.primary),
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
          textStyle: textTheme.labelLarge,
        ),
        child: Text(text),
      ),
    );
  }
}
