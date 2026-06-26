import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/library_recipe.dart';
import '../repositories/library_repository.dart';
// Use case for fetching detailed information about a specific recipe
// Encapsulates the business logic for retrieving a recipe by its ID
class GetLibraryRecipeDetailUseCase {
  final LibraryRepository repository;

  const GetLibraryRecipeDetailUseCase(this.repository);
// Executes the use case to fetch recipe details
  Future<Either<Failure, LibraryRecipe>> execute(String recipeId) {
    return repository.getRecipeDetail(recipeId);
  }
}
