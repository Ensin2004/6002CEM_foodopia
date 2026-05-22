import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/explore_repository.dart';

class UpdateRecipeVisibilityUseCase {
  final ExploreRepository repository;

  const UpdateRecipeVisibilityUseCase(this.repository);

  Future<Either<Failure, void>> execute({
    required String recipeId,
    required bool isPublished,
  }) {
    return repository.updateRecipeVisibility(
      recipeId: recipeId,
      isPublished: isPublished,
    );
  }
}
