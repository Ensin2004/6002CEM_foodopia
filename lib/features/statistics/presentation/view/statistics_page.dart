// These notes explain the statistics page code in simple words.
// Only comments were added here; the code behaviour stays the same.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/dependency_injection/injection_container.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../domain/usecases/get_statistics_dashboard_usecase.dart';
import '../viewmodel/statistics_viewmodel.dart';
import '../widgets/statistics_page_helpers.dart';
import 'admin_statistics_view.dart';
import 'user_statistics_view.dart';

/// Main entry page for statistics.
///
/// This page creates the shared dashboard ViewModel, then chooses the user or
/// admin layout based on [isAdmin].
// Handles StatisticsPage for this part of the statistics page.
class StatisticsPage extends StatelessWidget {
  final bool isAdmin;
  final bool showAppBar;

  // Handles StatisticsPage for this part of the statistics page.
  const StatisticsPage({
    super.key,
    required this.isAdmin,
    this.showAppBar = true,
  });

  @override
  // Build the statistics page with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
  // Handles build for this part of the statistics page.
  Widget build(BuildContext context) {
    // Keep the ViewModel above both layouts so every dashboard widget can read
    // the same loading state, data, and selected tab.
    return ChangeNotifierProvider(
      create: (_) => StatisticsViewModel(
        isAdmin: isAdmin,
        getDashboardUseCase: sl<GetStatisticsDashboardUseCase>(),
      ),
      // Some parent pages already have an app bar, so they can hide this one.
      child: showAppBar
          ? Scaffold(
              resizeToAvoidBottomInset: true,
              appBar: const CustomAppBar(
                title: 'Statistic',
                leading: StatisticsBackButton(),
              ),
              body: isAdmin
                  ? const AdminStatisticsView()
                  : UserStatisticsView(isAdmin: isAdmin),
            )
          : isAdmin
          ? const AdminStatisticsView()
          : UserStatisticsView(isAdmin: isAdmin),
    );
  }
}
