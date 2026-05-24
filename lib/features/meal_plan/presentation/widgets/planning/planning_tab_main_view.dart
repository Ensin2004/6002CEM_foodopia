import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_extension.dart';
import '../../../../../core/widgets/box/app_info_box.dart';
import '../../../../../core/widgets/buttons/app_filter_chip.dart';
import '../../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../../domain/entities/meal_plan_dashboard.dart';
import '../../viewmodel/meal_plan_viewmodel.dart';
import 'meal_plan_calendar.dart';
import 'meal_plan_section_card.dart';
import 'meal_plan_summary_strip.dart';

class PlanningTabMainView extends StatelessWidget {
  final MealPlanDashboard dashboard;

  const PlanningTabMainView({super.key, required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MealPlanViewModel>();
    final selectedDate = dashboard.selectedDate;

    return RefreshIndicator(
      onRefresh: viewModel.loadDashboard,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.xl,
        ),
        children: [
          MealPlanSummaryStrip(summary: dashboard.summary),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Today, ${DateFormat('d MMMM yyyy').format(selectedDate)}',
            style: context.text.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (viewModel.isWeatherLoading && dashboard.weather == null)
            const SizedBox(
              height: 84,
              child: LoadingDialog(inline: true, message: 'Loading weather...'),
            )
          else
            _WeatherBox(
              weather: dashboard.weather,
              errorMessage: viewModel.weatherErrorMessage,
            ),
          const SizedBox(height: AppSpacing.md),
          MealPlanCalendar(
            selectedDate: selectedDate,
            days: dashboard.monthDays,
            onDateSelected: viewModel.selectDate,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text("Today's Meal Plan", style: context.text.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          const _MealFilters(),
          const SizedBox(height: AppSpacing.md),
          if (viewModel.filteredSections.isEmpty)
            const _EmptyMeals()
          else
            ...viewModel.filteredSections.map(
              (section) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: MealPlanSectionCard(section: section),
              ),
            ),
        ],
      ),
    );
  }
}

class _WeatherBox extends StatelessWidget {
  final MealPlanWeather? weather;
  final String? errorMessage;

  const _WeatherBox({required this.weather, this.errorMessage});

  @override
  Widget build(BuildContext context) {
    final currentWeather = weather;

    if (currentWeather == null) {
      return AppInfoBox(
        icon: Icons.cloud_off_outlined,
        title: 'Weather unavailable',
        message: errorMessage ?? 'Meal suggestions are still ready.',
        backgroundColor: const Color(0xFFFFF7E8),
        iconBackgroundColor: const Color(0xFFFFE7BA),
        iconColor: AppColors.secondary,
      );
    }

    return AppInfoBox(
      icon: Icons.wb_sunny_outlined,
      title: '${currentWeather.condition} • ${currentWeather.currentTemp}°C',
      message: '${currentWeather.summary} ${_mealHintFor(currentWeather)}',
      backgroundColor: const Color(0xFFEFFAF1),
      iconBackgroundColor: const Color(0xFFD9F5DD),
      iconColor: AppColors.primary,
    );
  }
}

String _mealHintFor(MealPlanWeather weather) {
  if (weather.currentTemp >= 30) {
    return 'Light meals and hydrating ingredients are a good fit today.';
  }
  if (weather.condition.toLowerCase().contains('rain')) {
    return 'Warm bowls and comforting dishes fit the weather well.';
  }
  return 'Balanced meals should work nicely with today\'s weather.';
}

class _MealFilters extends StatelessWidget {
  const _MealFilters();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MealPlanViewModel>();
    final filters = viewModel.filterOptions;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((option) {
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: AppFilterChip(
              label: '${option.label} (${option.count})',
              selected: viewModel.selectedFilterId == option.id,
              onTap: () =>
                  context.read<MealPlanViewModel>().selectFilter(option.id),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _EmptyMeals extends StatelessWidget {
  const _EmptyMeals();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          Image.asset('assets/images/empty_page.png', height: 120),
          const SizedBox(height: AppSpacing.md),
          Text('No meals planned here yet', style: context.text.bodyMedium),
        ],
      ),
    );
  }
}
