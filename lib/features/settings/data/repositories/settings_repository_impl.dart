import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/shared_prefs_manager.dart';
import '../../domain/entities/settings_item.dart';
import '../../domain/entities/settings_section.dart';
import '../../domain/repositories/settings_repository.dart';

/// Defines behavior for settings repository impl.
class SettingsRepositoryImpl implements SettingsRepository {
  /// Loads data for the get user settings operation.
  @override
  Future<Either<Failure, List<SettingsSection>>> getUserSettings() async {
    /// Handles the get settings operation.
    return _getSettings(isAdmin: false);
  }

  /// Loads data for the get admin settings operation.
  @override
  Future<Either<Failure, List<SettingsSection>>> getAdminSettings() async {
    /// Handles the get settings operation.
    return _getSettings(isAdmin: true);
  }

  /// Private method to build settings sections based on user role
  Future<Either<Failure, List<SettingsSection>>> _getSettings({
    required bool isAdmin,
  }) async {
    try {
      // Runs the guarded operation that can throw.
      final sections = <SettingsSection>[];

      // ============================================================
      // 1. ACCOUNT SECTION (Same for both User and Admin)
      // ============================================================
      sections.add(
        /// Creates a settings section instance.
        const SettingsSection(
          title: 'Account',
          items: [
            /// Creates a settings item instance.
            SettingsItem(
              id: 'edit_profile',
              title: 'Edit Profile',
              icon: Icons.edit,
              type: SettingsItemType.navigation,
              routeName: '/settings/edit-profile',
            ),

            /// Creates a settings item instance.
            SettingsItem(
              id: 'change_password',
              title: 'Change Password',
              icon: Icons.vpn_key,
              type: SettingsItemType.navigation,
              routeName: '/settings/change-password',
            ),
          ],
        ),
      );

      // ============================================================
      // 2. PREFERENCES SECTION (User only)
      // ============================================================
      if (!isAdmin) {
        sections.add(
          /// Creates a settings section instance.
          const SettingsSection(
            title: 'Preferences',
            items: [
              /// Creates a settings item instance.
              SettingsItem(
                id: 'meal_preferences',
                title: 'Meal Preference',
                icon: Icons.restaurant_menu,
                type: SettingsItemType.navigation,
                routeName: '/settings/meal-preferences',
              ),

              /// Creates a settings item instance.
              SettingsItem(
                id: 'allergies',
                title: 'Allergies',
                icon: Icons.health_and_safety,
                type: SettingsItemType.navigation,
                routeName: '/settings/allergies',
              ),

              /// Creates a settings item instance.
              SettingsItem(
                id: 'dislikes',
                title: 'Dislikes',
                icon: Icons.thumb_down,
                type: SettingsItemType.navigation,
                routeName: '/settings/dislikes',
              ),

              /// Creates a settings item instance.
              SettingsItem(
                id: 'target_calories',
                title: 'Target Calories',
                icon: Icons.local_fire_department,
                subtitle: 'Manage your daily calorie target history',
                type: SettingsItemType.navigation,
                routeName: '/settings/target-calories',
              ),
            ],
          ),
        );
      }

      // ============================================================
      // 4. ADMIN SECTION
      // ============================================================
      if (isAdmin) {
        sections.add(
          /// Creates a settings section instance.
          const SettingsSection(
            title: 'User Profile Options',
            items: [
              /// Creates a settings item instance.
              SettingsItem(
                id: 'age_groups',
                title: 'Age Groups',
                icon: Icons.cake,
                subtitle: 'Manage age groups used during sign up and profiles',
                type: SettingsItemType.navigation,
                routeName: '/settings/age-groups',
              ),
            ],
          ),
        );
      }

      // ============================================================
      // 5. SUPPORT SECTION (Cannot be const because title depends on isAdmin)
      // ============================================================
      final supportItems = [
        /// Creates a settings item instance.
        const SettingsItem(
          id: 'faq',
          title: 'Frequently Asked Questions (FAQ)',
          icon: Icons.question_answer,
          type: SettingsItemType.navigation,
          routeName: '/settings/faq',
        ),

        /// Creates a settings item instance.
        SettingsItem(
          // Remove const because title uses ternary
          id: 'rate_us',
          title: isAdmin ? 'Rating & Feedback' : 'Rate Us & Feedback',
          icon: Icons.star,
          type: SettingsItemType.navigation,
          routeName: '/settings/rate-us',
        ),

        /// Creates a settings item instance.
        const SettingsItem(
          id: 'help_center',
          title: 'Help Center',
          icon: Icons.help,
          type: SettingsItemType.navigation,
          routeName: '/settings/help-center',
        ),
      ];

      sections.add(
        /// Creates a settings section instance.
        SettingsSection(title: 'Support', items: supportItems),
      );

      // ============================================================
      // 6. ABOUT SECTION (Same for both)
      // ============================================================
      sections.add(
        /// Creates a settings section instance.
        const SettingsSection(
          title: 'About',
          items: [
            /// Creates a settings item instance.
            SettingsItem(
              id: 'about_us',
              title: 'About Us',
              icon: Icons.info,
              type: SettingsItemType.navigation,
              routeName: '/settings/about',
            ),

            /// Creates a settings item instance.
            SettingsItem(
              id: 'terms',
              title: 'Terms & Conditions',
              icon: Icons.description,
              type: SettingsItemType.navigation,
              routeName: '/settings/terms',
            ),

            /// Creates a settings item instance.
            SettingsItem(
              id: 'privacy',
              title: 'Privacy Policy',
              icon: Icons.privacy_tip,
              type: SettingsItemType.navigation,
              routeName: '/settings/privacy',
            ),
          ],
        ),
      );

      return Right(sections);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Loads data for the get notification enabled operation.
  @override
  Future<Either<Failure, bool>> getNotificationEnabled() async {
    try {
      return Right(SharedPrefsManager.isNotificationEnabled());
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Handles the set notification enabled operation.
  @override
  Future<Either<Failure, void>> setNotificationEnabled(bool enabled) async {
    try {
      // Runs the guarded operation that can throw.
      await SharedPrefsManager.setNotificationEnabled(enabled);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Loads one notification preference by menu id.
  @override
  Future<Either<Failure, bool>> getNotificationTypeEnabled(String id) async {
    try {
      return Right(SharedPrefsManager.isNotificationTypeEnabled(id));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Updates one notification preference by menu id.
  @override
  Future<Either<Failure, void>> setNotificationTypeEnabled(
    String id,
    bool enabled,
  ) async {
    try {
      await SharedPrefsManager.setNotificationTypeEnabled(id, enabled);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
