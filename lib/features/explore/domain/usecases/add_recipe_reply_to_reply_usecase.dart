import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/explore_repository.dart';

/// Use case for adding a nested reply to an existing reply within a comment thread.
/// Encapsulates the business logic for nested reply creation on recipe comments.
/// Delegates the nested reply operation to the explore repository.
class AddRecipeReplyToReplyUseCase {
  /// Repository dependency for accessing nested reply data operations.
  final ExploreRepository repository;

  /// Constructs the use case with the required repository instance.
  const AddRecipeReplyToReplyUseCase(this.repository);

  /// Executes the nested reply addition operation on an existing reply.
  /// [replyPath] - The hierarchical path identifier locating the parent reply.
  /// [content] - The text content of the nested reply.
  /// Returns either a Failure or void on successful nested reply creation.
  Future<Either<Failure, void>> execute({
    required String replyPath,
    required String content,
  }) {
    /// Delegate the nested reply creation to the repository implementation.
    return repository.addReplyToReply(replyPath: replyPath, content: content);
  }
}