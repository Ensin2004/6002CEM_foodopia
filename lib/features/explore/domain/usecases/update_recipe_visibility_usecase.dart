import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/explore_repository.dart';

/// Use case for updating the publication visibility status of a recipe.
/// Encapsulates the business logic for publishing or unpublishing recipes.
/// Delegates the visibility update operation to the explore repository.
class UpdateRecipeVisibilityUseCase {
  /// Repository dependency for accessing recipe visibility data operations.
  final ExploreRepository repository;

  /// Constructs the use case with the required repository instance.
  const UpdateRecipeVisibilityUseCase(this.repository);

  /// Executes the recipe visibility update operation.
  /// [recipeId] - The unique identifier of the recipe to update.
  /// [isPublished] - Boolean flag indicating published (true) or unpublished (false).
  /// Returns either a Failure or void on successful visibility update.
  Future<Either<Failure, void>> execute({
    required String recipeId,
    required bool isPublished,
  }) {
    /// Delegate the visibility update to the repository implementation.
    return repository.updateRecipeVisibility(
      recipeId: recipeId,
      isPublished: isPublished,
    );
  }
}