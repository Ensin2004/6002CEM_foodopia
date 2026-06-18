import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/admin_manage_item.dart';

/// Model class for admin manage items.
/// Maps between domain entities and Firestore documents.
class AdminManageItemModel extends AdminManageItem {
  /// Creates a new admin manage item model instance.
  const AdminManageItemModel({
    super.id = '',
    required super.name,
    super.description = '',
    super.iconKey = '',
    required super.sortOrder,
    super.isActive = true,
  });

  /// Creates a model from a Firestore document.
  factory AdminManageItemModel.fromFirestore(
      QueryDocumentSnapshot<Map<String, dynamic>> doc,
      ) {
    // Extract data from the document.
    final data = doc.data();

    return AdminManageItemModel(
      id: doc.id,
      name: data['name']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      iconKey: data['iconKey']?.toString() ?? '',
      sortOrder: data['sortOrder'] is int ? data['sortOrder'] as int : 0,
      isActive: data['isActive'] is bool ? data['isActive'] as bool : true,
    );
  }

  /// Creates a model from a domain entity.
  factory AdminManageItemModel.fromEntity(AdminManageItem item) {
    return AdminManageItemModel(
      id: item.id,
      name: item.name,
      description: item.description,
      iconKey: item.iconKey,
      sortOrder: item.sortOrder,
      isActive: item.isActive,
    );
  }

  /// Converts this model to Firestore data.
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'iconKey': iconKey,
      'sortOrder': sortOrder,
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}