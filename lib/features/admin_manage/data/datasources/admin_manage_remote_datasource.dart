import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/admin_manage_item_model.dart';

/// Remote data source for admin management operations.
/// Handles CRUD operations for configurable items like age groups, categories, etc.
class AdminManageRemoteDataSource {
  /// Firestore instance for database operations.
  final FirebaseFirestore firestore;

  /// Creates a new admin manage remote data source instance.
  AdminManageRemoteDataSource({required this.firestore});

  /// Retrieves items for a category ordered by sort order.
  Future<List<AdminManageItemModel>> getItems(String categoryId) async {
    // Query items ordered by sortOrder.
    final snapshot = await _collection(categoryId).orderBy('sortOrder').get();

    // Map documents to models.
    return snapshot.docs.map(AdminManageItemModel.fromFirestore).toList();
  }

  /// Saves an item (creates or updates).
  Future<void> saveItem({
    required String categoryId,
    required AdminManageItemModel item,
  }) async {
    // Prepare data for Firestore.
    final data = item.toFirestore();

    // Check for duplicate names.
    await _throwIfDuplicateName(categoryId: categoryId, item: item);

    // Create or update the document.
    if (item.id.isEmpty) {
      // Create new document.
      await _collection(
        categoryId,
      ).add({...data, 'createdAt': FieldValue.serverTimestamp()});
    } else {
      // Update existing document.
      await _collection(categoryId).doc(item.id).update(data);
    }
  }

  /// Deletes an item.
  Future<void> deleteItem({
    required String categoryId,
    required String id,
  }) async {
    await _collection(categoryId).doc(id).delete();
  }

  /// Reorders items by updating sortOrder.
  Future<void> reorderItems({
    required String categoryId,
    required List<AdminManageItemModel> items,
  }) async {
    // Start a batch write.
    final batch = firestore.batch();

    // Update each item's sort order.
    for (var i = 0; i < items.length; i++) {
      batch.update(_collection(categoryId).doc(items[i].id), {
        'sortOrder': i + 1,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    // Commit the batch.
    await batch.commit();
  }

  /// Throws an error if a duplicate name exists.
  Future<void> _throwIfDuplicateName({
    required String categoryId,
    required AdminManageItemModel item,
  }) async {
    // Get all items in the category.
    final existingSnapshot = await _collection(categoryId).get();

    // Normalize the name for comparison.
    final normalizedName = _normalizeName(item.name);

    // Check for duplicates.
    for (final doc in existingSnapshot.docs) {
      // Skip the current item when updating.
      if (doc.id == item.id) continue;

      // Get the existing name.
      final existingName = doc.data()['name']?.toString() ?? '';

      // Throw error if duplicate found.
      if (_normalizeName(existingName) == normalizedName) {
        throw StateError('This name already exists in this list');
      }
    }
  }

  /// Returns a collection reference for a category.
  CollectionReference<Map<String, dynamic>> _collection(String categoryId) {
    return firestore
        .collection('app_config')
        .doc(categoryId)
        .collection('items');
  }

  /// Normalizes a string for comparison.
  String _normalizeName(String value) => value.trim().toLowerCase();
}