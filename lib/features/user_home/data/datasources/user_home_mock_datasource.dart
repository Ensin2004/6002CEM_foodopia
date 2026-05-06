import '../models/user_home_dashboard_model.dart';

class UserHomeMockDataSource {
  Future<UserHomeDashboardModel> getDashboard(String userName) async {
    return UserHomeDashboardModel.mock(userName);
  }
}
