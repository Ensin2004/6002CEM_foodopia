import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/manage_grocery_list_detail.dart';
import '../repositories/meal_plan_repository.dart';

/// Use case for retrieving detailed information about a grocery list.
/// Encapsulates the business logic for fetching grocery list details.
class GetManageGroceryListDetailUseCase {
  /// Repository instance for data operations.
  final MealPlanRepository repository;

  /// Creates a new get grocery list detail use case instance.
  const GetManageGroceryListDetailUseCase(this.repository);

  /// Executes the use case with the given list ID.
  ///
  /// [listId] is the ID of the grocery list to retrieve.
  /// Returns either a failure or the grocery list detail on success.
  Future<Either<Failure, ManageGroceryListDetail>> execute(String listId) {
    // Delegate to repository to retrieve the list detail.
    return repository.getManageGroceryListDetail(listId);
  }
}