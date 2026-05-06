import '../models/admin_home_dashboard_model.dart';

class AdminHomeMockDataSource {
  Future<AdminHomeDashboardModel> getDashboard(String adminName) async {
    return AdminHomeDashboardModel.mock(adminName);
  }
}
