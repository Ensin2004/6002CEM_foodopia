import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/extensions/either_extensions.dart';
import '../../../../core/services/shared_prefs_manager.dart';
import '../../../notifications/domain/entities/notification_preference.dart';
import '../../../notifications/domain/usecases/get_notification_preferences_usecase.dart';
import '../../../notifications/domain/usecases/update_notification_preference_usecase.dart';
import '../../domain/entities/user_setup_option.dart';
import '../../domain/entities/user_setup_preferences.dart';
import '../../domain/usecases/get_user_setup_options_usecase.dart';
import '../../domain/usecases/get_user_setup_preferences_usecase.dart';
import '../../domain/usecases/save_user_setup_preferences_usecase.dart';
import '../../domain/usecases/search_user_setup_foods_usecase.dart';

/// Navigation events for the user setup flow.
enum UserSetupNavigationEvent {
  /// Navigate to allergies page.
  goToAllergies,

  /// Navigate to dislikes page.
  goToDislikes,

  /// Navigate to calories page.
  goToCalories,

  /// Navigate to notifications page.
  goToNotifications,

  /// Navigate to home page.
  goToHome,

  /// Close settings and go back.
  closeSettings,
}

/// ViewModel for the user setup flow.
/// Manages state for diet, allergies, dislikes, calories, and notifications.
class UserSetupViewModel extends ChangeNotifier {
  // =========================================================================
  // CONSTANTS
  // =========================================================================

  /// Default value for "no diet" selection.
  static const noDietValue = 'No specific diet';

  /// Total number of steps in the setup flow.
  static const totalSteps = 5;

  /// List of notification preference IDs.
  static const notificationPreferenceIds = [
    'new_follower_notification',
    'new_rating_notification',
    'new_comment_notification',
    'new_recipe_notification',
    'new_reply_notification',
    'plan_reminder_notification',
  ];

  // =========================================================================
  // DEPENDENCIES
  // =========================================================================

  /// User ID.
  final String uid;

  /// Use case for getting admin options.
  final GetUserSetupOptionsUseCase _getOptionsUseCase;

  /// Use case for searching foods.
  final SearchUserSetupFoodsUseCase _searchFoodsUseCase;

  /// Use case for getting user preferences.
  final GetUserSetupPreferencesUseCase _getPreferencesUseCase;

  /// Use case for saving user preferences.
  final SaveUserSetupPreferencesUseCase _savePreferencesUseCase;

  /// Use case for getting notification preferences.
  final GetNotificationPreferencesUseCase _getNotificationPreferencesUseCase;

  /// Use case for updating notification preferences.
  final UpdateNotificationPreferenceUseCase
  _updateNotificationPreferenceUseCase;

  // =========================================================================
  // STATE
  // =========================================================================

  /// Whether data is loading.
  bool _isLoading = false;

  /// Whether saving is in progress.
  bool _isSaving = false;

  /// Whether search is in progress.
  bool _isSearching = false;

  /// Error message.
  String? _errorMessage;

  /// Diet options.
  List<UserSetupOption> _dietOptions = const [];

  /// Allergy options.
  List<UserSetupOption> _allergyOptions = const [];

  /// Dislike options.
  List<UserSetupOption> _dislikeOptions = const [];

  /// Search results.
  List<UserSetupOption> _searchResults = const [];

  /// Notification preferences.
  List<NotificationPreference> _notificationPreferences = const [];

  /// User preferences.
  UserSetupPreferences _preferences = const UserSetupPreferences();

  /// Notification settings map.
  final Map<String, bool> _notificationSettings = {};

  /// Active search query.
  String _activeSearchQuery = '';

  /// Debounce timer for search.
  Timer? _searchDebounce;

  /// Whether the ViewModel has been disposed.
  bool _isDisposed = false;

  /// Navigation event to emit.
  UserSetupNavigationEvent? _navigationEvent;

  // =========================================================================
  // CONSTRUCTOR
  // =========================================================================

