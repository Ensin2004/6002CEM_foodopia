/// Defines the onboarding item domain entity.

class OnboardingItem {
  /// Path to the image asset for this onboarding screen.
  final String image;

  /// Main title text displayed on the onboarding screen.
  final String title;

  /// Detailed description text explaining the feature.
  final String description;

  /// Creates a onboarding item instance.
  OnboardingItem({
    required this.image,
    required this.title,
    required this.description,
  });
}