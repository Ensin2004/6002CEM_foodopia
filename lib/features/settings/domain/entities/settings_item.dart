import 'package:flutter/material.dart';

/// Settings menu item entity
class SettingsItem {
  final String id;
  final String title;
  final IconData icon;
  final String? subtitle;
  final bool isDestructive;
  final SettingsItemType type;
  final String? routeName;

  const SettingsItem({
    required this.id,
    required this.title,
    required this.icon,
    this.subtitle,
    this.isDestructive = false,
    this.type = SettingsItemType.navigation,
    this.routeName,
  });
}

/// Type of settings item
enum SettingsItemType {
  navigation,   // Navigates to another page
  toggle,       // Switch toggle
  info,         // Information display
  button,       // Action button
}