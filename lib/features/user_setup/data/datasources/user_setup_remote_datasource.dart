import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/services/food_search_service.dart';
import '../models/user_setup_preferences_model.dart';
import '../../domain/entities/user_setup_option.dart';

class UserSetupRemoteDataSource {
  final FirebaseFirestore firestore;
  final FoodSearchService foodSearchService;
  final Map<String, List<UserSetupOption>> _adminOptionsCache = {};
  final Map<String, UserSetupPreferencesModel> _preferencesCache = {};

  UserSetupRemoteDataSource({
    required this.firestore,
    required this.foodSearchService,
  });

  Future<List<UserSetupOption>> getAdminOptions(String categoryId) async {
    final cached = _adminOptionsCache[categoryId];
    if (cached != null) return cached;

    final snapshot = await firestore
        .collection('app_config')
        .doc(categoryId)
        .collection('items')
        .get()
        .timeout(const Duration(seconds: 8));

    final docs = snapshot.docs.toList()
      ..sort((first, second) {
        final firstOrder = first.data()['sortOrder'];
        final secondOrder = second.data()['sortOrder'];
        final left = firstOrder is int ? firstOrder : 0;
        final right = secondOrder is int ? secondOrder : 0;
        return left.compareTo(right);
      });

    final options = docs
        .map((doc) {
          final data = doc.data();
          final isActive = data['isActive'] is bool
              ? data['isActive'] as bool
              : true;
          if (!isActive) return null;

          return UserSetupOption(
            id: doc.id,
            name: data['name']?.toString() ?? '',
          );
        })
        .whereType<UserSetupOption>()
        .where((item) {
          return item.name.trim().isNotEmpty;
        })
        .toList();
    _adminOptionsCache[categoryId] = options;
    return options;
  }

  Future<List<UserSetupOption>> searchFoods(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return [];

    final terms = await foodSearchService.searchFoodTerms(trimmed);
    return terms
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
    final cached = _preferencesCache[uid];
    if (cached != null) return cached;

    final doc = await _preferencesDoc(
      uid,
    ).get().timeout(const Duration(seconds: 8));
    if (!doc.exists) return const UserSetupPreferencesModel();
    final preferences = UserSetupPreferencesModel.fromFirestore(doc);
    _preferencesCache[uid] = preferences;
    return preferences;
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
    _preferencesCache[uid] = preferences;

    await firestore.collection('users').doc(uid).set({
      'onboardingCompleted': preferences.isCompleted,
      'onboardingStep': preferences.currentStep,
      'notificationPreferences': preferences.notificationPreferences,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _saveNotificationPreferences(
      uid: uid,
      notificationPreferences: preferences.notificationPreferences,
    );

    await _saveCalorieTargetHistory(
      uid: uid,
      previous: previous,
      next: preferences,
    );
  }

  Future<void> _saveNotificationPreferences({
    required String uid,
    required Map<String, bool> notificationPreferences,
  }) async {
    if (notificationPreferences.isEmpty) return;

    final collection = firestore
        .collection('users')
        .doc(uid)
        .collection('notification_preferences');
    final batch = firestore.batch();

    notificationPreferences.forEach((id, enabled) {
      if (id.trim().isEmpty) return;
      batch.set(collection.doc(id), {
        'enabled': enabled,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });

    await batch.commit();
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
