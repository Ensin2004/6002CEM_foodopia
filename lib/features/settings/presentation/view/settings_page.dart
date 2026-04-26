import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../app/dependency_injection/injection_container.dart';
import '../../../../app/navigation/navigation_events.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../onboarding/presentation/view/onboarding_screen.dart';
import '../../domain/repositories/settings_repository.dart';
import '../viewmodel/settings_viewmodel.dart';
import '../widgets/settings_section_widget.dart';
import 'subfeatures/account/edit_profile_page.dart';
import 'subfeatures/account/change_password_page.dart';
import 'subfeatures/about/about_editor_page.dart';
import 'subfeatures/about/about_viewer_page.dart';
import 'subfeatures/support/admin_faq_page.dart';
import 'subfeatures/support/user_faq_page.dart';
import 'subfeatures/support/rate_us_page.dart';
import 'subfeatures/support/admin_help_center_page.dart';
import 'subfeatures/support/user_help_center_page.dart';

class SettingsPage extends StatelessWidget {
  final UserEntity user;

  const SettingsPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SettingsViewModel(
        user: user,
        repository: sl<SettingsRepository>(),
      ),
      child: const _SettingsPageView(),
    );
  }
}

class _SettingsPageView extends StatelessWidget {
  const _SettingsPageView();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SettingsViewModel>();
    final isAdmin = viewModel.isAdmin;

    // ✅ Handle Settings navigation events (type-safe)
    final settingsEvent = viewModel.navigationEvent;
    if (settingsEvent != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleSettingsNavigation(context, settingsEvent, viewModel, isAdmin);
      });
    }

    // ✅ Handle App-level events (logout)
    final appEvent = viewModel.appEvent;
    if (appEvent == AppNavigationEvent.logout) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToOnboarding(context);
      });
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Settings',
        centerTitle: true,
      ),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileSection(context, viewModel),
            ..._buildSettingsSections(context, viewModel),
            const SizedBox(height: 32),
            _buildLogoutButton(context, viewModel),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context, SettingsViewModel viewModel) {
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
          CircleAvatar(
            radius: 40,
            backgroundColor: Theme.of(context).colorScheme.background,
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
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  viewModel.fullName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  viewModel.email,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
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

  List<Widget> _buildSettingsSections(BuildContext context, SettingsViewModel viewModel) {
    final sections = <Widget>[];
    final sectionCount = viewModel.sections.length;

    for (int i = 0; i < sectionCount; i++) {
      final section = viewModel.sections[i];
      final isLast = i == sectionCount - 1;

      sections.add(
        SettingsSectionWidget(
          section: section,
          viewModel: viewModel,
          isLast: isLast,
        ),
      );
    }

    return sections;
  }

  // ✅ Type-safe navigation handler
  void _handleSettingsNavigation(
      BuildContext context,
      SettingsNavigationEvent event,
      SettingsViewModel viewModel,
      bool isAdmin,
      ) {
    switch (event) {
      case SettingsNavigationEvent.goToEditProfile:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EditProfilePage(uid: viewModel.user.uid),
          ),
        ).then((_) => viewModel.refreshProfile());
        break;

      case SettingsNavigationEvent.goToChangePassword:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ChangePasswordPage()),
        );
        break;

      case SettingsNavigationEvent.goToAboutUs:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => isAdmin
                ? AboutEditorPage(documentId: 'about_us', title: 'About Us')
                : AboutViewerPage(documentId: 'about_us', title: 'About Us'),
          ),
        );
        break;

      case SettingsNavigationEvent.goToTerms:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => isAdmin
                ? AboutEditorPage(documentId: 'terms_and_conditions', title: 'Terms & Conditions')
                : AboutViewerPage(documentId: 'terms_and_conditions', title: 'Terms & Conditions'),
          ),
        );
        break;

      case SettingsNavigationEvent.goToPrivacy:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => isAdmin
                ? AboutEditorPage(documentId: 'privacy_policy', title: 'Privacy Policy')
                : AboutViewerPage(documentId: 'privacy_policy', title: 'Privacy Policy'),
          ),
        );
        break;

      case SettingsNavigationEvent.goToFaq:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => isAdmin ? const AdminFaqPage() : const UserFaqPage(),
          ),
        );
        break;

      case SettingsNavigationEvent.goToRateUs:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RateUsPage()),
        );
        break;

      case SettingsNavigationEvent.goToHelpCenter:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => isAdmin
                ? const AdminHelpCenterPage()
                : const UserHelpCenterPage(),
          ),
        );
        break;
    }
  }

  Widget _buildLogoutButton(BuildContext context, SettingsViewModel viewModel) {
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

  void _showLogoutDialog(BuildContext context, SettingsViewModel viewModel) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
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

  void _navigateToOnboarding(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
          (route) => false,
    );
  }
}