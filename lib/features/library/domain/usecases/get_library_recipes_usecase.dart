import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/library_recipe.dart';
import '../repositories/library_repository.dart';
// Use case for fetching recipes from the library
// Encapsulates the business logic for retrieving recipe lists
class GetLibraryRecipesUseCase {
  final LibraryRepository repository;

  const GetLibraryRecipesUseCase(this.repository);
// Executes a one-time fetch of all recipes
  Future<Either<Failure, List<LibraryRecipe>>> execute() {
    return repository.getRecipes();
  }
// Provides a real-time stream of recipe list updates
  Stream<Either<Failure, List<LibraryRecipe>>> watch() {
    return repository.watchRecipes();
  }
}
