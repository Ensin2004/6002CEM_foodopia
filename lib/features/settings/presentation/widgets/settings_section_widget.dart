// Defines the settings section widget.

import 'package:flutter/material.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../domain/entities/settings_section.dart';
import '../viewmodel/settings_viewmodel.dart';
import 'settings_item_widget.dart';

/// Defines behavior for settings section widget.
class SettingsSectionWidget extends StatelessWidget {
  final SettingsSection section;
  final SettingsViewModel viewModel;
  final bool isLast;

  /// Creates a settings section widget instance.
  const SettingsSectionWidget({
    super.key,
    required this.section,
    required this.viewModel,
    this.isLast = false,
  });

  /// Builds the widget tree for this component.
  @override
  Widget build(BuildContext context) {
    /// Handles the column operation.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Creates a padding instance.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            section.title,
            style: context.text.titleLarge,
          ),
        ),
        ...section.items.map((item) {
          /// Handles the settings item widget operation.
          return SettingsItemWidget(
            item: item,
            viewModel: viewModel,
          );
        }),
        if (!isLast)
          /// Creates a padding instance.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Divider(
              height: 1,
              color: Colors.grey[300],
              thickness: 2,
            ),
          ),
      ],
    );
  }
}
