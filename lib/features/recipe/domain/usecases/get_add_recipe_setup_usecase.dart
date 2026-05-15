import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/add_recipe_setup.dart';
import '../repositories/add_recipe_repository.dart';

class GetAddRecipeSetupUseCase {
  final AddRecipeRepository repository;

  const GetAddRecipeSetupUseCase(this.repository);

  Future<Either<Failure, AddRecipeSetup>> execute() {
    return repository.getSetup();
  }
}

