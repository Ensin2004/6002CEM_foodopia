import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_extension.dart';
import '../../../domain/entities/meal_plan_dashboard.dart';
import '../../viewmodel/meal_plan_viewmodel.dart';

class InspirationTabMainView extends StatelessWidget {
  final MealPlanDashboard dashboard;

  const InspirationTabMainView({super.key, required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MealPlanViewModel>();
    final preferences = viewModel.preferences;
    final weather = dashboard.weather;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      children: [
        _SmartInspirationBox(
          weather: weather,
          preferences: preferences,
          isWeatherLoading: viewModel.isWeatherLoading,
          isPreferencesLoading: viewModel.isPreferencesLoading,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Tell us what you have & like', style: context.text.titleMedium),
        const SizedBox(height: 3),
        Text(
          'AI will use these information to generate the best suggestions for you.',
          style: context.text.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),
        _WeatherInputCard(
          weather: weather,
          isLoading: viewModel.isWeatherLoading,
          errorMessage: viewModel.weatherErrorMessage,
        ),
        const SizedBox(height: AppSpacing.md),
        const _IngredientInputCard(),
        const SizedBox(height: AppSpacing.md),
        _PreferenceInputCard(preferences: preferences),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Get AI Recipe Ideas',
              style: context.text.labelLarge?.copyWith(color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Quick Inspiration', style: context.text.titleMedium),
        const SizedBox(height: AppSpacing.md),
        _QuickInspirationGrid(items: dashboard.quickInspirations),
      ],
    );
  }
}

class _SmartInspirationBox extends StatelessWidget {
  final MealPlanWeather? weather;
  final MealPlanPreferenceSummary? preferences;
  final bool isWeatherLoading;
  final bool isPreferencesLoading;

  const _SmartInspirationBox({
    required this.weather,
    required this.preferences,
    required this.isWeatherLoading,
    required this.isPreferencesLoading,
  });

  @override
  Widget build(BuildContext context) {
    final currentWeather = weather;
    final preferenceLabel = isPreferencesLoading
        ? 'Loading...'
        : preferences?.shortLabel ?? 'Not set';
    final weatherLabel = isWeatherLoading
        ? 'Loading...'
        : currentWeather == null
        ? 'Unavailable'
        : '${currentWeather.condition} - ${currentWeather.currentTemp}C';

    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: const Color(0xFFEFFAF1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: Color(0xFFDDF5E0),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.tips_and_updates_outlined,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Smart AI Inspiration',
                      style: context.text.titleMedium?.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Get recipe ideas based on what you have, today\'s weather and your preferences.',
                      style: context.text.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.auto_awesome,
                color: Color(0xFFB6E4BD),
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _SmartMetric(
                  icon: Icons.shopping_basket_outlined,
                  title: 'Your ingredients',
                  value: 'Not added yet',
                ),
              ),
              Expanded(
                child: _SmartMetric(
                  icon: Icons.wb_sunny_outlined,
                  title: "Today's Weather",
                  value: weatherLabel,
                ),
              ),
              Expanded(
                child: _SmartMetric(
                  icon: Icons.favorite_border,
                  title: 'Your Preferences',
                  value: preferenceLabel,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmartMetric extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _SmartMetric({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodySmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodySmall?.copyWith(fontSize: 10),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WeatherInputCard extends StatelessWidget {
  final MealPlanWeather? weather;
  final bool isLoading;
  final String? errorMessage;

  const _WeatherInputCard({
    required this.weather,
    required this.isLoading,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    final currentWeather = weather;
    final title = isLoading
        ? 'Loading weather'
        : currentWeather == null
        ? 'Weather unavailable'
        : '${currentWeather.condition} - ${currentWeather.currentTemp}C';
    final message =
        currentWeather?.summary ??
        errorMessage ??
        'Weather data will appear here.';

    return _InputCard(
      icon: Icons.wb_sunny_outlined,
      title: 'Weather',
      trailing: Icons.keyboard_arrow_down,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.text.bodyMedium),
          const SizedBox(height: 3),
          Text(
            message,
            style: context.text.bodySmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _IngredientInputCard extends StatelessWidget {
  const _IngredientInputCard();

  @override
  Widget build(BuildContext context) {
    return _InputCard(
      icon: Icons.shopping_cart_outlined,
      title: 'Add ingredients you have ...',
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'e.g. eggs, chicken, oats, spinach ...',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodySmall?.copyWith(
                  color: AppColors.textSecondary.withValues(alpha: 0.55),
                ),
              ),
            ),
            Text(
              '+ Add',
              style: context.text.bodySmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreferenceInputCard extends StatelessWidget {
  final MealPlanPreferenceSummary? preferences;

  const _PreferenceInputCard({required this.preferences});

  @override
  Widget build(BuildContext context) {
    final mealPreference = preferences?.diet ?? 'Any';
    final allergy = preferences?.allergies.isNotEmpty == true
        ? preferences!.allergies.first
        : 'Any';
    final dislike = preferences?.dislikes.isNotEmpty == true
        ? preferences!.dislikes.first
        : 'Any';

    return _InputCard(
      icon: Icons.room_service_outlined,
      title: 'Set your preferences',
      trailing: Icons.chevron_right,
      child: Row(
        children: [
          Expanded(
            child: _PreferenceMetric(
              icon: Icons.restaurant_menu,
              title: 'Meal Pref.',
              value: mealPreference,
            ),
          ),
          Expanded(
            child: _PreferenceMetric(
              icon: Icons.warning_amber_outlined,
              title: 'Allergies',
              value: allergy,
            ),
          ),
          Expanded(
            child: _PreferenceMetric(
              icon: Icons.block,
              title: 'Dislikes',
              value: dislike,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreferenceMetric extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _PreferenceMetric({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 5),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodySmall?.copyWith(fontSize: 10),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodySmall?.copyWith(
                  color: AppColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InputCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  final IconData? trailing;

  const _InputCard({
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (trailing != null)
                      Icon(trailing, size: 20, color: AppColors.textSecondary),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickInspirationGrid extends StatelessWidget {
  final List<MealPlanQuickInspiration> items;

  const _QuickInspirationGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Image.asset('assets/images/empty_page.png', height: 140),
      );
    }

    return GridView.builder(
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.58,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
      ),
      itemBuilder: (context, index) {
        return _QuickInspirationCard(item: items[index]);
      },
    );
  }
}

class _QuickInspirationCard extends StatelessWidget {
  final MealPlanQuickInspiration item;

  const _QuickInspirationCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.24)),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              item.imagePath,
              height: 44,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            item.title,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: context.text.bodySmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              item.subtitle,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: context.text.bodySmall?.copyWith(fontSize: 9),
            ),
          ),
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: AppColors.secondary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_forward,
              color: Colors.white,
              size: 14,
            ),
          ),
        ],
      ),
    );
  }
}
