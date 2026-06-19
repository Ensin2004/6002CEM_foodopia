import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/add_meal_ai_plan.dart';
import '../repositories/meal_plan_repository.dart';

/// Use case for retrieving all meal categories.
/// Encapsulates the business logic for fetching meal category options.
class GetMealCategoriesUseCase {
  /// Repository instance for data operations.
  final MealPlanRepository repository;

  /// Creates a new get meal categories use case instance.
  const GetMealCategoriesUseCase(this.repository);

  /// Executes the use case.
  ///
  /// Returns either a failure or a list of meal category options on success.
  Future<Either<Failure, List<AddMealCategoryOption>>> execute() {
    // Delegate to repository to retrieve meal categories.
    return repository.getMealCategories();
  }
}