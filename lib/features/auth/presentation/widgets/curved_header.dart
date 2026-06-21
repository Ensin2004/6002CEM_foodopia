import 'package:flutter/material.dart';
import 'curved_background_painter.dart';

/// Defines behavior for curved header.
/// A header with a curved bottom edge and centered logo.
class CurvedHeader extends StatelessWidget {
  /// Custom leading button widget.
  final Widget? leadingButton;

  /// Custom trailing button widget.
  final Widget? trailingButton;

  /// Callback when leading button is pressed.
  final VoidCallback? onLeadingPressed;

  /// Callback when trailing button is pressed.
  final VoidCallback? onTrailingPressed;

  /// Text for the leading button.
  final String? leadingText;

  /// Text for the trailing button.
  final String? trailingText;

  /// Path to the logo image asset.
  final String logoPath;

  /// Size of the logo.
  final double logoSize;

  /// Color of the curved section.
  final Color? curveColor;

  /// Background color of the header.
  final Color? backgroundColor;

  /// Creates a curved header instance.
  const CurvedHeader({
    super.key,
    this.leadingButton,
    this.trailingButton,
    this.onLeadingPressed,
    this.onTrailingPressed,
    this.leadingText,
    this.trailingText,
    this.logoPath = 'assets/images/foodopia_logo.png',
    this.logoSize = 80,
    this.curveColor,
    this.backgroundColor,
  });

  /// Builds the widget tree for this component.
  @override
  Widget build(BuildContext context) {
    // Get the theme.
    final theme = Theme.of(context);

    // Determine colors.
    final curveColor = this.curveColor ?? theme.colorScheme.primary;
    final backgroundColor = this.backgroundColor ?? theme.colorScheme.surface;

    /// Handles the stack operation.
    return Stack(
      children: [
        // Curved background.
        CustomPaint(
          painter: CurvedBackgroundPainter(
            backgroundColor: backgroundColor,
            curveColor: curveColor,
          ),
          child: Container(height: MediaQuery.of(context).size.height * 0.25),
        ),

        // Centered circular logo.
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: backgroundColor,
                border: Border.all(color: curveColor, width: 3),
              ),
              child: Image.asset(
                logoPath,
                height: logoSize,
                width: logoSize,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback icon if image fails to load.
                  /// Handles the container operation.
                  return Container(
                    height: logoSize,
                    width: logoSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: curveColor.withValues(alpha: 0.2),
                    ),
                    child: Icon(
                      Icons.restaurant,
                      size: logoSize * 0.6,
                      color: curveColor,
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        // Leading and trailing buttons.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Leading widget.
                if (leadingButton != null)
                  leadingButton!
                else if (onLeadingPressed != null && leadingText != null)
                  /// Creates a text button instance.
                  TextButton(
                    onPressed: onLeadingPressed,
                    child: Text(
                      leadingText!,
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                else
                  /// Creates a sized box instance.
                  const SizedBox(width: 48),

                // Trailing widget.
                if (trailingButton != null)
                  trailingButton!
                else if (onTrailingPressed != null && trailingText != null)
                  /// Creates a text button instance.
                  TextButton(
                    onPressed: onTrailingPressed,
                    child: Text(
                      trailingText!,
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                else
                  /// Creates a sized box instance.
                  const SizedBox(width: 48),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
