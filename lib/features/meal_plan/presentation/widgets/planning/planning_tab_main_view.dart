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

    return Stack(
      children: [
        RefreshIndicator(
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
                  child: LoadingDialog(
                    inline: true,
                    message: 'Loading weather...',
                  ),
                )
              else
                _WeatherBox(
                  weather: dashboard.weather,
                  errorMessage: viewModel.weatherErrorMessage,
                ),
              const SizedBox(height: AppSpacing.md),

              // Daily calorie progress.
              _DailyCaloriesCard(
                sections: dashboard.sections,
                preferences: viewModel.preferences,
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
        ),
        // Loading overlay matches the Generate with AI flow.
        if (viewModel.isLoading) ...[
          const Positioned.fill(child: ColoredBox(color: Colors.white)),
          const Positioned.fill(
            child: LoadingDialog(message: 'Loading meal plan...'),
          ),
        ],
      ],
    );
  }
}

/// Daily calorie progress card.
class _DailyCaloriesCard extends StatelessWidget {
  /// Meal sections for the selected date.
  final List<MealPlanSection> sections;

  /// User preference summary with calorie target.
  final MealPlanPreferenceSummary? preferences;

  /// Creates a new daily calories card instance.
  const _DailyCaloriesCard({required this.sections, required this.preferences});

  @override
  Widget build(BuildContext context) {
    // Planned calories are calculated from visible selected-date meals.
    final plannedCalories = _plannedCalories;
    final targetCalories = preferences?.calorieTargetEnabled == true
        ? preferences?.targetCalories
        : null;
    final unit = preferences?.calorieUnit ?? 'kcal';
    final plannedDisplayCalories = _displayCalories(plannedCalories, unit);
    final progress = targetCalories == null || targetCalories <= 0
        ? 0.0
        : (plannedDisplayCalories / targetCalories).clamp(0.0, 1.0);
    final status = _CalorieStatus.from(
      plannedCalories: plannedDisplayCalories,
      targetCalories: targetCalories,
      unit: unit,
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: status.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.local_fire_department_outlined,
                  color: status.color,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Calories',
                      style: context.text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      status.message,
                      style: context.text.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _CalorieStatusChip(status: status),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: targetCalories == null ? null : progress,
              backgroundColor: const Color(0xFFE9EEF0),
              valueColor: AlwaysStoppedAnimation<Color>(status.color),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _MealCalorieBreakdown(sections: sections, unit: unit),
        ],
      ),
    );
  }

  /// Total planned calories for the selected date.
  int get _plannedCalories {
    return sections.fold<int>(0, (sectionTotal, section) {
      return sectionTotal +
          section.meals.fold<int>(0, (mealTotal, meal) {
            return mealTotal + meal.calories;
          });
    });
  }

  /// Converts stored kcal into the selected display unit.
  int _displayCalories(int kcal, String unit) {
    if (unit.toLowerCase() == 'kj') return (kcal * 4.184).round();
    return kcal;
  }
}

/// Calorie target status chip.
class _CalorieStatusChip extends StatelessWidget {
  /// Status data.
  final _CalorieStatus status;

  /// Creates a new calorie status chip instance.
  const _CalorieStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: status.color.withValues(alpha: 0.16)),
      ),
      child: Text(
        status.label,
        style: context.text.bodySmall?.copyWith(
          color: status.color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Presentation status for the daily calorie summary.
class _CalorieStatus {
  /// Short chip label.
  final String label;

  /// Helpful message.
  final String message;

  /// Status color.
  final Color color;

  const _CalorieStatus({
    required this.label,
    required this.message,
    required this.color,
  });

  factory _CalorieStatus.from({
    required int plannedCalories,
    required int? targetCalories,
    required String unit,
  }) {
    final target = targetCalories;
    if (target == null || target <= 0) {
      return _CalorieStatus(
        label: 'Set target',
        message:
            '$plannedCalories $unit planned today. Add a target to track your day.',
        color: AppColors.textSecondary,
      );
    }

    if (plannedCalories > target) {
      final over = plannedCalories - target;
      return _CalorieStatus(
        label: 'Over by $over $unit',
        message:
            'You are over target. Choose lighter meals for the rest of today.',
        color: AppColors.error,
      );
    }

    final remaining = target - plannedCalories;
    final ratio = plannedCalories / target;
    if (ratio >= 0.85) {
      return _CalorieStatus(
        label: '$remaining $unit left',
        message:
            'Almost at your target. Keep the next meal light and balanced.',
        color: AppColors.secondary,
      );
    }

    return _CalorieStatus(
      label: '$remaining $unit left',
      message: 'On track today. You still have room for planned meals.',
      color: AppColors.primary,
    );
  }
}

/// Meal-type calorie breakdown.
class _MealCalorieBreakdown extends StatelessWidget {
  /// Meal sections for the selected date.
  final List<MealPlanSection> sections;

  /// Calorie unit label.
  final String unit;

  /// Creates a new meal calorie breakdown instance.
  const _MealCalorieBreakdown({required this.sections, required this.unit});

  @override
  Widget build(BuildContext context) {
    // Only sections with meals are shown in the compact breakdown row.
    final items = sections
        .map((section) {
          final total = section.meals.fold<int>(
            0,
            (sum, meal) => sum + meal.calories,
          );
          return MapEntry(section.mealType, _displayCalories(total));
        })
        .where((item) => item.value > 0)
        .toList();

    if (items.isEmpty) {
      return Text(
        'No meal calories planned yet',
        style: context.text.bodySmall?.copyWith(color: AppColors.textSecondary),
      );
    }

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [
        for (final item in items)
          Text(
            '${item.key} ${item.value} $unit',
            style: context.text.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
      ],
    );
  }

  /// Converts stored kcal into the selected display unit.
  int _displayCalories(int kcal) {
    if (unit.toLowerCase() == 'kj') return (kcal * 4.184).round();
    return kcal;
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
