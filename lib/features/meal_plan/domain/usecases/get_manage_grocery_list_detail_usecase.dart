import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/manage_grocery_list_detail.dart';
import '../repositories/meal_plan_repository.dart';

class GetManageGroceryListDetailUseCase {
  final MealPlanRepository repository;

  const GetManageGroceryListDetailUseCase(this.repository);

  Future<Either<Failure, ManageGroceryListDetail>> execute(String listId) {
    return repository.getManageGroceryListDetail(listId);
  }
}
