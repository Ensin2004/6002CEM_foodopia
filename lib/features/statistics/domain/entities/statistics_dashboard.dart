// These notes explain the statistics page code in simple words.
// Only comments were added here; the code behaviour stays the same.
// Domain entity for the main statistics dashboard.
// It only stores the data that the page needs to show hero cards and menus.
// Handles StatisticsDashboard for this part of the statistics page.
class StatisticsDashboard {
  final List<StatisticsHeroSlide> heroSlides;
  final List<StatisticsHeroSlide> communityHeroSlides;
  final List<StatisticsMenuItem> menuItems;
  final List<StatisticsMenuItem> communityMenuItems;

  // Handles StatisticsDashboard for this part of the statistics page.
  const StatisticsDashboard({
    required this.heroSlides,
    this.communityHeroSlides = const [],
    required this.menuItems,
    this.communityMenuItems = const [],
  });
}

// One slide/card in the top statistics carousel.
// Handles StatisticsHeroSlide for this part of the statistics page.
class StatisticsHeroSlide {
  final String title;
  final StatisticsHeroSlideType type;
  final List<StatisticsMetric> metrics;
  final StatisticsProgress? progress;

  // Handles StatisticsHeroSlide for this part of the statistics page.
  const StatisticsHeroSlide({
    required this.title,
    required this.type,
    required this.metrics,
    this.progress,
  });
}

// Handles StatisticsHeroSlideType for this part of the statistics page.
enum StatisticsHeroSlideType { overview, appUsage, achievement }

// One small number shown inside a statistics card, like total meals or top food.
class StatisticsMetric {
  final String label;
  final String value;
  final String? suffix;
  final StatisticsMetricTone tone;
  final bool isWide;

  // Handles StatisticsMetric for this part of the statistics page.
  const StatisticsMetric({
    required this.label,
    required this.value,
    this.suffix,
    this.tone = StatisticsMetricTone.neutral,
    this.isWide = false,
  });
}

// Handles StatisticsMetricTone for this part of the statistics page.
enum StatisticsMetricTone { positive, negative, neutral }

// Holds percentage values for progress-style statistics.
class StatisticsProgress {
  final double positivePercent;
  final double negativePercent;

  // Handles StatisticsProgress for this part of the statistics page.
  const StatisticsProgress({
    required this.positivePercent,
    required this.negativePercent,
  });
}

// One menu option that opens a detailed statistics report page.
// Handles StatisticsMenuItem for this part of the statistics page.
class StatisticsMenuItem {
  final String title;

  const StatisticsMenuItem({required this.title});
}
