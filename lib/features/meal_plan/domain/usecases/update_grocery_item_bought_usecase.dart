import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/meal_plan_repository.dart';

class UpdateGroceryItemBoughtUseCase {
  final MealPlanRepository repository;

  const UpdateGroceryItemBoughtUseCase(this.repository);

  Future<Either<Failure, void>> execute({
    required String listId,
    required String itemId,
    required bool bought,
  }) {
    return repository.updateGroceryItemBought(
      listId: listId,
      itemId: itemId,
      bought: bought,
    );
  }
}
