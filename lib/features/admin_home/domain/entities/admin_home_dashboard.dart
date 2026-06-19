import 'package:flutter/material.dart';

/// Main dashboard entity for the admin home screen.
/// Contains metrics, quick access, pending reviews, and feedback items.
class AdminHomeDashboard {
  /// Display name of the admin user.
  final String adminName;

  /// List of metrics displayed on the dashboard.
  final List<AdminMetric> metrics;

  /// List of quick access items for navigation.
  final List<AdminQuickAccessItem> quickAccessItems;

  /// List of pending reviews requiring admin attention.
  final List<AdminPendingReview> pendingReviews;

  /// List of user feedback items.
  final List<AdminFeedbackItem> feedbackItems;

  /// Creates a new admin home dashboard instance.
  const AdminHomeDashboard({
    required this.adminName,
    required this.metrics,
    required this.quickAccessItems,
    required this.pendingReviews,
    required this.feedbackItems,
  });
}

/// Metric item for the admin dashboard.
/// Displays a key performance indicator with change indicator.
class AdminMetric {
  /// Title of the metric (e.g., "New Users").
  final String title;

  /// Current value of the metric.
  final String value;

  /// Percentage change compared to previous period.
  final String change;

  /// Additional note about the change period.
  final String note;

  /// Icon to display for the metric.
  final IconData icon;

  /// Color of the icon.
  final Color iconColor;

  /// Background color of the icon container.
  final Color iconBackgroundColor;

  /// Creates a new admin metric instance.
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

/// Quick access item for the admin dashboard.
/// Represents a navigation shortcut.
class AdminQuickAccessItem {
  /// Display title of the quick access item.
  final String title;

  /// Description subtitle of the quick access item.
  final String description;

  /// Icon to display for the quick access item.
  final IconData icon;

  /// Creates a new admin quick access item instance.
  const AdminQuickAccessItem({
    required this.title,
    required this.description,
    required this.icon,
  });
}

/// Pending review item for the admin dashboard.
/// Represents a help ticket or review awaiting admin response.
class AdminPendingReview {
  /// User initials for avatar display.
  final String initials;

  /// Display name of the user.
  final String userName;

  /// Title or summary of the review.
  final String title;

  /// Time ago the review was submitted.
  final String timeAgo;

  /// Status badge (e.g., "New", "Open").
  final String badge;

  /// Creates a new admin pending review instance.
  const AdminPendingReview({
    required this.initials,
    required this.userName,
    required this.title,
    required this.timeAgo,
    required this.badge,
  });
}

/// Feedback item for the admin dashboard.
/// Represents user feedback with rating and comment.
class AdminFeedbackItem {
  /// User initials for avatar display.
  final String initials;

  /// Display name of the user.
  final String userName;

  /// Star rating given by the user.
  final double rating;

  /// Comment text from the user.
  final String comment;

  /// Time ago the feedback was submitted.
  final String timeAgo;

  /// Creates a new admin feedback item instance.
  const AdminFeedbackItem({
    required this.initials,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.timeAgo,
  });
}