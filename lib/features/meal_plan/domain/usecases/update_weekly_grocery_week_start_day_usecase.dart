import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/meal_plan_repository.dart';

/// Use case for updating the user's weekly grocery week start day preference.
/// Encapsulates the business logic for changing week start day settings.
class UpdateWeeklyGroceryWeekStartDayUseCase {
  /// Repository instance for data operations.
  final MealPlanRepository repository;

  /// Creates a new update weekly grocery week start day use case instance.
  const UpdateWeeklyGroceryWeekStartDayUseCase(this.repository);

  /// Executes the use case with the given parameters.
  ///
  /// [userId] is the ID of the user updating their preference.
  /// [weekStartDay] is the new week start day (e.g., 'monday' or 'sunday').
  /// Returns either a failure or void on success.
  Future<Either<Failure, void>> execute({
    required String userId,
    required String weekStartDay,
  }) {
    // Delegate to repository to update the week start day preference.
    return repository.updateWeeklyGroceryWeekStartDay(
      userId: userId,
      weekStartDay: weekStartDay,
    );
  }
}