import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/extensions/either_extensions.dart';
import '../../../../core/services/shared_prefs_manager.dart';
import '../../domain/entities/user_setup_option.dart';
import '../../domain/entities/user_setup_preferences.dart';
import '../../domain/usecases/get_user_setup_options_usecase.dart';
import '../../domain/usecases/get_user_setup_preferences_usecase.dart';
import '../../domain/usecases/save_user_setup_preferences_usecase.dart';
import '../../domain/usecases/search_user_setup_foods_usecase.dart';

enum UserSetupNavigationEvent {
  goToAllergies,
  goToDislikes,
  goToCalories,
  goToNotifications,
  goToHome,
  closeSettings,
}

class UserSetupViewModel extends ChangeNotifier {
  static const noneValue = 'None';
  static const noDietValue = 'No specific diet';
  static const totalSteps = 5;

  final String uid;
  final GetUserSetupOptionsUseCase _getOptionsUseCase;
  final SearchUserSetupFoodsUseCase _searchFoodsUseCase;
  final GetUserSetupPreferencesUseCase _getPreferencesUseCase;
  final SaveUserSetupPreferencesUseCase _savePreferencesUseCase;

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isSearching = false;
  String? _errorMessage;
  List<UserSetupOption> _dietOptions = const [];
  List<UserSetupOption> _allergyOptions = const [];
  List<UserSetupOption> _dislikeOptions = const [];
  List<UserSetupOption> _searchResults = const [];
  UserSetupPreferences _preferences = const UserSetupPreferences();
  final Map<String, bool> _notificationSettings = {};
  String _activeSearchQuery = '';
  Timer? _searchDebounce;
  bool _isDisposed = false;
  UserSetupNavigationEvent? _navigationEvent;

  UserSetupViewModel({
    required this.uid,
    required GetUserSetupOptionsUseCase getOptionsUseCase,
    required SearchUserSetupFoodsUseCase searchFoodsUseCase,
    required GetUserSetupPreferencesUseCase getPreferencesUseCase,
    required SaveUserSetupPreferencesUseCase savePreferencesUseCase,
  }) : _getOptionsUseCase = getOptionsUseCase,
       _searchFoodsUseCase = searchFoodsUseCase,
       _getPreferencesUseCase = getPreferencesUseCase,
       _savePreferencesUseCase = savePreferencesUseCase;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isSearching => _isSearching;
  String? get errorMessage => _errorMessage;
  List<UserSetupOption> get dietOptions => _dietOptions;
  List<UserSetupOption> get allergyOptions => _allergyOptions;
  List<UserSetupOption> get dislikeOptions => _dislikeOptions;
  List<UserSetupOption> get searchResults => _searchResults;
  UserSetupPreferences get preferences => _preferences;
  bool notificationValue(String id) =>
      _notificationSettings[id] ??
      SharedPrefsManager.isNotificationTypeEnabled(id);

  UserSetupNavigationEvent? get navigationEvent {
    final event = _navigationEvent;
    _navigationEvent = null;
    return event;
  }

