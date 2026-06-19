import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/add_recipe_repository.dart';

class GetAddRecipeIngredientImageUseCase {
  final AddRecipeRepository repository;

  const GetAddRecipeIngredientImageUseCase(this.repository);

  Future<Either<Failure, String?>> execute(String ingredientName) {
    return repository.getIngredientImageUrl(ingredientName);
  }
}
