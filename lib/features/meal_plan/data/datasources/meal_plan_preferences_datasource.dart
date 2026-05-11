import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/meal_plan_dashboard_model.dart';

class MealPlanPreferencesDataSource {
  final FirebaseFirestore firestore;

  const MealPlanPreferencesDataSource({required this.firestore});

  Future<MealPlanPreferenceSummaryModel> getPreferences(String uid) async {
    if (uid.trim().isEmpty) {
      return MealPlanPreferenceSummaryModel.empty();
    }

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
