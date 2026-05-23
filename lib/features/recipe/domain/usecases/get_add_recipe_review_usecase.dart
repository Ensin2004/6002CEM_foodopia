import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/add_recipe_review.dart';
import '../repositories/add_recipe_repository.dart';

class GetAddRecipeReviewUseCase {
  final AddRecipeRepository repository;

  const GetAddRecipeReviewUseCase(this.repository);

  Future<Either<Failure, AddRecipeReview>> execute(String recipeId) {
    return repository.getReview(recipeId);
  }
}
