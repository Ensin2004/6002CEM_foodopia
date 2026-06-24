import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/add_recipe_repository.dart';

/// Loads USDA label nutrients for a selected food result.
class GetAddRecipeFoodNutrientsUseCase {
  final AddRecipeRepository repository;

  const GetAddRecipeFoodNutrientsUseCase(this.repository);

  Future<Either<Failure, Map<String, dynamic>?>> execute(int fdcId) {
    return repository.getFoodLabelNutrients(fdcId);
  }
}
