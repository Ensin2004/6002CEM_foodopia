import '../models/meal_plan_dashboard_model.dart';

class MealPlanMockDataSource {
  Future<MealPlanDashboardModel> getDashboard() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return MealPlanDashboardModel.mock();
  }
}
