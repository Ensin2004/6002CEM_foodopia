import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/add_grocery_list_plan.dart';
import '../repositories/meal_plan_repository.dart';

class CreateGroceryListUseCase {
  final MealPlanRepository repository;

  const CreateGroceryListUseCase(this.repository);

  Future<Either<Failure, String>> execute(CreateGroceryListRequest request) {
    return repository.createGroceryList(request);
  }
}
