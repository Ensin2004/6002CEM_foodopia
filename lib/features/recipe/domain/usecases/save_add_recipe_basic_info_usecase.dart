import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/add_recipe_basic_info.dart';
import '../repositories/add_recipe_repository.dart';

class SaveAddRecipeBasicInfoUseCase {
  final AddRecipeRepository repository;

  const SaveAddRecipeBasicInfoUseCase(this.repository);

  Future<Either<Failure, String>> execute(AddRecipeBasicInfo info) {
    return repository.saveBasicInfo(info);
  }
}
