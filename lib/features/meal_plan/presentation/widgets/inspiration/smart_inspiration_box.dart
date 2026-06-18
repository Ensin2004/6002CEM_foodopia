part of 'inspiration_tab_main_view.dart';

/// Smart summary widgets for the Inspiration tab.
///
/// Weather, preferences, and ingredient context are summarized before input cards.
/// Smart inspiration box widget.
class _SmartInspirationBox extends StatelessWidget {
  /// Weather data.
  final MealPlanWeather? weather;

  /// User preferences.
  final MealPlanPreferenceSummary? preferences;

  /// Ingredients label.
  final String ingredientsLabel;

  /// Whether weather is loading.
  final bool isWeatherLoading;

  /// Whether preferences are loading.
  final bool isPreferencesLoading;

  /// Creates a new smart inspiration box instance.
  const _SmartInspirationBox({
    required this.weather,
    required this.preferences,
    required this.ingredientsLabel,
    required this.isWeatherLoading,
    required this.isPreferencesLoading,
  });

  @override
  Widget build(BuildContext context) {
    // Get current weather and preference labels.
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
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top indicator bar.
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 56,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Header row.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.tips_and_updates_outlined,
                  color: Color(0xFF8A6400),
                  size: 23,
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
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Get recipe ideas based on what you have, today\'s weather and your preferences.',
                      style: context.text.bodySmall?.copyWith(height: 1.35),
                    ),
                  ],
                ),
              ),
              _SmartChip(),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Metrics.
          Column(
            children: [
              _SmartMetric(
                icon: Icons.shopping_basket_outlined,
                title: 'Ingredients',
                value: ingredientsLabel,
              ),
              const SizedBox(height: AppSpacing.xs),
              _SmartMetric(
                icon: Icons.wb_sunny_outlined,
                title: 'Weather',
                value: weatherLabel,
              ),
              const SizedBox(height: AppSpacing.xs),
              _SmartMetric(
                icon: Icons.favorite_border,
                title: 'Preferences',
                value: preferenceLabel,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Smart chip widget.
class _SmartChip extends StatelessWidget {
  /// Creates a new smart chip instance.
  const _SmartChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, color: Color(0xFF8A6400), size: 14),
          const SizedBox(width: 4),
          Text(
            'Smart',
            style: context.text.bodySmall?.copyWith(
              color: const Color(0xFF8A6400),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Smart metric widget.
class _SmartMetric extends StatelessWidget {
  /// Icon to display.
  final IconData icon;

  /// Title text.
  final String title;

  /// Value text.
  final String value;

  /// Creates a new smart metric instance.
  const _SmartMetric({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.75)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.bodySmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: context.text.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
