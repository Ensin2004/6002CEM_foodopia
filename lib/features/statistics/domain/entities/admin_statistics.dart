// These notes explain the statistics page code in simple words.
// Only comments were added here; the code behaviour stays the same.
import 'package:flutter/material.dart';

import 'recipe_performance_statistics.dart';

// Handles AdminStatisticsSortOrder for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
enum AdminStatisticsSortOrder { ascending, descending }

class AdminDailyStatistic {
  final DateTime date;
  final int value;

  // Handles AdminDailyStatistic for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
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

  // Handles AdminRankedStatistic for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
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

// Handles AdminRankedStatisticDetail for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class AdminRankedStatisticDetail {
  final String title;
  final String? subtitle;
  final int quantity;
  final IconData icon;
  final String? imageUrl;

  // Handles AdminRankedStatisticDetail for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  const AdminRankedStatisticDetail({
    required this.title,
    this.subtitle,
    required this.quantity,
    required this.icon,
    this.imageUrl,
  });
}

// Handles AdminAnalyticSection for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class AdminAnalyticSection {
  final String title;
  final String summaryTitle;
  final String summaryValue;
  final String highlightTitle;
  final String highlightValue;
  final List<AdminRankedStatistic> items;

  // Handles AdminAnalyticSection for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  const AdminAnalyticSection({
    required this.title,
    required this.summaryTitle,
    required this.summaryValue,
    required this.highlightTitle,
    required this.highlightValue,
    required this.items,
  });

  // Handles sorted for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
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

// Handles AdminMealAnalyticStatistics for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class AdminMealAnalyticStatistics {
  final String dateRange;
  final List<AdminDailyStatistic> dailyPlans;
  final List<AdminAnalyticSection> sections;

  // Handles AdminMealAnalyticStatistics for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  const AdminMealAnalyticStatistics({
    required this.dateRange,
    required this.dailyPlans,
    required this.sections,
  });

  // Handles topDay for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  AdminDailyStatistic get topDay {
    final sortedDays = [...dailyPlans]
      ..sort((left, right) => right.value.compareTo(left.value));
    return sortedDays.first;
  }

  // Handles leastDay for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  AdminDailyStatistic get leastDay {
    final sortedDays = [...dailyPlans]
      ..sort((left, right) => left.value.compareTo(right.value));
    return sortedDays.first;
  }
}

// Handles AdminPostAnalyticStatistics for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class AdminPostAnalyticStatistics {
  final String dateRange;
  final List<AdminDailyStatistic> dailyPosts;
  final List<AdminAnalyticSection> sections;
  final RecipePerformanceStatistics? recipePerformance;

  // Handles AdminPostAnalyticStatistics for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  const AdminPostAnalyticStatistics({
    required this.dateRange,
    required this.dailyPosts,
    required this.sections,
    this.recipePerformance,
  });

  // Handles topDay for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  AdminDailyStatistic get topDay {
    final sortedDays = [...dailyPosts]
      ..sort((left, right) => right.value.compareTo(left.value));
    return sortedDays.first;
  }

  // Handles leastDay for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  AdminDailyStatistic get leastDay {
    final sortedDays = [...dailyPosts]
      ..sort((left, right) => left.value.compareTo(right.value));
    return sortedDays.first;
  }
}

// Handles AdminDietaryPreferenceStatistics for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class AdminDietaryPreferenceStatistics {
  final String dateRange;
  final int totalUsers;
  final String topPreference;
  final List<AdminRankedStatistic> preferences;

  // Handles AdminDietaryPreferenceStatistics for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  const AdminDietaryPreferenceStatistics({
    required this.dateRange,
    required this.totalUsers,
    required this.topPreference,
    required this.preferences,
  });
}

// Handles AdminGenderStatistics for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class AdminGenderStatistics {
  final String dateRange;
  final int totalUsers;
  final String mostGender;
  final List<AdminRankedStatistic> genders;

  // Handles AdminGenderStatistics for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  const AdminGenderStatistics({
    required this.dateRange,
    required this.totalUsers,
    required this.mostGender,
    required this.genders,
  });
}

// Handles AdminUserUsageStatistics for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class AdminUserUsageStatistics {
  final String dateRange;
  final int totalUsers;
  final String topMonth;
  final List<AdminMonthlyUserStatistic> monthlyUsers;

  // Handles AdminUserUsageStatistics for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  const AdminUserUsageStatistics({
    required this.dateRange,
    required this.totalUsers,
    required this.topMonth,
    required this.monthlyUsers,
  });
}

// Handles AdminHubRatingStatistics for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class AdminHubRatingStatistics {
  final String dateRange;
  final int totalRatings;
  final double averageRating;
  final List<AdminMonthlyRatingStatistic> monthlyRatings;

  // Handles AdminHubRatingStatistics for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  const AdminHubRatingStatistics({
    required this.dateRange,
    required this.totalRatings,
    required this.averageRating,
    required this.monthlyRatings,
  });
}

// Handles AdminMonthlyUserStatistic for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class AdminMonthlyUserStatistic {
  final DateTime month;
  final int newUsers;
  final bool isPrediction;

  // Handles AdminMonthlyUserStatistic for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  const AdminMonthlyUserStatistic({
    required this.month,
    required this.newUsers,
    this.isPrediction = false,
  });
}

// Handles AdminMonthlyRatingStatistic for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class AdminMonthlyRatingStatistic {
  final DateTime month;
  final int ratingCount;
  final double averageRating;

  // Handles AdminMonthlyRatingStatistic for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  const AdminMonthlyRatingStatistic({
    required this.month,
    required this.ratingCount,
    required this.averageRating,
  });
}
