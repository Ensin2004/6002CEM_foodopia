// Configures the navigation events application module.
// NAVIGATION EVENTS
// ============================================================================
// Type-safe navigation events for all features
// ViewModel emits events, UI handles actual navigation
// ============================================================================

/// Authentication navigation events.
/// Used for navigating between auth-related screens.
enum AuthNavigationEvent {
  /// Navigate to the home screen.
  goToHome,

  /// Navigate to the signup screen.
  goToSignup,

  /// Navigate to the login screen.
  goToLogin,

  /// Navigate to the forgot password screen.
  goToForgotPassword,
}

/// Onboarding navigation events.
/// Used for navigating from the onboarding flow.
enum OnboardingNavigationEvent {
  /// Navigate to the login screen.
  goToLogin,

  /// Navigate to the signup screen.
  goToSignup,
}

/// Main/Home navigation events.
/// Used for navigating from the main app shell.
enum MainNavigationEvent {
  /// Navigate to settings.
  goToSettings,

  /// Navigate to user profile.
  goToProfile,

  /// Navigate to notifications.
  goToNotifications,

  /// Navigate to statistics.
  goToStatistics,

  /// Navigate to add recipe.
  goToAddRecipe,
}

/// Settings navigation events.
/// Used for navigating within the settings section.
enum SettingsNavigationEvent {
  /// Navigate to edit profile.
  goToEditProfile,

  /// Navigate to change password.
  goToChangePassword,

  /// Navigate to about us.
  goToAboutUs,

  /// Navigate to terms and conditions.
  goToTerms,

  /// Navigate to privacy policy.
  goToPrivacy,

  /// Navigate to FAQ.
  goToFaq,

  /// Navigate to rate us.
  goToRateUs,

  /// Navigate to help center.
  goToHelpCenter,

  /// Navigate to age groups admin.
  goToAgeGroups,

  /// Navigate to meal preferences.
  goToMealPreferences,

  /// Navigate to allergies.
  goToAllergies,

  /// Navigate to dislikes.
  goToDislikes,

  /// Navigate to target calories.
  goToTargetCalories,
}

/// Common app navigation events.
/// Used for global navigation across the app.
enum AppNavigationEvent {
  /// Logout the user.
  logout,

  /// Navigate to home.
  goToHome,

  /// Navigate to login.
  goToLogin,

  /// Navigate to onboarding.
  goToOnboarding,

  /// Generic back navigation.
  back,
}