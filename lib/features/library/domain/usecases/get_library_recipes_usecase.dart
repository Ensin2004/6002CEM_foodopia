import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/library_recipe.dart';
import '../repositories/library_repository.dart';

class GetLibraryRecipesUseCase {
  final LibraryRepository repository;

  const GetLibraryRecipesUseCase(this.repository);

  Future<Either<Failure, List<LibraryRecipe>>> execute() {
    return repository.getRecipes();
  }
}
