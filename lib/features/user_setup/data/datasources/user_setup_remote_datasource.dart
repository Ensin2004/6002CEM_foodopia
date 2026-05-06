import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import '../models/user_setup_preferences_model.dart';
import '../../domain/entities/user_setup_option.dart';

class UserSetupRemoteDataSource {
  final FirebaseFirestore firestore;
  final http.Client client;

  UserSetupRemoteDataSource({required this.firestore, required this.client});

  Future<List<UserSetupOption>> getAdminOptions(String categoryId) async {
    final snapshot = await firestore
        .collection('app_config')
        .doc(categoryId)
        .collection('items')
        .where('isActive', isEqualTo: true)
        .orderBy('sortOrder')
        .get();

    return snapshot.docs
        .map((doc) {
          final data = doc.data();
          return UserSetupOption(
            id: doc.id,
            name: data['name']?.toString() ?? '',
          );
        })
        .where((item) => item.name.trim().isNotEmpty)
        .toList();
  }

  Future<List<UserSetupOption>> searchFoods(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return [];

    final uri = Uri.https('world.openfoodfacts.org', '/cgi/search.pl', {
      'search_terms': trimmed,
      'search_simple': '1',
      'action': 'process',
      'json': '1',
      'page_size': '12',
      'fields': 'product_name,generic_name,categories_tags',
    });

    final response = await client.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Food search failed');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final products = data['products'] is List ? data['products'] as List : [];
    final names = <String>{};

    for (final product in products) {
      if (product is! Map<String, dynamic>) continue;
      final productName = product['product_name']?.toString().trim() ?? '';
      final genericName = product['generic_name']?.toString().trim() ?? '';
      final name = productName.isNotEmpty ? productName : genericName;
      if (name.isNotEmpty) names.add(name);
    }

    return names
        .take(8)
        .map(
          (name) => UserSetupOption(
            id: name.toLowerCase().replaceAll(' ', '_'),
            name: name,
            isCustom: true,
          ),
        )
        .toList();
  }

  Future<UserSetupPreferencesModel> getPreferences(String uid) async {
    final doc = await _preferencesDoc(uid).get();
    if (!doc.exists) return const UserSetupPreferencesModel();
    return UserSetupPreferencesModel.fromFirestore(doc);
  }

  Future<bool> isSetupCompleted(String uid) async {
    final doc = await _preferencesDoc(uid).get();
    final data = doc.data();
    return data?['isCompleted'] == true;
  }

  Future<void> savePreferences({
    required String uid,
    required UserSetupPreferencesModel preferences,
  }) async {
    final existing = await _preferencesDoc(uid).get();
    final previous = existing.exists
        ? UserSetupPreferencesModel.fromFirestore(existing)
        : const UserSetupPreferencesModel();

    await _preferencesDoc(
      uid,
    ).set(preferences.toFirestore(), SetOptions(merge: true));

    await firestore.collection('users').doc(uid).set({
      'onboardingCompleted': preferences.isCompleted,
      'onboardingStep': preferences.currentStep,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _saveCalorieTargetHistory(
      uid: uid,
      previous: previous,
      next: preferences,
    );
  }

  DocumentReference<Map<String, dynamic>> _preferencesDoc(String uid) {
    return firestore
        .collection('users')
        .doc(uid)
        .collection('preferences')
        .doc('food_profile');
  }

  Future<void> _saveCalorieTargetHistory({
    required String uid,
    required UserSetupPreferencesModel previous,
    required UserSetupPreferencesModel next,
  }) async {
    final changed =
        previous.calorieTargetEnabled != next.calorieTargetEnabled ||
        previous.targetCalories != next.targetCalories ||
        previous.calorieUnit != next.calorieUnit;

    if (!changed) return;

    final collection = firestore
        .collection('users')
        .doc(uid)
        .collection('calorie_targets');

    final activeTargets = await collection
        .where('endedAt', isNull: true)
        .limit(1)
        .get();

    final batch = firestore.batch();
    for (final doc in activeTargets.docs) {
      batch.update(doc.reference, {'endedAt': FieldValue.serverTimestamp()});
    }

    if (next.calorieTargetEnabled && next.targetCalories != null) {
      batch.set(collection.doc(), {
        'targetCalories': next.targetCalories,
        'calorieUnit': next.calorieUnit,
        'startedAt': FieldValue.serverTimestamp(),
        'endedAt': null,
      });
    }

    await batch.commit();
  }
}
