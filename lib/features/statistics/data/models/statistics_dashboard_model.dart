// These notes explain the statistics page code in simple words.
// Only comments were added here; the code behaviour stays the same.
import '../../domain/entities/statistics_dashboard.dart';

// Handles StatisticsDashboardModel for this part of the statistics page.
class StatisticsDashboardModel extends StatisticsDashboard {
  const StatisticsDashboardModel({
    required super.heroSlides,
    super.communityHeroSlides,
    required super.menuItems,
    super.communityMenuItems,
  });
}
