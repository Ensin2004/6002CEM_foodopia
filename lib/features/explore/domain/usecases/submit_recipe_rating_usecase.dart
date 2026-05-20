import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/explore_repository.dart';

class SubmitRecipeRatingUseCase {
  final ExploreRepository repository;

  const SubmitRecipeRatingUseCase(this.repository);

  Future<Either<Failure, void>> execute({
    required String recipeId,
    required double rating,
  }) {
    return repository.submitRating(recipeId: recipeId, rating: rating);
  }
}
