import '../../domain/entities/admin_home_dashboard.dart';

/// Model class for admin home dashboard data.
/// Extends the domain entity with additional serialization capabilities.
class AdminHomeDashboardModel extends AdminHomeDashboard {
  /// Creates a new admin home dashboard model instance.
  const AdminHomeDashboardModel({
    required super.adminName,
    required super.metrics,
    required super.quickAccessItems,
    required super.pendingReviews,
    required super.feedbackItems,
  });
}