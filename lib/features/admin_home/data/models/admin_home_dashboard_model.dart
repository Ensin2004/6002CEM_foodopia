import 'package:flutter/material.dart';

import '../../domain/entities/admin_home_dashboard.dart';

class AdminHomeDashboardModel extends AdminHomeDashboard {
  const AdminHomeDashboardModel({
    required super.adminName,
    required super.metrics,
    required super.quickAccessItems,
    required super.pendingReviews,
    required super.feedbackItems,
  });

  factory AdminHomeDashboardModel.mock(String adminName) {
    return AdminHomeDashboardModel(
      adminName: adminName,
      metrics: const [
        AdminMetric(
          title: 'New Users',
          value: '1,250',
          change: '+18%',
          note: 'vs last 7 days',
          icon: Icons.group,
          iconColor: Color(0xFF10A84E),
          iconBackgroundColor: Color(0xFFEAF8EF),
        ),
        AdminMetric(
          title: 'New Recipes',
          value: '342',
          change: '+12%',
          note: 'vs last 7 days',
          icon: Icons.description,
          iconColor: Color(0xFF42A5F5),
          iconBackgroundColor: Color(0xFFE6F4FF),
        ),
        AdminMetric(
          title: 'Feedbacks',
          value: '86',
          change: '+8%',
          note: 'vs last 7 days',
          icon: Icons.chat_bubble_outline,
          iconColor: Color(0xFFFFA726),
          iconBackgroundColor: Color(0xFFFFF3E0),
        ),
        AdminMetric(
          title: 'Avg. Rating',
          value: '4.8',
          change: '+0.3',
          note: 'vs last 7 days',
          icon: Icons.star,
          iconColor: Color(0xFFB15CFF),
          iconBackgroundColor: Color(0xFFF3E8FF),
        ),
      ],
      quickAccessItems: const [
        AdminQuickAccessItem(
          title: 'Manage Content',
          description: 'Recipes, Categories',
          icon: Icons.article,
        ),
        AdminQuickAccessItem(
          title: 'View Stats',
          description: 'Analytics & Reports',
          icon: Icons.bar_chart,
        ),
        AdminQuickAccessItem(
          title: 'Manage Feedback',
          description: 'Reviews & Reports',
          icon: Icons.chat,
        ),
        AdminQuickAccessItem(
          title: 'Settings',
          description: 'App & System Settings',
          icon: Icons.settings,
        ),
      ],
      pendingReviews: const [
        AdminPendingReview(
          initials: 'JT',
          userName: 'Jeff Tan',
          title: 'Account Problem',
          timeAgo: '2 hours ago',
          badge: 'New',
        ),
        AdminPendingReview(
          initials: 'SC',
          userName: 'ShinChan',
          title: 'Having problem when login',
          timeAgo: '5 hours ago',
          badge: 'New',
        ),
      ],
      feedbackItems: const [
        AdminFeedbackItem(
          initials: 'JL',
          userName: 'Jhon Lau',
          rating: 4,
          comment: 'Best app ever',
          timeAgo: '1 day ago',
        ),
        AdminFeedbackItem(
          initials: 'GW',
          userName: 'Grace Wong',
          rating: 5,
          comment: 'Cover a lot functions and easy to use!',
          timeAgo: '2 days ago',
        ),
      ],
    );
  }
}
