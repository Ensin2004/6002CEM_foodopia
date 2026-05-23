import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../app/dependency_injection/injection_container.dart';
import '../../../../app/navigation/navigation_events.dart';
import '../../../../app/routers/app_router.dart';
import '../../../../app/routers/router_args.dart';
import '../../../../core/widgets/buttons/app_floating_action_button.dart';
import '../../../admin_home/presentation/view/admin_home_page.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../admin_manage/presentation/view/admin_manage_page.dart';
import '../../../user_home/domain/entities/user_home_dashboard.dart';
import '../../../user_home/presentation/view/home_page.dart';
import '../../../user_setup/domain/usecases/get_user_setup_status_usecase.dart';
import '../viewmodel/main_viewmodel.dart';
import '../widgets/main_app_bar.dart';

// Import pages (to be implemented in their own features)
import '../../../explore/presentation/view/explore_page.dart';
import '../../../meal_plan/presentation/view/meal_plan_page.dart';
import '../../../library/presentation/view/library_page.dart';
import '../../../statistics/presentation/view/statistics_page.dart';

/// Defines behavior for main page.
class MainPage extends StatelessWidget {
  final UserEntity user;
  final String role;
  final int initialIndex;
  final String? focusedRecipeId;
  final bool? focusedRecipeIsPublished;
  final String? libraryRefreshToken;

  /// Creates a main page instance.
  const MainPage({
    super.key,
    required this.user,
    required this.role,
    this.initialIndex = 0,
    this.focusedRecipeId,
    this.focusedRecipeIsPublished,
    this.libraryRefreshToken,
  });

  /// Builds the widget tree for this component.
  @override
  Widget build(BuildContext context) {
    /// Runs the change notifier provider operation.
    return ChangeNotifierProvider(
      create: (_) => MainViewModel(
        user: user,
        repository: sl(),
        initialIndex: initialIndex,
      ),
      child: _MainPageView(
        initialIndex: initialIndex,
        focusedRecipeId: focusedRecipeId,
        focusedRecipeIsPublished: focusedRecipeIsPublished,
        libraryRefreshToken: libraryRefreshToken,
      ),
    );
  }
}

/// Defines behavior for main page view.
class _MainPageView extends StatefulWidget {
  final int initialIndex;
  final String? focusedRecipeId;
  final bool? focusedRecipeIsPublished;
  final String? libraryRefreshToken;

  /// Handles the main page view operation.
  const _MainPageView({
    required this.initialIndex,
    this.focusedRecipeId,
    this.focusedRecipeIsPublished,
    this.libraryRefreshToken,
  });

  @override
  State<_MainPageView> createState() => _MainPageViewState();
}

class _MainPageViewState extends State<_MainPageView> {
  String? _focusedRecipeId;
  bool? _focusedRecipeIsPublished;

