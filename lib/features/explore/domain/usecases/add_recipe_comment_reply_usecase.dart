import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/explore_repository.dart';

class AddRecipeCommentReplyUseCase {
  final ExploreRepository repository;

  const AddRecipeCommentReplyUseCase(this.repository);

  Future<Either<Failure, void>> execute({
    required String recipeId,
    required String commentId,
    required String content,
  }) {
    return repository.addCommentReply(
      recipeId: recipeId,
      commentId: commentId,
      content: content,
    );
  }
}
