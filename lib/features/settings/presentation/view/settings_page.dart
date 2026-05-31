import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../app/dependency_injection/injection_container.dart';
import '../../../../app/navigation/navigation_events.dart';
import '../../../../app/routers/app_router.dart';
import '../../../../app/routers/router_args.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../notifications/domain/entities/notification_preference.dart';
import '../../../notifications/domain/usecases/get_notification_preferences_usecase.dart';
import '../../../notifications/domain/usecases/update_notification_preference_usecase.dart';
import '../../domain/repositories/settings_repository.dart';
import '../viewmodel/settings_viewmodel.dart';
import '../widgets/settings_section_widget.dart';

/// Defines behavior for settings page.
class SettingsPage extends StatelessWidget {
  final UserEntity user;

  /// Creates a settings page instance.
  const SettingsPage({super.key, required this.user});

  /// Builds the widget tree for this component.
  @override
  Widget build(BuildContext context) {
    /// Runs the change notifier provider operation.
    return ChangeNotifierProvider(
      create: (_) => SettingsViewModel(
        user: user,
        repository: sl<SettingsRepository>(),
        getNotificationPreferencesUseCase:
            sl<GetNotificationPreferencesUseCase>(),
        updateNotificationPreferenceUseCase:
            sl<UpdateNotificationPreferenceUseCase>(),
      ),
      child: const _SettingsPageView(),
    );
  }
}

/// Defines behavior for settings page view.
class _SettingsPageView extends StatelessWidget {
  /// Handles the settings page view operation.
  const _SettingsPageView();

  /// Builds the widget tree for this component.
  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SettingsViewModel>();
    final isAdmin = viewModel.isAdmin;

