import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/admin_manage_item_model.dart';

class AdminManageRemoteDataSource {
  final FirebaseFirestore firestore;

  AdminManageRemoteDataSource({required this.firestore});

  Future<List<AdminManageItemModel>> getItems(String categoryId) async {
    final snapshot = await _collection(categoryId).orderBy('sortOrder').get();
    return snapshot.docs.map(AdminManageItemModel.fromFirestore).toList();
  }

  Future<void> saveItem({
    required String categoryId,
    required AdminManageItemModel item,
  }) async {
    final data = item.toFirestore();

    if (item.id.isEmpty) {
      await _collection(
        categoryId,
      ).add({...data, 'createdAt': FieldValue.serverTimestamp()});
    } else {
      await _collection(categoryId).doc(item.id).update(data);
    }
  }

  Future<void> deleteItem({
    required String categoryId,
    required String id,
  }) async {
    await _collection(categoryId).doc(id).delete();
  }

  Future<void> reorderItems({
    required String categoryId,
    required List<AdminManageItemModel> items,
  }) async {
    final batch = firestore.batch();

    for (var i = 0; i < items.length; i++) {
      batch.update(_collection(categoryId).doc(items[i].id), {
        'sortOrder': i + 1,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  Future<void> seedDefaults({
    required String categoryId,
    required List<String> values,
  }) async {
    final existingSnapshot = await _collection(categoryId).get();
    final existingNames = existingSnapshot.docs
        .map((doc) => doc.data()['name']?.toString().trim().toLowerCase())
        .whereType<String>()
        .toSet();

    final batch = firestore.batch();
    var nextSortOrder = existingSnapshot.docs.length + 1;
    var hasWrites = false;

    for (final value in values) {
      final normalized = value.trim().toLowerCase();
      if (normalized.isEmpty || existingNames.contains(normalized)) continue;

      final ref = _collection(categoryId).doc();
      batch.set(ref, {
        'name': value,
        'description': '',
        'iconKey': '',
        'sortOrder': nextSortOrder,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      existingNames.add(normalized);
      nextSortOrder++;
      hasWrites = true;
    }

    if (hasWrites) await batch.commit();
  }

  CollectionReference<Map<String, dynamic>> _collection(String categoryId) {
    return firestore
        .collection('app_config')
        .doc(categoryId)
        .collection('items');
  }
}
