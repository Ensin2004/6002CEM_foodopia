import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/services/food_search_service.dart';
import '../models/user_setup_preferences_model.dart';
import '../../domain/entities/user_setup_option.dart';

/// Remote data source for user setup preferences.
/// Handles fetching admin options, food search, and preference storage.
class UserSetupRemoteDataSource {
  /// Firestore instance for database operations.
  final FirebaseFirestore firestore;

  /// Service for searching foods.
  final FoodSearchService foodSearchService;

  /// Cache for admin options by category ID.
  final Map<String, List<UserSetupOption>> _adminOptionsCache = {};

  /// Cache for user preferences by UID.
  final Map<String, UserSetupPreferencesModel> _preferencesCache = {};

  /// Creates a new user setup remote data source instance.
  UserSetupRemoteDataSource({
    required this.firestore,
    required this.foodSearchService,
  });

  // =========================================================================
  // ADMIN OPTIONS
  // =========================================================================

  /// Retrieves admin-configured options for a category.
  Future<List<UserSetupOption>> getAdminOptions(String categoryId) async {
    // Check cache first.
    final cached = _adminOptionsCache[categoryId];
    if (cached != null) return cached;

    // Query the collection.
    final snapshot = await firestore
        .collection('app_config')
        .doc(categoryId)
        .collection('items')
        .get()
        .timeout(const Duration(seconds: 8));

    // Sort by sort order.
    final docs = snapshot.docs.toList()
      ..sort((first, second) {
        final firstOrder = first.data()['sortOrder'];
        final secondOrder = second.data()['sortOrder'];
        final left = firstOrder is int ? firstOrder : 0;
        final right = secondOrder is int ? secondOrder : 0;
        return left.compareTo(right);
      });

    // Map to options, filtering inactive ones.
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

    // Cache the results.
    _adminOptionsCache[categoryId] = options;
    return options;
  }

  // =========================================================================
  // FOOD SEARCH
  // =========================================================================

  /// Searches for foods matching a query.
  Future<List<UserSetupOption>> searchFoods(String query) async {
    final trimmed = query.trim();

    // Return empty if query is too short.
    if (trimmed.length < 2) return [];

    // Search for food terms.
    final terms = await foodSearchService.searchFoodTerms(trimmed);

    // Map to options.
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

  // =========================================================================
  // PREFERENCES
  // =========================================================================

  /// Retrieves user preferences.
  Future<UserSetupPreferencesModel> getPreferences(String uid) async {
    // Check cache first.
    final cached = _preferencesCache[uid];
    if (cached != null) return cached;

    // Query the document.
    final doc = await _preferencesDoc(
      uid,
    ).get().timeout(const Duration(seconds: 8));

    // Return empty preferences if document doesn't exist.
    if (!doc.exists) return const UserSetupPreferencesModel();

    // Parse and cache the preferences.
    final preferences = UserSetupPreferencesModel.fromFirestore(doc);
    _preferencesCache[uid] = preferences;
    return preferences;
  }

  /// Checks if user setup is completed.
  Future<bool> isSetupCompleted(String uid) async {
    final doc = await _preferencesDoc(uid).get();
    final data = doc.data();
    return data?['isCompleted'] == true;
  }

  // =========================================================================
  // SAVE PREFERENCES
  // =========================================================================

  /// Saves user preferences.
  Future<void> savePreferences({
    required String uid,
    required UserSetupPreferencesModel preferences,
  }) async {
    // Get existing preferences for comparison.
    final existing = await _preferencesDoc(uid).get();
    final previous = existing.exists
        ? UserSetupPreferencesModel.fromFirestore(existing)
        : const UserSetupPreferencesModel();

    // Save to Firestore.
    await _preferencesDoc(
      uid,
    ).set(preferences.toFirestore(), SetOptions(merge: true));

    // Update cache.
    _preferencesCache[uid] = preferences;

    // Update user document.
    await firestore.collection('users').doc(uid).set({
      'onboardingCompleted': preferences.isCompleted,
      'onboardingStep': preferences.currentStep,
      'notificationPreferences': preferences.notificationPreferences,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Save notification preferences.
    await _saveNotificationPreferences(
      uid: uid,
      notificationPreferences: preferences.notificationPreferences,
    );

    // Save calorie target history.
    await _saveCalorieTargetHistory(
      uid: uid,
      previous: previous,
      next: preferences,
    );
  }

  // =========================================================================
  // NOTIFICATION PREFERENCES
  // =========================================================================

  /// Saves notification preferences to Firestore.
  Future<void> _saveNotificationPreferences({
    required String uid,
    required Map<String, bool> notificationPreferences,
  }) async {
    // Return if empty.
    if (notificationPreferences.isEmpty) return;

    // Get the collection reference.
    final collection = firestore
        .collection('users')
        .doc(uid)
        .collection('notification_preferences');

    // Start a batch write.
    final batch = firestore.batch();

    // Save each preference.
    notificationPreferences.forEach((id, enabled) {
      if (id.trim().isEmpty) return;
      batch.set(collection.doc(id), {
        'enabled': enabled,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });

    // Commit the batch.
    await batch.commit();
  }

  // =========================================================================
  // PRIVATE HELPERS
  // =========================================================================

  /// Returns a reference to the preferences document.
  DocumentReference<Map<String, dynamic>> _preferencesDoc(String uid) {
    return firestore
        .collection('users')
        .doc(uid)
        .collection('preferences')
        .doc('food_profile');
  }

  // =========================================================================
  // CALORIE TARGET HISTORY
  // =========================================================================

  /// Saves calorie target history.
  Future<void> _saveCalorieTargetHistory({
    required String uid,
    required UserSetupPreferencesModel previous,
    required UserSetupPreferencesModel next,
  }) async {
    // Check if calorie target changed.
    final changed =
        previous.calorieTargetEnabled != next.calorieTargetEnabled ||
            previous.targetCalories != next.targetCalories ||
            previous.calorieUnit != next.calorieUnit;

    // Return if no changes.
    if (!changed) return;

    // Get the collection reference.
    final collection = firestore
        .collection('users')
        .doc(uid)
        .collection('calorie_targets');

    // End active targets.
    final activeTargets = await collection
        .where('endedAt', isNull: true)
        .limit(1)
        .get();

    // Start a batch write.
    final batch = firestore.batch();

    // End existing active targets.
    for (final doc in activeTargets.docs) {
      batch.update(doc.reference, {'endedAt': FieldValue.serverTimestamp()});
    }

    // Create a new target if enabled.
    if (next.calorieTargetEnabled && next.targetCalories != null) {
      batch.set(collection.doc(), {
        'targetCalories': next.targetCalories,
        'calorieUnit': next.calorieUnit,
        'startedAt': FieldValue.serverTimestamp(),
        'endedAt': null,
      });
    }

    // Commit the batch.
    await batch.commit();
  }
}