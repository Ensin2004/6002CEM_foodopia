import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================================
// SHARED PREFERENCES MANAGER
// ============================================================================
// Centralized manager for all SharedPreferences operations
// Use this class instead of directly accessing SharedPreferences
// ============================================================================

class SharedPrefsManager {
  static SharedPreferences? _prefs;

  // Keys
  static const String _keyOnboardingDone = 'onboarding_done';
  static const String _keyNotificationsEnabled = 'notifications_enabled';
  static const String _keyNewFollowerNotification = 'notification_new_follower';
  static const String _keyNewRatingNotification = 'notification_new_rating';
  static const String _keyPlanReminderNotification =
      'notification_plan_reminder';

  /// Initialize the manager (call once in main.dart)
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Get the instance (ensure init() is called first)
  static SharedPreferences get instance {
    /// Creates a assert instance.
    assert(
      _prefs != null,
      'SharedPrefsManager not initialized. Call init() first.',
    );
    return _prefs!;
  }

  // ============================================================
  // Onboarding Methods
  // ============================================================

  /// Check if onboarding has been completed
  static bool hasCompletedOnboarding() {
    return _prefs?.getBool(_keyOnboardingDone) ?? false;
  }

  /// Mark onboarding as completed
  static Future<void> setOnboardingCompleted(bool completed) async {
    await _prefs?.setBool(_keyOnboardingDone, completed);
  }

  /// Reset onboarding (user needs to see onboarding again)
  static Future<void> resetOnboarding() async {
    await _prefs?.remove(_keyOnboardingDone);
    debugPrint('🔄 Onboarding flag reset');
  }

  // ============================================================
  // Notification Methods
  // ============================================================

  /// Get notification enabled status
  static bool isNotificationEnabled() {
    return _prefs?.getBool(_keyNotificationsEnabled) ?? false;
  }

  /// Set notification enabled status
  static Future<void> setNotificationEnabled(bool enabled) async {
    await _prefs?.setBool(_keyNotificationsEnabled, enabled);
  }

  /// Get one notification setting by menu id.
  static bool isNotificationTypeEnabled(String id) {
    return _prefs?.getBool(_notificationKeyFor(id)) ?? isNotificationEnabled();
  }

  /// Set one notification setting by menu id.
  static Future<void> setNotificationTypeEnabled(
    String id,
    bool enabled,
  ) async {
    await _prefs?.setBool(_notificationKeyFor(id), enabled);
  }

  static String _notificationKeyFor(String id) {
    switch (id) {
      case 'new_follower_notification':
        return _keyNewFollowerNotification;
      case 'new_rating_notification':
        return _keyNewRatingNotification;
      case 'plan_reminder_notification':
        return _keyPlanReminderNotification;
      default:
        return 'notification_$id';
    }
  }

  // ============================================================
  // Generic Methods (for future use)
  // ============================================================

  /// Get a string value
  static String? getString(String key) {
    return _prefs?.getString(key);
  }

  /// Set a string value
  static Future<void> setString(String key, String value) async {
    await _prefs?.setString(key, value);
  }

  /// Get an int value
  static int? getInt(String key) {
    return _prefs?.getInt(key);
  }

  /// Set an int value
  static Future<void> setInt(String key, int value) async {
    await _prefs?.setInt(key, value);
  }

  /// Remove a value by key
  static Future<void> remove(String key) async {
    await _prefs?.remove(key);
  }

  /// Clear all preferences
  static Future<void> clearAll() async {
    await _prefs?.clear();
  }
}
