import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/explore_repository.dart';

class ToggleRecipeReplyLikeUseCase {
  final ExploreRepository repository;

  const ToggleRecipeReplyLikeUseCase(this.repository);

  Future<Either<Failure, void>> execute({required String replyPath}) {
    return repository.toggleReplyLike(replyPath: replyPath);
  }
}
