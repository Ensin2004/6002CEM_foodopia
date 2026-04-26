import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/cloudinary_service.dart';

class FaqRemoteDataSource {
  final FirebaseFirestore _firestore;

  FaqRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<QuerySnapshot> getUserFaqItems() async {
    return await _firestore
        .collection('support')
        .doc('faq')
        .collection('faq_items')
        .orderBy('createdAt', descending: true)
        .get();
  }

  Future<QuerySnapshot> getAdminFaqItems() async {
    return await _firestore
        .collection('support')
        .doc('faq')
        .collection('faq_items')
        .orderBy('createdAt', descending: true)
        .get();
  }

  Future<void> addFaqItem(Map<String, dynamic> data) async {
    await _firestore
        .collection('support')
        .doc('faq')
        .collection('faq_items')
        .add(data);
  }

  Future<void> updateFaqItem(String id, Map<String, dynamic> data) async {
    await _firestore
        .collection('support')
        .doc('faq')
        .collection('faq_items')
        .doc(id)
        .update(data);
  }

  Future<void> deleteFaqItem(String id) async {
    await _firestore
        .collection('support')
        .doc('faq')
        .collection('faq_items')
        .doc(id)
        .delete();
  }

  Future<String> uploadFaqImage(File imageFile) async {
    return await CloudinaryService.uploadSupportImage(imageFile);
  }
}