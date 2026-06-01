import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/meal_plan_repository.dart';

class DeleteGroceryItemUseCase {
  final MealPlanRepository repository;

  const DeleteGroceryItemUseCase(this.repository);

  Future<Either<Failure, void>> execute({
    required String listId,
    required String itemId,
  }) {
    return repository.deleteGroceryItem(listId: listId, itemId: itemId);
  }
}
