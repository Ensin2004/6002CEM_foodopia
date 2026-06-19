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
import '../../../notifications/domain/usecases/get_notification_preferences_usecase.dart';
import '../../../notifications/domain/usecases/update_notification_preference_usecase.dart';
import '../../domain/repositories/settings_repository.dart';
import '../viewmodel/settings_viewmodel.dart';
import '../widgets/settings_notification_section.dart';
import '../widgets/settings_profile_header.dart';
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
                  SettingsProfileHeader(viewModel: viewModel),
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
        sections.add(SettingsNotificationSection(viewModel: viewModel));
      }
    }

    return sections;
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
        context.push(AppRouter.rateUs, extra: RateUsArgs(isAdmin: isAdmin));
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
