import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../app/navigation/navigation_events.dart';
import '../../../../core/error/failures.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../onboarding/presentation/viewmodel/onboarding_viewmodel.dart';
import '../../domain/entities/settings_item.dart';
import '../../domain/entities/settings_section.dart';
import '../../domain/repositories/settings_repository.dart';

class SettingsViewModel extends ChangeNotifier {
  final UserEntity user;
  final SettingsRepository _repository;

  // State
  bool _isLoading = true;
  String? _errorMessage;
  List<SettingsSection> _sections = [];
  bool _notificationsEnabled = false;
  String _fullName = '';
  String _email = '';
  String? _profileImageUrl;

  // ✅ Navigation event (one-time use, cleared after reading)
  SettingsNavigationEvent? _navigationEvent;
  AppNavigationEvent? _appEvent;

  SettingsViewModel({
    required this.user,
    required SettingsRepository repository,
  }) : _repository = repository {
    loadSettings();
  }

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<SettingsSection> get sections => _sections;
  bool get notificationsEnabled => _notificationsEnabled;
  String get fullName => _fullName;
  String get email => _email;
  String? get profileImageUrl => _profileImageUrl;
  bool get isAdmin => user.isAdmin;
  bool get isUser => user.isUser;

  // ✅ One-time navigation event (clears after reading)
  SettingsNavigationEvent? get navigationEvent {
    final event = _navigationEvent;
    _navigationEvent = null; // Clear after reading to prevent multiple navigations
    return event;
  }

  AppNavigationEvent? get appEvent {
    final event = _appEvent;
    _appEvent = null;
    return event;
  }

  // ✅ Handle settings item tap - emits typed event
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
      default:
        break;
    }
    notifyListeners();
  }

  // Load all settings
  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();

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
      await _loadNotificationSettings();
    }
  }

  // Load user profile from Firestore
  Future<void> _loadUserProfile() async {
    try {
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
    result.fold(
          (failure) => null,
          (enabled) {
        _notificationsEnabled = enabled;
        notifyListeners();
      },
    );
  }

  // Toggle notifications
  Future<void> toggleNotifications(bool value) async {
    final result = await _repository.setNotificationEnabled(value);
    result.fold(
          (failure) => null,
          (_) {
        _notificationsEnabled = value;
        notifyListeners();
      },
    );
  }

  // Refresh profile
  Future<void> refreshProfile() async {
    await _loadUserProfile();
    notifyListeners();
  }

  // ✅ Logout - emits logout event
  Future<void> logout() async {
    // Reset onboarding flag
    final onboardingViewModel = OnboardingViewModel();
    await onboardingViewModel.resetOnboarding();
    await FirebaseAuth.instance.signOut();

    _appEvent = AppNavigationEvent.logout;
    notifyListeners();
  }
}