  /// Creates a new user setup view model instance.
  UserSetupViewModel({
    required this.uid,
    required GetUserSetupOptionsUseCase getOptionsUseCase,
    required SearchUserSetupFoodsUseCase searchFoodsUseCase,
    required GetUserSetupPreferencesUseCase getPreferencesUseCase,
    required SaveUserSetupPreferencesUseCase savePreferencesUseCase,
    required GetNotificationPreferencesUseCase
    getNotificationPreferencesUseCase,
    required UpdateNotificationPreferenceUseCase
    updateNotificationPreferenceUseCase,
  }) : _getOptionsUseCase = getOptionsUseCase,
        _searchFoodsUseCase = searchFoodsUseCase,
        _getPreferencesUseCase = getPreferencesUseCase,
        _savePreferencesUseCase = savePreferencesUseCase,
        _getNotificationPreferencesUseCase = getNotificationPreferencesUseCase,
        _updateNotificationPreferenceUseCase =
            updateNotificationPreferenceUseCase;

  // =========================================================================
  // GETTERS
  // =========================================================================

  /// Whether data is loading.
  bool get isLoading => _isLoading;

  /// Whether saving is in progress.
  bool get isSaving => _isSaving;

  /// Whether search is in progress.
  bool get isSearching => _isSearching;

  /// Error message.
  String? get errorMessage => _errorMessage;

  /// Diet options.
  List<UserSetupOption> get dietOptions => _dietOptions;

  /// Allergy options.
  List<UserSetupOption> get allergyOptions => _allergyOptions;

  /// Dislike options.
  List<UserSetupOption> get dislikeOptions => _dislikeOptions;

  /// Search results.
  List<UserSetupOption> get searchResults => _searchResults;

  /// Notification preferences.
  List<NotificationPreference> get notificationPreferences =>
      List.unmodifiable(_notificationPreferences);

  /// User preferences.
  UserSetupPreferences get preferences => _preferences;

  /// Gets a notification value by ID.
  bool notificationValue(String id) =>
      _notificationSettings[id] ??
          SharedPrefsManager.isNotificationTypeEnabled(id);

  /// One-time navigation event. Returns and clears the event.
  UserSetupNavigationEvent? get navigationEvent {
    final event = _navigationEvent;
    _navigationEvent = null;
    return event;
  }

  // =========================================================================
  // LOAD
  // =========================================================================

  /// Loads all data for the setup flow.
  Future<void> load({
    List<String> optionCategoryIds = const [
      'meal_preferences',
      'allergies',
      'dislikes',
    ],
  }) async {
    // Set loading state.
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Load user preferences.
    final preferencesResult = await _getPreferencesUseCase.execute(uid);
    preferencesResult.ifLeft((failure) => _errorMessage = failure.message);
    preferencesResult.ifRight((preferences) {
      _preferences = _withoutEmptyChoices(preferences);
    });

    // Load options for each category.
    await Future.wait(optionCategoryIds.map(_loadOptions));

    // Load notification settings.
    await _loadNotificationSettings();

    // Reset loading state.
    _isLoading = false;
    notifyListeners();
  }

  // =========================================================================
  // SEARCH
  // =========================================================================

