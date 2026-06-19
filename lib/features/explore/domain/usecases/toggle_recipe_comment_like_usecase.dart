import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/explore_repository.dart';

/// Use case for toggling like status on a recipe comment.
/// Encapsulates the business logic for liking or unliking recipe comments.
/// Delegates the comment like toggle operation to the explore repository.
class ToggleRecipeCommentLikeUseCase {
  /// Repository dependency for accessing comment like data operations.
  final ExploreRepository repository;

  /// Constructs the use case with the required repository instance.
  const ToggleRecipeCommentLikeUseCase(this.repository);

  /// Executes the comment like toggle operation.
  /// [recipeId] - The unique identifier of the recipe containing the comment.
  /// [commentId] - The unique identifier of the comment to like or unlike.
  /// Returns either a Failure or void on successful like status change.
  Future<Either<Failure, void>> execute({
    required String recipeId,
    required String commentId,
  }) {
    /// Delegate the comment like toggle to the repository implementation.
    return repository.toggleCommentLike(
      recipeId: recipeId,
      commentId: commentId,
    );
  }
}