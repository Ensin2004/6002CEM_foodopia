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

/// Main view for the Planning tab in the meal plan page.
/// Displays calendar, weather, and meal plan sections.
class PlanningTabMainView extends StatelessWidget {
  /// The meal plan dashboard data.
  final MealPlanDashboard dashboard;

  /// Creates a new planning tab main view instance.
  const PlanningTabMainView({super.key, required this.dashboard});

  @override
  Widget build(BuildContext context) {
    // Watch the view model for state changes.
    final viewModel = context.watch<MealPlanViewModel>();

    // Get the selected date.
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
          // Summary strip.
          MealPlanSummaryStrip(summary: dashboard.summary),
          const SizedBox(height: AppSpacing.md),

          // Date header.
          Text(
            'Today, ${DateFormat('d MMMM yyyy').format(selectedDate)}',
            style: context.text.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),

          // Weather box or loading.
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

          // Calendar.
          MealPlanCalendar(
            selectedDate: selectedDate,
            days: dashboard.monthDays,
            onDateSelected: viewModel.selectDate,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Meal plan sections header.
          Text("Today's Meal Plan", style: context.text.titleMedium),
          const SizedBox(height: AppSpacing.sm),

          // Meal filters.
          const _MealFilters(),
          const SizedBox(height: AppSpacing.md),

          // Meal sections or empty state.
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

/// Weather box widget.
class _WeatherBox extends StatelessWidget {
  /// Weather data.
  final MealPlanWeather? weather;

  /// Error message if weather is unavailable.
  final String? errorMessage;

  /// Creates a new weather box instance.
  const _WeatherBox({required this.weather, this.errorMessage});

  @override
  Widget build(BuildContext context) {
    // Get the current weather.
    final currentWeather = weather;

    // Show error state if weather is null.
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

    // Show weather information.
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

/// Returns a meal hint based on weather conditions.
String _mealHintFor(MealPlanWeather weather) {
  // Hot weather: suggest light meals.
  if (weather.currentTemp >= 30) {
    return 'Light meals and hydrating ingredients are a good fit today.';
  }

  // Rainy weather: suggest warm comfort food.
  if (weather.condition.toLowerCase().contains('rain')) {
    return 'Warm bowls and comforting dishes fit the weather well.';
  }

  // Default: balanced meals.
  return 'Balanced meals should work nicely with today\'s weather.';
}

/// Meal filters widget.
class _MealFilters extends StatelessWidget {
  /// Creates a new meal filters instance.
  const _MealFilters();

  @override
  Widget build(BuildContext context) {
    // Watch the view model for state changes.
    final viewModel = context.watch<MealPlanViewModel>();

    // Get filter options.
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

/// Empty meals state widget.
class _EmptyMeals extends StatelessWidget {
  /// Creates a new empty meals instance.
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