  @override
  void initState() {
    super.initState();
    _focusedRecipeId = widget.focusedRecipeId;
    _focusedRecipeIsPublished = widget.focusedRecipeIsPublished;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyRouteTab();
      _checkUserSetup();
    });
  }

  @override
  void didUpdateWidget(covariant _MainPageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final focusChanged =
        oldWidget.focusedRecipeId != widget.focusedRecipeId ||
        oldWidget.focusedRecipeIsPublished != widget.focusedRecipeIsPublished;
    final refreshChanged =
        oldWidget.libraryRefreshToken != widget.libraryRefreshToken;
    if (oldWidget.initialIndex != widget.initialIndex ||
        focusChanged ||
        refreshChanged) {
      _focusedRecipeId = widget.focusedRecipeId;
      _focusedRecipeIsPublished = widget.focusedRecipeIsPublished;
      WidgetsBinding.instance.addPostFrameCallback((_) => _applyRouteTab());
    }
  }

  void _applyRouteTab() {
    if (!mounted) return;
    final viewModel = context.read<MainViewModel>();
    if (viewModel.selectedIndex == widget.initialIndex) return;
    viewModel.onTabTapped(widget.initialIndex);
  }

  void _handleBottomNavTap(MainViewModel viewModel, int index) {
    if (index != 4 && _focusedRecipeId != null) {
      setState(() {
        _focusedRecipeId = null;
        _focusedRecipeIsPublished = null;
      });
    }

    viewModel.onTabTapped(index);
  }

  Future<void> _checkUserSetup() async {
    final viewModel = context.read<MainViewModel>();
    if (viewModel.isAdmin) {
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

    /// Handles the scaffold operation.
    return Scaffold(
      appBar: MainAppBar(
        isAdmin: isAdmin,
        profileImageUrl: viewModel.profileImageUrl,
        onSettingsTap: viewModel.goToSettings,
        onFavoritesTap: isAdmin ? null : viewModel.goToFavorites,
        onNotificationsTap: isAdmin ? null : viewModel.goToNotifications,
      ),
      body: _buildBody(context, viewModel),
      bottomNavigationBar: _buildBottomNavigationBar(context, viewModel),
      floatingActionButton: isAdmin
          ? null
          : _buildFloatingActionButton(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  /// Handles the build body operation.
  Widget _buildBody(BuildContext context, MainViewModel viewModel) {
    final isAdmin = viewModel.isAdmin;
    final currentIndex = viewModel.selectedIndex;

    if (!isAdmin) {
      // User pages
      switch (currentIndex) {
        case 0:
          return HomePage(
            userName: viewModel.user.name ?? 'Foodie',
            onQuickLinkTap: (target) =>
                _handleUserHomeQuickLink(context, target, viewModel),
          );
        case 1:
          return const ExplorePage();
        case 3:
          return MealPlanPage(
            initialTabIndex: viewModel.mealPlanInitialTabIndex,
            userId: viewModel.user.uid,
          );
        case 4:
          return LibraryPage(
            key: ValueKey(
              _focusedRecipeId ?? widget.libraryRefreshToken ?? 'library',
            ),
            onExploreNow: () => viewModel.onTabTapped(1),
            focusedRecipeId: _focusedRecipeId,
            focusedRecipeIsPublished: _focusedRecipeIsPublished,
          );
        default:
          return HomePage(
            userName: viewModel.user.name ?? 'Foodie',
            onQuickLinkTap: (target) =>
                _handleUserHomeQuickLink(context, target, viewModel),
          );
      }
    } else {
      // Admin pages
      switch (currentIndex) {
        case 0:
          return AdminHomePage(adminName: viewModel.user.name ?? 'Admin');
        case 1:
          return const AdminManagePage();
        case 2:
          return const StatisticsPage(isAdmin: true, showAppBar: false);
        default:
          return HomePage(userName: viewModel.user.name ?? 'Foodie');
      }
    }
  }

  void _handleUserHomeQuickLink(
    BuildContext context,
    UserHomeQuickLinkTarget target,
    MainViewModel viewModel,
  ) {
    switch (target) {
      case UserHomeQuickLinkTarget.explore:
        viewModel.goToExplore();
        break;
      case UserHomeQuickLinkTarget.addRecipe:
        viewModel.goToAddRecipe();
        break;
      case UserHomeQuickLinkTarget.mealPlan:
        viewModel.goToMealPlan();
        break;
      case UserHomeQuickLinkTarget.groceryList:
        viewModel.goToMealPlan(initialTabIndex: 2);
        break;
      case UserHomeQuickLinkTarget.statistics:
        context.push(
          AppRouter.statistics,
          extra: const StatisticsArgs(isAdmin: false),
        );
        break;
      case UserHomeQuickLinkTarget.tryAi:
        context.push(
          AppRouter.generateAiMeal,
          extra: GenerateAiMealArgs(
            userId: viewModel.user.uid,
            mealType: 'Breakfast',
          ),
        );
        break;
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
        onTap: (index) => _handleBottomNavTap(viewModel, index),
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
