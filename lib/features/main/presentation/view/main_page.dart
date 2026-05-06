import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../app/dependency_injection/injection_container.dart';
import '../../../../app/navigation/navigation_events.dart';
import '../../../../app/routers/app_router.dart';
import '../../../../app/routers/router_args.dart';
import '../../../../core/widgets/buttons/app_floating_action_button.dart';
import '../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../../admin_home/presentation/view/admin_home_page.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../admin_manage/presentation/view/admin_manage_page.dart';
import '../../../user_setup/domain/usecases/get_user_setup_status_usecase.dart';
import '../viewmodel/main_viewmodel.dart';
import '../widgets/main_app_bar.dart';

// Import pages (to be implemented in their own features)
import '../../../home/presentation/view/home_page.dart';
import '../../../explore/presentation/view/explore_page.dart';
import '../../../meal_plan/presentation/view/meal_plan_page.dart';
import '../../../library/presentation/view/library_page.dart';
import '../../../statistics/presentation/view/statistics_page.dart';

/// Defines behavior for main page.
class MainPage extends StatelessWidget {
  final UserEntity user;
  final String role;

  /// Creates a main page instance.
  const MainPage({super.key, required this.user, required this.role});

  /// Builds the widget tree for this component.
  @override
  Widget build(BuildContext context) {
    /// Runs the change notifier provider operation.
    return ChangeNotifierProvider(
      create: (_) => MainViewModel(user: user, repository: sl()),
      child: const _MainPageView(),
    );
  }
}

/// Defines behavior for main page view.
class _MainPageView extends StatefulWidget {
  /// Handles the main page view operation.
  const _MainPageView();

  @override
  State<_MainPageView> createState() => _MainPageViewState();
}

class _MainPageViewState extends State<_MainPageView> {
  bool _checkingSetup = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkUserSetup();
    });
  }

  Future<void> _checkUserSetup() async {
    final viewModel = context.read<MainViewModel>();
    if (viewModel.isAdmin) {
      if (mounted) setState(() => _checkingSetup = false);
      return;
    }

    final result = await sl<GetUserSetupStatusUseCase>().execute(
      viewModel.user.uid,
    );
    final completed = result.fold((_) => true, (value) => value);

    if (!mounted) return;
    if (!completed) {
      context.go(
        AppRouter.setupDiet,
        extra: UserSetupArgs(uid: viewModel.user.uid, user: viewModel.user),
      );
      return;
    }

    setState(() => _checkingSetup = false);
  }

  /// Builds the widget tree for this component.
  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MainViewModel>();
    final isAdmin = viewModel.isAdmin;
    final navigationEvent = viewModel.navigationEvent;

    if (navigationEvent != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleNavigation(context, navigationEvent, viewModel);
      });
    }

    if (_checkingSetup) return const LoadingDialog();

    /// Handles the scaffold operation.
    return Scaffold(
      appBar: MainAppBar(
        isAdmin: isAdmin,
        profileImageUrl: viewModel.profileImageUrl,
        onSettingsTap: viewModel.goToSettings,
        onFavoritesTap: isAdmin ? null : viewModel.goToFavorites,
        onNotificationsTap: isAdmin ? null : viewModel.goToNotifications,
      ),
      body: _buildBody(viewModel),
      bottomNavigationBar: _buildBottomNavigationBar(context, viewModel),
      floatingActionButton: isAdmin
          ? null
          : _buildFloatingActionButton(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  /// Handles the build body operation.
  Widget _buildBody(MainViewModel viewModel) {
    final isAdmin = viewModel.isAdmin;
    final currentIndex = viewModel.selectedIndex;

    if (!isAdmin) {
      // User pages
      switch (currentIndex) {
        case 0:
          return const HomePage();
        case 1:
          return const ExplorePage();
        case 2:
          return const MealPlanPage();
        case 3:
          return const LibraryPage();
        default:
          return const HomePage();
      }
    } else {
      // Admin pages
      switch (currentIndex) {
        case 0:
          return AdminHomePage(adminName: viewModel.user.name ?? 'Admin');
        case 1:
          return const AdminManagePage();
        case 2:
          return const StatisticsPage(isAdmin: true);
        default:
          return const HomePage();
      }
    }
  }

  /// Handles the build bottom navigation bar operation.
  Widget _buildBottomNavigationBar(
    BuildContext context,
    MainViewModel viewModel,
  ) {
    final isAdmin = viewModel.isAdmin;

    /// Handles the material operation.
    return Material(
      elevation: 30,
      shadowColor: Colors.black.withValues(alpha: 0.8),
      child: BottomNavigationBar(
        currentIndex: viewModel.selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        backgroundColor: Theme.of(context).colorScheme.surface,
        onTap: viewModel.onTabTapped,
        type: BottomNavigationBarType.fixed,
        items: isAdmin
            ? const [
                /// Creates a bottom navigation bar item instance.
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),

                /// Creates a bottom navigation bar item instance.
                BottomNavigationBarItem(
                  icon: Icon(Icons.admin_panel_settings),
                  label: 'Manage',
                ),

                /// Creates a bottom navigation bar item instance.
                BottomNavigationBarItem(
                  icon: Icon(Icons.bar_chart),
                  label: 'Statistics',
                ),
              ]
            : const [
                /// Creates a bottom navigation bar item instance.
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),

                /// Creates a bottom navigation bar item instance.
                BottomNavigationBarItem(
                  icon: Icon(Icons.explore),
                  label: 'Explore',
                ),

                /// Creates a bottom navigation bar item instance.
                BottomNavigationBarItem(
                  icon: Icon(Icons.add_box),
                  label: 'Add',
                ),

                /// Creates a bottom navigation bar item instance.
                BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_month),
                  label: 'Meal Plan',
                ),

                /// Creates a bottom navigation bar item instance.
                BottomNavigationBarItem(
                  icon: Icon(Icons.library_books),
                  label: 'Library',
                ),
              ],
      ),
    );
  }

  /// Handles the build floating action button operation.
  Widget _buildFloatingActionButton(BuildContext context) {
    /// Handles the floating action button operation.
    return AppFloatingActionButton(
      onPressed: context.read<MainViewModel>().goToAddRecipe,
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      tooltip: 'Add Recipe',
    );
  }

  // Navigation methods
  void _handleNavigation(
    BuildContext context,
    MainNavigationEvent event,
    MainViewModel viewModel,
  ) {
    switch (event) {
      case MainNavigationEvent.goToSettings:
        // Pass the user from MainViewModel to SettingsPage
        context
            .push(AppRouter.settings, extra: SettingsArgs(user: viewModel.user))
            .then((_) {
              viewModel.refreshProfile();
            });
        break;
      case MainNavigationEvent.goToFavorites:
        ScaffoldMessenger.of(context).showSnackBar(
          /// Creates a snack bar instance.
          const SnackBar(content: Text('Favorites - Coming Soon')),
        );
        break;
      case MainNavigationEvent.goToNotifications:
        context.push(
          AppRouter.notifications,
          extra: const AuthenticatedRouteArgs(),
        );
        break;
      case MainNavigationEvent.goToAddRecipe:
        context.push(
          AppRouter.addRecipe,
          extra: const AuthenticatedRouteArgs(),
        );
        break;
      case MainNavigationEvent.goToProfile:
      case MainNavigationEvent.goToStatistics:
        break;
    }
  }
}