  /// Searches for foods matching a query.
  Future<void> search(String query) async {
    // Cancel any pending search.
    _searchDebounce?.cancel();

    // Get trimmed query.
    final trimmed = query.trim();

    // Clear results if query is too short.
    if (trimmed.length < 2) {
      _activeSearchQuery = '';
      _searchResults = const [];
      _isSearching = false;
      notifyListeners();
      return;
    }

    // Set searching state.
    _activeSearchQuery = trimmed;
    _isSearching = true;
    _errorMessage = null;
    notifyListeners();

    // Debounce the search.
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      _runSearch(trimmed);
    });
  }

  /// Executes the search.
  Future<void> _runSearch(String trimmed) async {
    // Execute the search.
    final result = await _searchFoodsUseCase.execute(trimmed);

    // Check if disposed or search query changed.
    if (_isDisposed || _activeSearchQuery != trimmed) return;

    // Handle result.
    result.ifLeft((failure) => _errorMessage = failure.message);
    result.ifRight((items) {
      _searchResults = items
          .where((item) => !_isEmptyChoiceName(item.name))
          .toList();
    });

    // Reset searching state.
    _isSearching = false;
    notifyListeners();
  }

  /// Clears the search.
  void clearSearch() {
    _searchDebounce?.cancel();
    _activeSearchQuery = '';
    _searchResults = const [];
    _isSearching = false;
    notifyListeners();
  }

  // =========================================================================
  // DISPOSAL
  // =========================================================================

  @override
  void dispose() {
    _isDisposed = true;
    _searchDebounce?.cancel();
    super.dispose();
  }

  // =========================================================================
  // DIET
  // =========================================================================

  /// Selects a diet.
  void selectDiet(String value) {
    if (_isEmptyChoiceName(value)) {
      clearDiet();
      return;
    }
    _preferences = _preferences.copyWith(diet: value);
    notifyListeners();
  }

  /// Clears the diet selection.
  void clearDiet() {
    _preferences = _preferences.copyWith(clearDiet: true);
    notifyListeners();
  }

  // =========================================================================
  // ALLERGIES
  // =========================================================================

  /// Toggles an allergy.
  void toggleAllergy(String value) {
    if (_isEmptyChoiceName(value)) return;
    _preferences = _preferences.copyWith(
      allergies: _toggleValue(_preferences.allergies, value),
    );
    notifyListeners();
  }

  /// Clears all allergies.
  void clearAllergies() {
    _preferences = _preferences.copyWith(allergies: const []);
    notifyListeners();
  }

  // =========================================================================
  // DISLIKES
  // =========================================================================

  /// Toggles a dislike.
  void toggleDislike(String value) {
    if (_isEmptyChoiceName(value)) return;
    _preferences = _preferences.copyWith(
      dislikes: _toggleValue(_preferences.dislikes, value),
    );
    notifyListeners();
  }

  /// Clears all dislikes.
  void clearDislikes() {
    _preferences = _preferences.copyWith(dislikes: const []);
    notifyListeners();
  }

  // =========================================================================
  // CALORIES
  // =========================================================================

  /// Sets calorie target enabled.
  void setCalorieTargetEnabled(bool value) {
    _preferences = _preferences.copyWith(
      calorieTargetEnabled: value,
      clearTargetCalories: !value,
    );
    notifyListeners();
  }

  /// Sets calorie unit.
  void setCalorieUnit(String value) {
    _preferences = _preferences.copyWith(calorieUnit: value);
    notifyListeners();
  }

  /// Sets target calories.
  void setTargetCalories(int? value) {
    _preferences = _preferences.copyWith(
      targetCalories: value,
      clearTargetCalories: value == null,
    );
    notifyListeners();
  }

  // =========================================================================
  // NOTIFICATIONS
  // =========================================================================

  /// Sets notifications enabled/disabled.
  Future<void> setNotificationsEnabled(bool value) async {
    // Update preferences.
    _preferences = _preferences.copyWith(
      notificationsEnabled: value,
      notificationPreferences: {
        for (final id in notificationPreferenceIds) id: value,
      },
    );

    // Save to shared preferences.
    await SharedPrefsManager.setNotificationEnabled(value);
    await Future.wait(
      notificationPreferenceIds.map((id) {
        return SharedPrefsManager.setNotificationTypeEnabled(id, value);
      }),
    );

    // Update notification settings.
    for (final id in notificationPreferenceIds) {
      _notificationSettings[id] = value;
    }

    // Update preferences.
    _preferences = _preferences.copyWith(notificationsEnabled: value);
    notifyListeners();

    // Update each notification preference.
    final nextValue = value;
    for (final item in _notificationPreferences) {
      await setNotificationValue(item.id, nextValue);
    }
  }

  /// Toggles a notification value.
  Future<void> toggleNotificationValue(String id, bool value) async {
    // Enable notifications if any are turned on.
    _preferences = _preferences.copyWith(notificationsEnabled: true);

    // Set the notification value.
    await setNotificationValue(id, value);

    // Update notifications enabled based on any enabled.
    _preferences = _preferences.copyWith(
      notificationsEnabled: _notificationSettings.values.any(
            (enabled) => enabled,
      ),
    );
    notifyListeners();
  }

  /// Sets notification time.
  void setNotificationTime(String value) {
    _preferences = _preferences.copyWith(notificationTime: value);
    notifyListeners();
  }

  /// Sets a notification value.
  Future<void> setNotificationValue(String id, bool value) async {
    // Save to shared preferences.
    await SharedPrefsManager.setNotificationTypeEnabled(id, value);

    // Update notification settings.
    _notificationSettings[id] = value;

    // Update preferences.
    _preferences = _preferences.copyWith(
      notificationPreferences: {..._notificationSettings},
    );
    notifyListeners();

    // Update notification preference in Firestore.
    final result = await _updateNotificationPreferenceUseCase.execute(
      preferenceId: id,
      enabled: value,
    );

    // Handle result.
    result.ifLeft((failure) => _errorMessage = failure.message);
    result.ifRight((_) {
      _notificationSettings[id] = value;
      _notificationPreferences = _notificationPreferences
          .map((item) => item.id == id ? item.copyWith(enabled: value) : item)
          .toList(growable: false);
      _errorMessage = null;
    });

    // Notify listeners if not disposed.
    if (!_isDisposed) notifyListeners();
  }

  // =========================================================================
  // SAVE STEPS
  // =========================================================================

  /// Saves diet and navigates to allergies.
  Future<void> saveDiet() async {
    await _save(
      _preferences.copyWith(currentStep: 2),
      UserSetupNavigationEvent.goToAllergies,
    );
  }

  /// Saves allergies and navigates to dislikes.
  Future<void> saveAllergies() async {
    await _save(
      _preferences.copyWith(currentStep: 3),
      UserSetupNavigationEvent.goToDislikes,
    );
  }

  /// Saves dislikes and navigates to calories.
  Future<void> saveDislikes() async {
    await _save(
      _preferences.copyWith(currentStep: 4),
      UserSetupNavigationEvent.goToCalories,
    );
  }

  /// Saves calories and navigates to notifications.
  Future<void> saveCalories() async {
    // Validate calories.
    final validationMessage = _validateCalories();
    if (validationMessage != null) {
      _errorMessage = validationMessage;
      notifyListeners();
      return;
    }

    // Clear target calories if not enabled.
    final nextPreferences = _preferences.calorieTargetEnabled
        ? _preferences
        : _preferences.copyWith(clearTargetCalories: true);

    // Save and navigate.
    await _save(
      nextPreferences.copyWith(currentStep: 5),
      UserSetupNavigationEvent.goToNotifications,
    );
  }

  /// Completes the setup.
  Future<void> complete() async {
    // Save notification enabled state.
    await SharedPrefsManager.setNotificationEnabled(
      _preferences.notificationsEnabled,
    );

    // Save and navigate to home.
    await _save(
      _preferences.copyWith(currentStep: totalSteps, isCompleted: true),
      UserSetupNavigationEvent.goToHome,
    );
  }

  // =========================================================================
  // SETTINGS MODE SAVE
  // =========================================================================

  /// Saves diet from settings.
  Future<void> saveDietFromSettings() async {
    await _save(
      _preferences.copyWith(isCompleted: true),
      UserSetupNavigationEvent.closeSettings,
    );
  }

  /// Saves allergies from settings.
  Future<void> saveAllergiesFromSettings() async {
    await _save(
      _preferences.copyWith(isCompleted: true),
      UserSetupNavigationEvent.closeSettings,
    );
  }

  /// Saves dislikes from settings.
  Future<void> saveDislikesFromSettings() async {
    await _save(
      _preferences.copyWith(isCompleted: true),
      UserSetupNavigationEvent.closeSettings,
    );
  }

  /// Saves calories from settings.
  Future<void> saveCaloriesFromSettings() async {
    // Validate calories.
    final validationMessage = _validateCalories();
    if (validationMessage != null) {
      _errorMessage = validationMessage;
      notifyListeners();
      return;
    }

    // Clear target calories if not enabled.
    final nextPreferences = _preferences.calorieTargetEnabled
        ? _preferences
        : _preferences.copyWith(clearTargetCalories: true);

    // Save and close.
    await _save(
      nextPreferences.copyWith(isCompleted: true),
      UserSetupNavigationEvent.closeSettings,
    );
  }

  // =========================================================================
  // PRIVATE HELPERS
  // =========================================================================

  /// Validates calorie target.
  String? _validateCalories() {
    // Return null if calorie target is disabled.
    if (!_preferences.calorieTargetEnabled) return null;

    // Check if target calories is set.
    final value = _preferences.targetCalories;
    if (value == null) return 'Please enter a target or choose No target';

    // Validate range based on unit.
    final isKcal = _preferences.calorieUnit == 'kcal';
    final min = isKcal ? 500 : 2100;
    final max = isKcal ? 10000 : 42000;
    final unit = _preferences.calorieUnit;

    if (value < min || value > max) {
      return 'Target calories must be between $min and $max $unit';
    }

    return null;
  }

  /// Loads options for a category.
  Future<void> _loadOptions(String categoryId) async {
    // Execute the use case.
    final result = await _getOptionsUseCase.execute(categoryId);

    // Handle result.
    result.ifLeft((failure) => _errorMessage = failure.message);
    result.ifRight((items) {
      switch (categoryId) {
        case 'meal_preferences':
          _dietOptions = items
              .where((item) => !_isEmptyChoiceName(item.name))
              .toList();
          break;
        case 'allergies':
          _allergyOptions = items
              .where((item) => !_isEmptyChoiceName(item.name))
              .toList();
          break;
        case 'dislikes':
          _dislikeOptions = items
              .where((item) => !_isEmptyChoiceName(item.name))
              .toList();
          break;
      }
    });
  }

  /// Saves preferences and emits navigation event.
  Future<void> _save(
      UserSetupPreferences nextPreferences,
      UserSetupNavigationEvent nextEvent,
      ) async {
    // Set saving state.
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    // Execute the use case.
    final result = await _savePreferencesUseCase.execute(
      uid: uid,
      preferences: nextPreferences,
    );

    // Handle result.
    result.ifLeft((failure) => _errorMessage = failure.message);
    result.ifRight((_) {
      _preferences = nextPreferences;
      _navigationEvent = nextEvent;
    });

    // Reset saving state.
    _isSaving = false;
    notifyListeners();
  }

  /// Toggles a value in a list.
  List<String> _toggleValue(List<String> source, String value) {
    // Filter out empty choices.
    final values = source.where((item) => !_isEmptyChoiceName(item)).toList();

    // Toggle the value.
    if (values.contains(value)) {
      values.remove(value);
    } else {
      values.add(value);
    }

    return values;
  }

  /// Removes empty choices from preferences.
  UserSetupPreferences _withoutEmptyChoices(UserSetupPreferences preferences) {
    // Get the diet value.
    final diet = preferences.diet;

    return preferences.copyWith(
      clearDiet: diet == null || _isEmptyChoiceName(diet),
      allergies: preferences.allergies
          .where((item) => !_isEmptyChoiceName(item))
          .toList(),
      dislikes: preferences.dislikes
          .where((item) => !_isEmptyChoiceName(item))
          .toList(),
    );
  }

  /// Checks if a choice name is empty.
  bool _isEmptyChoiceName(String name) {
    // Normalize the name.
    final normalized = name.trim().toLowerCase();

    // Check against empty choice values.
    return normalized == 'none' ||
        normalized == 'no preference' ||
        normalized == 'no preferences' ||
        normalized == 'no dietary preference' ||
        normalized == noDietValue.toLowerCase();
  }

  /// Loads notification settings.
  Future<void> _loadNotificationSettings() async {
    // Execute the use case.
    final result = await _getNotificationPreferencesUseCase.execute();

    // Handle result.
    result.ifLeft((failure) => _errorMessage = failure.message);
    result.ifRight((items) {
      _notificationPreferences = items;
      _notificationSettings
        ..clear()
        ..addEntries(items.map((item) => MapEntry(item.id, item.enabled)));
      _preferences = _preferences.copyWith(
        notificationsEnabled: items.any((item) => item.enabled),
        notificationPreferences: {..._notificationSettings},
      );
    });
  }
}