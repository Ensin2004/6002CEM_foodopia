import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/meal_plan_dashboard_model.dart';

/// Data source for retrieving user meal plan preferences from Firestore.
class MealPlanPreferencesDataSource {
  final FirebaseFirestore firestore;

  const MealPlanPreferencesDataSource({required this.firestore});

  // ---------------------------------------------------------------------------
  // Preference Retrieval
  // ---------------------------------------------------------------------------

  /// Fetches the food profile preferences for a given user.
  /// Returns an empty summary model if the UID is invalid or no document exists.
  Future<MealPlanPreferenceSummaryModel> getPreferences(String uid) async {
    // Guard against empty or whitespace-only UIDs.
    if (uid.trim().isEmpty) {
      return MealPlanPreferenceSummaryModel.empty();
    }

    // Retrieve the food_profile document from the user's preferences sub-collection.
    final doc = await firestore
        .collection('users')
        .doc(uid)
        .collection('preferences')
        .doc('food_profile')
        .get();

    final data = doc.data();
    if (data == null) return MealPlanPreferenceSummaryModel.empty();

    return MealPlanPreferenceSummaryModel.fromJson(data);
  }
}