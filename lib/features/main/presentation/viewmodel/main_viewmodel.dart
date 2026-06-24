import 'package:flutter/foundation.dart';
import '../../../../app/navigation/navigation_events.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/repositories/main_repository.dart';

/// Defines behavior for main view model.
/// Manages state for the main page with bottom navigation.
class MainViewModel extends ChangeNotifier {
  // =========================================================================
  // DEPENDENCIES
  // =========================================================================

  /// The authenticated user.
  final UserEntity user;

  /// Role passed by the route.
  final String role;

  /// Repository for main operations.
  final MainRepository _repository;

  // =========================================================================
  // STATE
  // =========================================================================

  /// Currently selected tab index.
  int _selectedIndex = 0;

  /// Initial tab index for the meal plan.
  int _mealPlanInitialTabIndex = 0;

  /// URL of the user's profile image.
  String? _profileImageUrl;

  /// Whether data is loading.
  bool _isLoading = false;

  /// Error message.
  String? _errorMessage;

  /// Navigation event to emit.
  MainNavigationEvent? _navigationEvent;

  /// Whether the ViewModel has been disposed.
  bool _isDisposed = false;

  // =========================================================================
  // CONSTRUCTOR
  // =========================================================================

  /// Creates a main view model instance.
  MainViewModel({
    required this.user,
    required this.role,
    required MainRepository repository,
    int initialIndex = 0,
    int initialMealPlanTabIndex = 0,
  }) : _repository = repository,
        _selectedIndex = initialIndex {
    // Clamp the meal plan tab index.
    _mealPlanInitialTabIndex = initialMealPlanTabIndex.clamp(0, 2);

    // Load user profile image.
    _loadUserProfile();

    // Update last login timestamp.
    _updateLastLogin();
  }

  // =========================================================================
  // GETTERS
  // =========================================================================

  /// Currently selected tab index.
  int get selectedIndex => _selectedIndex;

  /// Initial tab index for the meal plan.
  int get mealPlanInitialTabIndex => _mealPlanInitialTabIndex;

  /// URL of the user's profile image.
  String? get profileImageUrl => _profileImageUrl;

  /// Whether data is loading.
  bool get isLoading => _isLoading;

  /// Error message.
  String? get errorMessage => _errorMessage;

  /// Whether the user is an admin.
  bool get isAdmin => user.isAdmin || role.toLowerCase() == 'admin';

  /// Whether the user is a regular user.
  bool get isUser => !isAdmin;

  /// One-time navigation event. Returns and clears the event.
  MainNavigationEvent? get navigationEvent {
    final event = _navigationEvent;
    _navigationEvent = null;
    return event;
  }

  // =========================================================================
  // TAB NAVIGATION
  // =========================================================================

  /// Handles tab tap.
  void onTabTapped(int index) {
    // Handle "Add" tab for users.
    if (!isAdmin && index == 2) {
      _navigationEvent = MainNavigationEvent.goToAddRecipe;
      _notifyIfActive();
      return;
    }

    // Reset meal plan tab index when navigating to meal plan.
    if (!isAdmin && index == 3) {
      _mealPlanInitialTabIndex = 0;
    }

    // Update selected index.
    _selectedIndex = index;
    _notifyIfActive();
  }

  /// Navigates to explore tab.
  void goToExplore() {
    if (isAdmin) return;
    _selectedIndex = 1;
    _notifyIfActive();
  }

  /// Navigates to meal plan tab.
  void goToMealPlan({int initialTabIndex = 0}) {
    if (isAdmin) return;
    _mealPlanInitialTabIndex = initialTabIndex.clamp(0, 2);
    _selectedIndex = 3;
    _notifyIfActive();
  }

  // =========================================================================
  // APP BAR NAVIGATION
  // =========================================================================

  /// Navigates to settings.
  void goToSettings() {
    _navigationEvent = MainNavigationEvent.goToSettings;
    _notifyIfActive();
  }

  /// Navigates to statistics.
  void goToStatistics() {
    _navigationEvent = MainNavigationEvent.goToStatistics;
    _notifyIfActive();
  }

  /// Navigates to notifications.
  void goToNotifications() {
    _navigationEvent = MainNavigationEvent.goToNotifications;
    _notifyIfActive();
  }

  /// Navigates to add recipe.
  void goToAddRecipe() {
    _navigationEvent = MainNavigationEvent.goToAddRecipe;
    _notifyIfActive();
  }

  // =========================================================================
  // PROFILE
  // =========================================================================

  /// Loads the user's profile image.
  Future<void> _loadUserProfile() async {
    // Set loading state.
    _isLoading = true;
    _notifyIfActive();

    // Execute the use case.
    final result = await _repository.getUserProfileImage(user.uid);

    // Check if disposed.
    if (_isDisposed) return;

    // Handle result.
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

  /// Refreshes the profile (called after returning from settings).
  Future<void> refreshProfile() async {
    /// Handles the load user profile operation.
    await _loadUserProfile();
  }

  // =========================================================================
  // LAST LOGIN
  // =========================================================================

  /// Updates the last login timestamp.
  Future<void> _updateLastLogin() async {
    await _repository.updateLastLogin(user.uid);
  }

  // =========================================================================
  // PRIVATE HELPERS
  // =========================================================================

  /// Notifies listeners if the ViewModel is not disposed.
  void _notifyIfActive() {
    if (!_isDisposed) notifyListeners();
  }

  // =========================================================================
  // DISPOSAL
  // =========================================================================

  /// Releases resources before widget removal.
  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}