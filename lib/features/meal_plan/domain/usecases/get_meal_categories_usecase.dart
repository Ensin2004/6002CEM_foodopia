import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/add_meal_ai_plan.dart';
import '../repositories/meal_plan_repository.dart';

class GetMealCategoriesUseCase {
  final MealPlanRepository repository;

  const GetMealCategoriesUseCase(this.repository);

  Future<Either<Failure, List<AddMealCategoryOption>>> execute() {
    return repository.getMealCategories();
  }
}
