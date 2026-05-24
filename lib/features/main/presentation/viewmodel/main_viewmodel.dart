import 'package:flutter/foundation.dart';
import '../../../../app/navigation/navigation_events.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/repositories/main_repository.dart';

/// Defines behavior for main view model.
class MainViewModel extends ChangeNotifier {
  final UserEntity user;
  final MainRepository _repository;

  int _selectedIndex = 0;
  int _mealPlanInitialTabIndex = 0;
  String? _profileImageUrl;
  bool _isLoading = false;
  String? _errorMessage;
  MainNavigationEvent? _navigationEvent;
  bool _isDisposed = false;

  /// Creates a main view model instance.
  MainViewModel({
    required this.user,
    required MainRepository repository,
    int initialIndex = 0,
    int initialMealPlanTabIndex = 0,
  }) : _repository = repository,
       _selectedIndex = initialIndex {
    _mealPlanInitialTabIndex = initialMealPlanTabIndex.clamp(0, 2);
    _loadUserProfile();
    _updateLastLogin();
  }

  // Getters
  int get selectedIndex => _selectedIndex;

  int get mealPlanInitialTabIndex => _mealPlanInitialTabIndex;

  /// Handles the profile image url operation.
  String? get profileImageUrl => _profileImageUrl;

  /// Handles the is loading operation.
  bool get isLoading => _isLoading;

  /// Handles the error message operation.
  String? get errorMessage => _errorMessage;

  /// Handles the is admin operation.
  bool get isAdmin => user.isAdmin;

  /// Handles the is user operation.
  bool get isUser => user.isUser;

  /// Handles the navigation event operation.
  MainNavigationEvent? get navigationEvent {
    final event = _navigationEvent;
    _navigationEvent = null;
    return event;
  }

  // Navigation
  void onTabTapped(int index) {
    if (!isAdmin && index == 2) {
      _navigationEvent = MainNavigationEvent.goToAddRecipe;
      _notifyIfActive();
      return;
    }

    if (!isAdmin && index == 3) {
      _mealPlanInitialTabIndex = 0;
    }

    _selectedIndex = index;
    _notifyIfActive();
  }

  void goToExplore() {
    if (isAdmin) return;
    _selectedIndex = 1;
    _notifyIfActive();
  }

  void goToMealPlan({int initialTabIndex = 0}) {
    if (isAdmin) return;
    _mealPlanInitialTabIndex = initialTabIndex.clamp(0, 2);
    _selectedIndex = 3;
    _notifyIfActive();
  }

  /// Handles the go to settings operation.
  void goToSettings() {
    _navigationEvent = MainNavigationEvent.goToSettings;
    _notifyIfActive();
  }

  /// Handles the go to statistics operation.
  void goToStatistics() {
    _navigationEvent = MainNavigationEvent.goToStatistics;
    _notifyIfActive();
  }

  /// Handles the go to notifications operation.
  void goToNotifications() {
    _navigationEvent = MainNavigationEvent.goToNotifications;
    _notifyIfActive();
  }

  /// Handles the go to add recipe operation.
  void goToAddRecipe() {
    _navigationEvent = MainNavigationEvent.goToAddRecipe;
    _notifyIfActive();
  }

  // Load profile image
  Future<void> _loadUserProfile() async {
    _isLoading = true;
    _notifyIfActive();

    final result = await _repository.getUserProfileImage(user.uid);
    if (_isDisposed) return;

    result.fold(
      (failure) {
        _errorMessage = failure.message;
        _isLoading = false;
        _notifyIfActive();
      },
      (imageUrl) {
        _profileImageUrl = imageUrl;
        _isLoading = false;
        _notifyIfActive();
      },
    );
  }

  // Refresh profile (called after returning from settings)
  Future<void> refreshProfile() async {
    /// Handles the load user profile operation.
    await _loadUserProfile();
  }

  // Update last login timestamp
  Future<void> _updateLastLogin() async {
    await _repository.updateLastLogin(user.uid);
  }

  void _notifyIfActive() {
    if (!_isDisposed) notifyListeners();
  }

  /// Releases resources before widget removal.
  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
