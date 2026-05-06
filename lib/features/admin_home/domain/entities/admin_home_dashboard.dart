import 'package:flutter/material.dart';

class AdminHomeDashboard {
  final String adminName;
  final List<AdminMetric> metrics;
  final List<AdminQuickAccessItem> quickAccessItems;
  final List<AdminPendingReview> pendingReviews;
  final List<AdminFeedbackItem> feedbackItems;

  const AdminHomeDashboard({
    required this.adminName,
    required this.metrics,
    required this.quickAccessItems,
    required this.pendingReviews,
    required this.feedbackItems,
  });
}

class AdminMetric {
  final String title;
  final String value;
  final String change;
  final String note;
  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;

  const AdminMetric({
    required this.title,
    required this.value,
    required this.change,
    required this.note,
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
  });
}

class AdminQuickAccessItem {
  final String title;
  final String description;
  final IconData icon;

  const AdminQuickAccessItem({
    required this.title,
    required this.description,
    required this.icon,
  });
}

class AdminPendingReview {
  final String initials;
  final String userName;
  final String title;
  final String timeAgo;
  final String badge;

  const AdminPendingReview({
    required this.initials,
    required this.userName,
    required this.title,
    required this.timeAgo,
    required this.badge,
  });
}

class AdminFeedbackItem {
  final String initials;
  final String userName;
  final double rating;
  final String comment;
  final String timeAgo;

  const AdminFeedbackItem({
    required this.initials,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.timeAgo,
  });
}
