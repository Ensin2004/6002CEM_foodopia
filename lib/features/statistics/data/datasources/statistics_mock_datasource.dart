import '../models/statistics_dashboard_model.dart';
import '../../domain/entities/statistics_dashboard.dart';

class StatisticsMockDataSource {
  Future<StatisticsDashboardModel> getUserStatistics() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));

    return const StatisticsDashboardModel(
      heroSlides: [
        StatisticsHeroSlide(
          title: 'Overall Meals',
          type: StatisticsHeroSlideType.overview,
          metrics: [
            StatisticsMetric(
              label: 'Planned Meal',
              value: '50',
              tone: StatisticsMetricTone.positive,
            ),
            StatisticsMetric(
              label: 'Unplanned Meal',
              value: '2',
              tone: StatisticsMetricTone.negative,
            ),
            StatisticsMetric(
              label: 'Planned Meals',
              value: '12',
              suffix: 'Days',
              tone: StatisticsMetricTone.neutral,
            ),
            StatisticsMetric(
              label: 'Unplanned Meals',
              value: '2',
              suffix: 'Days',
              tone: StatisticsMetricTone.neutral,
            ),
          ],
        ),
        StatisticsHeroSlide(
          title: 'Days Using This App',
          type: StatisticsHeroSlideType.appUsage,
          metrics: [
            StatisticsMetric(label: 'Days', value: '40'),
            StatisticsMetric(
              label: 'Day with Planned Meals',
              value: '35',
              tone: StatisticsMetricTone.positive,
            ),
            StatisticsMetric(
              label: 'Unplanned Meals',
              value: '5',
              tone: StatisticsMetricTone.negative,
            ),
          ],
          progress: StatisticsProgress(
            positivePercent: 0.8,
            negativePercent: 0.2,
          ),
        ),
        StatisticsHeroSlide(
          title: 'Achievement',
          type: StatisticsHeroSlideType.achievement,
          metrics: [
            StatisticsMetric(label: 'Total Dish', value: '50'),
            StatisticsMetric(label: 'Different Category', value: '5'),
            StatisticsMetric(label: 'Difficulty Dishes', value: '4.1'),
            StatisticsMetric(
              label: 'Cooking Time',
              value: '9',
              suffix: 'Hrs 30 Min',
              isWide: true,
            ),
          ],
        ),
      ],
      menuItems: [
        StatisticsMenuItem(title: 'Food Analytic'),
        StatisticsMenuItem(title: 'Time Taken For Cooking'),
        StatisticsMenuItem(title: 'Category Intake'),
        StatisticsMenuItem(title: 'Meal Planned Time'),
        StatisticsMenuItem(title: 'Method For Creating Plan'),
        StatisticsMenuItem(title: 'Difficulty'),
      ],
    );
  }

  Future<StatisticsDashboardModel> getAdminStatistics() => getUserStatistics();
}
