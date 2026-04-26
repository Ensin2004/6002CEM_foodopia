import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/rating.dart';
import '../repositories/rating_repository.dart';

class GetUserRatingUseCase {
  final RatingRepository repository;

  GetUserRatingUseCase(this.repository);

  Future<Either<Failure, RatingEntity>> execute(String userId) async {
    if (userId.isEmpty) {
      return Left(ValidationFailure(message: 'User ID cannot be empty'));
    }
    return await repository.getUserRating(userId);
  }
}