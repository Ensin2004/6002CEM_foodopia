/// Admin-managed option shown in recipe setup and user preference lists.
class AdminManageItem {
  final String id;
  final String name;
  final String description;
  final String iconKey;
  final int sortOrder;
  final bool isActive;

  const AdminManageItem({
    this.id = '',
    required this.name,
    this.description = '',
    this.iconKey = '',
    required this.sortOrder,
    this.isActive = true,
  });

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
