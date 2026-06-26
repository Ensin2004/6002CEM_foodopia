import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/user_setup_preferences.dart';

/// Model class for user setup preferences.
/// Maps between domain entities and Firestore documents.
class UserSetupPreferencesModel extends UserSetupPreferences {
  /// Creates a new user setup preferences model instance.
  const UserSetupPreferencesModel({
    super.diet,
    super.diets,
    super.allergies,
    super.dislikes,
    super.targetCalories,
    super.calorieUnit,
    super.calorieTargetEnabled,
    super.notificationsEnabled,
    super.notificationPreferences,
    super.notificationTime,
    super.currentStep,
    super.isCompleted,
  });

  /// Creates a model from a Firestore document.
  factory UserSetupPreferencesModel.fromFirestore(DocumentSnapshot doc) {
    // Extract data from the document.
    final data = doc.data() as Map<String, dynamic>? ?? {};

    final diets = _stringList(data['diets']);
    final legacyDiet = data['diet'] as String?;

    return UserSetupPreferencesModel(
      diet: legacyDiet,
      diets: diets.isNotEmpty
          ? diets
          : legacyDiet == null || legacyDiet.trim().isEmpty
          ? const []
          : [legacyDiet],
      allergies: _stringList(data['allergies']),
      dislikes: _stringList(data['dislikes']),
      targetCalories: data['targetCalories'] as int?,
      calorieUnit: data['calorieUnit']?.toString() ?? 'kcal',
      calorieTargetEnabled: data['calorieTargetEnabled'] is bool
          ? data['calorieTargetEnabled'] as bool
          : true,
      notificationsEnabled: data['notificationsEnabled'] is bool
          ? data['notificationsEnabled'] as bool
          : false,
      notificationPreferences: _boolMap(data['notificationPreferences']),
      notificationTime: data['notificationTime']?.toString() ?? '08:00',
      currentStep: data['currentStep'] is int ? data['currentStep'] as int : 1,
      isCompleted: data['isCompleted'] is bool
          ? data['isCompleted'] as bool
          : false,
    );
  }

  /// Creates a model from a domain entity.
  factory UserSetupPreferencesModel.fromEntity(UserSetupPreferences entity) {
    return UserSetupPreferencesModel(
      diet: entity.diet,
      diets: entity.diets,
      allergies: entity.allergies,
      dislikes: entity.dislikes,
      targetCalories: entity.targetCalories,
      calorieUnit: entity.calorieUnit,
      calorieTargetEnabled: entity.calorieTargetEnabled,
      notificationsEnabled: entity.notificationsEnabled,
      notificationPreferences: entity.notificationPreferences,
      notificationTime: entity.notificationTime,
      currentStep: entity.currentStep,
      isCompleted: entity.isCompleted,
    );
  }

  /// Converts this model to Firestore data.
  Map<String, dynamic> toFirestore() {
    return {
      'diet': diet,
      'diets': diets,
      'allergies': allergies,
      'dislikes': dislikes,
      'targetCalories': targetCalories,
      'calorieUnit': calorieUnit,
      'calorieTargetEnabled': calorieTargetEnabled,
      'notificationsEnabled': notificationsEnabled,
      'notificationPreferences': notificationPreferences,
      'notificationTime': notificationTime,
      'currentStep': currentStep,
      'isCompleted': isCompleted,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Converts a dynamic value to a list of strings.
  static List<String> _stringList(dynamic value) {
    if (value is! List) return [];
    return value.map((item) => item.toString()).toList();
  }

  /// Converts a dynamic value to a map of string-bool pairs.
  static Map<String, bool> _boolMap(dynamic value) {
    if (value is! Map) return {};
    return value.map((key, item) => MapEntry(key.toString(), item == true));
  }
}
