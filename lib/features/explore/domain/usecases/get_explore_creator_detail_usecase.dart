import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/explore_recipe.dart';
import '../repositories/explore_repository.dart';

/// Use case for retrieving detailed profile information about a recipe creator.
/// Encapsulates the business logic for fetching creator details from the explore module.
/// Delegates the detail retrieval operation to the explore repository.
class GetExploreCreatorDetailUseCase {
  /// Repository dependency for accessing creator detail data operations.
  final ExploreRepository repository;

  /// Constructs the use case with the required repository instance.
  const GetExploreCreatorDetailUseCase(this.repository);

  /// Executes the creator detail retrieval operation.
  /// [creatorUid] - The unique identifier of the creator whose details are requested.
  /// Returns either a Failure or the requested ExploreCreatorDetail entity.
  Future<Either<Failure, ExploreCreatorDetail>> execute(String creatorUid) {
    /// Delegate the creator detail retrieval to the repository implementation.
    return repository.getCreatorDetail(creatorUid);
  }
}