import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/dependency_injection/injection_container.dart';
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

class HomePage extends StatelessWidget {
  final String userName;
  final ValueChanged<UserHomeQuickLinkTarget>? onQuickLinkTap;

  const HomePage({super.key, required this.userName, this.onQuickLinkTap});

  @override
  Widget build(BuildContext context) {
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

class _HomeView extends StatelessWidget {
  final ValueChanged<UserHomeQuickLinkTarget>? onQuickLinkTap;

  const _HomeView({this.onQuickLinkTap});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();

    if (viewModel.isLoading && viewModel.dashboard == null) {
      return const SizedBox.shrink();
    }

    final dashboard = viewModel.dashboard;
    if (dashboard == null) {
      return _HomeError(message: viewModel.errorMessage);
    }

    return RefreshIndicator(
      onRefresh: viewModel.loadDashboard,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserHomeHero(
            dashboard: dashboard,
            isWeatherLoading: viewModel.isWeatherLoading,
            weatherErrorMessage: viewModel.weatherErrorMessage,
          ),
          const SizedBox(height: AppSpacing.lg),
          HomeSection(
            title: 'Quick Links',
            child: UserQuickLinksGrid(
              links: dashboard.quickLinks,
              onLinkTap: (target) => _handleQuickLink(context, target),
            ),
          ),
          HomeSection(
            title: "Today's Meal Plan",
            child: UserMealPlanList(sections: dashboard.mealPlan),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  void _handleQuickLink(BuildContext context, UserHomeQuickLinkTarget target) {
    final handler = onQuickLinkTap;
    if (handler == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Menu is unavailable')));
      return;
    }

    handler(target);
  }
}

class _HomeError extends StatelessWidget {
  final String? message;

  const _HomeError({this.message});

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
