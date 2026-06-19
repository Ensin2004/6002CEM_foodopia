import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/explore_repository.dart';

/// Use case for toggling follow status on a recipe creator.
/// Encapsulates the business logic for following or unfollowing creators.
/// Delegates the follow toggle operation to the explore repository.
class ToggleCreatorFollowUseCase {
  /// Repository dependency for accessing creator follow data operations.
  final ExploreRepository repository;

  /// Constructs the use case with the required repository instance.
  const ToggleCreatorFollowUseCase(this.repository);

  /// Executes the follow status toggle operation for a creator.
  /// [creatorUid] - The unique identifier of the creator to follow or unfollow.
  /// [follow] - Boolean flag indicating whether to follow (true) or unfollow (false).
  /// Returns either a Failure or void on successful follow status change.
  Future<Either<Failure, void>> execute({
    required String creatorUid,
    required bool follow,
  }) {
    /// Delegate the follow toggle to the repository implementation.
    return repository.toggleCreatorFollow(
      creatorUid: creatorUid,
      follow: follow,
    );
  }
}