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
    await _throwIfDuplicateName(categoryId: categoryId, item: item);

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

  Future<void> _throwIfDuplicateName({
    required String categoryId,
    required AdminManageItemModel item,
  }) async {
    final existingSnapshot = await _collection(categoryId).get();
    final normalizedName = _normalizeName(item.name);

    for (final doc in existingSnapshot.docs) {
      if (doc.id == item.id) continue;
      final existingName = doc.data()['name']?.toString() ?? '';
      if (_normalizeName(existingName) == normalizedName) {
        throw StateError('This name already exists in this list');
      }
    }
  }

  CollectionReference<Map<String, dynamic>> _collection(String categoryId) {
    return firestore
        .collection('app_config')
        .doc(categoryId)
        .collection('items');
  }

  String _normalizeName(String value) => value.trim().toLowerCase();
}
