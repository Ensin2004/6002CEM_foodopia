// ============================================================================
// NAVIGATION EVENTS
// ============================================================================
// Type-safe navigation events for all features
// ViewModel emits events, UI handles actual navigation
// ============================================================================

/// Authentication navigation events
enum AuthNavigationEvent {
  goToHome,
  goToSignup,
  goToLogin,
  goToForgotPassword,
}

/// Onboarding navigation events
enum OnboardingNavigationEvent {
  goToLogin,
  goToSignup,
}

/// Main/Home navigation events
enum MainNavigationEvent {
  goToSettings,
  goToProfile,
  goToNotifications,
  goToStatistics,
}

/// Settings navigation events
enum SettingsNavigationEvent {
  goToEditProfile,
  goToChangePassword,
  goToAboutUs,
  goToTerms,
  goToPrivacy,
  goToFaq,
  goToRateUs,
  goToHelpCenter,
}

/// Common app navigation events
enum AppNavigationEvent {
  logout,
  goToHome,
  goToLogin,
  goToOnboarding,
  back,  // Generic back navigation
}