import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/explore_repository.dart';

/// Use case for toggling like status on a recipe reply.
/// Encapsulates the business logic for liking or unliking nested replies.
/// Delegates the reply like toggle operation to the explore repository.
class ToggleRecipeReplyLikeUseCase {
  /// Repository dependency for accessing reply like data operations.
  final ExploreRepository repository;

  /// Constructs the use case with the required repository instance.
  const ToggleRecipeReplyLikeUseCase(this.repository);

  /// Executes the reply like toggle operation.
  /// [replyPath] - The hierarchical path identifier locating the target reply.
  /// Returns either a Failure or void on successful like status change.
  Future<Either<Failure, void>> execute({required String replyPath}) {
    /// Delegate the reply like toggle to the repository implementation.
    return repository.toggleReplyLike(replyPath: replyPath);
  }
}