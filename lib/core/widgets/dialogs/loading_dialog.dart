// Defines the shared loading dialog widget.

import 'package:flutter/material.dart';

/// Loads data for the loading dialog operation.
class LoadingDialog extends StatelessWidget {
  final String? message;

  /// Loads data for the loading dialog operation.
  const LoadingDialog({super.key, this.message});

  /// Builds the widget tree for this component.
  @override
  Widget build(BuildContext context) {
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
