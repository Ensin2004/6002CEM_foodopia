import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/rating_repository.dart';

class DeleteRatingUseCase {
  final RatingRepository repository;

  DeleteRatingUseCase(this.repository);

  Future<Either<Failure, void>> execute(String userId) async {
    if (userId.isEmpty) {
      return Left(ValidationFailure(message: 'User ID cannot be empty'));
    }
    return await repository.deleteRating(userId);
  }
}