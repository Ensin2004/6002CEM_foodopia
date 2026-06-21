/// Represents user preferences collected during setup.
/// Contains dietary preferences, allergies, dislikes, and notification settings.
class UserSetupPreferences {
  /// Selected diet type (e.g., vegetarian, keto, none).
  final String? diet;

  /// List of food allergies.
  final List<String> allergies;

  /// List of disliked ingredients.
  final List<String> dislikes;

  /// Daily calorie target (optional).
  final int? targetCalories;

  /// Unit for calorie measurement (e.g., kcal, kJ).
  final String calorieUnit;

  /// Whether calorie targeting is enabled.
  final bool calorieTargetEnabled;

  /// Whether push notifications are enabled.
  final bool notificationsEnabled;

  /// Map of notification preference IDs to enabled status.
  final Map<String, bool> notificationPreferences;

  /// Time for daily notifications (HH:MM format).
  final String notificationTime;

  /// Current step in the setup flow.
  final int currentStep;

  /// Whether the setup process is complete.
  final bool isCompleted;

  /// Creates a new user setup preferences instance.
  const UserSetupPreferences({
    this.diet,
    this.allergies = const [],
    this.dislikes = const [],
    this.targetCalories,
    this.calorieUnit = 'kcal',
    this.calorieTargetEnabled = true,
    this.notificationsEnabled = false,
    this.notificationPreferences = const {},
    this.notificationTime = '08:00',
    this.currentStep = 1,
    this.isCompleted = false,
  });

  /// Creates a copy of this instance with optional field updates.
  ///
  /// [clearDiet] and [clearTargetCalories] allow explicit clearing of
  /// nullable fields by setting them to null.
  UserSetupPreferences copyWith({
    String? diet,
    List<String>? allergies,
    List<String>? dislikes,
    int? targetCalories,
    String? calorieUnit,
    bool? calorieTargetEnabled,
    bool? notificationsEnabled,
    Map<String, bool>? notificationPreferences,
    String? notificationTime,
    int? currentStep,
    bool? isCompleted,
    bool clearDiet = false,
    bool clearTargetCalories = false,
  }) {
    return UserSetupPreferences(
      diet: clearDiet ? null : diet ?? this.diet,
      allergies: allergies ?? this.allergies,
      dislikes: dislikes ?? this.dislikes,
      targetCalories: clearTargetCalories
          ? null
          : targetCalories ?? this.targetCalories,
      calorieUnit: calorieUnit ?? this.calorieUnit,
      calorieTargetEnabled: calorieTargetEnabled ?? this.calorieTargetEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notificationPreferences:
      notificationPreferences ?? this.notificationPreferences,
      notificationTime: notificationTime ?? this.notificationTime,
      currentStep: currentStep ?? this.currentStep,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}