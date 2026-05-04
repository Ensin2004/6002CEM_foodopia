import 'package:flutter/material.dart';
import 'package:foodopia/core/theme/theme_extension.dart';

/// A reusable elevated-primary button matching the app's design system.
class PrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final Widget? icon;
  final double? width;
  final double verticalPadding;
  final BorderRadiusGeometry borderRadius;
  final bool isLoading;

  /// Creates a primary button instance.
  const PrimaryButton({
    Key? key,
    required this.onPressed,
    required this.text,
    this.icon,
    this.width,
    this.verticalPadding = 16.0,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.isLoading = false,
  }) : super(key: key);

  /// Builds the widget tree for this component.
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.text;

    /// Handles the sized box operation.
    return SizedBox(
      width: width ?? double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          padding: EdgeInsets.symmetric(vertical: verticalPadding),
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
          textStyle: textTheme.labelLarge,
        ),
        child: isLoading
            ? SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(colors.onPrimary),
          ),
        )
            : icon != null
            ? Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon!,
            /// Creates a sized box instance.
            const SizedBox(width: 8),
            /// Creates a text instance.
            Text(text),
          ],
        )
            : Text(text),
      ),
    );
  }
}
