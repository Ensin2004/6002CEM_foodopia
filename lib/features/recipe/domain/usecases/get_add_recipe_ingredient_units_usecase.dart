import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/add_recipe_ingredient_unit.dart';
import '../repositories/add_recipe_repository.dart';

class GetAddRecipeIngredientUnitsUseCase {
  final AddRecipeRepository repository;

  const GetAddRecipeIngredientUnitsUseCase(this.repository);

  Future<Either<Failure, List<AddRecipeIngredientUnit>>> execute() {
    return repository.getIngredientUnits();
  }
}
