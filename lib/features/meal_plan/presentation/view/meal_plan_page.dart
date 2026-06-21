import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/dependency_injection/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../../../core/widgets/tabs/app_segmented_tabs.dart';
import '../../domain/usecases/get_meal_plan_dashboard_usecase.dart';
import '../../domain/usecases/get_meal_plan_inspiration_options_usecase.dart';
import '../../domain/usecases/get_meal_plan_preferences_usecase.dart';
import '../../domain/usecases/get_meal_plan_weather_usecase.dart';
import '../../domain/usecases/delete_meal_plan_usecase.dart';
import '../../domain/usecases/search_meal_plan_ingredients_usecase.dart';
import '../../domain/usecases/update_weekly_grocery_week_start_day_usecase.dart';
import '../viewmodel/meal_plan_viewmodel.dart';
import '../widgets/grocery_list/grocery_list_tab_main_view.dart';
import '../widgets/inspiration/inspiration_tab_main_view.dart';
import '../widgets/planning/planning_tab_main_view.dart';

/// Main page for the meal plan feature.
/// Contains three tabs: Planning, Inspiration, and Grocery List.
class MealPlanPage extends StatelessWidget {
  /// Initial tab index to display (0: Planning, 1: Inspiration, 2: Grocery List).
  final int initialTabIndex;

  /// User ID of the current user.
  final String userId;

  /// Creates a new meal plan page instance.
  const MealPlanPage({super.key, this.initialTabIndex = 0, this.userId = ''});

  @override
  Widget build(BuildContext context) {
    // Provide the view model to the widget tree.
    return ChangeNotifierProvider(
      create: (_) => MealPlanViewModel(
        userId: userId,
        getDashboardUseCase: sl<GetMealPlanDashboardUseCase>(),
        getWeatherUseCase: sl<GetMealPlanWeatherUseCase>(),
        getPreferencesUseCase: sl<GetMealPlanPreferencesUseCase>(),
        searchIngredientsUseCase: sl<SearchMealPlanIngredientsUseCase>(),
        getInspirationOptionsUseCase:
            sl<GetMealPlanInspirationOptionsUseCase>(),
        deleteMealPlanUseCase: sl<DeleteMealPlanUseCase>(),
        updateWeeklyGroceryWeekStartDayUseCase:
            sl<UpdateWeeklyGroceryWeekStartDayUseCase>(),
      ),
      child: _MealPlanView(initialTabIndex: initialTabIndex),
    );
  }
}

/// Internal view for the meal plan page.
class _MealPlanView extends StatefulWidget {
  /// Initial tab index.
  final int initialTabIndex;

  /// Creates a new meal plan view instance.
  const _MealPlanView({required this.initialTabIndex});

  @override
  State<_MealPlanView> createState() => _MealPlanViewState();
}

/// State for the meal plan view.
class _MealPlanViewState extends State<_MealPlanView>
    with SingleTickerProviderStateMixin {
  /// Tab controller for managing tab switching.
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();

    // Initialize the tab controller with 3 tabs.
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 2),
    );
  }

  @override
  void didUpdateWidget(covariant _MealPlanView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update tab index if initialTabIndex changed.
    final nextIndex = widget.initialTabIndex.clamp(0, 2);
    if (oldWidget.initialTabIndex != widget.initialTabIndex &&
        _tabController.index != nextIndex) {
      _tabController.animateTo(nextIndex);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the view model for state changes.
    final viewModel = context.watch<MealPlanViewModel>();

    // Show loading dialog while dashboard is loading.
    if (viewModel.isLoading && viewModel.dashboard == null) {
      return const LoadingDialog(message: 'Loading meal plan...');
    }

    // Get the dashboard.
    final dashboard = viewModel.dashboard;

    // Show error state if dashboard is null.
    if (dashboard == null) {
      return _MealPlanError(
        message: viewModel.errorMessage ?? 'Unable to load meal plan',
        onRetry: viewModel.loadDashboard,
      );
    }

    return Column(
      children: [
        // Tab bar with three tabs.
        AppSegmentedTabs(
          controller: _tabController,
          tabs: const ['Planning', 'Inspiration', 'Grocery List'],
        ),
        // Tab content.
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              PlanningTabMainView(dashboard: dashboard),
              InspirationTabMainView(dashboard: dashboard),
              GroceryListTabMainView(lists: dashboard.groceryLists),
            ],
          ),
        ),
      ],
    );
  }
}

/// Error state widget for the meal plan page.
class _MealPlanError extends StatelessWidget {
  /// Error message to display.
  final String message;

  /// Callback when retry is pressed.
  final Future<void> Function() onRetry;

  /// Creates a new meal plan error instance.
  const _MealPlanError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Empty state image.
            Image.asset('assets/images/empty_page.png', height: 140),
            const SizedBox(height: AppSpacing.lg),

            // Error message.
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.text.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),

            // Retry button.
            TextButton(
              onPressed: onRetry,
              child: Text(
                'Try Again',
                style: context.text.labelLarge?.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
