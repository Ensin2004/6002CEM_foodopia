class StatisticsDashboard {
  final List<StatisticsHeroSlide> heroSlides;
  final List<StatisticsMenuItem> menuItems;

  const StatisticsDashboard({
    required this.heroSlides,
    required this.menuItems,
  });
}

class StatisticsHeroSlide {
  final String title;
  final StatisticsHeroSlideType type;
  final List<StatisticsMetric> metrics;
  final StatisticsProgress? progress;

  const StatisticsHeroSlide({
    required this.title,
    required this.type,
    required this.metrics,
    this.progress,
  });
}

enum StatisticsHeroSlideType { overview, appUsage, achievement }

class StatisticsMetric {
  final String label;
  final String value;
  final String? suffix;
  final StatisticsMetricTone tone;
  final bool isWide;

  const StatisticsMetric({
    required this.label,
    required this.value,
    this.suffix,
    this.tone = StatisticsMetricTone.neutral,
    this.isWide = false,
  });
}

enum StatisticsMetricTone { positive, negative, neutral }

class StatisticsProgress {
  final double positivePercent;
  final double negativePercent;

  const StatisticsProgress({
    required this.positivePercent,
    required this.negativePercent,
  });
}

class StatisticsMenuItem {
  final String title;

  const StatisticsMenuItem({required this.title});
}
