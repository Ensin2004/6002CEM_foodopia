import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/library_repository.dart';

class ToggleLibraryRecipeFavouriteUseCase {
  final LibraryRepository repository;

  const ToggleLibraryRecipeFavouriteUseCase(this.repository);

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
