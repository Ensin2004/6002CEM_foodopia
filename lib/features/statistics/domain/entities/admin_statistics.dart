import 'package:flutter/material.dart';

enum AdminStatisticsSortOrder { ascending, descending }

class AdminDailyStatistic {
  final DateTime date;
  final int value;

  const AdminDailyStatistic({required this.date, required this.value});
}

class AdminRankedStatistic {
  final String label;
  final int value;
  final double percent;
  final IconData icon;
  final Color color;

  const AdminRankedStatistic({
    required this.label,
    required this.value,
    required this.percent,
    required this.icon,
    required this.color,
  });
}

class AdminAnalyticSection {
  final String title;
  final String summaryTitle;
  final String summaryValue;
  final String highlightTitle;
  final String highlightValue;
  final List<AdminRankedStatistic> items;

  const AdminAnalyticSection({
    required this.title,
    required this.summaryTitle,
    required this.summaryValue,
    required this.highlightTitle,
    required this.highlightValue,
    required this.items,
  });

  AdminAnalyticSection sorted(AdminStatisticsSortOrder order) {
    final sortedItems = [...items]
      ..sort(
        (left, right) => order == AdminStatisticsSortOrder.descending
            ? right.value.compareTo(left.value)
            : left.value.compareTo(right.value),
      );

    return AdminAnalyticSection(
      title: title,
      summaryTitle: summaryTitle,
      summaryValue: summaryValue,
      highlightTitle: highlightTitle,
      highlightValue: highlightValue,
      items: sortedItems,
    );
  }
}

class AdminMealAnalyticStatistics {
  final String dateRange;
  final List<AdminDailyStatistic> dailyPlans;
  final List<AdminAnalyticSection> sections;

  const AdminMealAnalyticStatistics({
    required this.dateRange,
    required this.dailyPlans,
    required this.sections,
  });

  AdminDailyStatistic get topDay {
    final sortedDays = [...dailyPlans]
      ..sort((left, right) => right.value.compareTo(left.value));
    return sortedDays.first;
  }

  AdminDailyStatistic get leastDay {
    final sortedDays = [...dailyPlans]
      ..sort((left, right) => left.value.compareTo(right.value));
    return sortedDays.first;
  }
}

class AdminPostAnalyticStatistics {
  final String dateRange;
  final List<AdminDailyStatistic> dailyPosts;
  final List<AdminAnalyticSection> sections;

  const AdminPostAnalyticStatistics({
    required this.dateRange,
    required this.dailyPosts,
    required this.sections,
  });

  AdminDailyStatistic get topDay {
    final sortedDays = [...dailyPosts]
      ..sort((left, right) => right.value.compareTo(left.value));
    return sortedDays.first;
  }

  AdminDailyStatistic get leastDay {
    final sortedDays = [...dailyPosts]
      ..sort((left, right) => left.value.compareTo(right.value));
    return sortedDays.first;
  }
}

class AdminDietaryPreferenceStatistics {
  final String dateRange;
  final int totalUsers;
  final String topPreference;
  final List<AdminRankedStatistic> preferences;

  const AdminDietaryPreferenceStatistics({
    required this.dateRange,
    required this.totalUsers,
    required this.topPreference,
    required this.preferences,
  });
}
