import 'package:flutter/material.dart';

import '../../../../core/theme/theme_extension.dart';

class AdminManageFormLabel extends StatelessWidget {
  final String text;

  const AdminManageFormLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: context.text.titleMedium),
    );
  }
}

class AdminManageIconGrid extends StatelessWidget {
  final Map<String, IconData> iconOptions;
  final String selectedKey;
  final ValueChanged<String> onSelected;
  final Color selectedColor;
  final Color selectedIconColor;

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
        final selected = entry.key == selectedKey;

        return InkWell(
          onTap: () => onSelected(entry.key),
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
                Center(
                  child: Icon(
                    entry.value,
                    color: selected ? selectedIconColor : Colors.blueGrey,
                    size: 30,
                  ),
                ),
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
