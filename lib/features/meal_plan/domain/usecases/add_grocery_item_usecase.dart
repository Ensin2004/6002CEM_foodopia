import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/manage_grocery_list_detail.dart';
import '../repositories/meal_plan_repository.dart';

class AddGroceryItemUseCase {
  final MealPlanRepository repository;

  const AddGroceryItemUseCase(this.repository);

  Future<Either<Failure, void>> execute(AddGroceryItemRequest request) {
    return repository.addGroceryItem(request);
  }
}
