import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/explore_repository.dart';

/// Use case for submitting a rating for a recipe.
/// Encapsulates the business logic for rating recipes in the explore section.
/// Delegates the rating submission operation to the explore repository.
class SubmitRecipeRatingUseCase {
  /// Repository dependency for accessing rating data operations.
  final ExploreRepository repository;

  /// Constructs the use case with the required repository instance.
  const SubmitRecipeRatingUseCase(this.repository);

  /// Executes the rating submission operation for a recipe.
  /// [recipeId] - The unique identifier of the recipe being rated.
  /// [rating] - The numerical rating value to assign to the recipe.
  /// Returns either a Failure or void on successful rating submission.
  Future<Either<Failure, void>> execute({
    required String recipeId,
    required double rating,
  }) {
    /// Delegate the rating submission to the repository implementation.
    return repository.submitRating(recipeId: recipeId, rating: rating);
  }
}