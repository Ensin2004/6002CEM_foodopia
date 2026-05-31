class UserSetupPreferences {
  final String? diet;
  final List<String> allergies;
  final List<String> dislikes;
  final int? targetCalories;
  final String calorieUnit;
  final bool calorieTargetEnabled;
  final bool notificationsEnabled;
  final String notificationTime;
  final int currentStep;
  final bool isCompleted;

  const UserSetupPreferences({
    this.diet,
    this.allergies = const [],
    this.dislikes = const [],
    this.targetCalories,
    this.calorieUnit = 'kcal',
    this.calorieTargetEnabled = true,
    this.notificationsEnabled = false,
    this.notificationTime = '08:00',
    this.currentStep = 1,
    this.isCompleted = false,
  });

  UserSetupPreferences copyWith({
    String? diet,
    List<String>? allergies,
    List<String>? dislikes,
    int? targetCalories,
    String? calorieUnit,
    bool? calorieTargetEnabled,
    bool? notificationsEnabled,
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
      notificationTime: notificationTime ?? this.notificationTime,
      currentStep: currentStep ?? this.currentStep,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
