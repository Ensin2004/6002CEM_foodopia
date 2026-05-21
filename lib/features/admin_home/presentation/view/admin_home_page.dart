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

class AdminHomePage extends StatelessWidget {
  final String adminName;

  const AdminHomePage({super.key, required this.adminName});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminHomeViewModel(
        adminName: adminName,
        getDashboardUseCase: sl<GetAdminHomeDashboardUseCase>(),
      ),
      child: const _AdminHomeView(),
    );
  }
}

class _AdminHomeView extends StatelessWidget {
  const _AdminHomeView();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminHomeViewModel>();

    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final dashboard = viewModel.dashboard;
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
          _HeroStatsSection(dashboard: dashboard),
          const SizedBox(height: AppSpacing.lg),
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
                      child: AdminQuickAccessCard(item: item),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          _Section(
            title: 'Pending Review',
            actionLabel: 'View All',
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
          _Section(
            title: 'Rating & Feedback',
            actionLabel: 'View All',
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

class _HeroStatsSection extends StatelessWidget {
  final AdminHomeDashboard dashboard;

  const _HeroStatsSection({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Image.asset(
          'assets/images/home.png',
          height: 220,
          width: double.infinity,
          fit: BoxFit.cover,
        ),

        Padding(
          padding: AppSpacing.pagePadding.copyWith(
            top: AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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

              Text(
                "Welcome back! Here's an overview\nof Foodopia today.",
                style: context.text.bodyMedium?.copyWith(height: 1.35),
              ),

              const SizedBox(height: AppSpacing.lg),

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

class _Section extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final Widget child;

  const _Section({required this.title, required this.child, this.actionLabel});

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
                Text(
                  actionLabel!,
                  style: context.text.titleMedium?.copyWith(
                    color: context.colors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}
