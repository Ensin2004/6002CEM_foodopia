import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/add_recipe_repository.dart';

class GetAddRecipeIngredientUnitsUseCase {
  final AddRecipeRepository repository;

  const GetAddRecipeIngredientUnitsUseCase(this.repository);

  Future<Either<Failure, List<String>>> execute() {
    return repository.getIngredientUnits();
  }
}
