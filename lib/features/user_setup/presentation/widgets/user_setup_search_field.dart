import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Search field for user setup pages.
/// Provides search input with clear button and consistent styling.
class UserSetupSearchField extends StatelessWidget {
  /// Controller for the search input.
  final TextEditingController controller;

  /// Hint text displayed when the field is empty.
  final String hintText;

  /// Callback when the search text changes.
  final ValueChanged<String> onChanged;

  /// Callback when the clear button is pressed.
  final VoidCallback onClear;

  /// Creates a new user setup search field instance.
  const UserSetupSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          // Search icon.
          prefixIcon: const Icon(Icons.search, size: 18),

          // Clear button.
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: onClear,
          ),

          // Hint text.
          hintText: hintText,

          // Content padding.
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),

          // Border styling.
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: AppColors.border),
          ),
        ),
      ),
    );
  }
}