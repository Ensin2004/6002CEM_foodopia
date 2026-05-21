import 'package:flutter/foundation.dart';

import '../../domain/entities/admin_home_dashboard.dart';
import '../../domain/usecases/get_admin_home_dashboard_usecase.dart';

class AdminHomeViewModel extends ChangeNotifier {
  final String adminName;
  final GetAdminHomeDashboardUseCase _getDashboardUseCase;

  bool _isLoading = true;
  String? _errorMessage;
  AdminHomeDashboard? _dashboard;

  AdminHomeViewModel({
    required this.adminName,
    required GetAdminHomeDashboardUseCase getDashboardUseCase,
  }) : _getDashboardUseCase = getDashboardUseCase {
    Future.microtask(loadDashboard);
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  AdminHomeDashboard? get dashboard => _dashboard;

  Future<void> loadDashboard() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _getDashboardUseCase.execute(adminName);
    result.fold(
      (failure) => _errorMessage = failure.message,
      (dashboard) => _dashboard = dashboard,
    );

    _isLoading = false;
    notifyListeners();
  }
}
