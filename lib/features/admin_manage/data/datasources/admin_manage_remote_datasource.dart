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

  Future<void> seedDefaults({
    required String categoryId,
    required List<String> values,
  }) async {
    final batch = firestore.batch();

    for (var i = 0; i < values.length; i++) {
      final ref = _collection(categoryId).doc();
      batch.set(ref, {
        'name': values[i],
        'description': '',
        'iconKey': '',
        'sortOrder': i + 1,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  CollectionReference<Map<String, dynamic>> _collection(String categoryId) {
    return firestore
        .collection('app_config')
        .doc(categoryId)
        .collection('items');
  }
}
