import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../app/navigation/navigation_events.dart';
import '../../../../core/services/shared_prefs_manager.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/entities/settings_item.dart';
import '../../domain/entities/settings_section.dart';
import '../../domain/repositories/settings_repository.dart';

/// Defines behavior for settings view model.
class SettingsViewModel extends ChangeNotifier {
  final UserEntity user;
  final SettingsRepository _repository;

  // State
  bool _isLoading = true;
  String? _errorMessage;
  List<SettingsSection> _sections = [];
  bool _notificationsEnabled = false;
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
  }) : _repository = repository {
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

    if (!user.isAdmin) {
      /// Handles the load notification settings operation.
      await _loadNotificationSettings();
    }
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
    final result = await _repository.getNotificationEnabled();
    result.fold((failure) => null, (enabled) {
      _notificationsEnabled = enabled;
      notifyListeners();
    });

    for (final section in _sections) {
      for (final item in section.items) {
        if (item.type != SettingsItemType.toggle) continue;

        final itemResult = await _repository.getNotificationTypeEnabled(
          item.id,
        );
        itemResult.fold((failure) => null, (enabled) {
          _notificationSettings[item.id] = enabled;
        });
      }
    }

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
    final result = await _repository.setNotificationTypeEnabled(id, value);
    result.fold((failure) => null, (_) {
      _notificationSettings[id] = value;
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
