import 'package:flutter/material.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../domain/entities/settings_item.dart';
import '../viewmodel/settings_viewmodel.dart';

/// Defines behavior for settings item widget.
class SettingsItemWidget extends StatelessWidget {
  final SettingsItem item;
  final SettingsViewModel viewModel;

  /// Creates a settings item widget instance.
  const SettingsItemWidget({
    super.key,
    required this.item,
    required this.viewModel,
  });

  /// Builds the widget tree for this component.
  @override
  Widget build(BuildContext context) {
    // 🔹 Toggle item
    if (item.type == SettingsItemType.toggle) {
      /// Handles the switch list tile operation.
      return SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        visualDensity: const VisualDensity(vertical: -2),
        title: Text(item.title, style: context.text.bodyLarge),
        subtitle: item.subtitle != null
            ? Text(
                item.subtitle!,
                style: context.text.bodySmall?.copyWith(height: 1.2),
              )
            : null,
        value: viewModel.isNotificationEnabled(item.id),
        onChanged: (value) => viewModel.toggleNotification(item.id, value),
        activeThumbColor: Theme.of(context).colorScheme.primary,
        secondary: Icon(
          item.icon,
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }

    // 🔹 Normal item - calls ViewModel to emit event
    if (item.type == SettingsItemType.info) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
        child: Text(
          item.title,
          style: context.text.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      visualDensity: const VisualDensity(vertical: -2),
      minVerticalPadding: 0,
      leading: Icon(
        item.icon,
        color: item.isDestructive
            ? Colors.red
            : Theme.of(context).colorScheme.primary,
      ),
      title: Text(
        item.title,
        style: context.text.bodyLarge?.copyWith(
          color: item.isDestructive ? Colors.red : null,
        ),
      ),
      subtitle: item.subtitle != null
          ? Text(
              item.subtitle!,
              style: context.text.bodySmall?.copyWith(height: 1.2),
            )
          : null,
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => viewModel.onSettingsItemTapped(item.id), // Emits typed event
    );
  }
}
