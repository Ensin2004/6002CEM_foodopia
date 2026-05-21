// Executes the get all ratings use case.

import 'package:dartz/dartz.dart';
import '../../../../../../core/error/failures.dart';
import '../../../entities/rating.dart';
import '../../../repositories/rating_repository.dart';

/// Loads data for the get all ratings use case operation.
class GetAllRatingsUseCase {
  final RatingRepository repository;

  /// Loads data for the get all ratings use case operation.
  GetAllRatingsUseCase(this.repository);

  /// Validates input and delegates the get all ratings request to the repository.
  Future<Either<Failure, List<RatingEntity>>> execute() async {
    return await repository.getAllRatings();
  }
}
