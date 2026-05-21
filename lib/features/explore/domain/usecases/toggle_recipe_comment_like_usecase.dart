import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/explore_repository.dart';

class ToggleRecipeCommentLikeUseCase {
  final ExploreRepository repository;

  const ToggleRecipeCommentLikeUseCase(this.repository);

  Future<Either<Failure, void>> execute({
    required String recipeId,
    required String commentId,
  }) {
    return repository.toggleCommentLike(
      recipeId: recipeId,
      commentId: commentId,
    );
  }
}
