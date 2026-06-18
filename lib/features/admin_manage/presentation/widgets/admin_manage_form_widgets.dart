import 'package:flutter/material.dart';

import '../../../../core/theme/theme_extension.dart';

/// Label widget for admin manage forms.
class AdminManageFormLabel extends StatelessWidget {
  /// Label text.
  final String text;

  /// Creates a new admin manage form label instance.
  const AdminManageFormLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: context.text.titleMedium),
    );
  }
}

/// Icon grid widget for selecting an icon.
class AdminManageIconGrid extends StatelessWidget {
  /// Map of icon keys to IconData.
  final Map<String, IconData> iconOptions;

  /// Currently selected icon key.
  final String? selectedKey;

  /// Callback when an icon is selected.
  final ValueChanged<String?> onSelected;

  /// Color for the selected icon border.
  final Color selectedColor;

  /// Color for the selected icon.
  final Color selectedIconColor;

  /// Creates a new admin manage icon grid instance.
  const AdminManageIconGrid({
    super.key,
    required this.iconOptions,
    required this.selectedKey,
    required this.onSelected,
    required this.selectedColor,
    required this.selectedIconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: iconOptions.entries.map((entry) {
        // Check if this entry is selected.
        final selected = entry.key == selectedKey;

        return InkWell(
          onTap: () => onSelected(selected ? null : entry.key),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: selected ? selectedColor : Colors.grey.shade200,
                width: selected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              children: [
                // Icon.
                Center(
                  child: Icon(
                    entry.value,
                    color: selected ? selectedIconColor : Colors.blueGrey,
                    size: 30,
                  ),
                ),
                // Selection checkmark.
                if (selected)
                  Positioned(
                    right: 4,
                    bottom: 4,
                    child: CircleAvatar(
                      radius: 8,
                      backgroundColor: selectedColor,
                      child: const Icon(
                        Icons.check,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}