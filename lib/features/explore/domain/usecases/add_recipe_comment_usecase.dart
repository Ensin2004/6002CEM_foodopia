import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/explore_repository.dart';

class AddRecipeCommentUseCase {
  final ExploreRepository repository;

  const AddRecipeCommentUseCase(this.repository);

  Future<Either<Failure, void>> execute({
    required String recipeId,
    required String content,
  }) {
    return repository.addComment(recipeId: recipeId, content: content);
  }
}
