import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/dependency_injection/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../../../core/widgets/tabs/app_segmented_tabs.dart';
import '../../domain/usecases/get_meal_plan_dashboard_usecase.dart';
import '../../domain/usecases/get_meal_plan_weather_usecase.dart';
import '../viewmodel/meal_plan_viewmodel.dart';
import '../widgets/grocery_list_tab_view.dart';
import '../widgets/inspiration_tab_view.dart';
import '../widgets/planning_tab_view.dart';

class MealPlanPage extends StatelessWidget {
  final int initialTabIndex;

  const MealPlanPage({super.key, this.initialTabIndex = 0});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MealPlanViewModel(
        getDashboardUseCase: sl<GetMealPlanDashboardUseCase>(),
        getWeatherUseCase: sl<GetMealPlanWeatherUseCase>(),
      ),
      child: _MealPlanView(initialTabIndex: initialTabIndex),
    );
  }
}

class _MealPlanView extends StatefulWidget {
  final int initialTabIndex;

  const _MealPlanView({required this.initialTabIndex});

  @override
  State<_MealPlanView> createState() => _MealPlanViewState();
}

class _MealPlanViewState extends State<_MealPlanView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 2),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MealPlanViewModel>();

    if (viewModel.isLoading && viewModel.dashboard == null) {
      return const LoadingDialog(inline: true, message: 'Loading meal plan...');
    }

    final dashboard = viewModel.dashboard;
    if (dashboard == null) {
      return _MealPlanError(
        message: viewModel.errorMessage ?? 'Unable to load meal plan',
        onRetry: viewModel.loadDashboard,
      );
    }

    return Column(
      children: [
        AppSegmentedTabs(
          controller: _tabController,
          tabs: const ['Planning', 'Inspiration', 'Grocery List'],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              PlanningTabView(dashboard: dashboard),
              InspirationTabView(items: dashboard.inspirations),
              GroceryListTabView(groups: dashboard.groceryGroups),
            ],
          ),
        ),
      ],
    );
  }
}

class _MealPlanError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _MealPlanError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/empty_page.png', height: 140),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.text.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
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
