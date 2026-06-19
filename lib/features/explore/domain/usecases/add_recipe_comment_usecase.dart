import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/explore_repository.dart';

/// Use case for adding a new comment to a recipe.
/// Encapsulates the business logic for posting comments on recipes.
/// Delegates the comment creation operation to the explore repository.
class AddRecipeCommentUseCase {
  /// Repository dependency for accessing recipe comment data operations.
  final ExploreRepository repository;

  /// Constructs the use case with the required repository instance.
  const AddRecipeCommentUseCase(this.repository);

  /// Executes the comment addition operation on a recipe.
  /// [recipeId] - The unique identifier of the recipe receiving the comment.
  /// [content] - The text content of the comment.
  /// Returns either a Failure or void on successful comment creation.
  Future<Either<Failure, void>> execute({
    required String recipeId,
    required String content,
  }) {
    /// Delegate the comment creation to the repository implementation.
    return repository.addComment(recipeId: recipeId, content: content);
  }
}