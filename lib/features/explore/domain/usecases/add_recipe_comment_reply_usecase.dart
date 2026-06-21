import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/explore_repository.dart';

/// Use case for adding a reply to an existing comment on a recipe.
/// Encapsulates the business logic for replying to recipe comments.
/// Delegates the actual operation to the explore repository.
class AddRecipeCommentReplyUseCase {
  /// Repository dependency for accessing recipe comment reply data operations.
  final ExploreRepository repository;

  /// Constructs the use case with the required repository instance.
  const AddRecipeCommentReplyUseCase(this.repository);

  /// Executes the comment reply addition operation.
  /// [recipeId] - The unique identifier of the recipe containing the comment.
  /// [commentId] - The unique identifier of the parent comment being replied to.
  /// [content] - The text content of the reply.
  /// Returns either a Failure or void on successful reply creation.
  Future<Either<Failure, void>> execute({
    required String recipeId,
    required String commentId,
    required String content,
  }) {
    /// Delegate the reply creation to the repository implementation.
    return repository.addCommentReply(
      recipeId: recipeId,
      commentId: commentId,
      content: content,
    );
  }
}