import 'package:flutter/material.dart';

import 'recipe_performance_statistics.dart';

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
  final String? imageUrl;
  final String? markerText;
  final List<AdminRankedStatisticDetail> details;

  const AdminRankedStatistic({
    required this.label,
    required this.value,
    required this.percent,
    required this.icon,
    required this.color,
    this.imageUrl,
    this.markerText,
    this.details = const [],
  });
}

class AdminRankedStatisticDetail {
  final String title;
  final String? subtitle;
  final int quantity;
  final IconData icon;
  final String? imageUrl;

  const AdminRankedStatisticDetail({
    required this.title,
    this.subtitle,
    required this.quantity,
    required this.icon,
    this.imageUrl,
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
  final RecipePerformanceStatistics? recipePerformance;

  const AdminPostAnalyticStatistics({
    required this.dateRange,
    required this.dailyPosts,
    required this.sections,
    this.recipePerformance,
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

class AdminGenderStatistics {
  final String dateRange;
  final int totalUsers;
  final String mostGender;
  final List<AdminRankedStatistic> genders;

  const AdminGenderStatistics({
    required this.dateRange,
    required this.totalUsers,
    required this.mostGender,
    required this.genders,
  });
}

class AdminUserUsageStatistics {
  final String dateRange;
  final int totalUsers;
  final String topMonth;
  final List<AdminMonthlyUserStatistic> monthlyUsers;

  const AdminUserUsageStatistics({
    required this.dateRange,
    required this.totalUsers,
    required this.topMonth,
    required this.monthlyUsers,
  });
}

class AdminHubRatingStatistics {
  final String dateRange;
  final int totalRatings;
  final double averageRating;
  final List<AdminMonthlyRatingStatistic> monthlyRatings;

  const AdminHubRatingStatistics({
    required this.dateRange,
    required this.totalRatings,
    required this.averageRating,
    required this.monthlyRatings,
  });
}

class AdminMonthlyUserStatistic {
  final DateTime month;
  final int newUsers;

  const AdminMonthlyUserStatistic({
    required this.month,
    required this.newUsers,
  });
}

class AdminMonthlyRatingStatistic {
  final DateTime month;
  final int ratingCount;
  final double averageRating;

  const AdminMonthlyRatingStatistic({
    required this.month,
    required this.ratingCount,
    required this.averageRating,
  });
}