    // Handle Settings navigation events (type-safe)
    final settingsEvent = viewModel.navigationEvent;
    if (settingsEvent != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleSettingsNavigation(context, settingsEvent, viewModel, isAdmin);
      });
    }

    // Handle App-level events (logout)
    final appEvent = viewModel.appEvent;
    if (appEvent == AppNavigationEvent.logout) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToOnboarding(context);
      });
    }

    /// Handles the scaffold operation.
    return Scaffold(
      appBar: CustomAppBar(title: 'Settings', centerTitle: true),
      body: viewModel.isLoading
          ? const LoadingDialog()
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileSection(context, viewModel),
                  ..._buildSettingsSections(context, viewModel),

                  /// Creates a sized box instance.
                  const SizedBox(height: 32),
                  _buildLogoutButton(context, viewModel),

                  /// Creates a sized box instance.
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  /// Handles the build profile section operation.
  Widget _buildProfileSection(
    BuildContext context,
    SettingsViewModel viewModel,
  ) {
    /// Handles the container operation.
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.yellow.shade100],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          /// Creates a circle avatar instance.
          CircleAvatar(
            radius: 40,
            backgroundColor: Theme.of(context).colorScheme.surface,
            backgroundImage: viewModel.profileImageUrl != null
                ? NetworkImage(viewModel.profileImageUrl!)
                : null,
            child: viewModel.profileImageUrl == null
                ? Icon(
                    Icons.person,
                    size: 40,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : null,
          ),

          /// Creates a sized box instance.
          const SizedBox(width: 16),

          /// Creates a expanded instance.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Creates a text instance.
                Text(
                  viewModel.fullName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                /// Creates a sized box instance.
                const SizedBox(height: 4),

                /// Creates a text instance.
                Text(
                  viewModel.email,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Handles the build settings sections operation.
  List<Widget> _buildSettingsSections(
    BuildContext context,
    SettingsViewModel viewModel,
  ) {
    final sections = <Widget>[];
    final sectionCount = viewModel.sections.length;

    for (int i = 0; i < sectionCount; i++) {
      final section = viewModel.sections[i];
      final shouldInsertNotifications =
          section.title == (viewModel.isAdmin ? 'Account' : 'Preferences');
      final isLast =
          i == sectionCount - 1 && viewModel.notificationPreferences.isEmpty;

      sections.add(
        /// Creates a settings section widget instance.
        SettingsSectionWidget(
          section: section,
          viewModel: viewModel,
          isLast: isLast,
        ),
      );

      if (shouldInsertNotifications &&
          viewModel.notificationPreferences.isNotEmpty) {
        sections.add(_buildNotificationSection(context, viewModel));
      }
    }

    return sections;
  }

  Widget _buildNotificationSection(
    BuildContext context,
    SettingsViewModel viewModel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Notifications',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        for (final item in viewModel.notificationPreferences)
          _NotificationPreferenceTile(
            icon: _iconForNotification(item),
            title: item.title,
            description: item.description,
            value: item.enabled,
            onChanged: (value) => viewModel.toggleNotification(item.id, value),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Divider(height: 1, color: Colors.grey[300], thickness: 2),
        ),
      ],
    );
  }

  IconData _iconForNotification(NotificationPreference preference) {
    switch (preference.id) {
      case 'new_follower_notification':
        return Icons.group_add_outlined;
      case 'new_rating_notification':
        return Icons.info_outline;
      case 'new_comment_notification':
        return Icons.comment_outlined;
      case 'new_recipe_notification':
        return Icons.restaurant_menu_outlined;
      case 'new_reply_notification':
        return Icons.reply_outlined;
      case 'new_like_notification':
        return Icons.favorite_border;
      case 'new_user_notification':
        return Icons.person_add_alt_1_outlined;
      case 'system_rating_notification':
        return Icons.star_rate_outlined;
      default:
        return Icons.notifications_none;
    }
  }

  // Type-safe navigation handler
  void _handleSettingsNavigation(
    BuildContext context,
    SettingsNavigationEvent event,
    SettingsViewModel viewModel,
    bool isAdmin,
  ) {
    switch (event) {
      case SettingsNavigationEvent.goToEditProfile:
        context
            .push(
              AppRouter.editProfile,
              extra: EditProfileArgs(uid: viewModel.user.uid),
            )
            .then((_) => viewModel.refreshProfile());
        break;

      case SettingsNavigationEvent.goToChangePassword:
        context.push(
          AppRouter.changePassword,
          extra: const AuthenticatedRouteArgs(),
        );
        break;

      case SettingsNavigationEvent.goToAboutUs:
        context.push(
          AppRouter.about,
          extra: AboutArgs(
            documentId: 'about_us',
            title: 'About Us',
            isAdmin: isAdmin,
          ),
        );
        break;

      case SettingsNavigationEvent.goToTerms:
        context.push(
          AppRouter.about,
          extra: AboutArgs(
            documentId: 'terms_and_conditions',
            title: 'Terms & Conditions',
            isAdmin: isAdmin,
          ),
        );
        break;

      case SettingsNavigationEvent.goToPrivacy:
        context.push(
          AppRouter.about,
          extra: AboutArgs(
            documentId: 'privacy_policy',
            title: 'Privacy Policy',
            isAdmin: isAdmin,
          ),
        );
        break;

      case SettingsNavigationEvent.goToFaq:
        context.push(AppRouter.faq, extra: FaqArgs(isAdmin: isAdmin));
        break;

      case SettingsNavigationEvent.goToRateUs:
        context.push(AppRouter.rateUs, extra: const AuthenticatedRouteArgs());
        break;

      case SettingsNavigationEvent.goToHelpCenter:
        context.push(
          AppRouter.helpCenter,
          extra: HelpCenterArgs(isAdmin: isAdmin),
        );
        break;

      case SettingsNavigationEvent.goToAgeGroups:
        context.push(AppRouter.ageGroups);
        break;
      case SettingsNavigationEvent.goToMealPreferences:
        context.push(
          AppRouter.settingsMealPreferences,
          extra: UserSetupArgs(
            uid: viewModel.user.uid,
            user: viewModel.user,
            isSettingsMode: true,
          ),
        );
        break;
      case SettingsNavigationEvent.goToAllergies:
        context.push(
          AppRouter.settingsAllergies,
          extra: UserSetupArgs(
            uid: viewModel.user.uid,
            user: viewModel.user,
            isSettingsMode: true,
          ),
        );
        break;
      case SettingsNavigationEvent.goToDislikes:
        context.push(
          AppRouter.settingsDislikes,
          extra: UserSetupArgs(
            uid: viewModel.user.uid,
            user: viewModel.user,
            isSettingsMode: true,
          ),
        );
        break;
      case SettingsNavigationEvent.goToTargetCalories:
        context.push(
          AppRouter.settingsTargetCalories,
          extra: UserSetupArgs(
            uid: viewModel.user.uid,
            user: viewModel.user,
            isSettingsMode: true,
          ),
        );
        break;
    }
  }

  /// Handles the build logout button operation.
  Widget _buildLogoutButton(BuildContext context, SettingsViewModel viewModel) {
    /// Handles the padding operation.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: PrimaryButton(
        text: 'Logout',
        onPressed: () => _showLogoutDialog(context, viewModel),
        isLoading: false,
        verticalPadding: 14,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
    );
  }

  /// Handles the show logout dialog operation.
  void _showLogoutDialog(BuildContext context, SettingsViewModel viewModel) {
    /// Displays the show dialog flow.
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          /// Creates a text button instance.
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),

          /// Creates a text button instance.
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Close dialog
              await viewModel.logout(); // This will emit logout event
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  /// Handles the navigate to onboarding operation.
  void _navigateToOnboarding(BuildContext context) {
    context.go(AppRouter.onboarding);
  }
}

class _NotificationPreferenceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NotificationPreferenceTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      visualDensity: const VisualDensity(vertical: -2),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      subtitle: Text(
        description,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.2),
      ),
      value: value,
      onChanged: onChanged,
      activeThumbColor: Theme.of(context).colorScheme.primary,
      secondary: Icon(icon, color: Theme.of(context).colorScheme.primary),
    );
  }
}
