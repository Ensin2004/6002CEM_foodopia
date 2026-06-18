import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../domain/entities/user_home_dashboard.dart';

/// Hero section for the user home page.
/// Displays user greeting, name, and weather information.
class UserHomeHero extends StatelessWidget {
  /// The user home dashboard data.
  final UserHomeDashboard dashboard;

  /// Whether weather data is loading.
  final bool isWeatherLoading;

  /// Error message from weather loading.
  final String? weatherErrorMessage;

  /// Creates a new user home hero instance.
  const UserHomeHero({
    super.key,
    required this.dashboard,
    required this.isWeatherLoading,
    this.weatherErrorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Background image.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Image.asset(
            'assets/images/home.png',
            alignment: Alignment.topCenter,
          ),
        ),
        // Content overlay.
        Padding(
          padding: AppSpacing.pagePadding.copyWith(top: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting.
              Text(
                '${dashboard.greeting},',
                style: context.text.bodyMedium?.copyWith(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),

              // User name.
              Text(
                dashboard.userName,
                style: context.text.headlineSmall?.copyWith(
                  color: context.colors.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),

              // Motivational subtitle.
              Text(
                "Let's make today a healthy one!",
                style: context.text.bodySmall?.copyWith(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Weather card.
              _WeatherCard(
                weather: dashboard.weather,
                isLoading: isWeatherLoading,
                errorMessage: weatherErrorMessage,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Weather card widget.
class _WeatherCard extends StatelessWidget {
  /// Weather data.
  final UserHomeWeather? weather;

  /// Whether weather is loading.
  final bool isLoading;

  /// Error message.
  final String? errorMessage;

  /// Creates a new weather card instance.
  const _WeatherCard({
    required this.weather,
    required this.isLoading,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: _buildContent(context),
    );
  }

  /// Builds the content based on state.
  Widget _buildContent(BuildContext context) {
    // Show loading state.
    if (isLoading) {
      return const SizedBox(
        height: 110,
        child: LoadingDialog(message: 'Loading weather...', inline: true),
      );
    }

    // Show error state.
    final message = errorMessage;
    if (message != null && message.isNotEmpty) {
      return SizedBox(
        height: 110,
        child: Center(
          child: Text(
            'Weather failed to load.\n$message',
            textAlign: TextAlign.center,
            style: context.text.bodySmall?.copyWith(
              color: context.colors.error,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    // Show empty state.
    final weatherData = weather;
    if (weatherData == null) {
      return SizedBox(
        height: 110,
        child: Center(
          child: Text(
            'Weather is unavailable.',
            textAlign: TextAlign.center,
            style: context.text.bodySmall?.copyWith(
              color: context.colors.error,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    // Show weather data.
    return Column(
      children: [
        // Main weather row.
        Row(
          children: [
            _WeatherIcon(condition: weatherData.condition),
            const SizedBox(width: AppSpacing.md),

            // Temperature and condition.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${weatherData.currentTemp}\u00B0C',
                    style: context.text.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    weatherData.condition,
                    style: context.text.bodySmall?.copyWith(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Summary.
            Expanded(
              child: Text(
                '${weatherData.summary}\nGreat day for something fresh and cool.',
                style: context.text.bodySmall?.copyWith(
                  height: 1.35,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Weather metrics row.
        Row(
          children: [
            Expanded(
              child: _WeatherMetric(
                icon: Icons.water_drop_outlined,
                label: 'Humidity',
                value: '${weatherData.humidity}%',
              ),
            ),
            Expanded(
              child: _WeatherMetric(
                icon: Icons.air,
                label: 'Wind',
                value: '${weatherData.windSpeed} km/h',
              ),
            ),
            Expanded(
              child: _WeatherMetric(
                icon: Icons.wb_sunny_outlined,
                label: 'UV Index',
                value: weatherData.uvIndex,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Weather icon widget.
class _WeatherIcon extends StatelessWidget {
  /// Weather condition string.
  final String condition;

  /// Creates a new weather icon instance.
  const _WeatherIcon({required this.condition});

  @override
  Widget build(BuildContext context) {
    // Normalize the condition string.
    final normalized = condition.toLowerCase();

    // Determine the icon based on condition.
    final icon = normalized.contains('rain')
        ? Icons.umbrella_outlined
        : normalized.contains('cloud')
        ? Icons.cloud_queue
        : Icons.wb_sunny_outlined;

    return Container(
      width: 58,
      height: 58,
      decoration: const BoxDecoration(
        color: Color(0xFFEAF5FF),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: const Color(0xFFFFB300), size: 34),
    );
  }
}

/// Weather metric widget.
class _WeatherMetric extends StatelessWidget {
  /// Icon to display.
  final IconData icon;

  /// Label text.
  final String label;

  /// Value text.
  final String value;

  /// Creates a new weather metric instance.
  const _WeatherMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: Colors.lightBlue.shade400),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.labelSmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.labelSmall?.copyWith(
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