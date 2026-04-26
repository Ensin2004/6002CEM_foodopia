import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/shared_prefs_manager.dart';
import '../../domain/entities/settings_item.dart';
import '../../domain/entities/settings_section.dart';
import '../../domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {

  @override
  Future<Either<Failure, List<SettingsSection>>> getUserSettings() async {
    return _getSettings(isAdmin: false);
  }

  @override
  Future<Either<Failure, List<SettingsSection>>> getAdminSettings() async {
    return _getSettings(isAdmin: true);
  }

  /// Private method to build settings sections based on user role
  Future<Either<Failure, List<SettingsSection>>> _getSettings({
    required bool isAdmin,
  }) async {
    try {
      final sections = <SettingsSection>[];

      // ============================================================
      // 1. ACCOUNT SECTION (Same for both User and Admin)
      // ============================================================
      sections.add(
        const SettingsSection(
          title: 'Account',
          items: [
            SettingsItem(
              id: 'edit_profile',
              title: 'Edit Profile',
              icon: Icons.edit,
              type: SettingsItemType.navigation,
              routeName: '/settings/edit-profile',
            ),
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
          const SettingsSection(
            title: 'Preferences',
            items: [
              SettingsItem(
                id: 'dietary_restrictions',
                title: 'Dietary Restrictions',
                icon: Icons.restaurant,
                type: SettingsItemType.navigation,
                routeName: '/settings/dietary-restrictions',
              ),
              SettingsItem(
                id: 'meal_preferences',
                title: 'Meal Preferences',
                icon: Icons.favorite,
                type: SettingsItemType.navigation,
                routeName: '/settings/meal-preferences',
              ),
            ],
          ),
        );
      }

      // ============================================================
      // 3. NOTIFICATIONS SECTION (User only)
      // ============================================================
      if (!isAdmin) {
        sections.add(
          SettingsSection(
            title: 'Notifications',
            items: [
              SettingsItem(
                id: 'notifications',
                title: 'Enable Notifications',
                icon: Icons.notifications,
                type: SettingsItemType.toggle,
              ),
            ],
          ),
        );
      }

      // ============================================================
      // 4. ADMIN SECTION (Admin only)
      // ============================================================
      if (isAdmin) {
        sections.add(
          const SettingsSection(
            title: 'Admin',
            items: [
              SettingsItem(
                id: 'user_management',
                title: 'User Management',
                icon: Icons.people,
                type: SettingsItemType.navigation,
                routeName: '/settings/user-management',
              ),
              SettingsItem(
                id: 'content_moderation',
                title: 'Content Moderation',
                icon: Icons.flag,
                type: SettingsItemType.navigation,
                routeName: '/settings/content-moderation',
              ),
              SettingsItem(
                id: 'system_settings',
                title: 'System Settings',
                icon: Icons.settings,
                type: SettingsItemType.navigation,
                routeName: '/settings/system-settings',
              ),
            ],
          ),
        );
      }

      // ============================================================
      // 5. SUPPORT SECTION (Cannot be const because title depends on isAdmin)
      // ============================================================
      final supportItems = [
        const SettingsItem(
          id: 'faq',
          title: 'Frequently Asked Questions (FAQ)',
          icon: Icons.question_answer,
          type: SettingsItemType.navigation,
          routeName: '/settings/faq',
        ),
        SettingsItem(  // ✅ Remove const because title uses ternary
          id: 'rate_us',
          title: isAdmin ? 'Rating & Feedback' : 'Rate Us & Feedback',
          icon: Icons.star,
          type: SettingsItemType.navigation,
          routeName: '/settings/rate-us',
        ),
        const SettingsItem(
          id: 'help_center',
          title: 'Help Center',
          icon: Icons.help,
          type: SettingsItemType.navigation,
          routeName: '/settings/help-center',
        ),
      ];

      sections.add(
        SettingsSection(
          title: 'Support',
          items: supportItems,
        ),
      );

      // ============================================================
      // 6. ABOUT SECTION (Same for both)
      // ============================================================
      sections.add(
        const SettingsSection(
          title: 'About',
          items: [
            SettingsItem(
              id: 'about_us',
              title: 'About Us',
              icon: Icons.info,
              type: SettingsItemType.navigation,
              routeName: '/settings/about',
            ),
            SettingsItem(
              id: 'terms',
              title: 'Terms & Conditions',
              icon: Icons.description,
              type: SettingsItemType.navigation,
              routeName: '/settings/terms',
            ),
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

  @override
  Future<Either<Failure, bool>> getNotificationEnabled() async {
    try {
      return Right(SharedPrefsManager.isNotificationEnabled());
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> setNotificationEnabled(bool enabled) async {
    try {
      await SharedPrefsManager.setNotificationEnabled(enabled);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}