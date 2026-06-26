import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/library_repository.dart';
// Use case for toggling the favourite status of a recipe.
// This class encapsulates the business logic for adding or removing a recipe
// from user favourite list
class ToggleLibraryRecipeFavouriteUseCase {
  final LibraryRepository repository;

  const ToggleLibraryRecipeFavouriteUseCase(this.repository);
// Executes the use case to toggle favourite status
  Future<Either<Failure, void>> execute({
    required String recipeId,
    required bool isFavourite,
  }) {
    return repository.toggleFavourite(
      recipeId: recipeId,
      isFavourite: isFavourite,
    );
  }
}
