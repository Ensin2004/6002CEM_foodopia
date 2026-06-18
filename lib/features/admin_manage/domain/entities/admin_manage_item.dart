/// Admin-managed option shown in recipe setup and user preference lists.
/// Represents a configurable item like age groups, categories, etc.
class AdminManageItem {
  /// Unique identifier of the item.
  final String id;

  /// Display name of the item.
  final String name;

  /// Optional description of the item.
  final String description;

  /// Key for the icon associated with the item.
  final String iconKey;

  /// Sort order for display ordering.
  final int sortOrder;

  /// Whether the item is active and visible.
  final bool isActive;

  /// Creates a new admin manage item instance.
  const AdminManageItem({
    this.id = '',
    required this.name,
    this.description = '',
    this.iconKey = '',
    required this.sortOrder,
    this.isActive = true,
  });

  /// Creates a copy of this item with optional field updates.
  AdminManageItem copyWith({
    String? id,
    String? name,
    String? description,
    String? iconKey,
    int? sortOrder,
    bool? isActive,
  }) {
    return AdminManageItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconKey: iconKey ?? this.iconKey,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
    );
  }
}