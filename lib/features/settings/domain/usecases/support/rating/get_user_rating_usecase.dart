// Executes the get user rating use case.

import 'package:dartz/dartz.dart';
import '../../../../../../core/error/failures.dart';
import '../../../entities/rating.dart';
import '../../../repositories/rating_repository.dart';

/// Loads data for the get user rating use case operation.
class GetUserRatingUseCase {
  final RatingRepository repository;

  /// Loads data for the get user rating use case operation.
  GetUserRatingUseCase(this.repository);

  /// Validates input and delegates the get user rating request to the repository.
  Future<Either<Failure, RatingEntity>> execute(String userId) async {
    if (userId.isEmpty) {
      return Left(ValidationFailure(message: 'User ID cannot be empty'));
    }
    return await repository.getUserRating(userId);
  }
}
