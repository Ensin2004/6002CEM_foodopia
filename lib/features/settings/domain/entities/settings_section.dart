import 'settings_item.dart';

/// Settings section (group of related settings items)
class SettingsSection {
  final String title;
  final List<SettingsItem> items;

  const SettingsSection({
    required this.title,
    required this.items,
  });
}