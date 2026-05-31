import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../app/navigation/navigation_events.dart';
import '../../../../core/services/shared_prefs_manager.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../notifications/domain/entities/notification_preference.dart';
import '../../../notifications/domain/usecases/get_notification_preferences_usecase.dart';
import '../../../notifications/domain/usecases/update_notification_preference_usecase.dart';
import '../../domain/entities/settings_section.dart';
import '../../domain/repositories/settings_repository.dart';

/// Defines behavior for settings view model.
class SettingsViewModel extends ChangeNotifier {
  final UserEntity user;
  final SettingsRepository _repository;
  final GetNotificationPreferencesUseCase _getNotificationPreferencesUseCase;
  final UpdateNotificationPreferenceUseCase
  _updateNotificationPreferenceUseCase;

  // State
  bool _isLoading = true;
  String? _errorMessage;
  List<SettingsSection> _sections = [];
  bool _notificationsEnabled = false;
  List<NotificationPreference> _notificationPreferences = [];
  final Map<String, bool> _notificationSettings = {};
  String _fullName = '';
  String _email = '';
  String? _profileImageUrl;

  // Navigation event (one-time use, cleared after reading)
  SettingsNavigationEvent? _navigationEvent;
  AppNavigationEvent? _appEvent;

  /// Creates a settings view model instance.
  SettingsViewModel({
    required this.user,
    required SettingsRepository repository,
    required GetNotificationPreferencesUseCase
    getNotificationPreferencesUseCase,
    required UpdateNotificationPreferenceUseCase
    updateNotificationPreferenceUseCase,
  }) : _repository = repository,
       _getNotificationPreferencesUseCase = getNotificationPreferencesUseCase,
       _updateNotificationPreferenceUseCase =
           updateNotificationPreferenceUseCase {
    /// Loads data for the load settings operation.
    loadSettings();
  }

  // Getters
  bool get isLoading => _isLoading;

  /// Handles the error message operation.
  String? get errorMessage => _errorMessage;

  /// Handles the sections operation.
  List<SettingsSection> get sections => _sections;

  /// Handles the notifications enabled operation.
  bool get notificationsEnabled => _notificationsEnabled;

  List<NotificationPreference> get notificationPreferences =>
      List.unmodifiable(_notificationPreferences);

  /// Handles one notification setting lookup.
  bool isNotificationEnabled(String id) =>
      _notificationSettings[id] ?? _notificationsEnabled;

  /// Handles the full name operation.
  String get fullName => _fullName;

  /// Handles the email operation.
  String get email => _email;

  /// Handles the profile image url operation.
  String? get profileImageUrl => _profileImageUrl;

  /// Handles the is admin operation.
  bool get isAdmin => user.isAdmin;

  /// Handles the is user operation.
  bool get isUser => user.isUser;

  // One-time navigation event (clears after reading)
  SettingsNavigationEvent? get navigationEvent {
    final event = _navigationEvent;
    _navigationEvent =
        null; // Clear after reading to prevent multiple navigations
    return event;
  }

  /// Handles the app event operation.
  AppNavigationEvent? get appEvent {
    final event = _appEvent;
    _appEvent = null;
    return event;
  }

  // Handle settings item tap - emits typed event
  void onSettingsItemTapped(String itemId) {
    switch (itemId) {
      case 'edit_profile':
        _navigationEvent = SettingsNavigationEvent.goToEditProfile;
        break;
      case 'change_password':
        _navigationEvent = SettingsNavigationEvent.goToChangePassword;
        break;
      case 'about_us':
        _navigationEvent = SettingsNavigationEvent.goToAboutUs;
        break;
      case 'terms':
        _navigationEvent = SettingsNavigationEvent.goToTerms;
        break;
      case 'privacy':
        _navigationEvent = SettingsNavigationEvent.goToPrivacy;
        break;
      case 'faq':
        _navigationEvent = SettingsNavigationEvent.goToFaq;
        break;
      case 'rate_us':
        _navigationEvent = SettingsNavigationEvent.goToRateUs;
        break;
      case 'help_center':
        _navigationEvent = SettingsNavigationEvent.goToHelpCenter;
        break;
      case 'age_groups':
        _navigationEvent = SettingsNavigationEvent.goToAgeGroups;
        break;
      case 'meal_preferences':
        _navigationEvent = SettingsNavigationEvent.goToMealPreferences;
        break;
      case 'allergies':
        _navigationEvent = SettingsNavigationEvent.goToAllergies;
        break;
      case 'dislikes':
        _navigationEvent = SettingsNavigationEvent.goToDislikes;
        break;
      case 'target_calories':
        _navigationEvent = SettingsNavigationEvent.goToTargetCalories;
        break;
      default:
        break;
    }
    notifyListeners();
  }

  // Load all settings
  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();

    /// Handles the load user profile operation.
    await _loadUserProfile();

    final result = user.isAdmin
        ? await _repository.getAdminSettings()
        : await _repository.getUserSettings();

    result.fold(
      (failure) {
        _errorMessage = failure.message;
        _isLoading = false;
        notifyListeners();
      },
      (sections) {
        _sections = sections;
        _isLoading = false;
        notifyListeners();
      },
    );

    /// Handles the load notification settings operation.
    await _loadNotificationSettings();
  }

  // Load user profile from Firestore
  Future<void> _loadUserProfile() async {
    try {
      // Runs the guarded operation that can throw.
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;
          _fullName = data['name'] ?? currentUser.displayName ?? 'User';
          _email = currentUser.email ?? '';
          _profileImageUrl = data['profileImage'];
        }
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
  }

  // Load notification settings
  Future<void> _loadNotificationSettings() async {
    final result = await _getNotificationPreferencesUseCase.execute();
    result.fold((failure) => _errorMessage = failure.message, (items) {
      _notificationPreferences = items;
      _notificationSettings
        ..clear()
        ..addEntries(items.map((item) => MapEntry(item.id, item.enabled)));
      _notificationsEnabled = items.any((item) => item.enabled);
    });

    notifyListeners();
  }

  // Toggle notifications
  Future<void> toggleNotifications(bool value) async {
    final result = await _repository.setNotificationEnabled(value);
    result.fold((failure) => null, (_) {
      _notificationsEnabled = value;
      notifyListeners();
    });
  }

  /// Toggle one notification preference.
  Future<void> toggleNotification(String id, bool value) async {
    final result = await _updateNotificationPreferenceUseCase.execute(
      preferenceId: id,
      enabled: value,
    );
    result.fold((failure) => null, (_) {
      _notificationSettings[id] = value;
      _notificationPreferences = _notificationPreferences
          .map((item) => item.id == id ? item.copyWith(enabled: value) : item)
          .toList(growable: false);
      _notificationsEnabled = _notificationPreferences.any(
        (item) => item.enabled,
      );
      notifyListeners();
    });
  }

  // Refresh profile
  Future<void> refreshProfile() async {
    /// Handles the load user profile operation.
    await _loadUserProfile();
    notifyListeners();
  }

  // Logout - emits logout event
  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    await SharedPrefsManager.resetOnboarding();

    _appEvent = AppNavigationEvent.logout;
    notifyListeners();
  }
}
