import 'package:flutter/foundation.dart';

import '../../../../app/navigation/navigation_events.dart';
import '../../../../core/services/shared_prefs_manager.dart';
import '../../domain/entities/onboarding_item.dart';

/// Defines behavior for onboarding view model.
class OnboardingViewModel extends ChangeNotifier {
  // =========================================================================
  // STATE
  // =========================================================================

  /// Current page index in the onboarding carousel.
  int _currentIndex = 0;

  /// Whether an async operation is in progress.
  bool _isLoading = false;

  /// Error message from async operations.
  String? _errorMessage;

  /// Navigation event to be emitted.
  OnboardingNavigationEvent? _navigationEvent;

  // =========================================================================
  // ONBOARDING ITEMS
  // =========================================================================

  /// List of onboarding items displayed in the carousel.
  final List<OnboardingItem> onboardingItems = [
    /// Creates a onboarding item instance.
    OnboardingItem(
      image: "assets/images/onboarding1.png",
      title: "Discover your favourite dishes",
      description: "Discover meals you like in minutes, spend less time thinking and more time enjoying!",
    ),
    /// Creates a onboarding item instance.
    OnboardingItem(
      image: "assets/images/onboarding2.png",
      title: "Learn how to prepare your meals easily",
      description: "Easily learn how to prepare, cook and serve your meals with detailed, easy to understand instructions!",
    ),
    /// Creates a onboarding item instance.
    OnboardingItem(
      image: "assets/images/onboarding3.png",
      title: "Plan your meals in advance",
      description: "Personalized meal planning allows you to plan what to eat in advance!",
    ),
    /// Creates a onboarding item instance.
    OnboardingItem(
      image: "assets/images/onboarding4.png",
      title: "Make grocery shopping stress-free",
      description: "Turn your meal plans into organized grocery list in seconds!",
    ),
    /// Creates a onboarding item instance.
    OnboardingItem(
      image: "assets/images/onboarding5.png",
      title: "Share your recipe and more",
      description: "Post, explore and recreate recipes and share your thoughts!",
    ),
  ];

  // =========================================================================
  // GETTERS
  // =========================================================================

  /// Current page index.
  int get currentIndex => _currentIndex;

  /// Whether an async operation is in progress.
  bool get isLoading => _isLoading;

  /// Error message from async operations.
  String? get errorMessage => _errorMessage;

  /// One-time navigation event. Returns and clears the event.
  OnboardingNavigationEvent? get navigationEvent {
    final event = _navigationEvent;
    _navigationEvent = null;
    return event;
  }

  /// Index of the next page (wraps around to 0 at the end).
  int get nextPageIndex {
    final isLast = _currentIndex == onboardingItems.length - 1;
    return isLast ? 0 : _currentIndex + 1;
  }

  // =========================================================================
  // PAGE CHANGE
  // =========================================================================

  /// Handles the on page changed operation.
  void onPageChanged(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  // =========================================================================
  // ONBOARDING COMPLETION
  // =========================================================================

  /// Completes the onboarding process and navigates to login.
  Future<void> completeOnboarding() async {
    // Set loading state.
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Runs the guarded operation that can throw.
      await SharedPrefsManager.setOnboardingCompleted(true);

      // Reset loading state.
      _isLoading = false;
      notifyListeners();

      // Success - emit navigation event.
      _navigationEvent = OnboardingNavigationEvent.goToLogin;
      notifyListeners();
    } catch (e) {
      // Converts the thrown error into the local error path.
      _isLoading = false;
      _errorMessage = 'Failed to complete onboarding. Please try again.';
      notifyListeners();
    }
  }

  /// Navigates to signup after completing onboarding.
  Future<void> goToSignup() async {
    // Set loading state.
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Mark onboarding as completed.
      await SharedPrefsManager.setOnboardingCompleted(true);

      // Reset loading state.
      _isLoading = false;

      // Emit navigation event.
      _navigationEvent = OnboardingNavigationEvent.goToSignup;
      notifyListeners();
    } catch (e) {
      // Handle error.
      _isLoading = false;
      _errorMessage = 'Failed to complete onboarding. Please try again.';
      notifyListeners();
    }
  }

  // =========================================================================
  // ERROR HANDLING
  // =========================================================================

  /// Clear error message.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // =========================================================================
  // RESET
  // =========================================================================

  /// Handles the reset onboarding operation.
  Future<void> resetOnboarding() async {
    await SharedPrefsManager.resetOnboarding();
  }
}