import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/dependency_injection/injection_container.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../domain/usecases/get_statistics_dashboard_usecase.dart';
import '../viewmodel/statistics_viewmodel.dart';
import '../widgets/statistics_page_helpers.dart';
import 'admin_statistics_view.dart';
import 'user_statistics_view.dart';

class StatisticsPage extends StatelessWidget {
  final bool isAdmin;
  final bool showAppBar;

  const StatisticsPage({
    super.key,
    required this.isAdmin,
    this.showAppBar = true,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StatisticsViewModel(
        isAdmin: isAdmin,
        getDashboardUseCase: sl<GetStatisticsDashboardUseCase>(),
      ),
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
