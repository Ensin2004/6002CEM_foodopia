import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/meal_plan_dashboard.dart';
import '../repositories/meal_plan_repository.dart';

/// Use case for retrieving the meal plan dashboard.
/// Encapsulates the business logic for fetching dashboard data.
class GetMealPlanDashboardUseCase {
  /// Repository instance for data operations.
  final MealPlanRepository repository;

  /// Creates a new get meal plan dashboard use case instance.
  const GetMealPlanDashboardUseCase(this.repository);

  /// Executes the use case with the given parameters.
  ///
  /// [userId] is the ID of the user requesting the dashboard.
  /// [selectedDate] is the date to display in the dashboard.
  /// Returns either a failure or the meal plan dashboard on success.
  Future<Either<Failure, MealPlanDashboard>> execute({
    required String userId,
    required DateTime selectedDate,
  }) {
    // Delegate to repository to retrieve the dashboard.
    return repository.getDashboard(userId: userId, selectedDate: selectedDate);
  }

  /// Executes a planning-only refresh with the given parameters.
  Future<Either<Failure, MealPlanDashboard>> executePlanning({
    required String userId,
    required DateTime selectedDate,
  }) {
    return repository.getPlanningDashboard(
      userId: userId,
      selectedDate: selectedDate,
    );
  }
}
