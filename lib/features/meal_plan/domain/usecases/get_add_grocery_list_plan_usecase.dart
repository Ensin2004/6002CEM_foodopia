import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/add_grocery_list_plan.dart';
import '../repositories/meal_plan_repository.dart';

class GetAddGroceryListPlanUseCase {
  final MealPlanRepository repository;

  const GetAddGroceryListPlanUseCase(this.repository);

  Future<Either<Failure, AddGroceryListPlan>> execute() {
    return repository.getAddGroceryListPlan();
  }
}
