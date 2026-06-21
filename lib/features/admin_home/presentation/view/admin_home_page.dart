import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/dependency_injection/injection_container.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../domain/entities/admin_home_dashboard.dart';
import '../../domain/usecases/get_admin_home_dashboard_usecase.dart';
import '../viewmodel/admin_home_viewmodel.dart';
import '../widgets/admin_feedback_card.dart';
import '../widgets/admin_home_stat_card.dart';
import '../widgets/admin_quick_access_card.dart';
import '../widgets/admin_review_card.dart';

/// Admin home page for the application.
/// Displays dashboard with metrics, quick access, and pending items.
class AdminHomePage extends StatelessWidget {
  /// Name of the admin user.
  final String adminName;

  /// Called when a quick access item is tapped.
  final ValueChanged<AdminQuickAccessItem>? onQuickAccessTap;

  /// Called when pending reviews "View All" is tapped.
  final VoidCallback? onViewAllPendingReviews;

  /// Called when feedback "View All" is tapped.
  final VoidCallback? onViewAllFeedback;

  /// Creates a new admin home page instance.
  const AdminHomePage({
    super.key,
    required this.adminName,
    this.onQuickAccessTap,
    this.onViewAllPendingReviews,
    this.onViewAllFeedback,
  });

  @override
  Widget build(BuildContext context) {
    // Provide the view model to the widget tree.
    return ChangeNotifierProvider(
      create: (_) => AdminHomeViewModel(
        adminName: adminName,
        getDashboardUseCase: sl<GetAdminHomeDashboardUseCase>(),
      ),
      child: _AdminHomeView(
        onQuickAccessTap: onQuickAccessTap,
        onViewAllPendingReviews: onViewAllPendingReviews,
        onViewAllFeedback: onViewAllFeedback,
      ),
    );
  }
}

/// Internal view for the admin home page.
class _AdminHomeView extends StatelessWidget {
  /// Called when a quick access item is tapped.
  final ValueChanged<AdminQuickAccessItem>? onQuickAccessTap;

  /// Called when pending reviews "View All" is tapped.
  final VoidCallback? onViewAllPendingReviews;

  /// Called when feedback "View All" is tapped.
  final VoidCallback? onViewAllFeedback;

  /// Creates a new admin home view instance.
  const _AdminHomeView({
    this.onQuickAccessTap,
    this.onViewAllPendingReviews,
    this.onViewAllFeedback,
  });

  @override
  Widget build(BuildContext context) {
    // Watch the view model for state changes.
    final viewModel = context.watch<AdminHomeViewModel>();

    // Show loading indicator.
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Get the dashboard.
    final dashboard = viewModel.dashboard;

    // Show error state if dashboard is null.
    if (dashboard == null) {
      return Center(
        child: Text(
          viewModel.errorMessage ?? 'Unable to load dashboard',
          style: context.text.bodyMedium,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: viewModel.loadDashboard,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Hero section with stats.
          _HeroStatsSection(dashboard: dashboard),
          const SizedBox(height: AppSpacing.lg),

          // Quick access section.
          _Section(
            title: 'Quick Access',
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: dashboard.quickAccessItems.map((item) {
                  final isLast = item == dashboard.quickAccessItems.last;

                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: isLast ? 0 : AppSpacing.sm,
                      ),
                      child: AdminQuickAccessCard(
                        item: item,
                        onTap: () => onQuickAccessTap?.call(item),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Pending review section.
          _Section(
            title: 'Pending Review',
            actionLabel: 'View All',
            onActionTap: onViewAllPendingReviews,
            child: Row(
              children: dashboard.pendingReviews
                  .map(
                    (review) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: AdminReviewCard(review: review),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

          // Rating and feedback section.
          _Section(
            title: 'Rating & Feedback',
            actionLabel: 'View All',
            onActionTap: onViewAllFeedback,
            child: Row(
              children: dashboard.feedbackItems
                  .map(
                    (feedback) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: AdminFeedbackCard(feedback: feedback),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

/// Hero stats section with admin greeting and metric cards.
class _HeroStatsSection extends StatelessWidget {
  /// The admin home dashboard data.
  final AdminHomeDashboard dashboard;

  /// Creates a new hero stats section instance.
  const _HeroStatsSection({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background image.
        Image.asset(
          'assets/images/home.png',
          height: 220,
          width: double.infinity,
          fit: BoxFit.cover,
        ),

        // Content overlay.
        Padding(
          padding: AppSpacing.pagePadding.copyWith(top: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting.
              RichText(
                text: TextSpan(
                  style: context.text.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  children: [
                    const TextSpan(text: 'Hello, '),
                    TextSpan(
                      text: dashboard.adminName,
                      style: TextStyle(color: context.colors.primary),
                    ),
                    const TextSpan(text: ' 👋'),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              // Subtitle.
              Text(
                "Welcome back! Here's an overview\nof Foodopia today.",
                style: context.text.bodyMedium?.copyWith(height: 1.35),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Metrics cards.
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: List.generate(dashboard.metrics.length, (index) {
                      final isLast = index == dashboard.metrics.length - 1;

                      return Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: AdminHomeStatCard(
                                metric: dashboard.metrics[index],
                              ),
                            ),

                            // Divider between metrics.
                            if (!isLast)
                              VerticalDivider(
                                width: 1,
                                thickness: 1,
                                color: Colors.grey.shade200,
                              ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Section widget with title and content.
class _Section extends StatelessWidget {
  /// Section title.
  final String title;

  /// Action label (e.g., "View All").
  final String? actionLabel;

  /// Called when the action label is tapped.
  final VoidCallback? onActionTap;

  /// Child content.
  final Widget child;

  /// Creates a new section instance.
  const _Section({
    required this.title,
    required this.child,
    this.actionLabel,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.pagePadding.copyWith(
        top: AppSpacing.sm,
        bottom: AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with title and action.
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: context.text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (actionLabel != null)
                TextButton(
                  onPressed: onActionTap,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(48, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    alignment: Alignment.centerRight,
                  ),
                  child: Text(
                    actionLabel!,
                    style: context.text.titleMedium?.copyWith(
                      color: context.colors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Child content.
          child,
        ],
      ),
    );
  }
}
