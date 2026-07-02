import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/add_recipe_repository.dart';

/// Updates recipe visibility between private and public.
class UpdateAddRecipeVisibilityUseCase {
  final AddRecipeRepository repository;

  const UpdateAddRecipeVisibilityUseCase(this.repository);

  Future<Either<Failure, void>> execute({
    required String recipeId,
    required String visibility,
  }) {
    return repository.updateVisibility(
      recipeId: recipeId,
      visibility: visibility,
    );
  }
}
