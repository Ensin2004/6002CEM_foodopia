import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../app/dependency_injection/injection_container.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../manage/presentation/view/manage_page.dart';
import '../viewmodel/main_viewmodel.dart';
import '../widgets/main_app_bar.dart';

// Import pages (to be implemented in their own features)
import '../../../home/presentation/view/home_page.dart';
import '../../../explore/presentation/view/explore_page.dart';
import '../../../meal_plan/presentation/view/meal_plan_page.dart';
import '../../../library/presentation/view/library_page.dart';
import '../../../statistics/presentation/view/statistics_page.dart';
import '../../../settings/presentation/view/settings_page.dart';
import '../../../notifications/presentation/view/notifications_page.dart';
import '../../../recipe/presentation/view/add_recipe_page.dart';

class MainPage extends StatelessWidget {
  final UserEntity user;
  final String role;

  const MainPage({
    super.key,
    required this.user,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MainViewModel(
        user: user,
        repository: sl(),
      ),
      child: const _MainPageView(),
    );
  }
}

class _MainPageView extends StatelessWidget {
  const _MainPageView();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MainViewModel>();
    final isAdmin = viewModel.isAdmin;

    return Scaffold(
      appBar: MainAppBar(
        isAdmin: isAdmin,
        profileImageUrl: viewModel.profileImageUrl,
        onSettingsTap: () => _navigateToSettings(context, viewModel),
        onFavoritesTap: isAdmin ? null : () => _navigateToFavorites(context),
        onNotificationsTap: isAdmin ? null : () => _navigateToNotifications(context),
      ),
      body: _buildBody(viewModel),
      bottomNavigationBar: _buildBottomNavigationBar(context, viewModel),
      floatingActionButton: isAdmin ? null : _buildFloatingActionButton(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildBody(MainViewModel viewModel) {
    final isAdmin = viewModel.isAdmin;
    final currentIndex = viewModel.selectedIndex;

    if (!isAdmin) {
      // User pages
      switch (currentIndex) {
        case 0: return const HomePage();
        case 1: return const ExplorePage();
        case 2: return const MealPlanPage();
        case 3: return const LibraryPage();
        default: return const HomePage();
      }
    } else {
      // Admin pages
      switch (currentIndex) {
        case 0: return const HomePage();
        case 1: return const ManagePage();
        case 2: return const StatisticsPage(isAdmin: true);
        default: return const HomePage();
      }
    }
  }

  Widget _buildBottomNavigationBar(BuildContext context, MainViewModel viewModel) {
    final isAdmin = viewModel.isAdmin;

    return Material(
      elevation: 30,
      shadowColor: Colors.black.withOpacity(0.8),
      child: BottomNavigationBar(
        currentIndex: viewModel.selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        backgroundColor: Theme.of(context).colorScheme.background,
        onTap: viewModel.onTabTapped,
        type: BottomNavigationBarType.fixed,
        items: isAdmin
            ? const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: 'Manage'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Statistics'),
        ]
            : const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explore'),
          BottomNavigationBarItem(icon: Icon(Icons.add_box), label: 'Add'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Meal Plan'),
          BottomNavigationBarItem(icon: Icon(Icons.library_books), label: 'Library'),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _navigateToAddRecipe(context),
      child: const Icon(Icons.add),
      tooltip: 'Add Recipe',
    );
  }

  // Navigation methods
  void _navigateToSettings(BuildContext context, MainViewModel viewModel) {
    // ✅ Pass the user from MainViewModel to SettingsPage
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsPage(user: viewModel.user),
      ),
    ).then((_) {
      viewModel.refreshProfile();
    });
  }

  void _navigateToFavorites(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Favorites - Coming Soon')),
    );
  }

  void _navigateToNotifications(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsPage()),
    );
  }

  void _navigateToAddRecipe(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddRecipePage()),
    );
  }
}