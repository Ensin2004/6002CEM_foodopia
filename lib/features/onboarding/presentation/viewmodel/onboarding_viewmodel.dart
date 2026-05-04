import 'package:flutter/foundation.dart';
import '../../../../app/navigation/navigation_events.dart';
import '../../../../core/services/shared_prefs_manager.dart';
import '../../domain/entities/onboarding_item.dart';

/// Defines behavior for onboarding view model.
class OnboardingViewModel extends ChangeNotifier {
  int _currentIndex = 0;
  bool _isLoading = false;
  String? _errorMessage;  // Add error message state

  // Navigation event
  OnboardingNavigationEvent? _navigationEvent;

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

  // Getters
  int get currentIndex => _currentIndex;
  /// Handles the is loading operation.
  bool get isLoading => _isLoading;
  /// Handles the error message operation.
  String? get errorMessage => _errorMessage;  // Error message getter

  // One-time navigation event
  OnboardingNavigationEvent? get navigationEvent {
    final event = _navigationEvent;
    _navigationEvent = null;
    return event;
  }

  /// Handles the on page changed operation.
  void onPageChanged(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  /// Handles the next page index operation.
  int get nextPageIndex {
    final isLast = _currentIndex == onboardingItems.length - 1;
    return isLast ? 0 : _currentIndex + 1;
  }

  // Complete onboarding with error handling
  Future<void> completeOnboarding() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Runs the guarded operation that can throw.
      await SharedPrefsManager.setOnboardingCompleted(true);

      _isLoading = false;
      notifyListeners();

      // Success - emit navigation event
      _navigationEvent = OnboardingNavigationEvent.goToLogin;
      notifyListeners();

    } catch (e) {
      // Converts the thrown error into the local error path.
      _isLoading = false;
      _errorMessage = 'Failed to complete onboarding. Please try again.';
      notifyListeners();
    }
  }

  // Go to signup
  Future<void> goToSignup() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await SharedPrefsManager.setOnboardingCompleted(true);

      _isLoading = false;
      _navigationEvent = OnboardingNavigationEvent.goToSignup;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to complete onboarding. Please try again.';
      notifyListeners();
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Handles the reset onboarding operation.
  Future<void> resetOnboarding() async {
    await SharedPrefsManager.resetOnboarding();
  }
}