  Future<void> load({
    List<String> optionCategoryIds = const [
      'meal_preferences',
      'allergies',
      'dislikes',
    ],
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final preferencesResult = await _getPreferencesUseCase.execute(uid);
    preferencesResult.ifLeft((failure) => _errorMessage = failure.message);
    preferencesResult.ifRight((preferences) => _preferences = preferences);

    await Future.wait(optionCategoryIds.map(_loadOptions));
    _loadNotificationSettings();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> search(String query) async {
    _searchDebounce?.cancel();
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      _activeSearchQuery = '';
      _searchResults = const [];
      _isSearching = false;
      notifyListeners();
      return;
    }

    _activeSearchQuery = trimmed;
    _isSearching = true;
    _errorMessage = null;
    notifyListeners();

    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      _runSearch(trimmed);
    });
  }

  Future<void> _runSearch(String trimmed) async {
    final result = await _searchFoodsUseCase.execute(trimmed);
    if (_isDisposed || _activeSearchQuery != trimmed) return;

    result.ifLeft((failure) => _errorMessage = failure.message);
    result.ifRight((items) => _searchResults = items);
    _isSearching = false;
    notifyListeners();
  }

  void clearSearch() {
    _searchDebounce?.cancel();
    _activeSearchQuery = '';
    _searchResults = const [];
    _isSearching = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _searchDebounce?.cancel();
    super.dispose();
  }

  void selectDiet(String value) {
    _preferences = _preferences.copyWith(diet: value);
    notifyListeners();
  }

  void toggleAllergy(String value) {
    _preferences = _preferences.copyWith(
      allergies: _toggleValue(_preferences.allergies, value),
    );
    notifyListeners();
  }

  void toggleDislike(String value) {
    _preferences = _preferences.copyWith(
      dislikes: _toggleValue(_preferences.dislikes, value),
    );
    notifyListeners();
  }

  void setCalorieTargetEnabled(bool value) {
    _preferences = _preferences.copyWith(
      calorieTargetEnabled: value,
      clearTargetCalories: !value,
    );
    notifyListeners();
  }

  void setCalorieUnit(String value) {
    _preferences = _preferences.copyWith(calorieUnit: value);
    notifyListeners();
  }

  void setTargetCalories(int? value) {
    _preferences = _preferences.copyWith(
      targetCalories: value,
      clearTargetCalories: value == null,
    );
    notifyListeners();
  }

  void setNotificationsEnabled(bool value) {
    _preferences = _preferences.copyWith(notificationsEnabled: value);
    notifyListeners();
  }

  void setNotificationTime(String value) {
    _preferences = _preferences.copyWith(notificationTime: value);
    notifyListeners();
  }

  Future<void> setNotificationValue(String id, bool value) async {
    await SharedPrefsManager.setNotificationTypeEnabled(id, value);
    _notificationSettings[id] = value;
    notifyListeners();
  }

  Future<void> saveDiet() async {
    final diet = _preferences.diet ?? noDietValue;
    await _save(
      _preferences.copyWith(diet: diet, currentStep: 2),
      UserSetupNavigationEvent.goToAllergies,
    );
  }

  Future<void> saveAllergies() async {
    await _save(
      _preferences.copyWith(currentStep: 3),
      UserSetupNavigationEvent.goToDislikes,
    );
  }

  Future<void> saveDislikes() async {
    await _save(
      _preferences.copyWith(currentStep: 4),
      UserSetupNavigationEvent.goToCalories,
    );
  }

  Future<void> saveCalories() async {
    final validationMessage = _validateCalories();
    if (validationMessage != null) {
      _errorMessage = validationMessage;
      notifyListeners();
      return;
    }

    final nextPreferences = _preferences.calorieTargetEnabled
        ? _preferences
        : _preferences.copyWith(clearTargetCalories: true);
    await _save(
      nextPreferences.copyWith(currentStep: 5),
      UserSetupNavigationEvent.goToNotifications,
    );
  }

  Future<void> complete() async {
    await SharedPrefsManager.setNotificationEnabled(
      _preferences.notificationsEnabled,
    );

    await _save(
      _preferences.copyWith(currentStep: totalSteps, isCompleted: true),
      UserSetupNavigationEvent.goToHome,
    );
  }

  void _loadNotificationSettings() {
    const ids = [
      'new_follower_notification',
      'new_rating_notification',
      'plan_reminder_notification',
    ];

    for (final id in ids) {
      _notificationSettings[id] = SharedPrefsManager.isNotificationTypeEnabled(
        id,
      );
    }
  }

  Future<void> saveDietFromSettings() async {
    final diet = _preferences.diet ?? noDietValue;
    await _save(
      _preferences.copyWith(diet: diet, isCompleted: true),
      UserSetupNavigationEvent.closeSettings,
    );
  }

  Future<void> saveAllergiesFromSettings() async {
    await _save(
      _preferences.copyWith(isCompleted: true),
      UserSetupNavigationEvent.closeSettings,
    );
  }

  Future<void> saveDislikesFromSettings() async {
    await _save(
      _preferences.copyWith(isCompleted: true),
      UserSetupNavigationEvent.closeSettings,
    );
  }

  Future<void> saveCaloriesFromSettings() async {
    final validationMessage = _validateCalories();
    if (validationMessage != null) {
      _errorMessage = validationMessage;
      notifyListeners();
      return;
    }

    final nextPreferences = _preferences.calorieTargetEnabled
        ? _preferences
        : _preferences.copyWith(clearTargetCalories: true);
    await _save(
      nextPreferences.copyWith(isCompleted: true),
      UserSetupNavigationEvent.closeSettings,
    );
  }

  String? _validateCalories() {
    if (!_preferences.calorieTargetEnabled) return null;

    final value = _preferences.targetCalories;
    if (value == null) return 'Please enter a target or choose No target';

    final isKcal = _preferences.calorieUnit == 'kcal';
    final min = isKcal ? 500 : 2100;
    final max = isKcal ? 10000 : 42000;
    final unit = _preferences.calorieUnit;

    if (value < min || value > max) {
      return 'Target calories must be between $min and $max $unit';
    }

    return null;
  }

  Future<void> _loadOptions(String categoryId) async {
    final result = await _getOptionsUseCase.execute(categoryId);
    result.ifLeft((failure) => _errorMessage = failure.message);
    result.ifRight((items) {
      switch (categoryId) {
        case 'meal_preferences':
          _dietOptions = _withRequiredOption(items, noDietValue);
          break;
        case 'allergies':
          _allergyOptions = _withRequiredOption(items, noneValue);
          break;
        case 'dislikes':
          _dislikeOptions = _withRequiredOption(items, noneValue);
          break;
      }
    });
  }

  Future<void> _save(
    UserSetupPreferences nextPreferences,
    UserSetupNavigationEvent nextEvent,
  ) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _savePreferencesUseCase.execute(
      uid: uid,
      preferences: nextPreferences,
    );

    result.ifLeft((failure) => _errorMessage = failure.message);
    result.ifRight((_) {
      _preferences = nextPreferences;
      _navigationEvent = nextEvent;
    });

    _isSaving = false;
    notifyListeners();
  }

  List<String> _toggleValue(List<String> source, String value) {
    if (value == noneValue) {
      return source.contains(noneValue) ? [] : [noneValue];
    }

    final values = source.where((item) => item != noneValue).toList();
    if (values.contains(value)) {
      values.remove(value);
    } else {
      values.add(value);
    }
    return values;
  }

  List<UserSetupOption> _withRequiredOption(
    List<UserSetupOption> source,
    String name,
  ) {
    final hasOption = source.any(
      (item) => item.name.toLowerCase() == name.toLowerCase(),
    );
    if (hasOption) return source;
    return [
      UserSetupOption(id: name.toLowerCase().replaceAll(' ', '_'), name: name),
      ...source,
    ];
  }
}
