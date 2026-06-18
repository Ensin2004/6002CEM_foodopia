// Defines the shared loading dialog widget.

import 'package:flutter/material.dart';

/// Loads data for the loading dialog operation.
/// Displays a loading indicator with optional message.
class LoadingDialog extends StatelessWidget {
  /// Optional message to display.
  final String? message;

  /// Whether to display inline (without dialog background).
  final bool inline;

  /// Loads data for the loading dialog operation.
  const LoadingDialog({super.key, this.message, this.inline = false});

  /// Builds the widget tree for this component.
  @override
  Widget build(BuildContext context) {
    // Inline variant (no dialog background).
    if (inline) {
      return Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Spinner.
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(width: 12),

            // Message.
            Flexible(
              child: Text(
                message ?? 'Please wait...',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Full dialog variant.
    /// Handles the dialog operation.
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// Creates a circular progress indicator instance.
              const CircularProgressIndicator(),

              /// Creates a sized box instance.
              const SizedBox(height: 16),

              /// Creates a text instance.
              Text(
                message ?? 'Please wait...',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}