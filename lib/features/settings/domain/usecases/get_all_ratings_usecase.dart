import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/rating.dart';
import '../repositories/rating_repository.dart';

class GetAllRatingsUseCase {
  final RatingRepository repository;

  GetAllRatingsUseCase(this.repository);

  Future<Either<Failure, List<RatingEntity>>> execute() async {
    return await repository.getAllRatings();
  }
}