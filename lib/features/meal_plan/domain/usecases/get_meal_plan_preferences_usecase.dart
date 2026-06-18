import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/meal_plan_dashboard.dart';
import '../repositories/meal_plan_repository.dart';

/// Use case for retrieving user meal preferences.
/// Encapsulates the business logic for fetching preference data.
class GetMealPlanPreferencesUseCase {
  /// Repository instance for data operations.
  final MealPlanRepository repository;

  /// Creates a new get meal plan preferences use case instance.
  const GetMealPlanPreferencesUseCase(this.repository);

  /// Executes the use case with the given user ID.
  ///
  /// [uid] is the unique identifier of the user.
  /// Returns either a failure or the preference summary on success.
  Future<Either<Failure, MealPlanPreferenceSummary>> execute(String uid) {
    // Delegate to repository to retrieve user preferences.
    return repository.getPreferences(uid);
  }
}