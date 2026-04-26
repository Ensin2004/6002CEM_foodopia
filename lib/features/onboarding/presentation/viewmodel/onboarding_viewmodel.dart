import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/navigation/navigation_events.dart';
import '../../../../core/utils/shared_prefs_manager.dart';
import '../../domain/entities/onboarding_item.dart';

class OnboardingViewModel extends ChangeNotifier {
  final PageController pageController = PageController();

  int _currentIndex = 0;
  Timer? _timer;
  bool _isLoading = false;
  String? _errorMessage;  // ✅ Add error message state

  // ✅ Navigation event
  OnboardingNavigationEvent? _navigationEvent;

  final List<OnboardingItem> onboardingItems = [
    OnboardingItem(
      image: "assets/images/onboarding1.png",
      title: "Smart Meal Planning",
      description: "Take the guesswork out of your kitchen. Organize your daily and weekly meals with a simple drag-and-drop interface.",
    ),
    OnboardingItem(
      image: "assets/images/onboarding2.png",
      title: "AI Recipe Generator",
      description: "Got random ingredients? Our AI creates delicious, step-by-step recipes based exactly on what's sitting in your fridge.",
    ),
    OnboardingItem(
      image: "assets/images/onboarding3.png",
      title: "Reduce Food Waste",
      description: "Save money and the planet. Get smart alerts when your ingredients are about to expire so you never throw food away again.",
    ),
    OnboardingItem(
      image: "assets/images/onboarding4.png",
      title: "Personalized For You",
      description: "A kitchen that knows you. Discover new favorites with recipe recommendations tailored to your diet and taste buds.",
    ),
  ];

  // Getters
  int get currentIndex => _currentIndex;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;  // ✅ Error message getter

  // ✅ One-time navigation event
  OnboardingNavigationEvent? get navigationEvent {
    final event = _navigationEvent;
    _navigationEvent = null;
    return event;
  }

  void onPageChanged(int index) {
    _currentIndex = index;
    HapticFeedback.lightImpact();
    notifyListeners();
  }

  void nextPage() {
    final isLast = _currentIndex == onboardingItems.length - 1;
    if (isLast) {
      pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    } else {
      pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
  }

  void startAutoPlay() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!pageController.hasClients) return;
      nextPage();
    });
  }

  // ✅ Complete onboarding with error handling
  Future<void> completeOnboarding() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await SharedPrefsManager.setOnboardingCompleted(true);

      _isLoading = false;
      notifyListeners();

      // ✅ Success - emit navigation event
      _navigationEvent = OnboardingNavigationEvent.goToLogin;
      notifyListeners();

    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to complete onboarding. Please try again.';
      notifyListeners();
    }
  }

  // ✅ Go to signup
  void goToSignup() {
    _navigationEvent = OnboardingNavigationEvent.goToSignup;
    notifyListeners();
  }

  // ✅ Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void stopAutoPlay() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> resetOnboarding() async {
    await SharedPrefsManager.resetOnboarding();
  }

  @override
  void dispose() {
    stopAutoPlay();
    pageController.dispose();
    super.dispose();
  }
}