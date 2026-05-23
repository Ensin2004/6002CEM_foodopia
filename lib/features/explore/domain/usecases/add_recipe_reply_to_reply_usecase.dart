import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/explore_repository.dart';

class AddRecipeReplyToReplyUseCase {
  final ExploreRepository repository;

  const AddRecipeReplyToReplyUseCase(this.repository);

  Future<Either<Failure, void>> execute({
    required String replyPath,
    required String content,
  }) {
    return repository.addReplyToReply(replyPath: replyPath, content: content);
  }
}
