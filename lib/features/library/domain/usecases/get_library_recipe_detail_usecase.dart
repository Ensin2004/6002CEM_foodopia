import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/library_recipe.dart';
import '../repositories/library_repository.dart';

class GetLibraryRecipeDetailUseCase {
  final LibraryRepository repository;

  const GetLibraryRecipeDetailUseCase(this.repository);

  Future<Either<Failure, LibraryRecipe>> execute(String recipeId) {
    return repository.getRecipeDetail(recipeId);
  }
}
