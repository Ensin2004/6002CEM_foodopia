// Handles remote data access for faq.

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/cloudinary_service.dart';

/// Defines behavior for faq remote data source.
class FaqRemoteDataSource {
  final FirebaseFirestore _firestore;

  /// Creates a faq remote data source instance.
  FaqRemoteDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('support_center').doc('faq').collection('items');

  /// Loads data for the get user faq items operation.
  Future<QuerySnapshot> getUserFaqItems() async {
    return await _collection.orderBy('createdAt', descending: true).get();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchUserFaqItems() {
    return _collection.orderBy('createdAt', descending: true).snapshots();
  }

  /// Loads data for the get admin faq items operation.
  Future<QuerySnapshot> getAdminFaqItems() async {
    return await _collection.orderBy('createdAt', descending: true).get();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchAdminFaqItems() {
    return _collection.orderBy('createdAt', descending: true).snapshots();
  }

  /// Handles the add faq item operation.
  Future<void> addFaqItem(Map<String, dynamic> data) async {
    await _collection.add(data);
  }

  /// Runs the update faq item operation.
  Future<void> updateFaqItem(String id, Map<String, dynamic> data) async {
    await _collection.doc(id).update(data);
  }

  /// Runs the delete faq item operation.
  Future<void> deleteFaqItem(String id) async {
    await _collection.doc(id).delete();
  }

  /// Runs the upload faq image operation.
  Future<String> uploadFaqImage(File imageFile) async {
    return await CloudinaryService.uploadSupportImage(imageFile);
  }
}
