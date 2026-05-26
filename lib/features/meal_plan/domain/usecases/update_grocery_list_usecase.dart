import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/meal_plan_repository.dart';

class UpdateGroceryListUseCase {
  final MealPlanRepository repository;

  const UpdateGroceryListUseCase(this.repository);

  Future<Either<Failure, void>> execute({
    required String listId,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return repository.updateGroceryList(
      listId: listId,
      name: name,
      startDate: startDate,
      endDate: endDate,
    );
  }
}
