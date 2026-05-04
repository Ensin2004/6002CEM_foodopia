// Executes the delete rating use case.

import 'package:dartz/dartz.dart';

import '../../../../../../core/error/failures.dart';
import '../../../repositories/rating_repository.dart';

/// Runs the delete rating use case operation.
class DeleteRatingUseCase {
  final RatingRepository repository;

  /// Runs the delete rating use case operation.
  DeleteRatingUseCase(this.repository);

  /// Validates input and delegates the delete rating request to the repository.
  Future<Either<Failure, void>> execute(String userId) async {
    if (userId.isEmpty) {
      return Left(ValidationFailure(message: 'User ID cannot be empty'));
    }
    return await repository.deleteRating(userId);
  }
}
