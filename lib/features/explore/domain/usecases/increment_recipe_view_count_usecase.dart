import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/explore_repository.dart';

class IncrementRecipeViewCountUseCase {
  final ExploreRepository repository;

  const IncrementRecipeViewCountUseCase(this.repository);

  Future<Either<Failure, void>> execute(String recipeId) {
    return repository.incrementViewCount(recipeId);
  }
}
