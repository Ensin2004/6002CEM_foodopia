import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/meal_plan_inspiration_input.dart';
import '../repositories/meal_plan_repository.dart';

/// Use case for retrieving inspiration preference options.
/// Encapsulates the business logic for fetching preference options.
class GetMealPlanInspirationOptionsUseCase {
  /// Repository instance for data operations.
  final MealPlanRepository repository;

  /// Creates a new get inspiration options use case instance.
  const GetMealPlanInspirationOptionsUseCase(this.repository);

  /// Executes the use case with the given category ID.
  ///
  /// [categoryId] is the ID of the category to get options for.
  /// Returns either a failure or a list of preference options on success.
  Future<Either<Failure, List<MealPlanPreferenceOption>>> execute(
      String categoryId,
      ) {
    // Delegate to repository to retrieve preference options.
    return repository.getInspirationPreferenceOptions(categoryId);
  }
}