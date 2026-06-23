import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/dependency_injection/injection_container.dart';
import '../../../../app/routers/app_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../domain/entities/user_home_dashboard.dart';
import '../../domain/usecases/get_user_home_dashboard_usecase.dart';
import '../../domain/usecases/get_user_home_weather_usecase.dart';
import '../viewmodel/home_viewmodel.dart';
import '../widgets/home_section.dart';
import '../widgets/user_home_hero.dart';
import '../widgets/user_meal_plan_list.dart';
import '../widgets/user_quick_links_grid.dart';
import '../../../statistics/presentation/widgets/ai_lifestyle_insight_card.dart';

/// Main home page for the application.
/// Displays user dashboard with weather, quick links, and meal plan.
class HomePage extends StatelessWidget {
  /// Name of the current user.
  final String userName;

  /// Callback when a quick link is tapped.
  final ValueChanged<UserHomeQuickLinkTarget>? onQuickLinkTap;

  /// Creates a new home page instance.
  const HomePage({super.key, required this.userName, this.onQuickLinkTap});

  @override
  Widget build(BuildContext context) {
    // Provide the view model to the widget tree.
    return ChangeNotifierProvider(
      create: (_) => HomeViewModel(
        userName: userName,
        getDashboardUseCase: sl<GetUserHomeDashboardUseCase>(),
        getWeatherUseCase: sl<GetUserHomeWeatherUseCase>(),
      ),
      child: _HomeView(onQuickLinkTap: onQuickLinkTap),
    );
  }
}

/// Internal view for the home page.
class _HomeView extends StatelessWidget {
  /// Callback when a quick link is tapped.
  final ValueChanged<UserHomeQuickLinkTarget>? onQuickLinkTap;

  /// Creates a new home view instance.
  const _HomeView({this.onQuickLinkTap});

  @override
  Widget build(BuildContext context) {
    // Watch the view model for state changes.
    final viewModel = context.watch<HomeViewModel>();

    // Show empty state while loading.
    if (viewModel.isLoading && viewModel.dashboard == null) {
      return const SizedBox.shrink();
    }

    // Get the dashboard.
    final dashboard = viewModel.dashboard;

    // Show error state if dashboard is null.
    if (dashboard == null) {
      return _HomeError(message: viewModel.errorMessage);
    }

    return RefreshIndicator(
      onRefresh: viewModel.loadDashboard,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Hero section with user info and weather.
          UserHomeHero(
            dashboard: dashboard,
            isWeatherLoading: viewModel.isWeatherLoading,
            weatherErrorMessage: viewModel.weatherErrorMessage,
          ),
          const SizedBox(height: AppSpacing.lg),

          HomeSection(
            title: 'AI Lifestyle Insight',
            child: AiLifestyleInsightCard(
              onViewDetail: () => context.push(AppRouter.aiLifestyleInsight),
            ),
          ),

          // Quick links section.
          HomeSection(
            title: 'Quick Links',
            child: UserQuickLinksGrid(
              links: dashboard.quickLinks,
              onLinkTap: (target) => _handleQuickLink(context, target),
            ),
          ),

          // Meal plan section.
          HomeSection(
            title: "Today's Meal Plan",
            child: UserMealPlanList(
              sections: dashboard.mealPlan,
              targetCalories: dashboard.calorieTargetEnabled
                  ? dashboard.targetCalories
                  : null,
              calorieUnit: dashboard.calorieUnit,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  /// Handles quick link taps.
  void _handleQuickLink(BuildContext context, UserHomeQuickLinkTarget target) {
    // Get the handler.
    final handler = onQuickLinkTap;

    // Show error if no handler is provided.
    if (handler == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Menu is unavailable')));
      return;
    }

    // Call the handler.
    handler(target);
  }
}

/// Error state widget for the home page.
class _HomeError extends StatelessWidget {
  /// Error message to display.
  final String? message;

  /// Creates a new home error instance.
  const _HomeError({this.message});

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
              message ?? 'Unable to load home',
              textAlign: TextAlign.center,
              style: context.text.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
