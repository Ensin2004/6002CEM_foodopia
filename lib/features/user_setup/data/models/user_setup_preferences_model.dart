import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/user_setup_preferences.dart';

class UserSetupPreferencesModel extends UserSetupPreferences {
  const UserSetupPreferencesModel({
    super.diet,
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

  factory UserSetupPreferencesModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserSetupPreferencesModel(
      diet: data['diet'] as String?,
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

  factory UserSetupPreferencesModel.fromEntity(UserSetupPreferences entity) {
    return UserSetupPreferencesModel(
      diet: entity.diet,
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

  Map<String, dynamic> toFirestore() {
    return {
      'diet': diet,
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

  static List<String> _stringList(dynamic value) {
    if (value is! List) return [];
    return value.map((item) => item.toString()).toList();
  }

  static Map<String, bool> _boolMap(dynamic value) {
    if (value is! Map) return {};
    return value.map((key, item) => MapEntry(key.toString(), item == true));
  }
}
