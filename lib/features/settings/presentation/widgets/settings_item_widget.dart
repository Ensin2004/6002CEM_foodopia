import 'package:flutter/material.dart';
import '../../domain/entities/settings_item.dart';
import '../viewmodel/settings_viewmodel.dart';

class SettingsItemWidget extends StatelessWidget {
  final SettingsItem item;
  final SettingsViewModel viewModel;

  const SettingsItemWidget({
    super.key,
    required this.item,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    // 🔹 Toggle item
    if (item.type == SettingsItemType.toggle) {
      return SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        visualDensity: const VisualDensity(vertical: -2),
        title: Text(item.title),
        subtitle: item.subtitle != null
            ? Text(
          item.subtitle!,
          style: const TextStyle(height: 1.2),
        )
            : null,
        value: viewModel.notificationsEnabled,
        onChanged: viewModel.toggleNotifications,
        activeColor: Theme.of(context).colorScheme.primary,
        secondary: Icon(
          item.icon,
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }

    // 🔹 Normal item - calls ViewModel to emit event
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
        style: TextStyle(
          color: item.isDestructive ? Colors.red : null,
        ),
      ),
      subtitle: item.subtitle != null
          ? Text(
        item.subtitle!,
        style: const TextStyle(height: 1.2),
      )
          : null,
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => viewModel.onSettingsItemTapped(item.id), // ✅ Emits typed event
    );
  }
}