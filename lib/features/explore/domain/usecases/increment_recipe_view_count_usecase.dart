import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/explore_repository.dart';

/// Use case for incrementing the view count of a recipe.
/// Encapsulates the business logic for tracking recipe view statistics.
/// Delegates the view count update operation to the explore repository.
class IncrementRecipeViewCountUseCase {
  /// Repository dependency for accessing view count data operations.
  final ExploreRepository repository;

  /// Constructs the use case with the required repository instance.
  const IncrementRecipeViewCountUseCase(this.repository);

  /// Executes the view count increment operation for a recipe.
  /// [recipeId] - The unique identifier of the recipe whose view count increases.
  /// Returns either a Failure or void on successful view count update.
  Future<Either<Failure, void>> execute(String recipeId) {
    /// Delegate the view count increment to the repository implementation.
    return repository.incrementViewCount(recipeId);
  }
}